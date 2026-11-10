import UIKit

final class KeyboardViewController: UIInputViewController {
    private let keyboard = KeyboardSurface()
    private var heightConstraint: NSLayoutConstraint?
    override func loadView() {
        // UIKit owns the only keyboard backdrop, including its system footer.
        view = UIInputView(frame: .zero, inputViewStyle: .keyboard)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        primaryLanguage = "mul"
        keyboard.systemManagedLayout = true
        keyboard.setContentHuggingPriority(.defaultLow, for: .vertical)
        keyboard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(keyboard)
        NSLayoutConstraint.activate([
            keyboard.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboard.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboard.topAnchor.constraint(equalTo: view.topAnchor),
            keyboard.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        let height = view.heightAnchor.constraint(equalToConstant: 229)
        height.priority = .init(999); height.isActive = true; heightConstraint = height
        inputView?.allowsSelfSizing = true
        keyboard.onMoveCursor = { [weak self] offset in self?.textDocumentProxy.adjustTextPosition(byCharacterOffset: offset) }
        keyboard.onInsert = { [weak self] text in self?.textDocumentProxy.insertText(text) }
        keyboard.onDelete = { [weak self] in self?.textDocumentProxy.deleteBackward() }
        keyboard.onNextKeyboard = { [weak self] sender, event in self?.handleInputModeList(from: sender, with: event) }
        updateAppearance()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        KeyFeedback.shared.soundAvailable = hasFullAccess
        keyboard.refreshVisibility()
    }
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        keyboard.needsGlobe = needsInputModeSwitchKey
        let screen = view.window?.windowScene?.screen.bounds.size ?? UIScreen.main.bounds.size
        keyboard.usesInlineGlobe = needsInputModeSwitchKey && max(screen.width, screen.height) <= 736
        let landscape = view.bounds.width > view.bounds.height && view.bounds.width > 600
        // Four key rows, with small top/bottom insets and no permanent callout band.
        let ownGlobeFooter: CGFloat = needsInputModeSwitchKey && !keyboard.usesInlineGlobe ? 42 : 0
        heightConstraint?.constant = (landscape ? 165 : 229) + ownGlobeFooter
    }
    override func textDidChange(_ textInput: UITextInput?) { KeyFeedback.shared.soundAvailable = hasFullAccess; keyboard.refreshVisibility(); updateAppearance() }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated); keyboard.cancelInteraction()
    }
    private func updateAppearance() {
        switch textDocumentProxy.keyboardAppearance {
        case .dark: keyboard.overrideUserInterfaceStyle = .dark
        case .light: keyboard.overrideUserInterfaceStyle = .light
        default: keyboard.overrideUserInterfaceStyle = .unspecified
        }
        let title: String
        switch textDocumentProxy.returnKeyType {
        case .go: title = "go"
        case .search: title = "search"
        case .send: title = "send"
        case .done: title = "done"
        case .next: title = "next"
        default: title = "return"
        }
        keyboard.returnTitle = title
    }
}
