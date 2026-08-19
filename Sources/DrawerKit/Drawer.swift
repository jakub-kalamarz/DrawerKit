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
    @Binding private var isOpen: Bool

    private let configuration: DrawerConfiguration
    private let panel: Panel
    private let content: Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.layoutDirection) private var layoutDirection
    @GestureState private var dragOffset: CGFloat = 0
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
            panel
                .frame(width: width)
                .frame(maxHeight: .infinity, alignment: .top)
                .allowsHitTesting(isOpen)
                .accessibilityHidden(!isOpen)

            movedContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(configuration.backgroundColor.ignoresSafeArea())
        .overlay(alignment: configuration.edge.alignment) { revealEdge }
        .onGeometryChange(for: CGFloat.self, of: { $0.size.width }) { containerWidth = $0 }
        .animation(resolvedAnimation, value: isOpen)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: hapticTrigger)
        .accessibilityAction(.escape, close)
    }

    // MARK: - Content

    private var movedContent: some View {
        ZStack {
            contentShape
                .fill(configuration.backgroundColor)
                .shadow(
                    color: shadowColor,
                    radius: contentOffset == 0 ? 0 : configuration.resolvedShadowRadius
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
        .overlay {
            if isOpen {
                dimScrim

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

    @ViewBuilder
    private var dimScrim: some View {
        if configuration.resolvedContentDimOpacity > 0 {
            contentShape
                .fill(Color.black.opacity(configuration.resolvedContentDimOpacity))
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

    private var contentOffset: CGFloat {
        let restingOffset = isOpen ? width : 0
        return min(width, max(0, restingOffset + dragOffset))
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
        configuration.respectsReduceMotion && reduceMotion ? nil : configuration.animation
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
        .updating($dragOffset) { value, state, _ in
            guard canTrack else { return }
            state = normalizedTranslation(value.translation.width)
        }
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
            offsetSign: offsetSign
        )
    }

    private func finishDrag(_ value: DragGesture.Value) {
        guard canTrack else { return }

        let translation = normalizedTranslation(value.translation.width)
        let predictedTranslation = normalizedTranslation(value.predictedEndTranslation.width)

        isOpen = DrawerMotion.settlesOpen(
            isOpen: isOpen,
            width: width,
            threshold: configuration.resolvedOpenThreshold,
            translation: translation,
            predictedTranslation: predictedTranslation
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
