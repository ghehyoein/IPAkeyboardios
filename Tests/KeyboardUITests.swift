import XCTest

final class KeyboardUITests: XCTestCase {
    private func launch() -> (XCUIApplication, XCUIElement) {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--screenshot", "-AppleLanguages", "(zh-Hans)"]
        app.launch()
        let editor = app.textViews["transcriptionEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 10))
        editor.tap()
        return (app, editor)
    }
    private func key(_ letter: String, in app: XCUIApplication) -> XCUIElement {
        let result = app.descendants(matching: .any).matching(identifier: "key_" + letter).firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 5)); return result
    }
    func testFourInterfaceLanguagesAndLocalizedSymbolSearch() {
        let cases = [("zh-Hans", "符号显示", "送气"), ("zh-Hant", "符號顯示", "送氣"), ("en", "Symbol settings", "Aspirated"), ("ja", "記号の設定", "有気音")]
        for (language, title, note) in cases {
            let app = XCUIApplication()
            app.launchArguments = ["--reset-settings", "-AppleLanguages", "(\(language))"]
            app.launch()
            XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 10))
            attach(app, name: "settings-" + language)
            let catalog = app.cells["openSymbolCatalog"]
            for _ in 0..<5 { if catalog.isHittable { break }; app.tables.firstMatch.swipeUp() }
            catalog.tap()
            let search = app.searchFields.firstMatch
            search.tap(); search.typeText("U+02B0")
            XCTAssertTrue(app.staticTexts[note].waitForExistence(timeout: 5))
            attach(app, name: "symbol-search-" + language)
            app.terminate()
        }
    }
    func testSymbolDetailsSupportSelectionAndCopy() {
        let app = XCUIApplication()
        app.launchArguments = ["--reset-settings", "-AppleLanguages", "(zh-Hans)"]
        app.launch()
        let catalog = app.cells["openSymbolCatalog"]
        for _ in 0..<5 { if catalog.isHittable { break }; app.tables.firstMatch.swipeUp() }
        catalog.tap()
        let search = app.searchFields.firstMatch
        search.tap(); search.typeText("U+02B0")
        let entry = app.cells["catalogEntry_U+02B0"]
        XCTAssertTrue(entry.waitForExistence(timeout: 5))
        entry.tap()
        let details = app.textViews["selectableSymbolDetails"]
        XCTAssertTrue(details.waitForExistence(timeout: 5))
        XCTAssertTrue((details.value as? String ?? "").contains("送气"))
        app.buttons["copySymbol"].tap()
        attach(app, name: "selectable-symbol-details")
        app.navigationBars.buttons["完成"].tap()
        entry.press(forDuration: 1)
        XCTAssertTrue(app.buttons["复制注释"].waitForExistence(timeout: 3))
    }
    func testLanguageChoicePersists() {
        let app = XCUIApplication()
        app.launchArguments = ["--reset-settings", "-AppleLanguages", "(zh-Hans)"]
        app.launch()
        let setting = app.cells["languageSetting"]
        for _ in 0..<10 { if setting.isHittable { break }; app.tables.firstMatch.swipeUp() }
        setting.tap(); app.buttons["English"].tap()
        XCTAssertTrue(app.navigationBars["Symbol settings"].waitForExistence(timeout: 5))
        app.terminate()
        app.launchArguments = ["-AppleLanguages", "(zh-Hans)"]
        app.launch()
        XCTAssertTrue(app.navigationBars["Symbol settings"].waitForExistence(timeout: 10))
    }
    func testTapAndLongPressReleaseProduceExactlyOneCharacter() {
        let (app, editor) = launch()
        let a = key("a", in: app)
        a.tap()
        XCTAssertEqual(editor.value as? String, "a")
        a.press(forDuration: 0.65)
        XCTAssertEqual(editor.value as? String, "aa")
        key("b", in: app).tap()
        XCTAssertEqual(editor.value as? String, "aab")
        XCTAssertFalse(app.staticTexts["a 的变体"].exists)
    }
    func testLongPressSlideSelectAndCancel() {
        let (app, editor) = launch()
        let a = key("a", in: app)
        let cellWidth = max(34, min(42, a.frame.width + 2))
        // The a key callout is left-clamped at 8pt;
        // base a is first and IPA ɑ is the next visible candidate.
        let destination = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: 14 + cellWidth * 1.5, dy: a.frame.minY - 30))
        a.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 0.65, thenDragTo: destination)
        XCTAssertEqual(editor.value as? String, "ɑ")
        let outside = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: 214, dy: 150))
        a.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 0.65, thenDragTo: outside)
        XCTAssertEqual(editor.value as? String, "ɑ")
        key("n", in: app).tap()
        XCTAssertEqual(editor.value as? String, "ɑn")
    }
    func testSwipeStillWorksAndTopRowHoldDoesNotLeaveMenu() {
        let (app, editor) = launch()
        let a = key("a", in: app)
        let from = a.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        from.press(forDuration: 0.05, thenDragTo: from.withOffset(CGVector(dx: 0, dy: -35)))
        XCTAssertEqual(editor.value as? String, "ɑ")
        key("q", in: app).press(forDuration: 0.65)
        XCTAssertEqual(editor.value as? String, "ɑq")
        key("w", in: app).tap()
        XCTAssertEqual(editor.value as? String, "ɑqw")
    }
    private func attach(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    func testNumericPagesAndVariants() {
        let (app, editor) = launch()
        app.buttons["numberModeKey"].tap()
        assertDiacriticsBetweenNumberAndSpace(app)
        for value in "1234567890-/:;()$&@\".,?!'" { XCTAssertTrue(key(String(value), in: app).exists) }
        XCTAssertEqual(app.buttons["pageToggleKey"].label, "#+=")
        attach(app, name: "custom-numbers")
        let two = key("2", in: app)
        let center = two.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        center.press(forDuration: 0.05, thenDragTo: center.withOffset(CGVector(dx: 0, dy: -35)))
        center.press(forDuration: 0.05, thenDragTo: center.withOffset(CGVector(dx: 0, dy: 35)))
        XCTAssertEqual(editor.value as? String, "²₂")
        // Long-press 2: [², 2, ₂, ⅔], with the base positioned over the key.
        let cell = max(34, min(42, two.frame.width + 2))
        let width = cell * 4 + 12
        let left = min(max(8, two.frame.midX - width / 2), app.frame.width - width - 8)
        let target = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: left + 6 + cell / 2, dy: two.frame.minY + 8))
        center.press(forDuration: 0.65, thenDragTo: target)
        XCTAssertEqual(editor.value as? String, "²₂²")
        app.buttons["pageToggleKey"].tap()
        assertDiacriticsBetweenNumberAndSpace(app)
        for value in "[]{}#%^*+=_\\|~<>€£¥•.,?!'" { XCTAssertTrue(key(String(value), in: app).exists) }
        XCTAssertEqual(app.buttons["pageToggleKey"].label, "123")
        attach(app, name: "custom-symbols")
        key("[", in: app).tap(); key("]", in: app).tap()
        let plus = key("+", in: app).coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        plus.press(forDuration: 0.05, thenDragTo: plus.withOffset(CGVector(dx: 0, dy: -35)))
        XCTAssertEqual(editor.value as? String, "²₂²[]⁺")
        app.buttons["pageToggleKey"].tap()
        XCTAssertTrue(key("1", in: app).exists)
        app.buttons["numberModeKey"].tap()
        key("a", in: app).tap()
        XCTAssertEqual(editor.value as? String, "²₂²[]⁺a")
    }
    private func assertDiacriticsBetweenNumberAndSpace(_ app: XCUIApplication) {
        let mode = app.buttons["numberModeKey"].frame
        let marks = app.buttons["diacriticsKey"].frame
        let space = app.buttons["spaceKey"].frame
        XCTAssertEqual(mode.midY, marks.midY, accuracy: 1)
        XCTAssertEqual(marks.midY, space.midY, accuracy: 1)
        XCTAssertLessThan(mode.maxX, marks.minX)
        XCTAssertLessThan(marks.maxX, space.minX)
    }
    func testComposeBaseAndSeparateMarks() {
        let (app, editor) = launch()
        assertDiacriticsBetweenNumberAndSpace(app)
        key("a", in: app).tap()
        app.buttons["diacriticsKey"].tap()
        app.collectionViews.cells["symbol_0308"].tap()
        app.collectionViews.cells["symbol_02B0"].tap()
        XCTAssertEqual((editor.value as? String)?.unicodeScalars.map { $0.value }, [0x61, 0x308, 0x2b0])
        app.buttons["closeSymbolPanel"].tap()
        key("t", in: app).tap()
        XCTAssertEqual(editor.value as? String, "äʰt")
    }
    func testDisplayAndFeedbackSettingsPersist() {
        let (app, _) = launch()
        app.buttons["openSymbolSettings"].tap()
        XCTAssertTrue(app.cells["currentIPAAlwaysVisible"].exists)
        for name in ["chinese", "historical", "extipa"] {
            let toggle = app.switches["visibility_" + name]
            XCTAssertEqual(toggle.value as? String, "1")
            toggle.tap()
            XCTAssertEqual(toggle.value as? String, "0")
        }
        let haptic = app.switches["feedback_haptics"]
        for _ in 0..<6 { if haptic.isHittable { break }; app.tables.firstMatch.swipeUp() }
        haptic.tap()
        attach(app, name: "symbol-display-and-feedback-settings")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["diacriticsKey"].tap()
        for name in ["chinese", "historical", "extipa"] { XCTAssertFalse(app.buttons["category_" + name].exists) }
        XCTAssertTrue(app.buttons["category_diacritics"].exists)
        app.terminate()
        app.launchArguments = ["--ui-testing", "--preserve-settings", "-AppleLanguages", "(zh-Hans)"]
        app.launch()
        app.buttons["openSymbolSettings"].tap()
        for name in ["chinese", "historical", "extipa"] { XCTAssertEqual(app.switches["visibility_" + name].value as? String, "0") }
        XCTAssertEqual(app.switches["feedback_haptics"].value as? String, "0")
        app.switches["visibility_chinese"].tap()
        XCTAssertEqual(app.switches["visibility_chinese"].value as? String, "1")
        XCTAssertEqual(app.switches["visibility_historical"].value as? String, "0")
    }
    func testProductionHomeAndSearchableInventory() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.tables["symbolSettings"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.textViews["transcriptionEditor"].exists)
        let catalog = app.cells["openSymbolCatalog"]
        for _ in 0..<5 { if catalog.isHittable { break }; app.tables.firstMatch.swipeUp() }
        XCTAssertTrue(catalog.isHittable)
        catalog.tap()
        XCTAssertTrue(app.tables["symbolCatalog"].waitForExistence(timeout: 5))
        attach(app, name: "catalog-index")
        let search = app.searchFields.firstMatch
        search.tap(); search.typeText("U+0308")
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "U+0308")).firstMatch.waitForExistence(timeout: 5))
        attach(app, name: "symbol-catalog-search")
    }
    func testPanelSettingsAreAvailableAndToggle() {
        let (app, _) = launch()
        app.buttons["openSymbolSettings"].tap()
        let table = app.tables["symbolSettings"]
        let toggle = app.switches["panelVisibility_1"]
        for _ in 0..<8 {
            if toggle.isHittable { break }
            table.swipeUp()
        }
        XCTAssertTrue(toggle.isHittable)
        toggle.tap()
        XCTAssertEqual(toggle.value as? String, "0")
        attach(app, name: "panel-display-settings")
    }
    func testPanelAnchorKeySizeAndLongPressDoesNotInsert() {
        let (app, editor) = launch()
        let mode = app.buttons["numberModeKey"].frame
        let letter = key("a", in: app).frame
        app.buttons["diacriticsKey"].tap()
        let close = app.buttons["closeSymbolPanel"]
        XCTAssertEqual(close.frame.minX, mode.minX, accuracy: 0.5)
        XCTAssertEqual(close.frame.maxY, mode.maxY, accuracy: 0.5)
        let mark = app.collectionViews.cells["symbol_0308"]
        XCTAssertLessThanOrEqual(mark.frame.width, letter.width + 0.5)
        XCTAssertLessThanOrEqual(mark.frame.height, letter.height)
        XCTAssertGreaterThanOrEqual(mark.frame.height, 32)
        let grid = app.collectionViews["symbolGrid"]
        let visible = grid.cells.allElementsBoundByIndex.filter { $0.isHittable }
        let rowPositions = Set(visible.map { Int($0.frame.minY.rounded()) })
        XCTAssertEqual(rowPositions.count, 5)
        mark.press(forDuration: 0.65)
        XCTAssertEqual(editor.value as? String, "")
        attach(app, name: "compact-diacritics-panel")
        app.collectionViews["symbolGrid"].swipeLeft()
        XCTAssertEqual(close.frame.minX, mode.minX, accuracy: 0.5)
        XCTAssertEqual(close.frame.maxY, mode.maxY, accuracy: 0.5)
        close.tap()
        XCTAssertEqual(key("a", in: app).frame, letter)
    }
    func testRecentPanelAndContinuousCategories() {
        let (app, _) = launch()
        app.buttons["diacriticsKey"].tap()
        app.collectionViews.cells["symbol_02B0"].firstMatch.tap()
        app.buttons["closeSymbolPanel"].tap()
        app.buttons["diacriticsKey"].tap()
        let recent = app.buttons["category_recent"]
        let before = recent.frame
        recent.tap()
        XCTAssertEqual(recent.frame, before)
        XCTAssertTrue(app.staticTexts["symbolSectionTitle"].label.contains("最近使用"))
        XCTAssertTrue(app.collectionViews.cells["symbol_02B0"].firstMatch.isHittable)
        app.collectionViews["symbolGrid"].swipeLeft()
        XCTAssertFalse(app.staticTexts["symbolSectionTitle"].label.contains("最近使用"))
        XCTAssertEqual(recent.frame, before)
        attach(app, name: "continuous-symbol-browser")
    }
    func testConfigureSwipeThenUseIt() {
        let (app, editor) = launch()
        app.buttons["openSymbolSettings"].tap()
        app.tables.firstMatch.swipeUp()
        app.cells["openSwipeSettings"].tap()
        attach(app, name: "swipe-settings-index")
        let a = app.cells["configureSwipe_a"]
        if !a.isHittable { app.tables.firstMatch.swipeUp() }
        a.tap(); app.cells["swipeDirection_up"].tap()
        app.cells["swipeCandidate_æ"].tap()
        for _ in 0..<3 { app.navigationBars.buttons.element(boundBy: 0).tap() }
        let from = key("a", in: app).coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        from.press(forDuration: 0.05, thenDragTo: from.withOffset(CGVector(dx: 0, dy: -35)))
        XCTAssertEqual(editor.value as? String, "æ")
    }
    func testSpaceTrackpadMovesCaretWithoutAddingSpace() {
        let (app, editor) = launch()
        for value in ["a", "b", "c", "d"] { key(value, in: app).tap() }
        let space = app.buttons["spaceKey"]
        let origin = space.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        origin.press(forDuration: 0.6, thenDragTo: origin.withOffset(CGVector(dx: -20, dy: 0)))
        XCTAssertEqual(editor.value as? String, "abcd")
        key("x", in: app).tap()
        XCTAssertEqual(editor.value as? String, "abxcd")
        space.tap()
        XCTAssertEqual(editor.value as? String, "abx cd")
    }
}
