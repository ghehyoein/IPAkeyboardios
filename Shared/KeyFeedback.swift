import UIKit

struct FeedbackPreferences: Codable, Equatable {
    var clicks = true
    var haptics = true
}

/// Public APIs only. Input clicks respect the system's sound policy; UIKit
/// haptics need an explicit app preference because the native toggle is private.
@MainActor final class KeyFeedback {
    static let shared = KeyFeedback()
    var soundAvailable = true
    private let impact = UIImpactFeedbackGenerator(style: .light)
    private let selection = UISelectionFeedbackGenerator()
    private(set) var preferences = FeedbackPreferences()
    func reload() { preferences = SymbolSettingsStore.shared.loadFeedback() }
    func keyDown() {
        if preferences.clicks && soundAvailable { UIDevice.current.playInputClick() }
        if preferences.haptics { impact.impactOccurred(intensity: 0.45); impact.prepare() }
    }
    func candidateChanged() {
        if preferences.haptics { selection.selectionChanged(); selection.prepare() }
    }
}
