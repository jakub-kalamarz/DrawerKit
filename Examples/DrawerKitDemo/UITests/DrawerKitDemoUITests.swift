import XCTest

final class DrawerKitDemoUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func test_tappingMovedContentClosesWithoutActivatingIt() {
        app.buttons["drawer.open"].tap()
        XCTAssertTrue(app.buttons["drawer.saved"].waitForExistence(timeout: 1))

        app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.35)).tap()

        XCTAssertTrue(app.buttons["drawer.open"].waitForExistence(timeout: 1))
        XCTAssertEqual(app.staticTexts["main.tapCount"].label, "Tap count: 0")
    }

    func test_panelRemainsInteractive() {
        app.buttons["drawer.open"].tap()
        app.buttons["drawer.saved"].tap()

        XCTAssertTrue(app.navigationBars["Saved"].waitForExistence(timeout: 1))
    }

    func test_swipingMovedContentClosesDrawer() {
        app.buttons["drawer.open"].tap()

        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: end)

        XCTAssertTrue(app.buttons["drawer.open"].waitForExistence(timeout: 1))
    }

    func test_accessibilityAudit() throws {
        try app.performAccessibilityAudit()
    }
}
