import UIKit

/// Continuous columns, with no page padding or viewport-sized snapping.
private final class SymbolColumnsLayout: UICollectionViewLayout {
    var counts: [Int] = [] { didSet { cachedSize = CGSize(width: -1, height: -1); invalidateLayout() } }
    private var cachedSize = CGSize.zero
    private var cachedHeight: CGFloat = 0
    private var cachedStarts: [CGFloat] = []
    var keyHeight: CGFloat = 36
    var rows: Int { max(1, min(5, Int(((collectionView?.bounds.height ?? 150) + 6) / (keyHeight + 6)))) }
    var keyWidth: CGFloat {
        let width = collectionView?.bounds.width ?? 428
        let columns = CGFloat(KeyboardMetrics.symbolColumns(for: width))
        return (width - 17 - (columns - 1) * 6) / columns
    }
    var stride: CGFloat { keyWidth + 6 }
    var starts: [CGFloat] {
        let size = collectionView?.bounds.size ?? .zero
        if cachedSize != size || cachedHeight != keyHeight || cachedStarts.count != counts.count {
            let rowCount = rows
            let pitch = stride
            var x: CGFloat = 0
            cachedStarts = counts.map { count in
                defer { x += CGFloat(max(2, (count + rowCount - 1) / rowCount)) * pitch + 12 }
                return x
            }
            cachedSize = size; cachedHeight = keyHeight
        }
        return cachedStarts
    }
    override var collectionViewContentSize: CGSize {
        let width = collectionView?.bounds.width ?? 0
        let last = counts.last ?? 0
        return CGSize(width: (starts.last ?? 0) + max(width, CGFloat(max(2, (last + rows - 1) / rows)) * stride + 17), height: collectionView?.bounds.height ?? 0)
    }
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool { newBounds.size != collectionView?.bounds.size }
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let item = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        item.frame = CGRect(x: starts[indexPath.section] + 8.5 + CGFloat(indexPath.item / rows) * stride,
                            y: CGFloat(indexPath.item % rows) * (keyHeight + 6), width: keyWidth, height: keyHeight)
        return item
    }
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var result: [UICollectionViewLayoutAttributes] = []
        let positions = starts
        for (section, count) in counts.enumerated() {
            let start = positions[section]
            let end = start + CGFloat(max(2, (count + rows - 1) / rows)) * stride + 12
            guard end >= rect.minX && start <= rect.maxX else { continue }
            let firstColumn = max(0, Int(floor((rect.minX - start - 8.5) / stride)))
            let lastColumn = max(firstColumn, Int(ceil((rect.maxX - start) / stride)))
            let lower = min(count, firstColumn * rows)
            let upper = min(count, (lastColumn + 1) * rows)
            for item in lower..<upper {
                if let a = layoutAttributesForItem(at: IndexPath(item: item, section: section)), a.frame.intersects(rect) { result.append(a) }
            }
        }
        return result
    }
}

private final class SymbolCell: UICollectionViewCell {
    let glyph = UILabel()
    var preferredFontSize: CGFloat = 22 { didSet { setNeedsLayout() } }
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = KeyboardMaterial.key
        contentView.layer.cornerRadius = 10; contentView.layer.cornerCurve = .continuous
        glyph.textAlignment = .center; glyph.adjustsFontSizeToFitWidth = true
        glyph.minimumScaleFactor = 0.4; glyph.numberOfLines = 2
        contentView.addSubview(glyph)
        isAccessibilityElement = true; accessibilityTraits = .button
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() {
        super.layoutSubviews(); glyph.frame = bounds.insetBy(dx: 2, dy: 2)
        glyph.font = .systemFont(ofSize: max(8, min(preferredFontSize, bounds.height - 6)))
    }
}

