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

        XCTAssertEqual(configuration.resolvedShadowRadius, 0)
        XCTAssertEqual(configuration.resolvedEdgeRevealWidth, 0)
        XCTAssertEqual(configuration.resolvedMinimumDragDistance, 0)
        XCTAssertEqual(configuration.resolvedOpenThreshold, 1)
        XCTAssertEqual(configuration.resolvedContentDimOpacity, 0)
        XCTAssertEqual(configuration.resolvedContentCornerRadius, 0)
    }
}
