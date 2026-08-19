import SwiftUI

/// Pure geometry and settling rules shared by the view and its tests.
@available(iOS 18.0, macOS 15.0, *)
struct DrawerMotion {
    static let minimumVisibleContentWidth: CGFloat = 44

    /// Ceiling on the spring velocity handed to a release animation. A drag released a hair from
    /// its destination divides a real velocity by a near-zero distance, which asks for a spring
    /// that overshoots the screen.
    static let maximumInitialVelocity: Double = 40

    let requestedWidth: CGFloat
    let containerWidth: CGFloat

    var width: CGFloat {
        let requestedWidth = max(0, requestedWidth)
        guard containerWidth > 0 else { return requestedWidth }
        return min(requestedWidth, max(0, containerWidth - Self.minimumVisibleContentWidth))
    }

    /// Folds a raw drag into the drawer's travel range. Past either end the drag keeps moving, but
    /// with a decaying tail rather than against a wall — `rubberBandFactor` is the fraction of
    /// `width` that tail can ever reach, and zero restores a hard clamp.
    static func normalizedTranslation(
        _ translation: CGFloat,
        isOpen: Bool,
        width: CGFloat,
        offsetSign: CGFloat,
        rubberBandFactor: CGFloat = 0
    ) -> CGFloat {
        let translation = offsetSign * translation
        let lowerBound = isOpen ? -width : 0
        let upperBound = isOpen ? 0 : width

        if translation < lowerBound {
            return lowerBound
                - rubberBand(lowerBound - translation, limit: width, factor: rubberBandFactor)
        }
        if translation > upperBound {
            return upperBound
                + rubberBand(translation - upperBound, limit: width, factor: rubberBandFactor)
        }
        return translation
    }

    /// Follows the finger 1:1 at the start and saturates at `limit * factor`, so the end of the
    /// travel is felt as resistance rather than as a dead stop.
    static func rubberBand(_ distance: CGFloat, limit: CGFloat, factor: CGFloat) -> CGFloat {
        let factor = min(1, max(0, factor))
        let maximum = limit * factor
        guard distance > 0, maximum > 0 else { return 0 }
        return maximum * (1 - exp(-distance / maximum))
    }

    /// Whether a gesture's first movement is horizontal enough to belong to the drawer. Without
    /// this a list scroll that drifts sideways past the minimum distance starts a reveal.
    static func beginsHorizontally(_ translation: CGSize) -> Bool {
        abs(translation.width) > abs(translation.height)
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

    /// Converts a lift-off velocity in points per second into the units a spring wants: multiples
    /// of the distance still to travel, per second. This is what keeps the content moving at the
    /// speed the finger left it instead of restarting from rest.
    static func initialVelocity(
        _ velocity: CGFloat,
        offsetSign: CGFloat,
        from currentOffset: CGFloat,
        to targetOffset: CGFloat
    ) -> Double {
        let remaining = targetOffset - currentOffset
        guard abs(remaining) > 0.5 else { return 0 }
        let normalized = Double((offsetSign * velocity) / remaining)
        return min(maximumInitialVelocity, max(-maximumInitialVelocity, normalized))
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
    var resolvedPanelParallax: CGFloat { min(1, max(0, panelParallax)) }
    var resolvedRubberBandFactor: CGFloat { min(1, max(0, rubberBandFactor)) }
    var resolvedReleaseDuration: Double { max(0, releaseDuration) }
    var resolvedReleaseBounce: Double { min(1, max(-1, releaseBounce)) }
}