/// Cancel a category button's highlight as soon as the user starts a horizontal drag.
final class SymbolCategoryScrollView: UIScrollView {
    var selectionButtons: [UIButton] = []
    var onScrubSelection: ((Int) -> Void)?
    private var selectedIndex: Int?
    var compactTitles: [String] = []
    private var originalButtons: [(frame: CGRect, title: String?)] = []
    private var compactWidth: CGFloat = 0
    static func categoryIndex(at x: CGFloat, width: CGFloat, count: Int) -> Int? {
        guard width > 0, count > 0, x.isFinite else { return nil }
        return min(count - 1, Int(max(0, min(1, x / width)) * CGFloat(count)))
    }
    private lazy var hold = UILongPressGestureRecognizer(target: self, action: #selector(scrub(_:)))
    override init(frame: CGRect) {
        super.init(frame: frame)
        delaysContentTouches = false
        canCancelContentTouches = true
        isDirectionalLockEnabled = true
        alwaysBounceHorizontal = true
        decelerationRate = .normal
        contentInsetAdjustmentBehavior = .never
        hold.minimumPressDuration = 0.3
        hold.cancelsTouchesInView = true
        addGestureRecognizer(hold)
        panGestureRecognizer.require(toFail: hold)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func touchesShouldCancel(in view: UIView) -> Bool {
        view is UIControl || super.touchesShouldCancel(in: view)
    }
    @objc private func scrub(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            guard !selectionButtons.isEmpty, bounds.width > 0 else { return }
            setContentOffset(contentOffset, animated: false)
            originalButtons = selectionButtons.map { ($0.frame, $0.title(for: .normal)) }
            compactWidth = bounds.width
            let width = compactWidth / CGFloat(selectionButtons.count)
            for (index, button) in selectionButtons.enumerated() {
                button.accessibilityLabel = originalButtons[index].title
                button.frame = CGRect(x: bounds.minX + CGFloat(index) * width, y: 0,
                                      width: width, height: bounds.height)
                button.setTitle(compactTitles.indices.contains(index) ? compactTitles[index] : originalButtons[index].title, for: .normal)
                button.titleLabel?.font = .systemFont(ofSize: 10, weight: .medium)
                button.titleLabel?.adjustsFontSizeToFitWidth = true
                button.titleLabel?.minimumScaleFactor = 0.5
                button.layer.cornerRadius = min(8, width / 2)
            }
            chooseUnderFinger(gesture.location(in: self))
        case .changed:
            chooseUnderFinger(gesture.location(in: self))
        case .ended:
            chooseUnderFinger(gesture.location(in: self))
            stopScrubbing()
        default: stopScrubbing()
        }
    }
    private func chooseUnderFinger(_ finger: CGPoint) {
        guard !originalButtons.isEmpty, finger.y >= -20, finger.y <= bounds.height + 20,
              let index = Self.categoryIndex(at: finger.x - bounds.minX, width: compactWidth, count: selectionButtons.count),
              index != selectedIndex else { return }
        selectedIndex = index
        KeyFeedback.shared.candidateChanged()
        onScrubSelection?(index)
    }
    private func stopScrubbing() {
        for (button, original) in zip(selectionButtons, originalButtons) {
            button.frame = original.frame
            button.setTitle(original.title, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 12)
            button.titleLabel?.adjustsFontSizeToFitWidth = false
            button.layer.cornerRadius = 12
        }
        originalButtons.removeAll(); selectedIndex = nil
    }
    override func layoutSubviews() {
        if !originalButtons.isEmpty && bounds.width != compactWidth { stopScrubbing() }
        super.layoutSubviews()
    }
    override func willMove(toWindow newWindow: UIWindow?) {
        if newWindow == nil { stopScrubbing() }
        super.willMove(toWindow: newWindow)
    }
}

final class SymbolGrid: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDataSourcePrefetching {
    let sections: [SymbolSection]
    private let columns: SymbolColumnsLayout
    var keyHeight: CGFloat = 36 { didSet { if oldValue != keyHeight { columns.keyHeight = keyHeight; columns.invalidateLayout() } } }
    private var explanation: UILabel?
    var onInsert: ((String) -> Void)?
    var onSectionChange: ((String, String) -> Void)? { didSet { reportedSection = nil } }
    private var reportedSection: Int?

