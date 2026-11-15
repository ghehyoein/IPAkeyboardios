import Foundation

struct SymbolSection {
    let id: String
    let title: String
    let values: [String]
}

/// One canonical home per character; recents are a separate convenience view.
enum SymbolPanelInventory {
    static func reachable(catalog: IPACatalog, visibility: SymbolVisibility) -> Set<String> {
        var result = Set<String>()
        for page in [KeyboardPage.letters, .numbers, .symbols] {
            for key in page.rows.flatMap({ $0 }) {
                result.insert(key)
                if page == .letters { result.insert(key.uppercased()) }
                let mapping = page == .letters ? catalog.keys[key] : AuxiliaryKeyMapping.mapping(for: key)
                if let mapping { result.formUnion(visibility.filter(mapping, catalog: catalog).variants) }
            }
        }
        return result
    }
    static func isModifier(_ symbol: IPASymbol) -> Bool {
        symbol.combining || !Set(symbol.collections + [symbol.category]).isDisjoint(with: ["diacritics", "superscripts", "subscripts", "combining"])
    }
    static func sections(catalog: IPACatalog, visibility: SymbolVisibility) -> [SymbolSection] {
        let reachable = reachable(catalog: catalog, visibility: visibility)
        var seen = Set<String>()
        let symbols = catalog.symbols.sorted { $0.priority < $1.priority }.filter { symbol in
            guard symbol.atomic, visibility.contains(symbol), seen.insert(symbol.text).inserted else { return false }
            if !reachable.contains(symbol.text) { return visibility.panelUnavailable }
            return isModifier(symbol) ? visibility.panelModifiers : visibility.panelOrdinary
        }
        let order = ["diacritics", "superscripts", "subscripts", "combining", "suprasegmentals", "tones"]
        let categories = catalog.categories.sorted {
            (order.firstIndex(of: $0.id) ?? 100) < (order.firstIndex(of: $1.id) ?? 100)
        }
        var result: [SymbolSection] = []
        // Finish all modifiers before showing ordinary letters, even in mixed categories.
        for modifiers in [true, false] {
            for category in categories {
                let values = symbols.filter { $0.category == category.id && isModifier($0) == modifiers }.map { $0.text }
                guard !values.isEmpty else { continue }
                let reused = result.contains { $0.id == category.id }
                result.append(SymbolSection(id: category.id + (reused ? "-letters" : ""),
                    title: category.title + (reused ? " · 字母".localized : ""), values: values))
            }
        }
        return result
    }
}

