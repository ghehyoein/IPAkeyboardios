import UIKit

/// Inventory uses the same atomic catalog and auxiliary mappings as the keyboard.
/// Hidden optional families remain documented and are marked as disabled.
final class SymbolCatalogViewController: UITableViewController, UISearchResultsUpdating {
    private struct Entry {
        let text: String
        let display: String
        let note: String
    }
    private struct Group {
        let title: String
        let entries: [Entry]
    }
    private var selectedGroup: String?
    private var groups: [Group] = []
    private var filtered: [Group] = []
    private let search = UISearchController(searchResultsController: nil)

    init() { super.init(style: .plain) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "全部符号与注释".localized
        tableView.accessibilityIdentifier = "symbolCatalog"
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 90
        let catalog = IPACatalog.shared
        let visibility = SymbolSettingsStore.shared.load()
        groups = catalog.categories.compactMap { category in
            let entries = catalog.symbols.filter { $0.atomic && $0.category == category.id }.map { symbol in
                let state = visibility.contains(symbol) ? "" : "\n" + "已隐藏".localized
                return Entry(text: symbol.text, display: symbol.display, note: symbol.name + state)
            }
            return entries.isEmpty ? nil : Group(title: category.title, entries: entries)
        }
        // Include any category not listed in the tab catalog without dropping it.
        let included = Set(groups.flatMap { $0.entries.map { $0.text } })
        let rest = catalog.symbols.filter { $0.atomic && !included.contains($0.text) }.map {
            Entry(text: $0.text, display: $0.display, note: $0.name)
        }
        if !rest.isEmpty { groups.append(Group(title: "其他音标".localized, entries: rest)) }
        var seen = Set(catalog.symbols.filter { $0.atomic }.map { $0.text })
        var general: [Entry] = []
        let keys = KeyboardPage.letters.rows.flatMap { $0 } + KeyboardPage.numbers.rows.flatMap { $0 } + KeyboardPage.symbols.rows.flatMap { $0 } + [" ", "\n"]
        for key in keys {
            for text in [key] + AuxiliaryKeyMapping.mapping(for: key).variants where seen.insert(text).inserted {
                let display = text == " " ? "␠" : text == "\n" ? "↵" : text
                let name = text.unicodeScalars.map { $0.properties.name ?? "Unicode 字符".localized }.joined(separator: " + ")
                general.append(Entry(text: text, display: display, note: L10n.unicodeName(name)))
            }
        }
        groups.append(Group(title: "字母、数字、标点及变体".localized, entries: general))
        filtered = groups
        configureCategoryMenu()
        search.searchResultsUpdater = self
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "搜索符号、名称或 Unicode 编码".localized
        navigationItem.searchController = search
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }
    private func configureCategoryMenu() {
        let choices: [(String, String?)] = [("全部分类".localized, nil)] + groups.map { ($0.title, Optional($0.title)) }
        let actions = choices.map { title, group in
            UIAction(title: title, state: selectedGroup == group ? .on : .off) { [weak self] _ in
                guard let self = self else { return }
                self.selectedGroup = group
                self.configureCategoryMenu()
                self.updateSearchResults(for: self.search)
                self.tableView.setContentOffset(CGPoint(x: 0, y: -self.tableView.adjustedContentInset.top), animated: false)
            }
        }
        let item = UIBarButtonItem(title: selectedGroup ?? "分类".localized, menu: UIMenu(title: "选择符号分区".localized, children: actions))
        item.accessibilityIdentifier = "chooseCatalogCategory"
        navigationItem.rightBarButtonItem = item
    }
    private func codes(_ text: String) -> String {
        text.unicodeScalars.map { String(format: "U+%04X", $0.value) }.joined(separator: " ")
    }
    func updateSearchResults(for searchController: UISearchController) {
        let query = (searchController.searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let scope = groups.filter { selectedGroup == nil || $0.title == selectedGroup }
        filtered = query.isEmpty ? scope : scope.compactMap { group in
            let entries = group.entries.filter { ($0.text + " " + $0.display + " " + $0.note + " " + (IPACatalog.shared.symbol($0.text)?.rawName ?? "") + " " + codes($0.text)).localizedCaseInsensitiveContains(query) }
            return entries.isEmpty ? nil : Group(title: group.title, entries: entries)
        }
        tableView.reloadData()
    }
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        guard !filtered.isEmpty else { return nil }
        let abbreviations = ["肺部气流辅音".localized: "肺辅".localized, "非肺部气流辅音".localized: "非肺".localized, "旧版与非标准 IPA".localized: "旧IPA".localized, "Unicode 语音补充".localized: "UNI", "字母、数字、标点及变体".localized: "ABC", "extIPA": "ext"]
        return filtered.map { abbreviations[$0.title] ?? String($0.title.prefix(2)) }
    }
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int { index }
    override func numberOfSections(in tableView: UITableView) -> Int { filtered.count }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { filtered[section].entries.count }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { "\(filtered[section].title)（\(filtered[section].entries.count)）" }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let entry = filtered[indexPath.section].entries[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "entry") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "entry")
        cell.textLabel?.text = entry.display + "    " + codes(entry.text)
        cell.textLabel?.font = .systemFont(ofSize: 23)
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.text = entry.note
        cell.detailTextLabel?.numberOfLines = 0
        cell.selectionStyle = .none
        return cell
    }
}
