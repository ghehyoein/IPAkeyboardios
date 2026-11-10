import UIKit

private final class SandboxInputView: UIInputView {
    var requestedHeight: CGFloat = 301 {
        didSet { invalidateIntrinsicContentSize() }
    }
    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: requestedHeight)
    }
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: size.width, height: requestedHeight)
    }
}

final class SandboxViewController: UIViewController {
    private let editor = UITextView()
    private let keyboard = KeyboardSurface(frame: CGRect(x: 0, y: 0, width: 428, height: 301))
    override func viewDidLoad() {
        super.viewDidLoad()
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") && !ProcessInfo.processInfo.arguments.contains("--preserve-settings") { SymbolSettingsStore.shared.resetForTesting() }
        #endif
        keyboard.refreshVisibility()
        title = "IPA Keyboard"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "符号显示".localized, style: .plain, target: self, action: #selector(showSymbolSettings))
        navigationItem.leftBarButtonItem?.accessibilityIdentifier = "openSymbolSettings"
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "使用说明".localized, style: .plain, target: self, action: #selector(showGuide))
        let heading = UILabel()
        heading.text = "把声音，写准确。".localized
        heading.font = .systemFont(ofSize: 28, weight: .bold)
        let description = UILabel()
        description.text = "轻点字母 · 四向滑动 · 长按选变体".localized
        description.font = .systemFont(ofSize: 15)
        description.textColor = .secondaryLabel
        description.numberOfLines = 0
        editor.font = .systemFont(ofSize: 28)
        editor.text = "[ˌɪntəˈnæʃənəl fəˈnɛtɪk ˈælfəbet]\n"
        editor.backgroundColor = .secondarySystemBackground
        editor.layer.cornerRadius = 14
        editor.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        editor.autocorrectionType = .no
        editor.autocapitalizationType = .none
        editor.smartQuotesType = .no
        editor.smartDashesType = .no
        editor.spellCheckingType = .no
        editor.accessibilityLabel = "IPA 试打区域".localized
        editor.accessibilityIdentifier = "transcriptionEditor"
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") { editor.text = "" }
        if !ProcessInfo.processInfo.arguments.contains("--reference-keyboard") { installKeyboardInputView() }
        keyboard.needsGlobe = false
        keyboard.onHeightChange = { [weak self] in self?.installKeyboardInputView() }
        keyboard.onInsert = { [weak self] text in self?.editor.insertText(text) }
        keyboard.onMoveCursor = { [weak self] offset in
            guard let editor = self?.editor, let range = editor.selectedTextRange else { return }
            let text = editor.text as NSString
            var target = editor.offset(from: editor.beginningOfDocument, to: range.start)
            for _ in 0..<abs(offset) {
                if offset > 0, target < text.length { target = NSMaxRange(text.rangeOfComposedCharacterSequence(at: target)) }
                else if offset < 0, target > 0 { target = text.rangeOfComposedCharacterSequence(at: target - 1).location }
            }
            editor.selectedRange = NSRange(location: target, length: 0)
        }
        if CommandLine.arguments.contains("--search-key") { keyboard.returnTitle = "search" }
        keyboard.onDelete = { [weak self] in self?.editor.deleteBackward() }
        let done = UIToolbar()
        done.sizeToFit()
        done.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), UIBarButtonItem(title: "收起键盘".localized, style: .done, target: self, action: #selector(dismissKeyboard))]
        if !ProcessInfo.processInfo.arguments.contains("--screenshot") { editor.inputAccessoryView = done }
        let footer = UILabel()
        footer.text = "打开设置可调整符号、滑动和语言。".localized
        footer.font = .systemFont(ofSize: 13)
        footer.textColor = .secondaryLabel
        footer.numberOfLines = 0
        let stack = UIStackView(arrangedSubviews: [heading, description, editor, footer])
        stack.axis = .vertical; stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        let editorHeight = editor.heightAnchor.constraint(greaterThanOrEqualToConstant: 70)
        editorHeight.priority = .defaultHigh
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 18),
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -12),
            editorHeight
        ])
    }
    private func installKeyboardInputView() {
        // UITextView caches an input view's hosted height. A new host ensures that
        // both expanding and collapsing use the requested size immediately.
        let height = keyboard.intrinsicContentSize.height
        let width = view.window?.bounds.width ?? view.bounds.width
        let container = SandboxInputView(frame: CGRect(x: 0, y: 0, width: width, height: height), inputViewStyle: .default)
        container.requestedHeight = height
        container.allowsSelfSizing = true
        keyboard.removeFromSuperview()
        keyboard.translatesAutoresizingMaskIntoConstraints = true
        keyboard.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        keyboard.frame = container.bounds
        container.addSubview(keyboard)
        editor.inputView = container
        if editor.isFirstResponder { editor.reloadInputViews() }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboard.refreshVisibility()
    }
    @objc private func showSymbolSettings() {
        editor.resignFirstResponder()
        navigationController?.pushViewController(SymbolSettingsViewController(), animated: true)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if ProcessInfo.processInfo.arguments.contains("--screenshot") {
            editor.becomeFirstResponder()
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--screenshot-popup") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in self?.keyboard.showCalloutForSnapshot("q") }
            }
            #endif
        }
    }
    @objc private func dismissKeyboard() { editor.resignFirstResponder() }
    @objc private func showGuide() {
        let guide = UIViewController()
        guide.title = "启用与输入".localized
        guide.view.backgroundColor = .systemBackground
        let text = UITextView()
        text.isEditable = false
        text.font = .systemFont(ofSize: 17)
        text.text = "键盘使用说明".localized
        text.translatesAutoresizingMaskIntoConstraints = false
        guide.view.addSubview(text)
        NSLayoutConstraint.activate([
            text.topAnchor.constraint(equalTo: guide.view.safeAreaLayoutGuide.topAnchor),
            text.bottomAnchor.constraint(equalTo: guide.view.safeAreaLayoutGuide.bottomAnchor),
            text.leadingAnchor.constraint(equalTo: guide.view.leadingAnchor, constant: 16),
            text.trailingAnchor.constraint(equalTo: guide.view.trailingAnchor, constant: -16)
        ])
        navigationController?.pushViewController(guide, animated: true)
    }
}
