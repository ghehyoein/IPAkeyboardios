import UIKit
import CoreText

/// Use the system's fallback fonts. If even fallback fonts lack a new Unicode
/// character, show its code point instead of an indistinguishable tofu box.
enum PhoneticDisplay {
    private static let cache: NSCache<NSString, NSNumber> = {
        let cache = NSCache<NSString, NSNumber>(); cache.countLimit = 512; return cache
    }()
    static func isSupported(_ text: String) -> Bool {
        if let cached = cache.object(forKey: text as NSString) { return cached.boolValue }
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: 26)]))
        let runs = CTLineGetGlyphRuns(line) as! [CTRun]
        let supported = runs.allSatisfy { run in
            // Apple's LastResort font has nonzero glyph IDs but draws boxed
            // placeholders. Treat it as missing coverage too.
            let attributes = CTRunGetAttributes(run) as NSDictionary
            if let font = attributes[kCTFontAttributeName] {
                let name = CTFontCopyPostScriptName(font as! CTFont) as String
                if name.lowercased().contains("lastresort") { return false }
            }
            var glyphs = [CGGlyph](repeating: 0, count: CTRunGetGlyphCount(run))
            CTRunGetGlyphs(run, CFRange(location: 0, length: 0), &glyphs)
            return !glyphs.contains(0)
        }
        cache.setObject(NSNumber(value: supported), forKey: text as NSString)
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
                               supports: (String) -> Bool = PhoneticDisplay.isSupported) -> IPASymbol? {
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

