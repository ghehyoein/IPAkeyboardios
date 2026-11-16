import XCTest
import UIKit
import CoreText
@testable import IPAKeyboard

final class UnifiedFontTests: XCTestCase {
    private func inputs() -> Set<String> {
        let catalog = IPACatalog.shared
        var result = Set(catalog.symbols.flatMap { [$0.text, $0.display] })
        for (key, map) in catalog.keys { result.insert(key); result.formUnion(map.variants); result.formUnion(map.swipes.values) }
        for page: KeyboardPage in [.letters, .numbers, .symbols] {
            for key in page.rows.flatMap({ $0 }) {
                result.insert(key); result.insert(key.uppercased())
                result.formUnion(AuxiliaryKeyMapping.mapping(for: key).variants)
            }
        }
        result.formUnion(["◌", "◌̃", "′", "″", " "])
        return result
    }
    private func line(_ text: String, size: CGFloat = 26) -> CTLine {
        CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: [.font: PhoneticDisplay.font(ofSize: size)]))
    }
    func testEveryInputUsesTheBundledFontWithoutFallback() {
        XCTAssertGreaterThan(IPACatalog.shared.symbols.count, 1200)
        XCTAssertEqual(PhoneticDisplay.font(ofSize: 26).fontName, PhoneticDisplay.fontName)
        XCTAssertEqual(PhoneticDisplay.font(ofSize: 26).familyName, "ipa+")
        for text in inputs() {
            for run in CTLineGetGlyphRuns(line(text)) as! [CTRun] {
                let attributes = CTRunGetAttributes(run) as NSDictionary
                let font = attributes[kCTFontAttributeName] as! CTFont
                XCTAssertEqual(CTFontCopyPostScriptName(font) as String, PhoneticDisplay.fontName, text)
                var glyphs = [CGGlyph](repeating: 0, count: CTRunGetGlyphCount(run))
                CTRunGetGlyphs(run, CFRange(location: 0, length: 0), &glyphs)
                XCTAssertFalse(glyphs.contains(0), text)
            }
            XCTAssertEqual(PhoneticDisplay.title(for: text), text)
        }
    }
    func testExtensionContainsTheSameSingleFontAndLicense() throws {
        let app = Bundle.main.bundleURL
        let ext = app.appendingPathComponent("PlugIns/IPAKeyboardExtension.appex")
        let fontName = "ipa-plus.ttf"
        XCTAssertEqual(try Data(contentsOf: app.appendingPathComponent(fontName)), try Data(contentsOf: ext.appendingPathComponent(fontName)))
        for folder in [app, ext] {
            let data = try Data(contentsOf: folder.appendingPathComponent("Info.plist"))
            let info = try PropertyListSerialization.propertyList(from: data, format: nil) as! [String: Any]
            XCTAssertEqual(info["UIAppFonts"] as? [String], [fontName])
            XCTAssertTrue(FileManager.default.fileExists(atPath: folder.appendingPathComponent("Font-Licenses.txt").path))
            let files = try FileManager.default.contentsOfDirectory(atPath: folder.path)
            XCTAssertEqual(files.filter { $0.hasSuffix(".ttf") || $0.hasSuffix(".otf") }, [fontName])
        }
    }
    func testNewCombiningMarksAttachWithoutAddingCharacterAdvance() {
        let baseWidth = CTLineGetTypographicBounds(line("a"), nil, nil, nil)
        for text in ["a\u{1ACF}", "a\u{1ACF}\u{0301}", "a\u{0301}\u{1ACF}", "a\u{0325}\u{1ADD}"] {
            XCTAssertEqual(CTLineGetTypographicBounds(line(text), nil, nil, nil), baseWidth, accuracy: 0.1, text)
        }
        // A cross-source above mark must be centered over the base, not over the next key.
        var boxes: [CGRect] = []
        for run in CTLineGetGlyphRuns(line("a\u{1ACF}")) as! [CTRun] {
            let font = (CTRunGetAttributes(run) as NSDictionary)[kCTFontAttributeName] as! CTFont
            var glyphs = [CGGlyph](repeating: 0, count: CTRunGetGlyphCount(run))
            var points = [CGPoint](repeating: .zero, count: glyphs.count)
            CTRunGetGlyphs(run, CFRange(location: 0, length: 0), &glyphs)
            CTRunGetPositions(run, CFRange(location: 0, length: 0), &points)
            for index in glyphs.indices {
                var glyph = glyphs[index]
                let bounds = CTFontGetBoundingRectsForGlyphs(font, .default, &glyph, nil, 1)
                boxes.append(bounds.offsetBy(dx: points[index].x, dy: points[index].y))
            }
        }
        XCTAssertEqual(boxes.count, 2)
        if boxes.count == 2 {
            XCTAssertEqual(boxes[0].midX, boxes[1].midX, accuracy: 1)
            XCTAssertGreaterThan(boxes[1].minY, boxes[0].maxY)
        }
    }
    func testEnclosingMarkIsCenteredAroundItsBase() {
        var boxes: [CGRect] = []
        for run in CTLineGetGlyphRuns(line("a\u{20DD}")) as! [CTRun] {
            let font = (CTRunGetAttributes(run) as NSDictionary)[kCTFontAttributeName] as! CTFont
            var glyphs = [CGGlyph](repeating: 0, count: CTRunGetGlyphCount(run))
            var points = [CGPoint](repeating: .zero, count: glyphs.count)
            CTRunGetGlyphs(run, CFRange(location: 0, length: 0), &glyphs)
            CTRunGetPositions(run, CFRange(location: 0, length: 0), &points)
            for index in glyphs.indices {
                var glyph = glyphs[index]
                boxes.append(CTFontGetBoundingRectsForGlyphs(font, .default, &glyph, nil, 1)
                    .offsetBy(dx: points[index].x, dy: points[index].y))
            }
        }
        XCTAssertEqual(boxes.count, 2)
        if boxes.count == 2 {
            XCTAssertEqual(boxes[0].midX, boxes[1].midX, accuracy: 1)
            XCTAssertEqual(boxes[0].midY, boxes[1].midY, accuracy: 1)
            XCTAssertGreaterThan(boxes[1].height, boxes[0].height)
        }
    }
    func testEnclosedDiacriticsAfterNormalization() {
        let samples = ["a\u{0325}\u{1ABD}", "g\u{030A}\u{1ABB}", "g\u{030C}\u{1ABB}",
                       "c\u{030C}\u{1AC1}", "ʒ\u{030C}\u{1AC2}", "ǧ\u{1ABB}", "č\u{1ABB}",
                       "a\u{1ABD}\u{0325}", "i\u{032C}\u{1ABD}"]
        for text in samples {
            var boxes: [CGRect] = []
            for run in CTLineGetGlyphRuns(line(text)) as! [CTRun] {
                let font = (CTRunGetAttributes(run) as NSDictionary)[kCTFontAttributeName] as! CTFont
                var glyphs = [CGGlyph](repeating: 0, count: CTRunGetGlyphCount(run))
                var positions = [CGPoint](repeating: .zero, count: glyphs.count)
                CTRunGetGlyphs(run, CFRange(location: 0, length: 0), &glyphs)
                CTRunGetPositions(run, CFRange(location: 0, length: 0), &positions)
                for index in glyphs.indices {
                    var glyph = glyphs[index]
                    boxes.append(CTFontGetBoundingRectsForGlyphs(font, .default, &glyph, nil, 1)
                        .offsetBy(dx: positions[index].x, dy: positions[index].y))
                }
            }
            XCTAssertEqual(boxes.count, 3, text)
            if boxes.count == 3 {
                XCTAssertEqual(boxes[1].midY, boxes[2].midY, accuracy: 1.3, text)
            }
        }
    }
    @MainActor func testUnifiedFontProof() {
        let values = ["a\u{1ACF}", "a\u{1ACF}\u{0301}", "a\u{0301}\u{1ACF}", "a\u{0325}\u{1ADD}", "t͡s", "ɿ", "ɥ", "ə", "ᴇ", "ᴀ", "⦃", "＠"] +
            (0x1DFCD...0x1DFFF).map { String(Unicode.Scalar($0)!) } +
            ["\u{1AD0}", "\u{1ADE}", "\u{1DF50}", "\u{1DF57}", "\u{209D}", "₽", "◌̥", "◌̃", "a⃝", "S⃝"]
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 960, height: 1080), format: format).image { context in
            UIColor.white.setFill(); context.fill(CGRect(x: 0, y: 0, width: 960, height: 1080))
            for (index, value) in values.enumerated() {
                let x = CGFloat(index % 8) * 120, y = CGFloat(index / 8) * 112
                let title = value.unicodeScalars.map { String($0.value, radix: 16).uppercased() }.joined(separator: " ")
                (title as NSString).draw(in: CGRect(x: x + 5, y: y + 8, width: 112, height: 25), withAttributes: [.font: UIFont.systemFont(ofSize: 10), .foregroundColor: UIColor.darkGray])
                (value as NSString).draw(in: CGRect(x: x + 9, y: y + 30, width: 108, height: 78), withAttributes: [.font: PhoneticDisplay.font(ofSize: 35), .foregroundColor: UIColor.black])
            }
        }
        let attachment = XCTAttachment(image: image); attachment.name = "unified-font-proof"; attachment.lifetime = .keepAlways; add(attachment)
    }
}
