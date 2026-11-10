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
        tableView.accessibilityIdentifier = "symbolSettings"
    }
    override func numberOfSections(in tableView: UITableView) -> Int { 8 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { (section == 1 || section == 6) ? 3 : (section == 2 ? 2 : 1) }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        ["始终显示".localized, "按需显示".localized, "输入反馈".localized, "系统键盘同步".localized, "符号参考".localized, "滑动自定义".localized, "符号面板内容".localized, "语言".localized][section]
    }
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 7: return "界面与符号注释".localized
        case 6: return "只影响符号面板，不改变主键盘的长按或滑动候选。主键盘包含字母、数字、标点及其长按变体。附加符号优先显示，同一符号仅保留一个分类；最近使用遵循这些开关。".localized
        case 0: return "现版 IPA 的独立字母、附加符号始终可用。组合形式仍需依次输入。".localized
        case 1: return "开关影响长按、四向滑动及符号面板。重复归类的符号，只要仍有一个所属分类开启就会显示；现版 IPA 不受影响。通用数字、标点及其他 Unicode 补充保留。".localized
        case 2: return "点击声使用系统输入点击接口，受静音及系统声音设置约束。触感使用轻触震动，也会在滑选候选时反馈；此开关独立于苹果键盘的触感设置。".localized
        case 5: return "逐键设置上、下、左、右滑动的输入字符；候选限于此键的长按菜单。与符号显示开关一样，需要共享容器才能同步到系统键盘。".localized
        case 4: return "按分类查看符号、名称与 Unicode 编码，支持搜索。".localized
        default: return shareAvailable ? "切回系统键盘即可读取开关，无需完全访问。若要播放扩展中的按键声音，请在系统键盘设置中开启「允许完全访问」。仅共享偏好；不联网、不记录正文。最近选用的符号仅保存在键盘本地。".localized : "当前签名没有可用的共享容器，偏好已保存在 App 中，但系统键盘暂时无法读取。重新签名时需为 App 和键盘扩展配置同一个 App Group；详见仓库签名说明。".localized
        }
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.selectionStyle = .none
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.numberOfLines = 0
        if indexPath.section == 7 {
            cell.textLabel?.text = "语言".localized
            cell.detailTextLabel?.text = L10n.languageName(visibility.language)
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
            cell.accessibilityIdentifier = "languageSetting"
        } else if indexPath.section == 6 {
            let titles = ["主键盘无法输入的符号".localized, "主键盘可输入的附加符号".localized, "主键盘可输入的普通符号".localized]
            let notes = ["独立附加符号及其他未映射字符".localized, "上标、下标、叠加符号，例如 ʰ".localized, "普通字母、音标和标点".localized]
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
            cell.detailTextLabel?.text = "始终显示，不可关闭".localized
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
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        } else if indexPath.section == 4 {
            cell.textLabel?.text = "全部符号与注释".localized
            cell.detailTextLabel?.text = "按分类浏览 · Unicode 编码 · 注释".localized
            cell.accessibilityIdentifier = "openSymbolCatalog"
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        } else {
            cell.textLabel?.text = shareAvailable ? "共享设置已就绪".localized : "仅在 App 内生效".localized
            cell.detailTextLabel?.text = shareAvailable ? "切回键盘后读取最新开关".localized : "签名需支持 App Groups".localized
        }
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
            actions.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
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
        tableView.reloadSections(IndexSet(integer: 3), with: .none)
    }
    @objc private func changed(_ sender: UISwitch) {
        switch sender.tag {
        case 0: visibility.chinese = sender.isOn
        case 1: visibility.historical = sender.isOn
        default: visibility.extipa = sender.isOn
        }
        shareAvailable = SymbolSettingsStore.shared.save(visibility)
        tableView.reloadSections(IndexSet(integer: 3), with: .none)
    }
    @objc private func feedbackChanged(_ sender: UISwitch) {
        if sender.tag == 10 { feedback.clicks = sender.isOn }
        else { feedback.haptics = sender.isOn }
        shareAvailable = SymbolSettingsStore.shared.saveFeedback(feedback)
        tableView.reloadSections(IndexSet(integer: 3), with: .none)
    }

}
