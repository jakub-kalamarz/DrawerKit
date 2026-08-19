import SwiftUI

/// Everything about a ``Drawer`` that a host may want to change. Defaults describe a standard
/// full-height navigation panel; a `Drawer` built with `.init()` needs nothing else.
@available(iOS 18.0, macOS 15.0, *)
public struct DrawerConfiguration: Equatable, Sendable {

    // MARK: - Layout and Motion

    /// Preferred panel width. The drawer preserves at least a 44-point dismiss target when space
    /// allows. Negative values resolve to zero.
    public var width: CGFloat = 320

    /// The radius the content is rounded and masked to. `nil` matches the device's display corners,
    /// so the moved-aside content looks like the screen it came from.
    public var contentCornerRadius: CGFloat?

    /// The animation used when `isOpen` changes from outside a gesture — a toggle button, a
    /// navigation. `nil` moves without animating. A drag release uses ``releaseDuration`` and
    /// ``releaseBounce`` instead, so it can carry the fling's velocity.
    public var animation: Animation? = .spring(duration: 0.35, bounce: 0.1)

    /// Duration of the spring that settles a released drag. Values below zero resolve to zero.
    public var releaseDuration: Double = 0.35

    /// Bounce of the spring that settles a released drag. Values are clamped to `-1...1`; zero is
    /// critically damped.
    public var releaseBounce: Double = 0.1

    /// Whether a released drag hands its velocity to the settling spring. Off, a flick and a slow
    /// release settle identically, which is what makes a drawer read as animated rather than moved.
    public var tracksReleaseVelocity: Bool = true

    /// How far the panel trails the content, as a fraction of ``width``. The panel sits offset
    /// behind the closed content and catches up as the drawer opens, fading in over the same
    /// travel, so the two read as separate layers. Zero holds the panel still. Clamped to `0...1`.
    public var panelParallax: CGFloat = 0.35

    /// Blur radius of the shadow cast by the content while it is moved aside. Values below zero
    /// resolve to zero.
    public var shadowRadius: CGFloat = 14

    /// `nil` derives a shadow from the color scheme: black at 20% in light, white at 8% in dark.
    public var shadowColor: Color?

    // MARK: - Gestures

    /// Whether dragging inwards from the panel's edge reveals the drawer. Turn this off on screens
    /// whose own content owns the horizontal axis; closing by drag keeps working.
    public var isRevealGestureEnabled: Bool = true

    /// Whether dragging the open content back over the panel closes the drawer.
    public var isCloseGestureEnabled: Bool = true

    /// Width of the edge strip that starts a reveal while the drawer is closed. Values below zero
    /// resolve to zero.
    public var edgeRevealWidth: CGFloat = 24

    /// How far a drag must travel before it is treated as a drawer drag rather than a tap. Values
    /// below zero resolve to zero.
    public var minimumDragDistance: CGFloat = 10

    /// The fraction of ``width`` a drag must reach, or be flung past, to settle open. Values are
    /// clamped to `0...1`.
    public var openThreshold: CGFloat = 0.5

    /// Whether a gesture must start out more horizontal than vertical to be taken as a drawer
    /// drag. Off, a vertical scroll that drifts past ``minimumDragDistance`` sideways opens the
    /// drawer.
    public var requiresHorizontalIntent: Bool = true

    /// The fraction of ``width`` a drag may travel past either end of the drawer's range, with
    /// decaying resistance. Zero stops the drag dead at the ends. Clamped to `0...1`.
    public var rubberBandFactor: CGFloat = 0.08

    // MARK: - Chrome and Feedback

    /// Painted behind both the panel and the content, including under the system safe areas.
    public var backgroundColor: Color = .platformBackground

    /// Whether a soft impact plays when the drawer settles into a new state.
    public var providesHapticFeedback: Bool = true

    /// Opacity of a scrim drawn over the content while the drawer is open. Values are clamped to
    /// `0...1`; zero draws no scrim.
    public var contentDimOpacity: CGFloat = 0

    // MARK: - Side and Accessibility

    /// The side the panel sits on.
    public var edge: DrawerEdge = .leading

    /// Whether the Reduce Motion setting suppresses ``animation``.
    public var respectsReduceMotion: Bool = true

    /// Label for the offscreen control that lets assistive technologies close the drawer.
    public var closeAccessibilityLabel: String = "Close navigation"

    /// Creates a configuration with the standard DrawerKit defaults.
    public init() {}
}
