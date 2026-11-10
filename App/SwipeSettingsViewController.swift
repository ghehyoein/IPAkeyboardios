import UIKit

final class SwipeSettingsViewController: UITableViewController {
    private let pages: [KeyboardPage] = [.letters, .numbers, .symbols]
    init() { super.init(style: .plain) }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() { super.viewDidLoad(); title = "四向滑动".localized; tableView.accessibilityIdentifier = "swipeSettings" }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); tableView.reloadData() }
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? { ["ABC", "123", "#+="] }
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int { index }
    override func numberOfSections(in tableView: UITableView) -> Int { pages.count }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { pages[section].rows.flatMap { $0 }.count }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { ["字母".localized, "数字与标点".localized, "符号".localized][section] }
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        section == 0 ? "只能选择该键长按菜单中的字符。关闭某个音标分类后，对应的自定义滑动暂不输入；重新开启即可恢复。".localized : nil
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let key = pages[indexPath.section].rows.flatMap { $0 }[indexPath.row]
        let map = SymbolSettingsStore.shared.loadSwipes().applying(to: SwipePreferences.source(for: key), key: key)
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.numberOfLines = 0; cell.detailTextLabel?.numberOfLines = 0
        cell.textLabel?.text = key
        cell.detailTextLabel?.text = zip(["↑", "↓", "←", "→"], SwipePreferences.directions).map { $0.0 + " " + (map.swipes[$0.1] ?? "—") }.joined(separator: "    ")
        cell.accessibilityIdentifier = "configureSwipe_" + key
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        navigationController?.pushViewController(SwipeKeyViewController(key: pages[indexPath.section].rows.flatMap { $0 }[indexPath.row]), animated: true)
    }
}

private final class SwipeKeyViewController: UITableViewController {
    private let key: String
    init(key: String) { self.key = key; super.init(style: .insetGrouped) }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() { super.viewDidLoad(); title = key + " · " + "滑动设置".localized }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); tableView.reloadData() }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 5 }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        if indexPath.row == 4 { cell.textLabel?.text = "恢复此键默认设置".localized; cell.accessibilityIdentifier = "resetSwipeKey"; return cell }
        let direction = SwipePreferences.directions[indexPath.row]
        cell.textLabel?.text = ["↑ 上滑".localized, "↓ 下滑".localized, "← 左滑".localized, "→ 右滑".localized][indexPath.row]
        let mapping = SymbolSettingsStore.shared.loadSwipes().applying(to: SwipePreferences.source(for: key), key: key)
        cell.detailTextLabel?.text = mapping.swipes[direction] ?? "无变体".localized
        cell.accessibilityIdentifier = "swipeDirection_" + direction
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 4 {
            var prefs = SymbolSettingsStore.shared.loadSwipes(); prefs.overrides.removeValue(forKey: key)
            SymbolSettingsStore.shared.saveSwipes(prefs); tableView.reloadData(); return
        }
        navigationController?.pushViewController(SwipeCandidateViewController(key: key, direction: SwipePreferences.directions[indexPath.row]), animated: true)
    }
}

private final class SwipeCandidateViewController: UITableViewController, UISearchResultsUpdating {
    private let key: String
    private let direction: String
    private var values: [String] = []
    private var filtered: [String] = []
    private let search = UISearchController(searchResultsController: nil)
    init(key: String, direction: String) { self.key = key; self.direction = direction; super.init(style: .insetGrouped) }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad(); title = "选择长按候选".localized
        values = [key] + SymbolSettingsStore.shared.load().filter(SwipePreferences.source(for: key)).variants
        filtered = values
        search.searchResultsUpdater = self; search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "搜索候选字符或注释".localized
        navigationItem.searchController = search; definesPresentationContext = true
    }
    func updateSearchResults(for searchController: UISearchController) {
        let q = searchController.searchBar.text ?? ""
        filtered = q.isEmpty ? values : values.filter { ($0 + " " + (IPACatalog.shared.symbol($0)?.name ?? "")).localizedCaseInsensitiveContains(q) }
        tableView.reloadData()
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { filtered.count }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let text = filtered[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.numberOfLines = 0; cell.detailTextLabel?.numberOfLines = 0
        cell.textLabel?.text = IPACatalog.shared.symbol(text)?.display ?? text
        cell.detailTextLabel?.text = IPACatalog.shared.symbol(text)?.name ?? "基础字符".localized
        cell.accessibilityIdentifier = "swipeCandidate_" + text
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var prefs = SymbolSettingsStore.shared.loadSwipes()
        prefs.overrides[key, default: [:]][direction] = filtered[indexPath.row]
        SymbolSettingsStore.shared.saveSwipes(prefs)
        navigationController?.popViewController(animated: true)
    }
}
