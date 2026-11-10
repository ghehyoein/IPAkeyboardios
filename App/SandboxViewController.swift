import UIKit

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
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "符号显示", style: .plain, target: self, action: #selector(showSymbolSettings))
        navigationItem.leftBarButtonItem?.accessibilityIdentifier = "openSymbolSettings"
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "使用说明", style: .plain, target: self, action: #selector(showGuide))
        let heading = UILabel()
        heading.text = "把声音，写准确。"
        heading.font = .systemFont(ofSize: 28, weight: .bold)
        let description = UILabel()
        description.text = "轻点字母 · 四向滑动 · 长按选变体\n点击 123 右侧的 ◌̃ 输入附加符号；123 切换数字与标点。"
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
        editor.accessibilityLabel = "IPA 试打区域"
        editor.accessibilityIdentifier = "transcriptionEditor"
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") { editor.text = "" }
        keyboard.autoresizingMask = [.flexibleWidth]
        if !ProcessInfo.processInfo.arguments.contains("--reference-keyboard") { editor.inputView = keyboard }
        keyboard.needsGlobe = false
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
        done.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), UIBarButtonItem(title: "收起键盘", style: .done, target: self, action: #selector(dismissKeyboard))]
        if !ProcessInfo.processInfo.arguments.contains("--screenshot") { editor.inputAccessoryView = done }
        let footer = UILabel()
        footer.text = "左上角可调整符号显示。设置会在重新切回键盘后生效；不联网；仅在本地保存最近选用的面板符号。"
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
        guide.title = "启用与输入"
        guide.view.backgroundColor = .systemBackground
        let text = UITextView()
        text.isEditable = false
        text.font = .systemFont(ofSize: 17)
        text.text = """
        启用系统键盘

        设置 → 通用 → 键盘 → 键盘 → 添加新键盘 → IPA Keyboard。
        在其他应用中长按地球键，选择 IPA Keyboard。
        基本输入和只读同步设置无需完全访问（签名需保留 App Groups）。系统键盘的按键声音需要允许完全访问。应用不联网；键盘仅在本地保存最多 60 个最近选用的面板符号，不保存正文。

        字母与变体

        轻点：输入英文字母。
        向上、右、下、左滑动：预览候选，松手输入。
        滑动到没有候选的方向：不输入。
        滑动后回到起点：取消本次输入。
        长按：按住显示浮动候选条，滑动选择并松手输入；移出候选条与原键组成的区域则取消。
        候选较多时，停在候选条左右边缘自动滚动。顺序：现版 IPA → 中国通用音标 → 旧版 IPA → extIPA → 其他 Unicode 语音符号。
        Shift：一次大写；连续双击锁定大写。IPA 变体保持原字形。

        附加符号

        点击 123 / ABC 右边、空格左边的 ◌̃ 打开分类面板。分类栏可以左右滚动。
        先输入 a，再选 ◌̃，得到 ã。虚线圆圈不会写入正文。
        先输入 t，再选 ʰ，得到 tʰ。
        连音线在两个字母之间输入：t → ◌͡ → s，得到 t͡s。
        声调既支持组合标记，也支持 ˥ ˦ ˧ ˨ ˩ 及总表轮廓组合。
        ABC 返回字母键盘。删除遵循系统的字符簇删除行为，可能一起删除字母与组合附加符号。

        符号范围

        组合形式请依次输入基本字母、上标、下标或组合附加符号，不再提供整个组合的快捷候选。

        当前依据国际语音协会 2026 版标准总表（表底标注 revised to 2015/2005）。
        覆盖肺部气流辅音、非肺部气流辅音、元音、其他符号、附加符号、超音段与声调。
        转写辅助页另提供括号、ASCII g、ɚ、ɝ 等便捷项。
        另包含中国通用音标的已编码符号（包括 ɿ ʅ ʮ ʯ ᴀ ᴇ）、旧版/非标准 IPA、extIPA 2025 及 Unicode 18 语音相关上标、下标和组合标记。
        某些 Unicode 新字符尚无系统字形，候选显示 U+码位，输入仍是原始字符。

        系统限制

        键盘使用 UIKit 实现，长按候选条显示在扩展视图内部。
        密码、部分电话号码输入框，以及禁用扩展的应用会使用系统键盘。
        字体、组合符号位置和声调连线效果由输入目标应用决定。
        """
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
