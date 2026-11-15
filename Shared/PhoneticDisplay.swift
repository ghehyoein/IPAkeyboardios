import UIKit
import CoreText

/// One bundled, subsetted OFL font for phonetic text in both hosting processes.
/// UIKit still supplies the interface font and fallback for ordinary UI languages.
enum PhoneticDisplay {
    static let fontName = "IPAPlusUnified-Regular"
    private final class BundleToken: NSObject {}
    private static let bundledFont: UIFont? = {
        if let font = UIFont(name: fontName, size: 26) { return font }
        let bundle = Bundle(for: BundleToken.self)
        if let url = bundle.url(forResource: "IPAPlusUnified-Regular", withExtension: "ttf") {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
        return UIFont(name: fontName, size: 26)
    }()
    static func font(ofSize size: CGFloat) -> UIFont {
        bundledFont?.withSize(size) ?? .systemFont(ofSize: size)
    }
    static func keyFont(for text: String, size: CGFloat) -> UIFont {
        text.unicodeScalars.allSatisfy { $0.value < 128 } ? .systemFont(ofSize: size) : font(ofSize: size)
    }
    static func scaledFont(for style: UIFont.TextStyle) -> UIFont {
        UIFontMetrics(forTextStyle: style).scaledFont(for: font(ofSize: UIFont.preferredFont(forTextStyle: style,
            compatibleWith: UITraitCollection(preferredContentSizeCategory: .large)).pointSize))
    }
    private static let cache: NSCache<NSString, NSNumber> = {
        let cache = NSCache<NSString, NSNumber>(); cache.countLimit = 2048; return cache
    }()
    static func isSupported(_ text: String) -> Bool { supports(text, font: font(ofSize: 26), prefix: "bundled:") }
    // Category representatives retain the promise that system fonts can show them.
    static func isSystemSupported(_ text: String) -> Bool { supports(text, font: .systemFont(ofSize: 26), prefix: "system:") }
    private static func supports(_ text: String, font: UIFont, prefix: String) -> Bool {
        let key = (prefix + text) as NSString
        if let cached = cache.object(forKey: key) { return cached.boolValue }
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: [.font: font]))
        let runs = CTLineGetGlyphRuns(line) as! [CTRun]
        let supported = runs.allSatisfy { run in
            let attributes = CTRunGetAttributes(run) as NSDictionary
            if let font = attributes[kCTFontAttributeName] {
                let name = CTFontCopyPostScriptName(font as! CTFont) as String
                if name.lowercased().contains("lastresort") { return false }
            }
            var glyphs = [CGGlyph](repeating: 0, count: CTRunGetGlyphCount(run))
            CTRunGetGlyphs(run, CFRange(location: 0, length: 0), &glyphs)
            return !glyphs.contains(0)
        }
        cache.setObject(NSNumber(value: supported), forKey: key)
        return supported
    }
    static func title(for text: String) -> String {
        if isSupported(text) { return text }
        return text.unicodeScalars.filter { $0.value != 0x25CC }.map { "U+" + String($0.value, radix: 16).uppercased() }.joined(separator: "\n")
    }
}

/// A category keeps its own symbol even when the panel's visibility filters change.
/// Recent items have no exclusive symbol, so use the familiar system clock instead.
enum SymbolCategoryIcon {
    case glyph(String)
    case systemImage(String)

    private static let preferred: [String: [String]] = [
        "pulmonic": ["ʃ", "ŋ"], "vowels": ["ə", "ɑ"], "nonpulmonic": ["ɓ", "ǃ"],
        "other": ["ɕ", "\u{0361}"], "diacritics": ["\u{0303}", "ʰ"],
        "suprasegmentals": ["ː", "\u{0306}"], "tones": ["˥", "\u{030C}"],
        "chinese": ["ɿ", "¹"], "historical": ["ƀ", "\u{0328}"],
        "extipa": ["ʩ", "\u{0348}", "ʶ"], "superscripts": ["ᵐ", "ᵃ"],
        "subscripts": ["ᵢ", "ₐ"], "combining": ["\u{0332}", "\u{0305}"],
        "unicode": ["ɫ", "ᴂ"], "extras": ["/"]
    ]

    static func representative(for section: SymbolSection, catalog: IPACatalog,
                               supports: (String) -> Bool = PhoneticDisplay.isSystemSupported) -> IPASymbol? {
        guard section.id != "recent" else { return nil }
        let visible = section.values.compactMap { catalog.symbol($0) }
        guard let first = visible.first else { return nil }
        func choose(_ members: [IPASymbol]) -> IPASymbol? {
            let preferredMembers = (preferred[first.category] ?? []).compactMap { text in
                members.first { $0.text == text }
            }
            return (preferredMembers + members).first {
                $0.display.count == 1 && !$0.display.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && supports($0.display)
            }
        }
        if let symbol = choose(visible) { return symbol }
        // A filter may leave only newer Unicode characters unsupported by this OS.
        // Use an older representative from the same canonical category AND partition;
        // never borrow another category's symbol or show a missing-glyph box.
        return choose(catalog.symbols.filter {
            $0.atomic && $0.category == first.category &&
            SymbolPanelInventory.isModifier($0) == SymbolPanelInventory.isModifier(first)
        })
    }

    static func icon(for section: SymbolSection, catalog: IPACatalog) -> Self {
        if section.id == "recent" { return .systemImage("clock") }
        if let symbol = representative(for: section, catalog: catalog) { return .glyph(symbol.display) }
        return .systemImage("square.dashed")
    }
}

