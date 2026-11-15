import Foundation

struct IPASymbol: Decodable {
    let id: String
    let text: String
    let display: String
    let rawName: String
    var name: String { L10n.symbolName(rawName) }
    private enum CodingKeys: String, CodingKey {
        case id, text, display, rawName = "name", category, combining, official, atomic, family, priority, collections, baseKey
    }
    let category: String
    let combining: Bool
    let official: Bool
    let atomic: Bool
    let family: String
    let priority: Int
    let collections: [String]
    let baseKey: String?
}
struct IPACategory: Decodable {
    let id: String
    let rawTitle: String
    var title: String { rawTitle.localized }
    private enum CodingKeys: String, CodingKey { case id, rawTitle = "title" }
}
struct IPAKeyMapping: Decodable {
    let variants: [String]
    let swipes: [String: String]
}
struct IPACatalog: Decodable {
    let categories: [IPACategory]
    let symbols: [IPASymbol]
    let keys: [String: IPAKeyMapping]
    private let symbolsByText: [String: IPASymbol]
    private enum CodingKeys: String, CodingKey { case categories, symbols, keys }
    init(categories: [IPACategory], symbols: [IPASymbol], keys: [String: IPAKeyMapping]) {
        self.categories = categories; self.symbols = symbols; self.keys = keys
        symbolsByText = Dictionary(symbols.map { ($0.text, $0) }, uniquingKeysWith: { first, _ in first })
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(categories: try values.decode([IPACategory].self, forKey: .categories),
                  symbols: try values.decode([IPASymbol].self, forKey: .symbols),
                  keys: try values.decode([String: IPAKeyMapping].self, forKey: .keys))
    }
    static let shared: IPACatalog = {
        guard let url = Bundle.main.url(forResource: "ipa-catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let catalog = try? JSONDecoder().decode(IPACatalog.self, from: data) else {
            // Keep the basic keyboard usable even if a resource is packaged incorrectly.
            return IPACatalog(categories: [], symbols: [], keys: [:])
        }
        return catalog
    }()
    func symbol(_ text: String) -> IPASymbol? { symbolsByText[text] }
}

enum SwipeDirection: String { case up, right, down, left }
enum KeyMotion {
    static func direction(dx: Double, dy: Double, threshold: Double = 20) -> SwipeDirection? {
        guard max(abs(dx), abs(dy)) >= threshold else { return nil }
        if abs(dx) > abs(dy) { return dx > 0 ? .right : .left }
        return dy > 0 ? .down : .up
    }
}
