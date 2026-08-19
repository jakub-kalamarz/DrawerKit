import SwiftUI
import XCTest

@testable import DrawerKit

@available(iOS 18.0, macOS 15.0, *)
final class DrawerMotionTests: XCTestCase {
    func test_widthPreservesDismissTarget() {
        let motion = DrawerMotion(requestedWidth: 320, containerWidth: 350)

        XCTAssertEqual(motion.width, 306)
    }

    func test_widthUsesRequestedWidthWhenSpaceAllows() {
        let motion = DrawerMotion(requestedWidth: 320, containerWidth: 430)

        XCTAssertEqual(motion.width, 320)
    }

    func test_widthClampsNegativeValues() {
        let motion = DrawerMotion(requestedWidth: -40, containerWidth: 430)

        XCTAssertEqual(motion.width, 0)
    }

    func test_openTranslationOnlyTracksTowardClosingEdge() {
        XCTAssertEqual(
            DrawerMotion.normalizedTranslation(
                -120,
                isOpen: true,
                width: 320,
                offsetSign: 1
            ),
            -120
        )
        XCTAssertEqual(
            DrawerMotion.normalizedTranslation(
                120,
                isOpen: true,
                width: 320,
                offsetSign: 1
            ),
            0
        )
    }

    func test_dragStopsDeadAtTheEndsWithoutRubberBanding() {
        XCTAssertEqual(
            DrawerMotion.normalizedTranslation(
                500,
                isOpen: false,
                width: 320,
                offsetSign: 1
            ),
            320
        )
    }

    func test_rubberBandingLetsADragRunPastOpenWithDecayingResistance() {
        let overshoot = DrawerMotion.normalizedTranslation(
            420,
            isOpen: false,
            width: 320,
            offsetSign: 1,
            rubberBandFactor: 0.08
        )

        XCTAssertGreaterThan(overshoot, 320)
        XCTAssertLessThan(overshoot, 320 + 320 * 0.08)
    }

    func test_rubberBandSaturatesAtItsFractionOfWidth() {
        let far = DrawerMotion.rubberBand(100_000, limit: 320, factor: 0.08)

        XCTAssertEqual(far, 320 * 0.08, accuracy: 0.001)
    }

    func test_rubberBandFollowsTheFingerAtTheStartOfTheOvershoot() {
        let nudge = DrawerMotion.rubberBand(1, limit: 320, factor: 0.08)

        XCTAssertEqual(nudge, 1, accuracy: 0.1)
    }

    func test_horizontalIntentRejectsAMostlyVerticalGesture() {
        XCTAssertTrue(DrawerMotion.beginsHorizontally(CGSize(width: 12, height: 6)))
        XCTAssertFalse(DrawerMotion.beginsHorizontally(CGSize(width: 6, height: 12)))
    }

    func test_initialVelocityIsMeasuredAgainstTheDistanceStillToTravel() {
        // Half the remaining travel every second is a spring velocity of 0.5.
        XCTAssertEqual(
            DrawerMotion.initialVelocity(160, offsetSign: 1, from: 0, to: 320),
            0.5,
            accuracy: 0.001
        )
    }

    func test_initialVelocityIsNegativeWhenTheFlingOpposesTheSettlingDirection() {
        XCTAssertLessThan(
            DrawerMotion.initialVelocity(-160, offsetSign: 1, from: 0, to: 320),
            0
        )
    }

    func test_initialVelocityIsCappedWhenTheDestinationIsClose() {
        XCTAssertEqual(
            DrawerMotion.initialVelocity(4000, offsetSign: 1, from: 319, to: 320),
            DrawerMotion.maximumInitialVelocity
        )
    }

    func test_initialVelocityIsZeroWithinAPointOfTheDestination() {
        XCTAssertEqual(
            DrawerMotion.initialVelocity(4000, offsetSign: 1, from: 319.9, to: 320),
            0
        )
        XCTAssertEqual(
            DrawerMotion.initialVelocity(4000, offsetSign: 1, from: 320, to: 320),
            0
        )
    }

    func test_predictedDragCanCrossSettlingThreshold() {
        XCTAssertTrue(
            DrawerMotion.settlesOpen(
                isOpen: false,
                width: 320,
                threshold: 0.5,
                translation: 80,
                predictedTranslation: 200
            )
        )
    }

    func test_shortClosingDragKeepsDrawerOpen() {
        XCTAssertTrue(
            DrawerMotion.settlesOpen(
                isOpen: true,
                width: 320,
                threshold: 0.5,
                translation: -40,
                predictedTranslation: -80
            )
        )
    }

    func test_configurationNormalizesPublicValues() {
        var configuration = DrawerConfiguration()
        configuration.shadowRadius = -1
        configuration.edgeRevealWidth = -1
        configuration.minimumDragDistance = -1
        configuration.openThreshold = 2
        configuration.contentDimOpacity = -1
        configuration.contentCornerRadius = -1
        configuration.panelParallax = 2
        configuration.rubberBandFactor = -1
        configuration.releaseDuration = -1
        configuration.releaseBounce = 5

        XCTAssertEqual(configuration.resolvedShadowRadius, 0)
        XCTAssertEqual(configuration.resolvedEdgeRevealWidth, 0)
        XCTAssertEqual(configuration.resolvedMinimumDragDistance, 0)
        XCTAssertEqual(configuration.resolvedOpenThreshold, 1)
        XCTAssertEqual(configuration.resolvedContentDimOpacity, 0)
        XCTAssertEqual(configuration.resolvedContentCornerRadius, 0)
        XCTAssertEqual(configuration.resolvedPanelParallax, 1)
        XCTAssertEqual(configuration.resolvedRubberBandFactor, 0)
        XCTAssertEqual(configuration.resolvedReleaseDuration, 0)
        XCTAssertEqual(configuration.resolvedReleaseBounce, 1)
    }
}
