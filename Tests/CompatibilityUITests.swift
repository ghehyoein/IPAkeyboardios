import XCTest

final class CompatibilityUITests: XCTestCase {
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<8 {
            if element.exists && element.isHittable { return }
            app.tables.firstMatch.swipeUp()
        }
        XCTAssertTrue(element.isHittable)
    }

    func testInformationPagesInAllFourLanguages() {
        continueAfterFailure = false
        let cases = [
            ("zh-Hans", "关于", "联系方式", "友情链接", "部分符号可能缺失或错位"),
            ("zh-Hant", "關於", "聯絡方式", "相關連結", "部分符號可能缺失或錯位"),
            ("en", "About", "Contact", "Useful links", "Some symbols may be missing or misaligned"),
            ("ja", "このアプリについて", "お問い合わせ", "関連リンク", "位置がずれたり")
        ]
        for (language, about, contact, links, warning) in cases {
            let app = XCUIApplication()
            app.launchArguments = ["--reset-settings", "-AppleLanguages", "(\(language))"]
            app.launch()
            XCTAssertTrue(app.tables["symbolSettings"].waitForExistence(timeout: 10))
            let info = app.buttons["fontInformation"]
            reveal(info, in: app)
            info.tap()
            XCTAssertTrue(app.tables["information_font"].waitForExistence(timeout: 5))
            let notice = app.cells["fontDisplayNotice"]
            reveal(notice, in: app)
            XCTAssertTrue(notice.staticTexts.firstMatch.label.contains(warning))
            app.buttons["closeFontInformation"].tap()
            XCTAssertTrue(app.cells["downloadIPAFont"].exists)

            let aboutRow = app.cells["open_about"]
            reveal(aboutRow, in: app)
            XCTAssertEqual(aboutRow.staticTexts.firstMatch.label, about)
            aboutRow.tap()
            XCTAssertTrue(app.navigationBars[about].waitForExistence(timeout: 5))
            XCTAssertTrue(app.cells["aboutIntroduction"].staticTexts.firstMatch.label.contains("ipa+ keyboard"))
            app.navigationBars.buttons.element(boundBy: 0).tap()

            let contactRow = app.cells["open_contact"]
            reveal(contactRow, in: app)
            contactRow.tap()
            XCTAssertTrue(app.navigationBars[contact].waitForExistence(timeout: 5))
            XCTAssertTrue(app.staticTexts["contact@ghehyoein.com"].exists)
            XCTAssertTrue(app.staticTexts["https://ghehyoein.com/"].exists)
            app.cells["contact_qq"].tap()
            XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 5))
            XCTAssertTrue(app.alerts.staticTexts["1127851625"].exists)
            app.alerts.buttons.firstMatch.tap()
            app.navigationBars.buttons.element(boundBy: 0).tap()

            let linksRow = app.cells["open_links"]
            reveal(linksRow, in: app)
            linksRow.tap()
            XCTAssertTrue(app.navigationBars[links].waitForExistence(timeout: 5))
            XCTAssertTrue(app.staticTexts["www.internationalphoneticassociation.org"].exists)
            XCTAssertTrue(app.staticTexts["zi.tools"].exists)
            XCTAssertTrue(app.staticTexts["www.phonetictoolbox.com"].exists)
            app.terminate()
        }
    }

    func testFontSheetWithLargeTextAndRotation() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--reset-settings", "-AppleLanguages", "(en)", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCTAssertTrue(app.tables["symbolSettings"].waitForExistence(timeout: 10))
        reveal(app.buttons["fontInformation"], in: app)
        app.buttons["fontInformation"].tap()
        XCTAssertTrue(app.tables["information_font"].waitForExistence(timeout: 5))
        XCUIDevice.shared.orientation = .landscapeLeft
        let done = app.buttons["closeFontInformation"]
        XCTAssertTrue(done.isHittable)
        reveal(app.cells["fontDisplayNotice"], in: app)
        done.tap()
        XCTAssertTrue(app.tables["symbolSettings"].waitForExistence(timeout: 5))
    }

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
        let p = app.descendants(matching: .any)["key_p"]
        XCTAssertTrue(p.isHittable)
        XCTAssertTrue(app.buttons["returnKey"].isHittable)
        p.tap()
        XCTAssertEqual(editor.value as? String, "qqp")
        // Full-screen capture avoids XCTest's cropped app image after rotation.
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "adaptive-landscape"; attachment.lifetime = .keepAlways
        add(attachment)
    }
}
