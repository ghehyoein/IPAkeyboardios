import XCTest
import UIKit
@testable import IPAKeyboard

final class KeyboardTests: XCTestCase {
    func testLocalizedSectionIndexesAndSpacing() {
        let original = L10n.selection
        defer { L10n.selection = original }
        for language in L10n.languages {
            L10n.selection = language
            let labels = IPACatalog.shared.categories.map { L10n.indexTitle(for: $0.id) }
            XCTAssertEqual(labels.count, Set(labels).count, language)
            XCTAssertTrue(labels.allSatisfy { !$0.isEmpty && $0.count <= 5 })
        }
        let swipe = SwipeSettingsViewController()
        swipe.loadViewIfNeeded()
        XCTAssertEqual(swipe.sectionIndexTitles(for: swipe.tableView), ["ABC", " ", "123", " ", "#+="])
        XCTAssertEqual(swipe.tableView(swipe.tableView, sectionForSectionIndexTitle: "123", at: 2), 1)
        XCTAssertEqual(swipe.tableView.sectionIndexColor, .systemBlue)
        let catalog = SymbolCatalogViewController()
        catalog.loadViewIfNeeded()
        let index = catalog.sectionIndexTitles(for: catalog.tableView) ?? []
        XCTAssertEqual(index[1], " ")
        XCTAssertEqual(catalog.tableView(catalog.tableView, sectionForSectionIndexTitle: index[2], at: 2), 1)
        XCTAssertEqual(catalog.tableView.sectionIndexColor, .systemBlue)
    }
    func testSearchKeyUsesTextAndSoftDarkFill() throws {
        let keyboard = KeyboardSurface(frame: CGRect(x: 0, y: 0, width: 414, height: 301))
        keyboard.overrideUserInterfaceStyle = .dark
        keyboard.returnTitle = "search"
        let button = try XCTUnwrap(keyboard.subviews.compactMap { $0 as? UIButton }.first { $0.accessibilityIdentifier == "returnKey" })
        XCTAssertEqual(button.title(for: .normal), "搜索".localized)
        XCTAssertNil(button.image(for: .normal))
        let dark = UITraitCollection(userInterfaceStyle: .dark)
        var white: CGFloat = 0; var alpha: CGFloat = 0
        XCTAssertTrue(try XCTUnwrap(button.backgroundColor).resolvedColor(with: dark).getWhite(&white, alpha: &alpha))
        XCTAssertLessThan(white, 0.5)
        XCTAssertGreaterThan(white, 0.2)
    }
    func testSymbolDetailsAllowSelectionAndCopyRawCombiningMark() throws {
        let detail = SymbolDetailViewController(symbol: "\u{0308}", display: "◌̈", code: "U+0308", note: "央化")
        detail.loadViewIfNeeded()
        let text = try XCTUnwrap(detail.view.subviews.compactMap { $0 as? UITextView }.first)
        XCTAssertTrue(text.isSelectable)
        XCTAssertFalse(text.isEditable)
        XCTAssertTrue(text.text.contains("U+0308"))
        XCTAssertTrue(text.text.contains("央化"))
        let copy = try XCTUnwrap(detail.view.subviews.compactMap { $0 as? UIButton }.first)
        copy.sendActions(for: .touchUpInside)
        XCTAssertEqual(UIPasteboard.general.string?.unicodeScalars.map { $0.value }, [0x0308])
    }
    func testPanelInventoryIsUniqueCompleteAndModifiersFirst() {
        let catalog = IPACatalog.shared
        let sections = SymbolPanelInventory.sections(catalog: catalog, visibility: SymbolVisibility())
        let values = sections.flatMap { $0.values }
        XCTAssertEqual(values.count, Set(values).count)
        XCTAssertEqual(Set(values), Set(catalog.symbols.filter { $0.atomic }.map { $0.text }))
        XCTAssertEqual(sections.first { $0.values.contains("ʰ") }?.id, "diacritics")
        var ordinarySeen = false
        for text in values {
            let modifier = SymbolPanelInventory.isModifier(catalog.symbol(text)!)
            if !modifier { ordinarySeen = true }
            if modifier { XCTAssertFalse(ordinarySeen, text) }
        }
    }
    func testPanelVisibilityPartitionsAndLegacyMigration() throws {
        let catalog = IPACatalog.shared
        let reachable = SymbolPanelInventory.reachable(catalog: catalog, visibility: SymbolVisibility())
        for mask in 0..<8 {
            let visibility = SymbolVisibility(panelUnavailable: mask & 1 != 0, panelModifiers: mask & 2 != 0, panelOrdinary: mask & 4 != 0)
            let values = Set(SymbolPanelInventory.sections(catalog: catalog, visibility: visibility).flatMap { $0.values })
            for symbol in catalog.symbols where symbol.atomic {
                let expected = !reachable.contains(symbol.text) ? visibility.panelUnavailable : (SymbolPanelInventory.isModifier(symbol) ? visibility.panelModifiers : visibility.panelOrdinary)
                XCTAssertEqual(values.contains(symbol.text), expected, symbol.text)
            }
            XCTAssertEqual(visibility.filter(catalog.keys["h"]!).variants, catalog.keys["h"]!.variants)
        }
        let old = Data(#"{"chinese":false,"historical":true,"extipa":false}"#.utf8)
        let migrated = try JSONDecoder().decode(SymbolVisibility.self, from: old)
        XCTAssertFalse(migrated.chinese); XCTAssertFalse(migrated.extipa)
        XCTAssertTrue(migrated.panelUnavailable && migrated.panelModifiers && migrated.panelOrdinary)
        let selection = SymbolVisibility(panelModifiers: false)
        XCTAssertEqual(try JSONDecoder().decode(SymbolVisibility.self, from: JSONEncoder().encode(selection)), selection)
    }
    func testLocalizationAndPreferenceMigration() throws {
        let previous = L10n.selection
        defer { L10n.selection = previous }
        XCTAssertEqual(L10n.resolve(selection: "system", preferred: ["zh-TW"]), "zh-Hant")
        XCTAssertEqual(L10n.resolve(selection: "system", preferred: ["ja-JP", "en"]), "ja")
        XCTAssertEqual(L10n.resolve(selection: "en", preferred: ["zh-Hans"]), "en")
        for (language, title, note) in [("zh-Hans", "符号显示", "送气"), ("zh-Hant", "符號顯示", "送氣"), ("en", "Symbol settings", "Aspirated"), ("ja", "記号の設定", "有気音")] {
            L10n.selection = language
            XCTAssertEqual("符号显示".localized, title)
            XCTAssertEqual(IPACatalog.shared.symbol("ʰ")?.name, note)
        }
        L10n.selection = "ja"
        XCTAssertTrue(L10n.unicodeName("LATIN SMALL LETTER A").contains("ラテン"))
        let old = try JSONDecoder().decode(SymbolVisibility.self, from: Data(#"{"chinese":false}"#.utf8))
        XCTAssertEqual(old.language, L10n.resolve(selection: "system", preferred: Locale.preferredLanguages)); XCTAssertFalse(old.chinese)
        let prefs = SymbolVisibility(language: "ja")
        XCTAssertEqual(try JSONDecoder().decode(SymbolVisibility.self, from: JSONEncoder().encode(prefs)).language, "ja")
    }
    @MainActor func testSymbolPanelHeightAndNeutralColors() {
        let keyboard = KeyboardSurface(frame: CGRect(x: 0, y: 0, width: 428, height: 229))
        keyboard.systemManagedLayout = true; keyboard.needsGlobe = false; keyboard.layoutIfNeeded()
        XCTAssertEqual(keyboard.contentHeight(landscape: false, globeFooter: 0), 229)
        let entry = keyboard.subviews.first { $0.accessibilityIdentifier == "diacriticsKey" } as! UIButton
        entry.sendActions(for: .touchUpInside)
        XCTAssertTrue(keyboard.isSymbolPanelVisible)
        XCTAssertEqual(keyboard.contentHeight(landscape: false, globeFooter: 0), 305)
        keyboard.frame.size.height = 305; keyboard.layoutIfNeeded()
        let panel = keyboard.subviews.last!
        let grid = panel.subviews.compactMap { $0 as? SymbolGrid }.first!
        XCTAssertEqual(grid.bounds.height, 204)
        XCTAssertEqual(grid.keyHeight, 36)
        let close = panel.subviews.first { $0.accessibilityIdentifier == "closeSymbolPanel" } as! UIButton
        close.sendActions(for: .touchUpInside)
        XCTAssertEqual(keyboard.contentHeight(landscape: false, globeFooter: 0), 229)
        for style in [UIUserInterfaceStyle.light, .dark] {
            for color in [KeyboardMaterial.key, KeyboardMaterial.utility] {
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                color.resolvedColor(with: UITraitCollection(userInterfaceStyle: style)).getRed(&r, green: &g, blue: &b, alpha: &a)
                XCTAssertEqual(r, g, accuracy: 0.001); XCTAssertEqual(g, b, accuracy: 0.001)
            }
        }
    }
    func testDirectionThresholdAndDominantAxis() {
        XCTAssertNil(KeyMotion.direction(dx: 19, dy: -19))
        XCTAssertEqual(KeyMotion.direction(dx: 20, dy: 3), .right)
        XCTAssertEqual(KeyMotion.direction(dx: -21, dy: 8), .left)
        XCTAssertEqual(KeyMotion.direction(dx: 6, dy: -20), .up)
        XCTAssertEqual(KeyMotion.direction(dx: 4, dy: 20), .down)
        XCTAssertNil(KeyMotion.direction(dx: 0, dy: 0))
    }
    func testCatalogDecodesAndContainsChartSymbols() {
        let catalog = IPACatalog.shared
        XCTAssertEqual(catalog.keys.count, 26)
        XCTAssertGreaterThan(catalog.symbols.count, 1000)
        XCTAssertEqual(catalog.symbols.filter { $0.official }.count, 175)
        XCTAssertEqual(catalog.symbol("ɡ")?.id, "0261")
        XCTAssertEqual(catalog.symbol("ǀ")?.id, "01C0")
        XCTAssertEqual(catalog.symbol("|")?.id, "007C")
        XCTAssertEqual(catalog.symbol("\u{0303}")?.display, "◌̃")
        XCTAssertFalse(catalog.symbol("\u{0303}")!.text.contains("◌"))
        XCTAssertEqual(catalog.keys["a"]?.swipes["up"], "ɑ")
    }
    func testPriorityAndChineseVowels() {
        let catalog = IPACatalog.shared
        for mapping in catalog.keys.values {
            let ranks = mapping.variants.compactMap { catalog.symbol($0)?.priority }
            XCTAssertEqual(ranks, ranks.sorted())
        }
        for text in ["ɿ", "ʅ", "ʮ", "ʯ", "ᴀ", "ᴇ", "𝿩", "𝿪"] {
            XCTAssertEqual(catalog.symbol(text)?.family, "chinese")
        }
    }
    @MainActor func testCalloutOrderingCancellationAndOverflow() {
        let variants = (0..<40).map { "candidate\($0)" }
        let strip = VariantStrip(keyFrame: CGRect(x: 24, y: 68, width: 36, height: 44), base: "a", variants: variants, in: CGRect(x: 0, y: 0, width: 428, height: 242))
        XCTAssertEqual(strip.values.filter { $0 != "a" }, variants)
        XCTAssertEqual(strip.selectedText, "a")
        XCTAssertLessThanOrEqual(strip.calloutFrame.maxX, 428)
        XCTAssertGreaterThanOrEqual(strip.calloutFrame.minY, 0)
        strip.track(CGPoint(x: strip.calloutFrame.maxX - 2, y: strip.calloutFrame.midY))
        for _ in 0..<50 { strip.advanceAtEdge(1) }
        XCTAssertEqual(strip.finish(), "candidate39")
        strip.track(CGPoint(x: 214, y: -100))
        XCTAssertNil(strip.finish())
        strip.cancel()
        XCTAssertNil(strip.selectedText)
    }
    @MainActor func testCompactTopRowCalloutStaysInsideKeyboard() {
        for size in [CGSize(width: 428, height: 229), CGSize(width: 375, height: 229), CGSize(width: 926, height: 165)] {
            let keyboard = KeyboardSurface(frame: CGRect(origin: .zero, size: size))
            keyboard.systemManagedLayout = true; keyboard.needsGlobe = false; keyboard.layoutIfNeeded()
            for key in keyboard.subviews.compactMap({ $0 as? LetterKey }).filter({ "qwertyuiop".contains($0.letter) }) {
                let strip = VariantStrip(keyFrame: key.frame, base: key.letter, variants: key.mapping?.variants ?? [], in: keyboard.bounds)
                XCTAssertEqual(key.frame.minY, 8, accuracy: 0.01)
                XCTAssertLessThanOrEqual(strip.calloutFrame.minY, key.frame.minY)
                XCTAssertLessThanOrEqual(strip.calloutFrame.maxY, keyboard.bounds.height)
                XCTAssertGreaterThanOrEqual(strip.calloutFrame.minY, 0)
                XCTAssertLessThanOrEqual(strip.calloutFrame.maxX, size.width)
            }
        }
    }
    @MainActor func testSystemSurfaceHasNoSecondBackdropOrTopBand() {
        for height in [CGFloat(229), 300] {
            let keyboard = KeyboardSurface(frame: CGRect(x: 0, y: 0, width: 428, height: height))
            keyboard.systemManagedLayout = true
            keyboard.needsGlobe = false
            keyboard.layoutIfNeeded()
            let space = keyboard.subviews.first { $0.accessibilityIdentifier == "spaceKey" }!
            XCTAssertEqual(space.frame.maxY, 221, accuracy: 0.01)
            XCTAssertEqual(keyboard.layer.cornerRadius, 0)
            XCTAssertTrue(keyboard.subviews.compactMap { $0 as? UIVisualEffectView }.allSatisfy { $0.isHidden })
            XCTAssertEqual(keyboard.intrinsicContentSize.height, UIView.noIntrinsicMetric)
            for key in keyboard.subviews.compactMap({ $0 as? LetterKey }) { XCTAssertTrue(keyboard.bounds.contains(key.frame)) }
        }
    }
    @MainActor func testDarkUtilityKeysHaveDistinctOpaqueSurfaces() {
        let traits = UITraitCollection(userInterfaceStyle: .dark)
        let color = KeyboardMaterial.utility.resolvedColor(with: traits)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        XCTAssertEqual(alpha, 1)
        XCTAssertGreaterThan(red, 0.30)
        XCTAssertNotEqual(color, KeyboardMaterial.key.resolvedColor(with: traits))
    }
    func testCustomSwipesStayInsideSourceMenuAndRespectVisibility() {
        let source = IPAKeyMapping(variants: ["ɑ", "ɋ"], swipes: ["up": "ɑ"])
        let custom = SwipePreferences(overrides: ["a": ["up": "ɋ", "down": "a", "left": "INVALID", "diagonal": "ɑ"]])
        let result = custom.applying(to: source, key: "a")
        XCTAssertEqual(result.variants, source.variants)
        XCTAssertEqual(result.swipes["up"], "ɋ")
        XCTAssertEqual(result.swipes["down"], "a")
        XCTAssertNil(result.swipes["left"]); XCTAssertNil(result.swipes["diagonal"])
        XCTAssertNil(SymbolVisibility(historical: false).filter(result).swipes["up"])
    }
    func testRecentSymbolsAreBoundedUniqueAndLocal() {
        let suite = "recent-tests-" + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let recent = RecentSymbols(defaults: defaults)
        for value in 0..<65 { recent.record(String(value)) }
        XCTAssertEqual(recent.values.count, 60)
        recent.record("10")
        XCTAssertEqual(recent.values.first, "10")
        XCTAssertEqual(recent.values.filter { $0 == "10" }.count, 1)
        XCTAssertEqual(RecentSymbols(defaults: defaults).values, recent.values)
        recent.clear(); XCTAssertTrue(recent.values.isEmpty)
    }
    @MainActor func testInlineGlobeLayoutKeepsAllKeysAndSymbolEntryAfterM() {
        let keyboard = KeyboardSurface(frame: CGRect(x: 0, y: 0, width: 375, height: 216))
        keyboard.systemManagedLayout = true; keyboard.usesInlineGlobe = true; keyboard.needsGlobe = true
        keyboard.layoutIfNeeded()
        let m = keyboard.subviews.compactMap { $0 as? LetterKey }.first { $0.letter == "m" }!
        let symbols = keyboard.subviews.first { $0.accessibilityIdentifier == "diacriticsKey" }!
        let delete = keyboard.subviews.first { $0.accessibilityIdentifier == "deleteKey" }!
        XCTAssertEqual(m.frame.minY, symbols.frame.minY)
        XCTAssertGreaterThan(symbols.frame.minX, m.frame.maxX)
        XCTAssertLessThan(symbols.frame.maxX, delete.frame.minX)
        for page in [KeyboardPage.letters, .numbers, .symbols] {
            keyboard.showPage(page); keyboard.layoutIfNeeded()
            XCTAssertEqual(keyboard.subviews.compactMap { $0 as? LetterKey }.count, page.rows.flatMap { $0 }.count)
        }
    }
    @MainActor func testContinuousSymbolSectionsCrossBoundary() {
        let grid = SymbolGrid(frame: CGRect(x: 0, y: 0, width: 428, height: 150), sections: [SymbolSection(id: "recent", title: "最近", values: []), SymbolSection(id: "a", title: "A", values: ["ɑ"]), SymbolSection(id: "b", title: "B", values: ["β"])])
        var selected = ""
        grid.onSectionChange = { id, _ in selected = id }
        grid.layoutIfNeeded(); grid.selectSection("a")
        XCTAssertEqual(selected, "a")
        XCTAssertFalse(grid.isPagingEnabled)
        let aOffset = grid.contentOffset.x
        grid.selectSection("b")
        XCTAssertEqual(selected, "b")
        XCTAssertLessThan(grid.contentOffset.x - aOffset, grid.bounds.width)
        grid.setContentOffset(CGPoint(x: aOffset + 13, y: 0), animated: false)
        XCTAssertEqual(grid.contentOffset.x, aOffset + 13, accuracy: 0.1)
    }
    @MainActor func testNativeSizedKeyboardSnapshots() {
        let keyboard = KeyboardSurface(frame: CGRect(x: 0, y: 0, width: 428, height: 301))
        keyboard.layoutIfNeeded()
        for style in [UIUserInterfaceStyle.light, .dark] {
            keyboard.overrideUserInterfaceStyle = style
            let renderer = UIGraphicsImageRenderer(bounds: keyboard.bounds)
            let attachment = XCTAttachment(image: renderer.image { _ in keyboard.drawHierarchy(in: keyboard.bounds, afterScreenUpdates: true) })
            attachment.name = style == .light ? "keyboard-light-428pt" : "keyboard-dark-428pt"
            attachment.lifetime = .keepAlways; add(attachment)
        }
    }
    func testAtomicCandidatesAndNumericVariants() {
        let catalog = IPACatalog.shared
        for mapping in catalog.keys.values {
            for value in mapping.variants {
                XCTAssertEqual(value.unicodeScalars.count, 1)
                XCTAssertEqual(catalog.symbol(value)?.atomic, true)
            }
        }
        XCTAssertEqual(catalog.symbol("p̪")?.atomic, false)
        XCTAssertEqual(catalog.symbol("č")?.atomic, false)
        XCTAssertEqual(catalog.symbol("ç")?.atomic, true)
        XCTAssertNotNil(catalog.symbol("\u{20DD}"))
        for digit in "0123456789" {
            let mapping = AuxiliaryKeyMapping.mapping(for: String(digit))
            XCTAssertNotNil(mapping.swipes["up"])
            XCTAssertNotNil(mapping.swipes["down"])
        }
        XCTAssertEqual(AuxiliaryKeyMapping.mapping(for: "2").swipes["up"], "²")
        XCTAssertEqual(AuxiliaryKeyMapping.mapping(for: "2").swipes["down"], "₂")
        for page in [KeyboardPage.numbers, .symbols] {
            XCTAssertEqual(page.rows.map { $0.count }, [10, 10, 5])
            for key in page.rows.flatMap({ $0 }) {
                let mapping = AuxiliaryKeyMapping.mapping(for: key)
                XCTAssertFalse(mapping.variants.isEmpty, key)
                XCTAssertTrue(mapping.variants.allSatisfy { $0.unicodeScalars.count == 1 })
                XCTAssertTrue(mapping.swipes.values.allSatisfy { mapping.variants.contains($0) })
            }
        }
    }
    @MainActor func testAllPagesKeepEnglishKeyboardGeometry() {
        let keyboard = KeyboardSurface(frame: CGRect(x: 0, y: 0, width: 428, height: 301))
        keyboard.layoutIfNeeded()
        let accessory = keyboard.subviews.first { $0.accessibilityIdentifier == "diacriticsKey" }!
        let number = keyboard.subviews.first { $0.accessibilityIdentifier == "numberModeKey" }!
        let space = keyboard.subviews.first { $0.accessibilityIdentifier == "spaceKey" }!
        let expectedAccessory = accessory.frame
        for page in [KeyboardPage.numbers, .symbols, .letters] {
            keyboard.showPage(page); keyboard.layoutIfNeeded()
            let keys = keyboard.subviews.compactMap { $0 as? LetterKey }
            XCTAssertEqual(Set(keys.map { $0.letter }), Set(page.rows.flatMap { $0 }))
            XCTAssertEqual(accessory.frame, expectedAccessory)
            XCTAssertEqual(number.frame.minY, accessory.frame.minY)
            XCTAssertEqual(accessory.frame.minY, space.frame.minY)
            XCTAssertEqual(number.frame.maxX + 6, accessory.frame.minX, accuracy: 0.01)
            XCTAssertEqual(accessory.frame.maxX + 6, space.frame.minX, accuracy: 0.01)
            XCTAssertEqual(accessory.frame.height, space.frame.height)
            XCTAssertGreaterThanOrEqual(number.frame.width, 44)
            XCTAssertGreaterThanOrEqual(accessory.frame.width, 44)
            for key in keys { XCTAssertTrue(keyboard.bounds.contains(key.frame)) }
            let punct = keys.first { $0.letter == "." }
            if page != .letters { XCTAssertGreaterThan(punct!.frame.width, 45) }
        }
    }
    @MainActor func testVisualGuttersStillHitKeys() {
        let keyboard = KeyboardSurface(frame: CGRect(x: 0, y: 0, width: 428, height: 301))
        keyboard.layoutIfNeeded()
        let key = keyboard.subviews.compactMap { $0 as? LetterKey }.first { $0.letter == "a" }!
        XCTAssertTrue(keyboard.hitTest(CGPoint(x: key.frame.maxX + 2, y: key.frame.midY), with: nil) === key)
        XCTAssertTrue(keyboard.hitTest(CGPoint(x: key.frame.midX, y: key.frame.maxY + 3), with: nil) === key)
        XCTAssertNil(keyboard.hitTest(CGPoint(x: -1, y: key.frame.midY), with: nil))
    }
    func testOptionalFamiliesNeverHideCurrentIPA() {
        let catalog = IPACatalog.shared
        for mask in 0..<8 {
            let value = SymbolVisibility(chinese: mask & 1 != 0, historical: mask & 2 != 0, extipa: mask & 4 != 0)
            for symbol in catalog.symbols where symbol.official { XCTAssertTrue(value.contains(symbol), symbol.text) }
            XCTAssertEqual(value.contains(catalog.symbol("ɚ")!), value.chinese)
            XCTAssertEqual(value.contains(catalog.symbol("ɋ")!), value.historical)
            XCTAssertEqual(value.contains(catalog.symbol("ʩ")!), value.extipa)
            for mapping in catalog.keys.values {
                let filtered = value.filter(mapping)
                for text in filtered.variants { XCTAssertTrue(value.contains(catalog.symbol(text)!)) }
                for text in filtered.swipes.values { XCTAssertTrue(value.contains(catalog.symbol(text)!)) }
                let current = mapping.variants.filter { catalog.symbol($0)?.official == true }
                XCTAssertTrue(Set(current).isSubset(of: Set(filtered.variants)))
            }
        }
        let off = SymbolVisibility(chinese: false, historical: false, extipa: false)
        XCTAssertFalse(off.contains(catalog.symbol("ɿ")!))
        XCTAssertTrue(off.filter(AuxiliaryKeyMapping.mapping(for: "?")).variants.contains("ʔ"))
    }
    func testPreferencePersistenceAndSharedContainer() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let nameA = "ipa-test-app-" + UUID().uuidString, nameB = "ipa-test-keyboard-" + UUID().uuidString
        let appDefaults = UserDefaults(suiteName: nameA)!, keyboardDefaults = UserDefaults(suiteName: nameB)!
        defer { appDefaults.removePersistentDomain(forName: nameA); keyboardDefaults.removePersistentDomain(forName: nameB) }
        let app = SymbolSettingsStore(defaults: appDefaults, container: { folder })
        let keyboard = SymbolSettingsStore(defaults: keyboardDefaults, container: { folder })
        let selection = SymbolVisibility(chinese: false, historical: true, extipa: false)
        XCTAssertTrue(app.save(selection))
        XCTAssertEqual(keyboard.load(), selection)
        XCTAssertTrue(app.saveFeedback(FeedbackPreferences(clicks: false, haptics: true)))
        XCTAssertEqual(keyboard.loadFeedback(), FeedbackPreferences(clicks: false, haptics: true))
        let swipes = SwipePreferences(overrides: ["a": ["up": "æ"]])
        XCTAssertTrue(app.saveSwipes(swipes))
        XCTAssertEqual(keyboard.loadSwipes(), swipes)
        try Data("broken".utf8).write(to: folder.appendingPathComponent("swipe-preferences.json"))
        XCTAssertEqual(keyboard.loadSwipes(), swipes)
        let offline = SymbolSettingsStore(defaults: keyboardDefaults, container: { nil })
        XCTAssertEqual(offline.loadSwipes(), swipes)
        XCTAssertEqual(offline.load(), selection)
        XCTAssertFalse(offline.save(SymbolVisibility()))
        XCTAssertEqual(offline.load(), SymbolVisibility())
        try Data("broken".utf8).write(to: folder.appendingPathComponent("symbol-visibility.json"))
        XCTAssertEqual(app.load(), selection)
    }
    func testCursorDragAccumulatesAndReverses() {
        var drag = CursorDrag()
        XCTAssertEqual(drag.consume(dx: 3), 0)
        XCTAssertEqual(drag.consume(dx: 6), 1)
        XCTAssertEqual(drag.consume(dx: -17), -2)
        drag.reset(); XCTAssertEqual(drag.consume(dx: 7), 0)
    }
    @MainActor func testSearchKeyHasImageAndListsHaveRightIndexes() {
        let keyboard = KeyboardSurface(frame: CGRect(x: 0, y: 0, width: 428, height: 301))
        keyboard.returnTitle = "search"
        let key = keyboard.subviews.compactMap { $0 as? UIButton }.first { $0.accessibilityIdentifier == "returnKey" }!
        XCTAssertNotNil(key.image(for: .normal)); XCTAssertNil(key.title(for: .normal))
        let settings = SwipeSettingsViewController(); settings.loadViewIfNeeded()
        XCTAssertEqual(settings.tableView.style, .plain)
        XCTAssertEqual(settings.sectionIndexTitles(for: settings.tableView), ["ABC", "123", "#+="])
        let catalog = SymbolCatalogViewController(); catalog.loadViewIfNeeded()
        XCTAssertEqual(catalog.tableView.style, .plain)
        XCTAssertGreaterThan(catalog.sectionIndexTitles(for: catalog.tableView)?.count ?? 0, 10)
        let cell = catalog.tableView(catalog.tableView, cellForRowAt: IndexPath(row: 0, section: 0))
        XCTAssertFalse(cell.detailTextLabel?.text?.contains("输入") ?? true)
    }
    func testUnicodeSequencesRemainUnnormalized() {
        let text = "a" + "\u{0303}" + "\u{0301}"
        XCTAssertEqual(text.unicodeScalars.map { $0.value }, [0x61, 0x303, 0x301])
        let affricate = "t" + "\u{0361}" + "s"
        XCTAssertEqual(affricate.unicodeScalars.map { $0.value }, [0x74, 0x361, 0x73])
    }
}
