import SwiftUI

/// A navigation panel that moves the app's content aside instead of covering it.
///
/// The drawer owns the background, motion, gestures and safe-area behaviour; the panel and the
/// content are whatever the host puts in them. Panel and content use the system safe area
/// normally — only the shared background extends under system chrome.
///
/// ```swift
/// Drawer(isOpen: $isOpen) {
///     SidebarView()
/// } content: {
///     NavigationStack { HomeView() }
/// }
/// ```
///
/// Pass a ``DrawerConfiguration`` to change width, motion, gestures, chrome or side.
@available(iOS 18.0, macOS 15.0, *)
public struct Drawer<Panel: View, Content: View>: View {
    /// What the drawer decided about the gesture in flight. The decision is taken once, on the
    /// first movement, and held for the rest of the gesture so a drag can't change its mind
    /// halfway down a scroll.
    private enum DragIntent {
        case tracking
        case rejected
    }

    @Binding private var isOpen: Bool

    private let configuration: DrawerConfiguration
    private let panel: Panel
    private let content: Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.layoutDirection) private var layoutDirection

    // Plain state, not `@GestureState`: a gesture state's reset transaction is empty, so a drag
    // released short of the threshold snapped back with no animation at all. Owning the value is
    // what lets the release be a settle rather than a cut.
    @State private var drag: CGFloat = 0
    @State private var dragIntent: DragIntent?
    @State private var containerWidth: CGFloat = 0

    /// Creates a drawer with a panel behind the main content.
    ///
    /// - Parameters:
    ///   - isOpen: A binding that controls presentation and receives gesture-driven state changes.
    ///   - configuration: Layout, gesture, appearance, feedback, and accessibility options.
    ///   - panel: The navigation panel shown behind the moved content.
    ///   - content: The app's main content.
    public init(
        isOpen: Binding<Bool>,
        configuration: DrawerConfiguration = DrawerConfiguration(),
        @ViewBuilder panel: () -> Panel,
        @ViewBuilder content: () -> Content
    ) {
        _isOpen = isOpen
        self.configuration = configuration
        self.panel = panel()
        self.content = content()
    }

    /// The composed drawer hierarchy.
    public var body: some View {
        ZStack(alignment: configuration.edge.alignment) {
            movedPanel

            movedContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(configuration.backgroundColor.ignoresSafeArea())
        .overlay(alignment: configuration.edge.alignment) { revealEdge }
        .onGeometryChange(for: CGFloat.self, of: { $0.size.width }) { containerWidth = $0 }
        // Not `.animation(_:value:)`: that overrides the ambient transaction, which would throw
        // away the velocity spring a released drag builds. This supplies the default animation
        // only when the change arrived without one — a host toggling `isOpen` directly.
        .transaction(value: isOpen) { transaction in
            if transaction.animation == nil { transaction.animation = resolvedAnimation }
        }
        .onChange(of: isOpen) { _, _ in
            // Safety net for a gesture cancelled without `onEnded`, which would otherwise strand
            // the offset. A drag settling on its own has already zeroed this.
            if dragIntent == nil { drag = 0 }
        }
        .sensoryFeedback(.impact(flexibility: .soft), trigger: hapticTrigger)
        .accessibilityAction(.escape, close)
    }

    // MARK: - Content

    private var movedPanel: some View {
        panel
            .frame(width: width)
            .frame(maxHeight: .infinity, alignment: .top)
            .offset(x: -offsetSign * parallaxDistance * (1 - progress))
            .opacity(panelOpacity)
            .allowsHitTesting(isOpen)
            .accessibilityHidden(!isOpen)
    }

    private var movedContent: some View {
        ZStack {
            contentShape
                .fill(configuration.backgroundColor)
                .shadow(
                    color: shadowColor,
                    radius: configuration.resolvedShadowRadius * progress
                )
                .ignoresSafeArea()

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .mask {
                    contentShape
                        .ignoresSafeArea()
                }
                .allowsHitTesting(!isOpen)
                .accessibilityHidden(isOpen)
        }
        .overlay { dimScrim }
        .overlay {
            if isOpen {
                // Nothing on screen closes the drawer for VoiceOver, since the content behind it is
                // hidden. This gives it one control to do so.
                Button(configuration.closeAccessibilityLabel, action: close)
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .foregroundStyle(.clear)
                    .contentShape(Rectangle())
            }
        }
        .offset(x: offsetSign * contentOffset)
        .simultaneousGesture(drawerGesture, including: closeGestureMask)
    }

    /// Tracks the drag rather than appearing with the open state, so a half-open drawer is half
    /// dimmed.
    @ViewBuilder
    private var dimScrim: some View {
        let opacity = configuration.resolvedContentDimOpacity * progress

        if opacity > 0 {
            contentShape
                .fill(Color.black.opacity(opacity))
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
    }

    /// A strip along the panel's edge that starts a reveal while the drawer is closed. The
    /// content's own horizontal gestures win everywhere else.
    @ViewBuilder
    private var revealEdge: some View {
        if !isOpen && configuration.isRevealGestureEnabled {
            Color.clear
                .frame(width: configuration.resolvedEdgeRevealWidth)
                .contentShape(Rectangle())
                .gesture(drawerGesture)
                .accessibilityHidden(true)
        }
    }

    // MARK: - Geometry

    private var offsetSign: CGFloat {
        configuration.edge.offsetSign(for: layoutDirection)
    }

    private var width: CGFloat {
        DrawerMotion(requestedWidth: configuration.width, containerWidth: containerWidth).width
    }

    /// Where the content sits right now, resting position plus whatever the finger has added. It
    /// may run slightly past either end while a drag is rubber-banding.
    private var contentOffset: CGFloat {
        (isOpen ? width : 0) + drag
    }

    /// How far through the open transition the drawer is, clamped so an overshooting drag doesn't
    /// over-dim or over-fade anything.
    private var progress: CGFloat {
        guard width > 0 else { return isOpen ? 1 : 0 }
        return min(1, max(0, contentOffset / width))
    }

    private var parallaxDistance: CGFloat {
        width * configuration.resolvedPanelParallax
    }

    private var panelOpacity: CGFloat {
        let parallax = configuration.resolvedPanelParallax
        guard parallax > 0 else { return 1 }
        return (1 - parallax) + parallax * progress
    }

    private var contentShape: AnyShape {
        if let cornerRadius = configuration.resolvedContentCornerRadius {
            return AnyShape(RoundedRectangle(cornerRadius: cornerRadius))
        }

        // A bare `ConcentricRectangle` resolves against an ancestor container shape, and the
        // drawer's content has none — it sits in the app's root, not in a rounded container — so
        // it came out square. The display's own radius is the floor instead; a host that does put
        // the drawer inside a rounded container still gets a shape concentric with it.
        if #available(iOS 26, macOS 26, *) {
            return AnyShape(
                ConcentricRectangle(
                    corners: .concentric(minimum: .fixed(DisplayCornerRadius.current)),
                    isUniform: true
                )
            )
        }

        return AnyShape(RoundedRectangle(cornerRadius: DisplayCornerRadius.current))
    }

    private var shadowColor: Color {
        if let shadowColor = configuration.shadowColor { return shadowColor }
        let opacity = colorScheme == .dark ? 0.08 : 0.2
        return (colorScheme == .dark ? Color.white : Color.black).opacity(opacity)
    }

    private var resolvedAnimation: Animation? {
        suppressesMotion ? nil : configuration.animation
    }

    private var suppressesMotion: Bool {
        configuration.respectsReduceMotion && reduceMotion
    }

    private var hapticTrigger: Bool {
        configuration.providesHapticFeedback ? isOpen : false
    }

    // MARK: - Gestures

    private var closeGestureMask: GestureMask {
        isOpen && configuration.isCloseGestureEnabled ? .all : .none
    }

    private var drawerGesture: some Gesture {
        DragGesture(
            minimumDistance: configuration.resolvedMinimumDragDistance,
            coordinateSpace: .global
        )
        .onChanged(trackDrag)
        .onEnded(finishDrag)
    }

    private var canTrack: Bool {
        isOpen ? configuration.isCloseGestureEnabled : configuration.isRevealGestureEnabled
    }

    private func normalizedTranslation(_ translation: CGFloat) -> CGFloat {
        DrawerMotion.normalizedTranslation(
            translation,
            isOpen: isOpen,
            width: width,
            offsetSign: offsetSign,
            rubberBandFactor: configuration.resolvedRubberBandFactor
        )
    }

    private func trackDrag(_ value: DragGesture.Value) {
        guard canTrack else { return }

        if dragIntent == nil {
            let isHorizontal =
                !configuration.requiresHorizontalIntent
                || DrawerMotion.beginsHorizontally(value.translation)
            dragIntent = isHorizontal ? .tracking : .rejected
        }

        guard dragIntent == .tracking else { return }

        drag = normalizedTranslation(value.translation.width)
    }

    private func finishDrag(_ value: DragGesture.Value) {
        defer { dragIntent = nil }

        guard canTrack, dragIntent == .tracking else { return }

        let translation = normalizedTranslation(value.translation.width)
        let predictedTranslation = normalizedTranslation(value.predictedEndTranslation.width)

        let settlesOpen = DrawerMotion.settlesOpen(
            isOpen: isOpen,
            width: width,
            threshold: configuration.resolvedOpenThreshold,
            translation: translation,
            predictedTranslation: predictedTranslation
        )

        let animation = releaseAnimation(
            velocity: value.velocity.width,
            from: contentOffset,
            to: settlesOpen ? width : 0
        )

        withAnimation(animation) {
            drag = 0
            isOpen = settlesOpen
        }
    }

    /// The spring a released drag settles on. It carries the lift-off velocity, so the content
    /// keeps the speed the finger gave it instead of stopping and starting again.
    private func releaseAnimation(
        velocity: CGFloat,
        from currentOffset: CGFloat,
        to targetOffset: CGFloat
    ) -> Animation? {
        guard !suppressesMotion else { return nil }
        guard configuration.tracksReleaseVelocity else { return configuration.animation }

        return .interpolatingSpring(
            duration: configuration.resolvedReleaseDuration,
            bounce: configuration.resolvedReleaseBounce,
            initialVelocity: DrawerMotion.initialVelocity(
                velocity,
                offsetSign: offsetSign,
                from: currentOffset,
                to: targetOffset
            )
        )
    }

    private func close() {
        isOpen = false
    }
}

@available(iOS 18.0, macOS 15.0, *)
#Preview {
    @Previewable @State var isOpen = true

    Drawer(isOpen: $isOpen) {
        Text("Navigation")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    } content: {
        Button("Toggle Drawer") { isOpen.toggle() }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.platformBackground)
    }
}
