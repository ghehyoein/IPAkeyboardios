import UIKit

/// Native-style transient callout. The originating key owns the entire touch;
/// this view never presents a menu, intercepts a touch, or survives finger-up.
final class VariantStrip: UIView {
    private let body = UIView()
    private let scroll = UIScrollView()
    private let stem = CAShapeLayer()
    private var labels: [UILabel] = []
    private let edgeLeft = UILabel()
    private let edgeRight = UILabel()
    private(set) var values: [String] = []
    private(set) var selectedIndex: Int?
    private var sourceRect = CGRect.zero
    private var cellWidth: CGFloat = 38
    private var lastPoint: CGPoint?
    private var edgeDirection = 0
    private var edgeTimer: Timer?
    private var baseIndex = 0
    private let showsSelection: Bool
    var selectedText: String? { selectedIndex.map { values[$0] } }
    var calloutFrame: CGRect { body.frame }
    var visibleCandidateCount: Int { max(1, Int((body.bounds.width - 12) / cellWidth)) }

    init(keyFrame: CGRect, base: String, variants: [String], in bounds: CGRect, showsSelection: Bool = true) {
        self.showsSelection = showsSelection
        super.init(frame: bounds)
        isUserInteractionEnabled = false
        accessibilityIdentifier = "variantStrip"
        sourceRect = keyFrame
        cellWidth = showsSelection ? max(34, min(42, keyFrame.width + 2)) : max(44, keyFrame.width + 14)
        let visibleCount = min(variants.count + 1, max(1, Int((bounds.width - 16) / cellWidth)))
        let width = CGFloat(visibleCount) * cellWidth + 12
        let left = min(max(8, keyFrame.midX - width / 2), bounds.width - width - 8)
        let height: CGFloat = showsSelection ? 57 : 55
        // Prefer above-key placement. At the top edge, temporarily overlay the
        // first row rather than reserving space or drawing outside the extension.
        let top = max(4, keyFrame.minY - height - 7)
        body.frame = CGRect(x: left, y: top, width: width, height: height)
        baseIndex = min(visibleCount - 1, max(0, Int((keyFrame.midX - left - 6) / cellWidth)))
        values = variants
        values.insert(base, at: min(baseIndex, values.count))
        selectedIndex = baseIndex
        layer.addSublayer(stem)
        addSubview(body)
        body.layer.cornerRadius = 10
        body.layer.cornerCurve = .continuous
        body.layer.shadowColor = UIColor.black.cgColor
        body.layer.shadowOpacity = 0.23
        body.layer.shadowRadius = 6
        body.layer.shadowOffset = CGSize(width: 0, height: 2)
        scroll.frame = body.bounds.insetBy(dx: 6, dy: 5)
        scroll.clipsToBounds = true
        scroll.showsHorizontalScrollIndicator = false
        body.addSubview(scroll)
        for (i, value) in values.enumerated() {
            let label = UILabel(frame: CGRect(x: CGFloat(i) * cellWidth, y: 0, width: cellWidth, height: height - 10))
            let display = IPACatalog.shared.symbol(value)?.display ?? value
            label.text = PhoneticDisplay.title(for: display)
            label.numberOfLines = 2
            label.font = .systemFont(ofSize: PhoneticDisplay.isSupported(display) ? (showsSelection ? 27 : 34) : 10, weight: showsSelection ? .regular : .light)
            label.textAlignment = .center
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.55
            label.layer.cornerRadius = 6
            label.clipsToBounds = true
            label.isAccessibilityElement = true
            label.accessibilityLabel = IPACatalog.shared.symbol(value)?.name ?? value
            label.accessibilityIdentifier = "variant_" + value.unicodeScalars.map { String($0.value, radix: 16) }.joined(separator: "_")
            scroll.addSubview(label); labels.append(label)
        }
        scroll.contentSize = CGSize(width: CGFloat(values.count) * cellWidth, height: scroll.bounds.height)
        for (label, text) in [(edgeLeft, "‹"), (edgeRight, "›")] {
            label.text = text; label.font = .systemFont(ofSize: 13, weight: .semibold)
            label.textAlignment = .center; body.addSubview(label)
        }
        edgeLeft.frame = CGRect(x: 0, y: 18, width: 9, height: 18)
        edgeRight.frame = CGRect(x: width - 9, y: 18, width: 9, height: 18)
        let path = UIBezierPath()
        let stemX = min(max(keyFrame.midX, body.frame.minX + 12), body.frame.maxX - 12)
        let edgeY = body.frame.maxY - 8
        let keyY = max(edgeY, keyFrame.maxY - 7)
        let half = keyFrame.width / 2
        path.move(to: CGPoint(x: stemX - half - 5, y: edgeY))
        path.addCurve(to: CGPoint(x: keyFrame.minX, y: keyY - 5), controlPoint1: CGPoint(x: stemX - half - 5, y: edgeY + 12), controlPoint2: CGPoint(x: keyFrame.minX, y: keyY - 17))
        path.addQuadCurve(to: CGPoint(x: keyFrame.minX + 6, y: keyY), controlPoint: CGPoint(x: keyFrame.minX, y: keyY))
        path.addLine(to: CGPoint(x: keyFrame.maxX - 6, y: keyY))
        path.addQuadCurve(to: CGPoint(x: keyFrame.maxX, y: keyY - 5), controlPoint: CGPoint(x: keyFrame.maxX, y: keyY))
        path.addCurve(to: CGPoint(x: stemX + half + 5, y: edgeY), controlPoint1: CGPoint(x: keyFrame.maxX, y: keyY - 17), controlPoint2: CGPoint(x: stemX + half + 5, y: edgeY + 12))
        path.close(); stem.path = path.cgPath
        updateAppearance()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection); updateAppearance()
    }
    private func updateAppearance() {
        let dark = traitCollection.userInterfaceStyle == .dark
        body.backgroundColor = dark ? UIColor(white: 0.30, alpha: 1) : .white
        stem.fillColor = body.backgroundColor?.cgColor
        refreshSelection()
    }
    private func refreshSelection() {
        for (index, label) in labels.enumerated() {
            label.backgroundColor = showsSelection && index == selectedIndex ? .label : .clear
            label.textColor = showsSelection && index == selectedIndex ? .systemBackground : .label
        }
        edgeLeft.isHidden = scroll.contentOffset.x <= 0
        edgeRight.isHidden = scroll.contentOffset.x >= max(0, scroll.contentSize.width - scroll.bounds.width) - 1
    }
    func track(_ point: CGPoint) {
        lastPoint = point
        let corridor = body.frame.union(sourceRect).insetBy(dx: -18, dy: -18)
        guard corridor.contains(point) else {
            selectedIndex = nil; setEdge(0); refreshSelection(); return
        }
        let localX = point.x - body.frame.minX - 6 + scroll.contentOffset.x
        let previous = selectedIndex
        selectedIndex = min(values.count - 1, max(0, Int(floor(localX / cellWidth))))
        if selectedIndex != previous { KeyFeedback.shared.candidateChanged() }
        let maxOffset = max(0, scroll.contentSize.width - scroll.bounds.width)
        if values.count > visibleCandidateCount && point.x > body.frame.maxX - 20 && scroll.contentOffset.x < maxOffset {
            setEdge(1)
        } else if point.x < body.frame.minX + 20 && scroll.contentOffset.x > 0 {
            setEdge(-1)
        } else { setEdge(0) }
        refreshSelection()
    }
    /// Deterministic step shared by the timer and tests. Keeps item order intact.
    func advanceAtEdge(_ direction: Int) {
        let maximum = max(0, scroll.contentSize.width - scroll.bounds.width)
        scroll.contentOffset.x = min(maximum, max(0, scroll.contentOffset.x + CGFloat(direction) * cellWidth))
        if let point = lastPoint { track(point) }
        refreshSelection()
    }
    private func setEdge(_ direction: Int) {
        guard direction != edgeDirection else { return }
        edgeTimer?.invalidate(); edgeTimer = nil; edgeDirection = direction
        guard direction != 0 else { return }
        edgeTimer = Timer.scheduledTimer(withTimeInterval: 0.22, repeats: true) { [weak self] _ in self?.advanceAtEdge(direction) }
    }
    func finish() -> String? {
        setEdge(0)
        return selectedText
    }
    func cancel() { setEdge(0); selectedIndex = nil }
    deinit { edgeTimer?.invalidate() }
}
