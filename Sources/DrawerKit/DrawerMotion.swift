import SwiftUI

/// Pure geometry and settling rules shared by the view and its tests.
@available(iOS 18.0, macOS 15.0, *)
struct DrawerMotion {
    static let minimumVisibleContentWidth: CGFloat = 44

    let requestedWidth: CGFloat
    let containerWidth: CGFloat

    var width: CGFloat {
        let requestedWidth = max(0, requestedWidth)
        guard containerWidth > 0 else { return requestedWidth }
        return min(requestedWidth, max(0, containerWidth - Self.minimumVisibleContentWidth))
    }

    static func normalizedTranslation(
        _ translation: CGFloat,
        isOpen: Bool,
        width: CGFloat,
        offsetSign: CGFloat
    ) -> CGFloat {
        let translation = offsetSign * translation
        return isOpen
            ? min(0, max(-width, translation))
            : min(width, max(0, translation))
    }

    static func settlesOpen(
        isOpen: Bool,
        width: CGFloat,
        threshold: CGFloat,
        translation: CGFloat,
        predictedTranslation: CGFloat
    ) -> Bool {
        let threshold = min(1, max(0, threshold))
        let resting = isOpen ? width : 0
        let target = width * threshold
        return (resting + predictedTranslation) > target || (resting + translation) > target
    }
}

@available(iOS 18.0, macOS 15.0, *)
extension DrawerConfiguration {
    var resolvedShadowRadius: CGFloat { max(0, shadowRadius) }
    var resolvedEdgeRevealWidth: CGFloat { max(0, edgeRevealWidth) }
    var resolvedMinimumDragDistance: CGFloat { max(0, minimumDragDistance) }
    var resolvedOpenThreshold: CGFloat { min(1, max(0, openThreshold)) }
    var resolvedContentDimOpacity: CGFloat { min(1, max(0, contentDimOpacity)) }
    var resolvedContentCornerRadius: CGFloat? { contentCornerRadius.map { max(0, $0) } }
}
