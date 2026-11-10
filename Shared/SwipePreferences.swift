import Foundation

struct SwipePreferences: Codable, Equatable {
    var overrides: [String: [String: String]] = [:]
    static let directions = ["up", "down", "left", "right"]
    static func source(for key: String, catalog: IPACatalog = .shared) -> IPAKeyMapping {
        catalog.keys[key] ?? AuxiliaryKeyMapping.mapping(for: key)
    }
    func applying(to source: IPAKeyMapping, key: String) -> IPAKeyMapping {
        var swipes = source.swipes
        let allowed = Set(source.variants + [key])
        for (direction, value) in overrides[key] ?? [:] where Self.directions.contains(direction) {
            // Ignore malformed or out-of-menu assignments, including old settings.
            if allowed.contains(value) { swipes[direction] = value }
        }
        return IPAKeyMapping(variants: source.variants, swipes: swipes)
    }
}

/// Only explicitly selected panel symbols, never surrounding text or letter input.
final class RecentSymbols {
    static let shared = RecentSymbols()
    private let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) { self.defaults = defaults }
    var values: [String] { defaults.stringArray(forKey: "ipa.recentSymbols.v1") ?? [] }
    func record(_ text: String) {
        let next = [text] + values.filter { $0 != text }
        defaults.set(Array(next.prefix(60)), forKey: "ipa.recentSymbols.v1")
    }
    func clear() { defaults.removeObject(forKey: "ipa.recentSymbols.v1") }
}
