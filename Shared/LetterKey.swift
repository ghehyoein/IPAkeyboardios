import UIKit

/// Owns one touch sequence. A held touch can never fall through to a normal tap.
final class LetterKey: UIControl {
    let letter: String
    private let label = UILabel()
    private var start = CGPoint.zero
    private var holdTimer: Timer?
    private var held = false
    private var moved = false
    private var direction: SwipeDirection?
    var legendHidden = false { didSet { label.isHidden = legendHidden } }
    var mapping: IPAKeyMapping?
    private var keyTitle: String { letter == "'" ? "′" : (letter == "\"" ? "″" : letter) }
    var numericAppearance = false { didSet { label.font = .systemFont(ofSize: numericAppearance ? 22 : 25) } }
    var uppercase = false { didSet { label.text = uppercase ? keyTitle.uppercased() : keyTitle } }
    var onInsert: ((String) -> Void)?
    var onPreview: ((LetterKey, String?) -> Void)?
    var onHold: ((LetterKey) -> Void)?
    var onHoldMove: ((CGPoint, Bool) -> Void)?
    var onHoldCancel: (() -> Void)?

    init(letter: String, mapping: IPAKeyMapping?) {
        self.letter = letter; self.mapping = mapping
        super.init(frame: .zero)
        isMultipleTouchEnabled = false
        isExclusiveTouch = true
        layer.cornerRadius = 11
        layer.cornerCurve = .continuous
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.07
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 1.5
        label.text = keyTitle
        label.font = .systemFont(ofSize: 25)
        label.textAlignment = .center
        label.isUserInteractionEnabled = false
        addSubview(label)
        isAccessibilityElement = true
        accessibilityIdentifier = "key_" + letter
        accessibilityLabel = letter
        accessibilityHint = "轻点输入字母；上下左右滑动输入变体；长按显示所有变体"
        accessibilityTraits = .keyboardKey
        accessibilityCustomActions = (mapping?.variants ?? []).map { symbol in
            UIAccessibilityCustomAction(name: symbol) { [weak self] _ in
                self?.onInsert?(symbol); return true
            }
        }
        updateColors()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func layoutSubviews() { super.layoutSubviews(); label.frame = bounds }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection); updateColors()
    }
    private func updateColors() {
        backgroundColor = KeyboardMaterial.key
        label.textColor = traitCollection.userInterfaceStyle == .dark ? .white : .black
    }
    override func accessibilityActivate() -> Bool {
        onInsert?(uppercase ? letter.uppercased() : letter); return true
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        KeyFeedback.shared.keyDown()
        start = touch.location(in: self); held = false; moved = false; direction = nil
        alpha = 0.9
        onPreview?(self, uppercase ? letter.uppercased() : letter)
        holdTimer?.invalidate()
        holdTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            guard let self = self, !self.moved else { return }
            self.held = true; self.onPreview?(self, nil); self.onHold?(self)
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if held { onHoldMove?(touch.location(in: window), false); return }
        let point = touch.location(in: self)
        direction = KeyMotion.direction(dx: Double(point.x - start.x), dy: Double(point.y - start.y))
        if direction != nil { moved = true; holdTimer?.invalidate() }
        let value = direction.flatMap { mapping?.swipes[$0.rawValue] }
        onPreview?(self, direction == nil ? (uppercase ? letter.uppercased() : letter) : (value ?? "—"))
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        defer { reset() }
        if held {
            if let point = touches.first?.location(in: window) { onHoldMove?(point, true) }
            return
        }
        if let direction = direction {
            if let symbol = mapping?.swipes[direction.rawValue] { onInsert?(symbol) }
        } else {
            // Returning to the origin after a flick cancels; it never types an accidental letter.
            if !moved { onInsert?(uppercase ? letter.uppercased() : letter) }
        }
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        onHoldCancel?(); reset()
    }
    func cancelInteraction() { onHoldCancel?(); reset() }
    private func reset() {
        holdTimer?.invalidate(); holdTimer = nil
        alpha = 1; held = false; moved = false; direction = nil; onPreview?(self, nil)
    }
    deinit { holdTimer?.invalidate() }
}
