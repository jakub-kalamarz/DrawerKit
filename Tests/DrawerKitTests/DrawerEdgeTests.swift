import SwiftUI
import XCTest

@testable import DrawerKit

@available(iOS 18.0, macOS 15.0, *)
final class DrawerEdgeTests: XCTestCase {
    func test_leadingEdgeMirrorsWithLayoutDirection() {
        XCTAssertEqual(DrawerEdge.leading.offsetSign(for: .leftToRight), 1)
        XCTAssertEqual(DrawerEdge.leading.offsetSign(for: .rightToLeft), -1)
    }

    func test_trailingEdgeMirrorsWithLayoutDirection() {
        XCTAssertEqual(DrawerEdge.trailing.offsetSign(for: .leftToRight), -1)
        XCTAssertEqual(DrawerEdge.trailing.offsetSign(for: .rightToLeft), 1)
    }
}