    private final class Presentation: NSObject {
        let title: String
        let fontSize: CGFloat
        let label: String
        let identifier: String
        let explanation: String
        init(title: String, fontSize: CGFloat, label: String, identifier: String, explanation: String) {
            self.title = title; self.fontSize = fontSize; self.label = label
            self.identifier = identifier; self.explanation = explanation
        }
    }
    // Local to the panel: rebuilding it after a language change also clears translations.
    private let presentations = NSCache<NSString, Presentation>()
    private func presentation(for text: String) -> Presentation {
        if let value = presentations.object(forKey: text as NSString) { return value }
        let symbol = IPACatalog.shared.symbol(text)
        let display = symbol?.display ?? text
        let name = symbol?.name ?? text
        let value = Presentation(title: PhoneticDisplay.title(for: display),
            fontSize: PhoneticDisplay.isSupported(display) ? 22 : 10,
            label: "\(display)，\(name)", identifier: "symbol_" + (symbol?.id ?? text),
            explanation: display + " · " + name)
        presentations.setObject(value, forKey: text as NSString)
        return value
    }
    init(frame: CGRect, sections: [SymbolSection]) {
        self.sections = sections
        let layout = SymbolColumnsLayout()
        layout.counts = sections.map { $0.values.count }
        self.columns = layout
        super.init(frame: frame, collectionViewLayout: layout)
        presentations.countLimit = 384
        backgroundColor = .clear; isPagingEnabled = false
        decelerationRate = .normal
        delaysContentTouches = false
        canCancelContentTouches = true
        isDirectionalLockEnabled = true
        contentInsetAdjustmentBehavior = .never
        prefetchDataSource = self
        showsHorizontalScrollIndicator = false; alwaysBounceHorizontal = true
        register(SymbolCell.self, forCellWithReuseIdentifier: "symbol")
        dataSource = self; delegate = self; accessibilityIdentifier = "symbolGrid"
        let hold = UILongPressGestureRecognizer(target: self, action: #selector(showExplanation(_:)))
        hold.minimumPressDuration = 0.5; hold.cancelsTouchesInView = true; addGestureRecognizer(hold)
    }
    required init?(coder: NSCoder) { fatalError() }
    func selectSection(_ id: String, animated: Bool = false) {
        guard let section = sections.firstIndex(where: { $0.id == id }) else { return }
        setContentOffset(CGPoint(x: columns.starts[section], y: 0), animated: animated && !UIAccessibility.isReduceMotionEnabled)
        scrollViewDidScroll(self)
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard bounds.width > 0, !sections.isEmpty else { return }
        let offset = max(0, contentOffset.x + 0.5)
        let section = columns.starts.lastIndex(where: { $0 <= offset }) ?? 0
        guard reportedSection != section else { return }
        reportedSection = section
        let value = sections[section]
        onSectionChange?(value.id, value.title + (value.values.isEmpty ? " · 暂无最近使用".localized : ""))
    }
    func numberOfSections(in collectionView: UICollectionView) -> Int { sections.count }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { sections[section].values.count }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = dequeueReusableCell(withReuseIdentifier: "symbol", for: indexPath) as! SymbolCell
        let text = sections[indexPath.section].values[indexPath.item]
        let value = presentation(for: text)
        cell.glyph.text = value.title
        cell.preferredFontSize = value.fontSize
        cell.accessibilityLabel = value.label
        cell.accessibilityHint = "轻点输入，长按查看注释".localized
        cell.accessibilityIdentifier = value.identifier
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for index in indexPaths { _ = presentation(for: sections[index.section].values[index.item]) }
    }
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        explanation?.removeFromSuperview(); explanation = nil
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let value = sections[indexPath.section].values[indexPath.item]
        KeyFeedback.shared.keyDown(); RecentSymbols.shared.record(value); onInsert?(value)
    }
    @objc private func showExplanation(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began || gesture.state == .changed else { explanation?.removeFromSuperview(); explanation = nil; return }
        guard let index = indexPathForItem(at: gesture.location(in: self)) else { return }
        let text = sections[index.section].values[index.item]
        let label = explanation ?? UILabel()
        label.text = presentation(for: text).explanation
        label.font = .systemFont(ofSize: 13); label.numberOfLines = 3; label.textAlignment = .center
        label.backgroundColor = .secondarySystemBackground; label.textColor = .label
        label.layer.cornerRadius = 9; label.clipsToBounds = true
        label.accessibilityIdentifier = "symbolExplanation"; label.isUserInteractionEnabled = false
        label.frame = CGRect(x: 8, y: max(0, frame.minY), width: bounds.width - 16, height: 54)
        superview?.addSubview(label); explanation = label
        if gesture.state == .began { KeyFeedback.shared.candidateChanged() }
    }
    override func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview == nil { explanation?.removeFromSuperview(); explanation = nil }
        super.willMove(toSuperview: newSuperview)
    }
}
