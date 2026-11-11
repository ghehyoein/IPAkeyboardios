import UIKit
import CoreText

/// Use the system's fallback fonts. If even fallback fonts lack a new Unicode
/// character, show its code point instead of an indistinguishable tofu box.
enum PhoneticDisplay {
    private static var cache: [String: Bool] = [:]
    static func isSupported(_ text: String) -> Bool {
        if let cached = cache[text] { return cached }
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: 26)]))
        let runs = CTLineGetGlyphRuns(line) as! [CTRun]
        let supported = runs.allSatisfy { run in
            // Apple's LastResort font has nonzero glyph IDs but draws boxed
            // placeholders. Treat it as missing coverage too.
            let attributes = CTRunGetAttributes(run) as NSDictionary
            if let font = attributes[kCTFontAttributeName] {
                let name = CTFontCopyPostScriptName(font as! CTFont) as String
                if name.lowercased().contains("lastresort") { return false }
            }
            var glyphs = [CGGlyph](repeating: 0, count: CTRunGetGlyphCount(run))
            CTRunGetGlyphs(run, CFRange(location: 0, length: 0), &glyphs)
            return !glyphs.contains(0)
        }
        cache[text] = supported
        return supported
    }
    static func title(for text: String) -> String {
        if isSupported(text) { return text }
        return text.unicodeScalars.filter { $0.value != 0x25CC }.map { "U+" + String($0.value, radix: 16).uppercased() }.joined(separator: "\n")
    }
}

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

/// Continuous columns, with no page padding or viewport-sized snapping.
private final class SymbolColumnsLayout: UICollectionViewLayout {
    var counts: [Int] = [] { didSet { cachedSize = CGSize(width: -1, height: -1); invalidateLayout() } }
    private var cachedSize = CGSize.zero
    private var cachedHeight: CGFloat = 0
    private var cachedStarts: [CGFloat] = []
    var keyHeight: CGFloat = 36
    var rows: Int { max(1, min(5, Int(((collectionView?.bounds.height ?? 150) + 6) / (keyHeight + 6)))) }
    var keyWidth: CGFloat { ((collectionView?.bounds.width ?? 428) - 17 - 9 * 6) / 10 }
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
    override func layoutSubviews() { super.layoutSubviews(); glyph.frame = bounds.insetBy(dx: 2, dy: 2) }
}

/// Cancel a category button's highlight as soon as the user starts a horizontal drag.
final class SymbolCategoryScrollView: UIScrollView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        delaysContentTouches = false
        canCancelContentTouches = true
        isDirectionalLockEnabled = true
        alwaysBounceHorizontal = true
        decelerationRate = .normal
        contentInsetAdjustmentBehavior = .never
    }
    required init?(coder: NSCoder) { fatalError() }
    override func touchesShouldCancel(in view: UIView) -> Bool {
        view is UIControl || super.touchesShouldCancel(in: view)
    }
}

final class SymbolGrid: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDataSourcePrefetching {
    let sections: [SymbolSection]
    private let columns: SymbolColumnsLayout
    var keyHeight: CGFloat = 36 { didSet { columns.keyHeight = keyHeight; columns.invalidateLayout() } }
    private let edgeFade = CAGradientLayer()
    private var explanation: UILabel?
    var onInsert: ((String) -> Void)?
    var onSectionChange: ((String, String) -> Void)? { didSet { reportedSection = nil } }
    private var reportedSection: Int?
    private static let symbolsByText = Dictionary(IPACatalog.shared.symbols.map { ($0.text, $0) }, uniquingKeysWith: { first, _ in first })
    private struct Presentation {
        let title: String
        let fontSize: CGFloat
        let label: String
        let identifier: String
        let explanation: String
    }
    // Local to the panel: rebuilding it after a language change also clears translations.
    private var presentations: [String: Presentation] = [:]
    private func presentation(for text: String) -> Presentation {
        if let value = presentations[text] { return value }
        let symbol = Self.symbolsByText[text]
        let display = symbol?.display ?? text
        let name = symbol?.name ?? text
        let value = Presentation(title: PhoneticDisplay.title(for: display),
            fontSize: PhoneticDisplay.isSupported(display) ? 22 : 10,
            label: "\(display)，\(name)", identifier: "symbol_" + (symbol?.id ?? text),
            explanation: display + " · " + name)
        presentations[text] = value
        return value
    }
    init(frame: CGRect, sections: [SymbolSection]) {
        self.sections = sections
        let layout = SymbolColumnsLayout()
        layout.counts = sections.map { $0.values.count }
        self.columns = layout
        super.init(frame: frame, collectionViewLayout: layout)
        backgroundColor = .clear; isPagingEnabled = false
        decelerationRate = .normal
        delaysContentTouches = false
        canCancelContentTouches = true
        isDirectionalLockEnabled = true
        contentInsetAdjustmentBehavior = .never
        prefetchDataSource = self
        edgeFade.colors = [UIColor.clear.cgColor, UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor]
        edgeFade.locations = [0, 0.025, 0.975, 1]
        edgeFade.startPoint = CGPoint(x: 0, y: 0.5); edgeFade.endPoint = CGPoint(x: 1, y: 0.5)
        layer.mask = edgeFade
        showsHorizontalScrollIndicator = false; alwaysBounceHorizontal = true
        register(SymbolCell.self, forCellWithReuseIdentifier: "symbol")
        dataSource = self; delegate = self; accessibilityIdentifier = "symbolGrid"
        let hold = UILongPressGestureRecognizer(target: self, action: #selector(showExplanation(_:)))
        hold.minimumPressDuration = 0.5; hold.cancelsTouchesInView = true; addGestureRecognizer(hold)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin(); CATransaction.setDisableActions(true)
        edgeFade.frame = bounds
        CATransaction.commit()
    }
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
        cell.glyph.font = .systemFont(ofSize: value.fontSize)
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
