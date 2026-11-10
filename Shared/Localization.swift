import Foundation

enum L10n {
    static let languages = ["system", "zh-Hans", "zh-Hant", "en", "ja"]
    static var selection = "system"
    static var language: String { resolve(selection: selection, preferred: Locale.preferredLanguages) }
    static func resolve(selection: String, preferred: [String]) -> String {
        if languages.dropFirst().contains(selection) { return selection }
        for code in preferred {
            if code.hasPrefix("zh") { return code.contains("Hant") || code.contains("TW") || code.contains("HK") || code.contains("MO") ? "zh-Hant" : "zh-Hans" }
            if code.hasPrefix("ja") { return "ja" }
            if code.hasPrefix("en") { return "en" }
        }
        return "en"
    }
    private static let data: [String: [String: [String: String]]] = {
        guard let url = Bundle.main.url(forResource: "localization", withExtension: "json"),
              let bytes = try? Data(contentsOf: url),
              let value = try? JSONDecoder().decode([String: [String: [String: String]]].self, from: bytes) else { return [:] }
        return value
    }()
    private static func traditional(_ text: String) -> String {
        text.applyingTransform(StringTransform("Simplified-Traditional"), reverse: false) ?? text
    }
    static func text(_ key: String) -> String {
        switch language {
        case "zh-Hans": return key
        case "zh-Hant": return traditional(key)
        default: return data["ui"]?[key]?[language] ?? key
        }
    }
    static func symbolName(_ original: String) -> String {
        if let entry = data["names"]?[original] {
            if language == "zh-Hans" { return original }
            if language == "zh-Hant" { return traditional(original) }
            return entry[language] ?? original
        }
        return unicodeName(original)
    }
    static func unicodeName(_ name: String) -> String {
        if language == "en" { return name }
        let target = language == "zh-Hant" ? "zh-Hans" : language
        let translated = name.split(separator: " ").map { token -> String in
            let word = String(token)
            if let text = data["words"]?[word]?[target] { return text }
            // Hyphenated Unicode descriptors are composed from the same glossary.
            return word.split(separator: "-", omittingEmptySubsequences: false).map { data["words"]?[String($0)]?[target] ?? String($0) }.joined(separator: "-")
        }.joined(separator: " ")
        return language == "zh-Hant" ? traditional(translated) : translated
    }
    static func languageName(_ code: String) -> String {
        ["system": text("跟随系统"), "zh-Hans": "简体中文", "zh-Hant": "繁體中文", "en": "English", "ja": "日本語"][code] ?? code
    }
}

extension String {
    var localized: String { L10n.text(self) }
}
