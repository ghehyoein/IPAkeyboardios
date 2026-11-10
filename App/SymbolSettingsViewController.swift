import UIKit

final class SymbolSettingsViewController: UITableViewController {
    private var feedback = SymbolSettingsStore.shared.loadFeedback()
    private var visibility = SymbolSettingsStore.shared.load()
    private var shareAvailable = SymbolSettingsStore.shared.canShare
    private let families = ["chinese", "historical", "extipa"]
    private var titles: [String] { ["中国通用音标".localized, "旧版 IPA".localized, "extIPA"] }
    private var examples: [String] { ["ɿ ʅ ʮ ʯ · ᴀ ᴇ", "历史与非标准形式".localized, "言语障碍等扩展音标".localized] }

    init() { super.init(style: .insetGrouped) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "符号显示".localized
        navigationItem.largeTitleDisplayMode = .never
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 64
        tableView.sectionHeaderTopPadding = 12
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.accessibilityIdentifier = "symbolSettings"
    }
    // Keep related choices together; technical signing details do not belong on the home screen.
    private func settingsPath(_ path: IndexPath) -> IndexPath {
        switch path.section {
        case 0: return IndexPath(row: max(0, path.row - 1), section: path.row == 0 ? 0 : 1)
        case 1: return IndexPath(row: 0, section: [4, 5, 7][path.row])
        case 2: return IndexPath(row: path.row, section: 6)
        case 3: return IndexPath(row: path.row, section: 2)
        default: return IndexPath(row: 0, section: 3)
        }
    }
    override func numberOfSections(in tableView: UITableView) -> Int { shareAvailable ? 4 : 5 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { [4, 3, 3, 2, 1][section] }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        ["符号".localized, "偏好与参考".localized, "符号面板内容".localized, "输入反馈".localized, "设置同步".localized][section]
    }
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 2: return "仅控制附加符号页面。".localized
        case 3: return "按键声音需在系统设置中允许完全访问。".localized
        default: return nil
        }
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let indexPath = settingsPath(indexPath)
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.font = .preferredFont(forTextStyle: .body)
        cell.detailTextLabel?.font = .preferredFont(forTextStyle: .footnote)
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        cell.detailTextLabel?.adjustsFontForContentSizeCategory = true
        cell.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 14, leading: 18, bottom: 14, trailing: 18)
        cell.selectionStyle = .none
        cell.imageView?.tintColor = .secondaryLabel
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.numberOfLines = 0
        if indexPath.section == 7 {
            cell.textLabel?.text = "语言".localized
            cell.detailTextLabel?.text = L10n.languageName(visibility.language)
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
            cell.accessibilityIdentifier = "languageSetting"
            cell.imageView?.image = UIImage(systemName: "globe")
        } else if indexPath.section == 6 {
            let titles = ["面板专用符号".localized, "主键盘附加符号".localized, "主键盘普通符号".localized]
            let notes = ["主键盘长按菜单中没有的符号".localized, "上标、下标与组合符号".localized, "字母、音标与标点".localized]
            cell.textLabel?.text = titles[indexPath.row]
            cell.detailTextLabel?.text = notes[indexPath.row]
            let toggle = UISwitch()
            toggle.tag = indexPath.row
            toggle.isOn = [visibility.panelUnavailable, visibility.panelModifiers, visibility.panelOrdinary][indexPath.row]
            toggle.accessibilityIdentifier = "panelVisibility_\(indexPath.row)"
            toggle.accessibilityLabel = titles[indexPath.row]
            toggle.addTarget(self, action: #selector(panelChanged(_:)), for: .valueChanged)
            cell.accessoryView = toggle
        } else if indexPath.section == 0 {
            cell.textLabel?.text = "现版 IPA".localized
            cell.detailTextLabel?.text = "始终显示".localized
            cell.accessoryType = .checkmark
            cell.accessibilityIdentifier = "currentIPAAlwaysVisible"
        } else if indexPath.section == 1 {
            let i = indexPath.row
            cell.textLabel?.text = titles[i]; cell.detailTextLabel?.text = examples[i]
            let toggle = UISwitch()
            toggle.isOn = visibility.enabled(families[i]); toggle.tag = i
            toggle.accessibilityIdentifier = "visibility_" + families[i]
            toggle.accessibilityLabel = titles[i]
            toggle.addTarget(self, action: #selector(changed(_:)), for: .valueChanged)
            cell.accessoryView = toggle
        } else if indexPath.section == 2 {
            let sound = indexPath.row == 0
            cell.textLabel?.text = sound ? "按键声音".localized : "按键触感".localized
            let toggle = UISwitch()
            toggle.isOn = sound ? feedback.clicks : feedback.haptics
            toggle.tag = sound ? 10 : 11
            toggle.accessibilityIdentifier = sound ? "feedback_clicks" : "feedback_haptics"
            toggle.accessibilityLabel = sound ? "按键声音".localized : "按键触感".localized
            toggle.addTarget(self, action: #selector(feedbackChanged(_:)), for: .valueChanged)
            cell.accessoryView = toggle
        } else if indexPath.section == 5 {
            cell.textLabel?.text = "四向滑动设置".localized
            cell.accessibilityIdentifier = "openSwipeSettings"
            cell.imageView?.image = UIImage(systemName: "hand.draw")
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        } else if indexPath.section == 4 {
            cell.textLabel?.text = "全部符号与注释".localized

            cell.accessibilityIdentifier = "openSymbolCatalog"
            cell.imageView?.image = UIImage(systemName: "book.closed")
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        } else {
            cell.textLabel?.text = shareAvailable ? "共享设置已就绪".localized : "仅在 App 内生效".localized
            cell.detailTextLabel?.text = shareAvailable ? "切回键盘后读取最新开关".localized : "键盘暂时无法读取 App 设置".localized
        }
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sourceCell = tableView.cellForRow(at: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
        let indexPath = settingsPath(indexPath)
        if indexPath.section == 7 {
            let actions = UIAlertController(title: "语言".localized, message: nil, preferredStyle: .actionSheet)
            for code in L10n.languages {
                actions.addAction(UIAlertAction(title: L10n.languageName(code), style: .default) { [weak self] _ in
                    guard let self = self else { return }
                    self.visibility.language = code
                    self.shareAvailable = SymbolSettingsStore.shared.save(self.visibility)
                    L10n.selection = code
                    self.title = "符号显示".localized
                    self.tableView.reloadData()
                })
            }
            actions.addAction(UIAlertAction(title: "取消".localized, style: .cancel))
            actions.popoverPresentationController?.sourceView = sourceCell
            present(actions, animated: true); return
        }
        if indexPath.section == 5 {
            navigationController?.pushViewController(SwipeSettingsViewController(), animated: true); return
        }
        guard indexPath.section == 4 else { return }
        navigationController?.pushViewController(SymbolCatalogViewController(), animated: true)
    }
    @objc private func panelChanged(_ sender: UISwitch) {
        switch sender.tag {
        case 0: visibility.panelUnavailable = sender.isOn
        case 1: visibility.panelModifiers = sender.isOn
        default: visibility.panelOrdinary = sender.isOn
        }
        shareAvailable = SymbolSettingsStore.shared.save(visibility)
        tableView.reloadData()
    }
    @objc private func changed(_ sender: UISwitch) {
        switch sender.tag {
        case 0: visibility.chinese = sender.isOn
        case 1: visibility.historical = sender.isOn
        default: visibility.extipa = sender.isOn
        }
        shareAvailable = SymbolSettingsStore.shared.save(visibility)
        tableView.reloadData()
    }
    @objc private func feedbackChanged(_ sender: UISwitch) {
        if sender.tag == 10 { feedback.clicks = sender.isOn }
        else { feedback.haptics = sender.isOn }
        shareAvailable = SymbolSettingsStore.shared.saveFeedback(feedback)
        tableView.reloadData()
    }

}
