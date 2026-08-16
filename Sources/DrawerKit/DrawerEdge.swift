import SwiftUI

/// The side of the screen the panel sits on.
@available(iOS 18.0, macOS 15.0, *)
public enum DrawerEdge: Hashable, Sendable {
    /// Pinned to the leading side, which still flips with the layout direction.
    case leading
    /// Pinned to the trailing side, which still flips with the layout direction.
    case trailing

    var alignment: Alignment {
        switch self {
        case .leading: return .leading
        case .trailing: return .trailing
        }
    }

    /// The sign of the x offset that moves the content away from the panel. `.offset(x:)` works in
    /// raw coordinates, so the layout direction has to be folded in by hand.
    func offsetSign(for layoutDirection: LayoutDirection) -> CGFloat {
        let mirrored: CGFloat = layoutDirection == .rightToLeft ? -1 : 1
        switch self {
        case .leading: return mirrored
        case .trailing: return -mirrored
        }
    }
}
