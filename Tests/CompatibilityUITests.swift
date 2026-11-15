import XCTest

final class CompatibilityUITests: XCTestCase {
    override func tearDown() {
        XCUIDevice.shared.orientation = .portrait
        super.tearDown()
    }
    func testTypingSymbolsAndRotation() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--screenshot", "-AppleLanguages", "(en)"]
        app.launch()
        let editor = app.textViews["transcriptionEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 15))
        editor.tap()
        let q = app.descendants(matching: .any)["key_q"]
        XCTAssertTrue(q.waitForExistence(timeout: 5))
        q.tap()
        XCTAssertEqual(editor.value as? String, "q")
        let symbols = app.buttons["diacriticsKey"]
        XCTAssertTrue(symbols.exists)
        symbols.tap()
        let grid = app.collectionViews["symbolGrid"]
        XCTAssertTrue(grid.waitForExistence(timeout: 5))
        grid.swipeLeft()
        grid.swipeLeft()
        let close = app.buttons["closeSymbolPanel"]
        XCTAssertTrue(close.isHittable)
        close.tap()
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(q.waitForExistence(timeout: 5))
        XCTAssertTrue(q.isHittable)
        q.tap()
        XCTAssertEqual(editor.value as? String, "qq")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "adaptive-landscape"; attachment.lifetime = .keepAlways
        add(attachment)
    }
}
