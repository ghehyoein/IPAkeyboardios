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

