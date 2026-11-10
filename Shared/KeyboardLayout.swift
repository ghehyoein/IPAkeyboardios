import Foundation

/// US English iPhone keyboard pages. The bottom row and footer are shared.
enum KeyboardPage {
    case letters, numbers, symbols
    var rows: [[String]] {
        switch self {
        case .letters: return [Array("qwertyuiop"), Array("asdfghjkl"), Array("zxcvbnm")].map { $0.map(String.init) }
        case .numbers: return [Array("1234567890"), Array("-/:;()$&@\""), Array(".,?!'")].map { $0.map(String.init) }
        case .symbols: return [Array("[]{}#%^*+="), Array("_\\|~<>€£¥•"), Array(".,?!'")].map { $0.map(String.init) }
        }
    }
}

enum AuxiliaryKeyMapping {
    static func mapping(for key: String) -> IPAKeyMapping {
        let digits = Array("0123456789").map(String.init)
        if let index = digits.firstIndex(of: key) {
            let upper = Array("⁰¹²³⁴⁵⁶⁷⁸⁹").map(String.init)[index]
            let lower = Array("₀₁₂₃₄₅₆₇₈₉").map(String.init)[index]
            let others: [String: [String]] = ["0": ["°", "∅"], "1": ["½", "⅓", "¼", "⅛"], "2": ["⅔"], "3": ["¾", "⅜"], "5": ["⅝"], "7": ["⅞"]]
            let variants = [upper, lower] + (others[key] ?? [])
            return build(variants)
        }
        let punctuation: [String: [String]] = [
            "-": ["–", "—", "−", "_", "⁻", "₋"],
            "/": ["⁄", "∕", "\\"], ":": ["ː", "ˑ", "："], ";": ["；"],
            "(": ["⁽", "₍"], ")": ["⁾", "₎"],
            "$": ["€", "£", "¥", "₩", "₽", "¢"],
            "&": ["§"], "@": ["＠"],
            "\"": ["“", "”", "„", "«", "»", "″", "ʺ"],
            ".": ["…", "·", "。"], ",": ["‚", "，", "،"],
            "?": ["¿", "ʔ", "ʕ"], "!": ["¡", "ǃ"],
            "'": ["‘", "’", "ʼ", "ʹ", "′", "`"],
            "[": ["⟦", "⟨"], "]": ["⟧", "⟩"],
            "{": ["⦃"], "}": ["⦄"], "#": ["♯", "№"],
            "%": ["‰", "‱"], "^": ["↑", "ꜛ", "↗"],
            "*": ["⁎", "×", "⋆"], "+": ["⁺", "₊", "±"],
            "=": ["⁼", "₌", "≠", "≈", "≡"],
            "_": ["‿", "ˍ"], "\\": ["∖", "/"],
            "|": ["ǀ", "ǁ", "‖", "¦"], "~": ["∼", "≈", "˜"],
            "<": ["≤", "‹", "«", "⟨"], ">": ["≥", "›", "»", "⟩"],
            "€": ["$", "£", "¥", "₩", "₽", "¢"],
            "£": ["$", "€", "¥", "₩", "₽", "¢"],
            "¥": ["$", "€", "£", "₩", "₽", "¢"],
            "•": ["·", "◦", "∙", "○", "●"]
        ]
        return build(punctuation[key] ?? [])
    }
    private static func build(_ variants: [String]) -> IPAKeyMapping {
        // Up/down expose super/subscripts; left/right expose further variants.
        let directions = ["up", "down", "left", "right"]
        return IPAKeyMapping(variants: variants, swipes: Dictionary(uniqueKeysWithValues: zip(directions, variants)))
    }
}

/// Accumulates sub-character movement without losing small drags or reversals.
struct CursorDrag {
    private var remainder: Double = 0
    mutating func reset() { remainder = 0 }
    mutating func consume(dx: Double) -> Int {
        remainder += dx
        let count = Int(remainder / 8)
        remainder -= Double(count) * 8
        return count
    }
}
