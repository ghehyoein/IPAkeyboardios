import UIKit

/// Shared by the app's local sandbox and the actual system keyboard extension.
final class KeyboardSurface: UIView, UIInputViewAudioFeedback {
    var enableInputClicksWhenVisible: Bool { KeyFeedback.shared.preferences.clicks }
    var onInsert: ((String) -> Void)?
    var onMoveCursor: ((Int) -> Void)?
    private var cursorDrag = CursorDrag()
    private var cursorPoint = CGPoint.zero
    private var trackingCursor = false
    private var suppressSpaceTap = false
    var onDelete: (() -> Void)?
    var onNextKeyboard: ((UIButton, UIEvent) -> Void)?
    var usesInlineGlobe = false { didSet { setNeedsLayout() } }
    private var swipePreferences = SymbolSettingsStore.shared.loadSwipes()
    var systemManagedLayout = false { didSet { invalidateIntrinsicContentSize(); setNeedsLayout() } }
    var needsGlobe = true { didSet { setNeedsLayout() } }
    var returnTitle = "return" { didSet { updateReturnKey() } }
    private let catalog = IPACatalog.shared
    private(set) var visibility = SymbolSettingsStore.shared.load()
    private var rows: [[LetterKey]] = []
    private(set) var page: KeyboardPage = .letters
    private var uppercase = false
    private var capsLocked = false
    private var lastShiftTap: TimeInterval = 0
    private let shiftButton = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)
    private let numberButton = UIButton(type: .system)
    private let globeButton = UIButton(type: .system)
    private let spaceButton = UIButton(type: .system)
    private let symbolsButton = UIButton(type: .system)
    private let returnButton = UIButton(type: .system)
    private let preview = UILabel()
    private var touchPreview: VariantStrip?
    private var overlay: UIView?
    private var variantStrip: VariantStrip?
    private var repeatTimer: Timer?
    private var delayTimer: Timer?
    private var panelCategory = "diacritics"
    private var panelTitle: UILabel?
    private var previousSize = CGSize.zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        KeyFeedback.shared.reload()
        clipsToBounds = true
        layer.cornerRadius = 20
        layer.cornerCurve = .continuous
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        _ = KeyboardMaterial.install(in: self)
        rebuildRows()
        configure(shiftButton, title: "", action: #selector(shift))
        configure(deleteButton, title: "", action: nil)
        shiftButton.setImage(UIImage(systemName: "shift", withConfiguration: UIImage.SymbolConfiguration(pointSize: 15)), for: .normal)
        deleteButton.setImage(UIImage(systemName: "delete.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 15)), for: .normal)
        shiftButton.accessibilityIdentifier = "pageToggleKey"
        numberButton.accessibilityIdentifier = "numberModeKey"
        symbolsButton.accessibilityIdentifier = "diacriticsKey"
        spaceButton.accessibilityIdentifier = "spaceKey"
        spaceButton.accessibilityLabel = "space"
        deleteButton.accessibilityIdentifier = "deleteKey"
        deleteButton.accessibilityLabel = "删除"
        deleteButton.addTarget(self, action: #selector(deleteDown), for: .touchDown)
        deleteButton.addTarget(self, action: #selector(deleteUp), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
        configure(numberButton, title: "123", action: #selector(showNumbers))
        configure(globeButton, title: "◎", action: nil)
        globeButton.setImage(UIImage(systemName: "globe"), for: .normal)
        globeButton.setTitle(nil, for: .normal)
        globeButton.accessibilityLabel = "切换输入法"
        globeButton.addTarget(self, action: #selector(nextKeyboard(_:event:)), for: .allTouchEvents)
        configure(spaceButton, title: "", action: #selector(space))
        spaceButton.addTarget(self, action: #selector(spaceTouchBegan), for: .touchDown)
        let trackpad = UILongPressGestureRecognizer(target: self, action: #selector(moveCursor(_:)))
        trackpad.minimumPressDuration = 0.4; trackpad.allowableMovement = 18
        trackpad.cancelsTouchesInView = true; spaceButton.addGestureRecognizer(trackpad)
        spaceButton.accessibilityHint = "轻点输入空格；长按后左右拖动移动光标"
        spaceButton.accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: "光标左移") { [weak self] _ in self?.onMoveCursor?(-1); return true },
            UIAccessibilityCustomAction(name: "光标右移") { [weak self] _ in self?.onMoveCursor?(1); return true }
        ]
        configure(symbolsButton, title: "◌̃", action: #selector(showSymbols))
        symbolsButton.titleLabel?.font = .systemFont(ofSize: 28)
        symbolsButton.accessibilityLabel = "IPA 附加符号与全部符号"
        configure(returnButton, title: "", action: #selector(newline))
        updateReturnKey()
        preview.font = .systemFont(ofSize: 33)
        preview.textAlignment = .center
        preview.layer.cornerRadius = 8
        preview.clipsToBounds = true
        preview.isUserInteractionEnabled = false
        preview.isHidden = true
        addSubview(preview)
        applyColors()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override var intrinsicContentSize: CGSize { CGSize(width: UIView.noIntrinsicMetric, height: systemManagedLayout ? UIView.noIntrinsicMetric : 380) }

    private func configure(_ button: UIButton, title: String, action: Selector?) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18)
        button.layer.cornerRadius = 12
        button.layer.cornerCurve = .continuous
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowRadius = 0
        button.addTarget(self, action: #selector(keyFeedback), for: .touchDown)
        if let action = action { button.addTarget(self, action: action, for: .touchUpInside) }
        addSubview(button)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        let width = bounds.width
        guard width > 0 else { return }
        if previousSize != .zero && previousSize != bounds.size { closePanel(); dismissVariants(); preview.isHidden = true }
        previousSize = bounds.size
        let gap: CGFloat = width < 360 ? 5 : 6
        let inset: CGFloat = 8.5
        let keyWidth = (width - inset * 2 - gap * 9) / 10
        let footer: CGFloat = systemManagedLayout ? (needsGlobe && !usesInlineGlobe ? 50 : 8) : 80
        let available = max(140, bounds.height - footer - 8)
        let rowPitch: CGFloat = min(width > 600 ? 40 : 56, (available + 11) / 4)
        let keyHeight = max(24, rowPitch - 11)
        let top: CGFloat = max(8, bounds.height - footer - 3 * rowPitch - keyHeight)
        for (r, row) in rows.enumerated() {
            // Five punctuation keys occupy exactly the seven-letter region.
            let middleWidth = 7 * keyWidth + 6 * gap
            let slots = row.count + (usesInlineGlobe && r == 2 ? 1 : 0)
            let w = r == 2 && (page != .letters || usesInlineGlobe) ? (middleWidth - CGFloat(slots - 1) * gap) / CGFloat(slots) : keyWidth
            let rowWidth = CGFloat(slots) * w + CGFloat(slots - 1) * gap
            let left = (width - rowWidth) / 2
            for (i, key) in row.enumerated() {
                key.frame = CGRect(x: left + CGFloat(i) * (w + gap), y: top + CGFloat(r) * rowPitch, width: w, height: keyHeight)
            }
        }
        let sideWidth = keyWidth + 12
        shiftButton.frame = CGRect(x: inset, y: top + rowPitch * 2, width: sideWidth, height: keyHeight)
        deleteButton.frame = CGRect(x: width - inset - sideWidth, y: top + rowPitch * 2, width: sideWidth, height: keyHeight)
        let bottomY = top + rowPitch * 3
        let spaceWidth = 5 * keyWidth + 4 * gap
        let side = (width - inset * 2 - gap * 2 - spaceWidth) / 2
        let leftKeyWidth = (side - gap) / 2
        numberButton.frame = CGRect(x: inset, y: bottomY, width: leftKeyWidth, height: keyHeight)
        symbolsButton.frame = CGRect(x: numberButton.frame.maxX + gap, y: bottomY, width: leftKeyWidth, height: keyHeight)
        returnButton.frame = CGRect(x: width - inset - side, y: bottomY, width: side, height: keyHeight)
        spaceButton.frame = CGRect(x: symbolsButton.frame.maxX + gap, y: bottomY, width: returnButton.frame.minX - symbolsButton.frame.maxX - gap * 2, height: keyHeight)
        // The bottom-row order is 123/ABC, diacritics, space, return.
        // The language switch remains separate from the diacritics panel.
        let footerY = bottomY + keyHeight + 18
        if usesInlineGlobe {
            globeButton.frame = symbolsButton.frame
            if let last = rows.last?.last {
                symbolsButton.frame = CGRect(x: last.frame.maxX + gap, y: last.frame.minY, width: last.frame.width, height: keyHeight)
            }
        }
        globeButton.isHidden = overlay != nil || !needsGlobe
        if !usesInlineGlobe { globeButton.frame = CGRect(x: width - 64, y: footerY, width: 42, height: 42) }
        overlay?.frame = bounds
    }
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled, !isHidden, alpha > 0.01, bounds.contains(point) else { return nil }
        let normal = super.hitTest(point, with: event)
        guard overlay == nil, normal === self else { return normal }
        // Native keys accept taps in the visual gutters, not only on the cap.
        // Keep the original control as touch owner for flicks and hold selection.
        let controls = subviews.compactMap { $0 as? UIControl }.filter { !$0.isHidden && $0.isEnabled }
        let nearest: UIView? = controls.filter { $0.frame.insetBy(dx: -3, dy: -5.5).contains(point) }
            .min { hypot($0.center.x - point.x, $0.center.y - point.y) < hypot($1.center.x - point.x, $1.center.y - point.y) }
        return nearest ?? normal
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection); applyColors()
    }
    private func applyColors() {
        let dark = traitCollection.userInterfaceStyle == .dark
        backgroundColor = .clear
        for button in [shiftButton, deleteButton, numberButton, globeButton, symbolsButton, returnButton] {
            button.backgroundColor = KeyboardMaterial.utility
            button.tintColor = dark ? .white : .black
        }
        spaceButton.backgroundColor = KeyboardMaterial.key
        spaceButton.tintColor = dark ? .white : .black
        globeButton.backgroundColor = usesInlineGlobe ? KeyboardMaterial.key : .clear
        preview.backgroundColor = dark ? UIColor(white: 0.4, alpha: 1) : .white
        preview.textColor = dark ? .white : .black
        updateReturnKey()
    }
    private func updateReturnKey() {
        let imageName: String? = returnTitle == "return" ? "return" : (returnTitle == "search" ? "magnifyingglass" : nil)
        returnButton.setTitle(imageName == nil ? returnTitle : nil, for: .normal)
        returnButton.setImage(imageName.flatMap { UIImage(systemName: $0, withConfiguration: UIImage.SymbolConfiguration(pointSize: returnTitle == "search" ? 22 : 15)) }, for: .normal)
        returnButton.backgroundColor = returnTitle == "search" ? .systemBlue : KeyboardMaterial.key
        returnButton.tintColor = returnTitle == "search" ? .white : .label
        returnButton.accessibilityLabel = returnTitle
        returnButton.accessibilityIdentifier = "returnKey"
    }
    private func rebuildRows() {
        for key in rows.flatMap({ $0 }) { key.cancelInteraction(); key.removeFromSuperview() }
        rows = page.rows.map { values in
            values.map { value in
                let mapping = page == .letters ? catalog.keys[value] : AuxiliaryKeyMapping.mapping(for: value)
                let key = LetterKey(letter: value, mapping: mapping.map { visibility.filter(swipePreferences.applying(to: $0, key: value)) })
                key.numericAppearance = page != .letters
                key.uppercase = page == .letters && uppercase
                key.onInsert = { [weak self] text in self?.insert(text) }
                key.onPreview = { [weak self] key, value in self?.showPreview(key: key, value: value) }
                key.onHold = { [weak self] key in self?.showVariants(key) }
                key.onHoldCancel = { [weak self] in self?.dismissVariants() }
                key.onHoldMove = { [weak self] point, ended in self?.trackVariant(point, ended: ended) }
                addSubview(key)
                return key
            }
        }
    }
    @objc private func keyFeedback() { KeyFeedback.shared.keyDown() }
    func refreshVisibility() {
        KeyFeedback.shared.reload()
        let updated = SymbolSettingsStore.shared.load()
        let swipes = SymbolSettingsStore.shared.loadSwipes()
        guard updated != visibility || swipes != swipePreferences else { return }
        visibility = updated; swipePreferences = swipes
        showPage(page)
    }
    func showPage(_ newPage: KeyboardPage) {
        closePanel(); dismissVariants(); deleteUp()
        touchPreview?.removeFromSuperview(); touchPreview = nil
        page = newPage
        rebuildRows()
        numberButton.setTitle(page == .letters ? "123" : "ABC", for: .normal)
        if page == .letters { updateShift() }
        else {
            shiftButton.setImage(nil, for: .normal)
            shiftButton.titleLabel?.font = .systemFont(ofSize: page == .numbers ? 14 : 18)
            shiftButton.setTitle(page == .numbers ? "#+=" : "123", for: .normal)
            shiftButton.accessibilityLabel = page == .numbers ? "#+=" : "123"
        }
        setNeedsLayout()
    }
    private func insert(_ text: String) {
        onInsert?(text)
        if uppercase && !capsLocked {
            uppercase = false; updateShift()
        }
    }
    @objc private func shift() {
        if page != .letters { showPage(page == .numbers ? .symbols : .numbers); return }
        let now = Date.timeIntervalSinceReferenceDate
        if now - lastShiftTap < 0.3 { capsLocked = true; uppercase = true }
        else { capsLocked = false; uppercase.toggle() }
        lastShiftTap = now; updateShift()
    }
    private func updateShift() {
        guard page == .letters else { return }
        shiftButton.setTitle(nil, for: .normal)
        rows.flatMap { $0 }.forEach { $0.uppercase = uppercase }
        shiftButton.setImage(UIImage(systemName: capsLocked ? "capslock.fill" : (uppercase ? "shift.fill" : "shift"), withConfiguration: UIImage.SymbolConfiguration(pointSize: 15)), for: .normal)
        shiftButton.accessibilityLabel = capsLocked ? "大写锁定" : (uppercase ? "大写" : "小写")
    }
    @objc private func deleteDown() {
        deleteUp(); onDelete?()
        delayTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.repeatTimer = Timer.scheduledTimer(withTimeInterval: 0.085, repeats: true) { [weak self] _ in self?.onDelete?() }
        }
    }
    @objc private func deleteUp() { delayTimer?.invalidate(); repeatTimer?.invalidate(); delayTimer = nil; repeatTimer = nil }
    @objc private func spaceTouchBegan() { suppressSpaceTap = false }
    @objc private func space() { if !suppressSpaceTap { insert(" ") } }
    @objc private func moveCursor(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            trackingCursor = true; suppressSpaceTap = true
            cursorDrag.reset(); cursorPoint = gesture.location(in: self)
            dismissVariants(); touchPreview?.removeFromSuperview(); touchPreview = nil
            rows.flatMap { $0 }.forEach { $0.legendHidden = true }
            spaceButton.setTitle("移动光标", for: .normal)
            KeyFeedback.shared.candidateChanged()
        case .changed:
            guard trackingCursor else { return }
            let point = gesture.location(in: self)
            let offset = cursorDrag.consume(dx: Double(point.x - cursorPoint.x))
            cursorPoint = point
            if offset != 0 { onMoveCursor?(offset) }
        case .ended, .cancelled, .failed: endCursorTracking()
        default: break
        }
    }
    private func endCursorTracking() {
        trackingCursor = false; cursorDrag.reset()
        rows.flatMap { $0 }.forEach { $0.legendHidden = false }
        spaceButton.setTitle("", for: .normal)
    }
    @objc private func newline() { insert("\n") }
    @objc private func nextKeyboard(_ sender: UIButton, event: UIEvent) { onNextKeyboard?(sender, event) }
    private func showPreview(key: LetterKey, value: String?) {
        touchPreview?.removeFromSuperview(); touchPreview = nil
        preview.isHidden = true
        guard let value = value, overlay == nil, variantStrip == nil else { return }
        let bubble = VariantStrip(keyFrame: key.frame, base: value, variants: [], in: bounds, showsSelection: false)
        addSubview(bubble); touchPreview = bubble
    }
    @objc private func closePanel() {
        overlay?.removeFromSuperview(); overlay = nil; panelTitle = nil
        subviews.compactMap { $0 as? UIControl }.forEach { $0.isHidden = false }
        setNeedsLayout()
    }
    @objc private func returnToLetters() { showPage(.letters) }
    private func makePanel() -> UIView {
        closePanel(); dismissVariants(); preview.isHidden = true
        touchPreview?.removeFromSuperview(); touchPreview = nil
        subviews.compactMap { $0 as? UIControl }.forEach { $0.isHidden = true }
        let panel = UIView(frame: bounds)
        panel.backgroundColor = backgroundColor
        addSubview(panel); overlay = panel
        let close = UIButton(type: .system)
        close.setTitle("ABC", for: .normal)
        close.accessibilityIdentifier = "closeSymbolPanel"
        close.titleLabel?.font = .systemFont(ofSize: 18)
        close.frame = numberButton.frame
        close.backgroundColor = .clear
        close.tintColor = numberButton.tintColor
        close.layer.cornerRadius = 9
        close.layer.cornerCurve = .continuous
        close.addTarget(self, action: #selector(returnToLetters), for: .touchUpInside)
        close.addTarget(self, action: #selector(keyFeedback), for: .touchDown)
        panel.addSubview(close)
        return panel
    }
    func dismissVariants() {
        variantStrip?.cancel(); variantStrip?.removeFromSuperview(); variantStrip = nil
    }
    private func showVariants(_ key: LetterKey) {
        dismissVariants(); touchPreview?.removeFromSuperview(); touchPreview = nil; preview.isHidden = true
        let variants = key.mapping?.variants ?? []
        let strip = VariantStrip(keyFrame: key.frame, base: key.uppercase ? key.letter.uppercased() : key.letter, variants: variants, in: bounds)
        addSubview(strip); variantStrip = strip
    }
    private func trackVariant(_ windowPoint: CGPoint, ended: Bool) {
        guard let strip = variantStrip else { return }
        if !ended { strip.track(convert(windowPoint, from: nil)) }
        if ended {
            let text = strip.finish()
            dismissVariants()
            if let text = text { insert(text) }
        }
    }
    @objc private func showSymbols() { showCategory(panelCategory) }
    private func showCategory(_ id: String) {
        let panel = makePanel()
        let inventory = SymbolPanelInventory.sections(catalog: catalog, visibility: visibility)
        let allowed = Set(inventory.flatMap { $0.values })
        let recent = RecentSymbols.shared.values.filter { allowed.contains($0) }
        let sections = [SymbolSection(id: "recent", title: "最近使用", values: recent)] + inventory
        let tabs = UIScrollView(frame: CGRect(x: numberButton.frame.maxX + 6, y: numberButton.frame.minY, width: bounds.width - numberButton.frame.maxX - 14.5, height: numberButton.frame.height))
        tabs.showsHorizontalScrollIndicator = false
        tabs.accessibilityIdentifier = "symbolCategories"
        panel.addSubview(tabs)
        let top: CGFloat = 16
        let title = UILabel(frame: CGRect(x: 10, y: top - 2, width: bounds.width - 20, height: 20))
        title.font = .systemFont(ofSize: 12, weight: .medium); title.textColor = .secondaryLabel
        title.accessibilityIdentifier = "symbolSectionTitle"; panel.addSubview(title)
        let grid = SymbolGrid(frame: CGRect(x: 0, y: top + 20, width: bounds.width, height: max(1, numberButton.frame.minY - top - 26)), sections: sections)
        grid.keyHeight = min(36, numberButton.frame.height)
        grid.onInsert = { [weak self] text in self?.insert(text) }
        panel.addSubview(grid)
        var x: CGFloat = 0
        var buttons: [String: UIButton] = [:]
        for section in sections {
            let button = UIButton(type: .system)
            button.setTitle(section.title, for: .normal)
            button.accessibilityIdentifier = "category_" + section.id
            button.titleLabel?.font = .systemFont(ofSize: 12)
            let width = max(54, CGFloat(section.title.count) * 13 + 18)
            button.frame = CGRect(x: x, y: 0, width: width, height: numberButton.frame.height)
            button.layer.cornerRadius = 12; button.layer.cornerCurve = .continuous
            button.addAction(UIAction { [weak grid] _ in grid?.selectSection(section.id, animated: true) }, for: .touchUpInside)
            tabs.addSubview(button); buttons[section.id] = button; x += width + 5
        }
        tabs.contentSize = CGSize(width: x, height: numberButton.frame.height)
        grid.onSectionChange = { [weak self, weak title] id, heading in
            self?.panelCategory = id; title?.text = heading
            for (key, button) in buttons {
                button.backgroundColor = key == id ? UIColor.systemTeal.withAlphaComponent(0.18) : .clear
                button.tintColor = key == id ? .label : .secondaryLabel
                button.setTitleColor(key == id ? .label : .secondaryLabel, for: .normal)
                button.accessibilityTraits = key == id ? [.button, .selected] : [.button]
            }
            // Selection never changes the category strip's scroll offset.
        }
        let target = sections.contains { $0.id == id } ? id : (inventory.first?.id ?? "recent")
        grid.layoutIfNeeded()
        grid.selectSection(target)
    }
    @objc private func showNumbers() { showPage(page == .letters ? .numbers : .letters) }
    #if DEBUG
    func showCalloutForSnapshot(_ letter: String) {
        if let key = rows.flatMap({ $0 }).first(where: { $0.letter == letter }) { showVariants(key) }
    }
    #endif
    func cancelInteraction() {
        endCursorTracking(); deleteUp(); closePanel(); dismissVariants(); touchPreview?.removeFromSuperview(); touchPreview = nil; rows.flatMap { $0 }.forEach { $0.cancelInteraction() }; preview.isHidden = true
    }
    deinit { repeatTimer?.invalidate(); delayTimer?.invalidate() }
}
