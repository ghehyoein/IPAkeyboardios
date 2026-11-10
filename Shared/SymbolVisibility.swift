import Foundation

struct SymbolVisibility: Codable, Equatable {
    var language = "system"
    var chinese = true
    var historical = true
    var extipa = true
    var panelUnavailable = true
    var panelModifiers = true
    var panelOrdinary = true

    private enum CodingKeys: String, CodingKey {
        case language, chinese, historical, extipa, panelUnavailable, panelModifiers, panelOrdinary
    }
    init(language: String = "system", chinese: Bool = true, historical: Bool = true, extipa: Bool = true,
         panelUnavailable: Bool = true, panelModifiers: Bool = true, panelOrdinary: Bool = true) {
        self.language = L10n.languages.contains(language) ? language : "system"
        self.chinese = chinese; self.historical = historical; self.extipa = extipa
        self.panelUnavailable = panelUnavailable; self.panelModifiers = panelModifiers; self.panelOrdinary = panelOrdinary
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let storedLanguage = try c.decodeIfPresent(String.self, forKey: .language) ?? "system"
        language = L10n.languages.contains(storedLanguage) ? storedLanguage : "system"
        chinese = try c.decodeIfPresent(Bool.self, forKey: .chinese) ?? true
        historical = try c.decodeIfPresent(Bool.self, forKey: .historical) ?? true
        extipa = try c.decodeIfPresent(Bool.self, forKey: .extipa) ?? true
        panelUnavailable = try c.decodeIfPresent(Bool.self, forKey: .panelUnavailable) ?? true
        panelModifiers = try c.decodeIfPresent(Bool.self, forKey: .panelModifiers) ?? true
        panelOrdinary = try c.decodeIfPresent(Bool.self, forKey: .panelOrdinary) ?? true
    }

    func enabled(_ family: String) -> Bool {
        switch family {
        case "chinese": return chinese
        case "historical": return historical
        case "extipa": return extipa
        default: return true
        }
    }
    func contains(_ symbol: IPASymbol) -> Bool {
        // Current IPA always wins, including symbols shared with optional sets.
        if symbol.official || symbol.family == "current" { return true }
        let groups = Set(symbol.collections + [symbol.family]).intersection(["chinese", "historical", "extipa"])
        return groups.isEmpty || groups.contains(where: enabled)
    }
    func filter(_ mapping: IPAKeyMapping, catalog: IPACatalog = .shared) -> IPAKeyMapping {
        let allowed: (String) -> Bool = { text in catalog.symbol(text).map(self.contains) ?? true }
        return IPAKeyMapping(variants: mapping.variants.filter(allowed), swipes: mapping.swipes.filter { allowed($0.value) })
    }
}

/// Preferences cross the process boundary; recent panel symbols stay local.
final class SymbolSettingsStore {
    static let shared = SymbolSettingsStore()
    static var groupIdentifier: String {
        Bundle.main.object(forInfoDictionaryKey: "IPASettingsAppGroup") as? String ?? "group.org.example.IPAKeyboard"
    }
    private let defaults: UserDefaults
    private let container: () -> URL?
    private let localKey = "ipa.symbolVisibility.v1"
    var canShare: Bool { container() != nil }

    init(defaults: UserDefaults = .standard, container: @escaping () -> URL? = {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SymbolSettingsStore.groupIdentifier)
    }) {
        self.defaults = defaults; self.container = container
    }
    func load() -> SymbolVisibility {
        if let url = container()?.appendingPathComponent("symbol-visibility.json"),
           let data = try? Data(contentsOf: url), let value = try? JSONDecoder().decode(SymbolVisibility.self, from: data) {
            defaults.set(data, forKey: localKey)
            return value
        }
        if let data = defaults.data(forKey: localKey), let value = try? JSONDecoder().decode(SymbolVisibility.self, from: data) { return value }
        return SymbolVisibility()
    }
    @discardableResult func save(_ value: SymbolVisibility) -> Bool {
        guard let data = try? JSONEncoder().encode(value) else { return false }
        defaults.set(data, forKey: localKey)
        guard let url = container()?.appendingPathComponent("symbol-visibility.json") else { return false }
        do { try data.write(to: url, options: .atomic); return true }
        catch { return false }
    }
    func loadFeedback() -> FeedbackPreferences {
        if let url = container()?.appendingPathComponent("keyboard-feedback.json"),
           let data = try? Data(contentsOf: url), let value = try? JSONDecoder().decode(FeedbackPreferences.self, from: data) {
            defaults.set(data, forKey: "ipa.feedback.v1")
            return value
        }
        if let data = defaults.data(forKey: "ipa.feedback.v1"), let value = try? JSONDecoder().decode(FeedbackPreferences.self, from: data) { return value }
        return FeedbackPreferences()
    }
    @discardableResult func saveFeedback(_ value: FeedbackPreferences) -> Bool {
        guard let data = try? JSONEncoder().encode(value) else { return false }
        defaults.set(data, forKey: "ipa.feedback.v1")
        guard let url = container()?.appendingPathComponent("keyboard-feedback.json") else { return false }
        do { try data.write(to: url, options: .atomic); return true }
        catch { return false }
    }
    func loadSwipes() -> SwipePreferences {
        if let url = container()?.appendingPathComponent("swipe-preferences.json"),
           let data = try? Data(contentsOf: url), let value = try? JSONDecoder().decode(SwipePreferences.self, from: data) {
            defaults.set(data, forKey: "ipa.swipes.v1"); return value
        }
        if let data = defaults.data(forKey: "ipa.swipes.v1"), let value = try? JSONDecoder().decode(SwipePreferences.self, from: data) { return value }
        return SwipePreferences()
    }
    @discardableResult func saveSwipes(_ value: SwipePreferences) -> Bool {
        guard let data = try? JSONEncoder().encode(value) else { return false }
        defaults.set(data, forKey: "ipa.swipes.v1")
        guard let url = container()?.appendingPathComponent("swipe-preferences.json") else { return false }
        do { try data.write(to: url, options: .atomic); return true } catch { return false }
    }
    #if DEBUG
    func resetForTesting() { save(SymbolVisibility()); saveFeedback(FeedbackPreferences()); saveSwipes(SwipePreferences()); RecentSymbols.shared.clear() }
    #endif
}
