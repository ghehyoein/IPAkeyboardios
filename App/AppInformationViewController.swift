import UIKit

enum AppLinks {
    static let fontRelease = URL(string: "https://github.com/ghehyoein/IPAplus-keyboard-ios/releases/tag/font-v0.600")!
    static let email = "contact@ghehyoein.com"
    static let qqGroup = "1127851625"
    static let author = URL(string: "https://ghehyoein.com/")!
    static let ipa = URL(string: "https://www.internationalphoneticassociation.org/")!
    static let ziTools = URL(string: "https://zi.tools/")!
    static let phoneticToolbox = URL(string: "https://www.phonetictoolbox.com/")!
}

enum AppInformationPage: String {
    case font, about, contact, links, editorHelp
    static let settingsPages: [AppInformationPage] = [.about, .contact, .links]
    var title: String {
        switch self {
        case .font: return "ipa+ 字体介绍".localized
        case .about: return "关于".localized
        case .contact: return "联系方式".localized
        case .links: return "友情链接".localized
        case .editorHelp: return "说明".localized
        }
    }
    var icon: String {
        switch self {
        case .font, .about, .editorHelp: return "info.circle"
        case .contact: return "envelope"
        case .links: return "link"
        }
    }
}

final class AppInformationViewController: UITableViewController {
    private struct Entry {
        let id: String
        let title: String
        var detail: String? = nil
        var icon: String? = nil
        var url: URL? = nil
        var copyValue: String? = nil
    }
    private let page: AppInformationPage
    private var entries: [Entry] {
        switch page {
        case .font:
            return [
                Entry(id: "fontIntroduction", title: "ipa+ 为音标转写整合了多种开放许可字体，并补充了新绘与改作字形，以 SIL OFL 1.1 许可证发布。".localized),
                Entry(id: "fontDisplayNotice", title: "文字复制到其他软件或发送给别人后，显示效果取决于对方使用的字体；部分符号可能缺失或错位。".localized)
            ]
        case .about:
            return [Entry(id: "aboutIntroduction", title: "ipa+ keyboard 是一款适用于 iPhone 和 iPad 的音标输入法。轻点输入字母，四向滑动或长按选择音标变体，也可在符号面板输入附加符号。支持符号检索和输入自定义，让学习、研究与日常转写更便捷。".localized)]
        case .editorHelp:
            return [
                Entry(id: "editorFontExplanation", title: "此输入框使用内置 ipa+ 字体，可显示本应用支持的全部音标符号。若符号在其他地方显示异常，可粘贴到这里查看。".localized),
                Entry(id: "editorSystemFontExplanation", title: "iOS 可以安装字体，但不能让所有应用统一使用它。这里的字体显示效果也不会随文字一起发送。".localized)
            ]
        case .contact:
            return [
                Entry(id: "contact_email", title: "电子邮箱".localized, detail: AppLinks.email, icon: "envelope", url: URL(string: "mailto:" + AppLinks.email), copyValue: AppLinks.email),
                Entry(id: "contact_qq", title: "QQ 反馈群".localized, detail: AppLinks.qqGroup, icon: "bubble.left.and.bubble.right", copyValue: AppLinks.qqGroup),
                Entry(id: "contact_author", title: "作者主页".localized, detail: AppLinks.author.absoluteString, icon: "person.crop.circle", url: AppLinks.author, copyValue: AppLinks.author.absoluteString)
            ]
        case .links:
            return [
                Entry(id: "link_ipa", title: "国际语音学协会（IPA）".localized, detail: AppLinks.ipa.host, icon: "globe", url: AppLinks.ipa),
                Entry(id: "link_ziTools", title: "字统网".localized, detail: AppLinks.ziTools.host, icon: "character.book.closed", url: AppLinks.ziTools),
                Entry(id: "link_phoneticToolbox", title: "Phonetic Toolbox", detail: AppLinks.phoneticToolbox.host, icon: "waveform", url: AppLinks.phoneticToolbox)
            ]
        }
    }

    init(page: AppInformationPage) {
        self.page = page
        super.init(style: .insetGrouped)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = page.title
        navigationItem.largeTitleDisplayMode = .never
        tableView.accessibilityIdentifier = "information_" + page.rawValue
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        tableView.cellLayoutMarginsFollowReadableWidth = true
        if page == .font || page == .editorHelp {
            let done = UIBarButtonItem(title: "完成".localized, style: .done, target: self, action: #selector(close))
            done.accessibilityIdentifier = page == .font ? "closeFontInformation" : "closeEditorHelp"
            navigationItem.rightBarButtonItem = done
        }
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { entries.count }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let entry = entries[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.accessibilityIdentifier = entry.id
        cell.textLabel?.text = entry.title
        cell.textLabel?.font = .preferredFont(forTextStyle: .body)
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        cell.detailTextLabel?.text = entry.detail
        cell.detailTextLabel?.font = .preferredFont(forTextStyle: .subheadline)
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.adjustsFontForContentSizeCategory = true
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.imageView?.image = entry.icon.flatMap { UIImage(systemName: $0) }
        cell.imageView?.tintColor = .secondaryLabel
        cell.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 18, leading: 20, bottom: 18, trailing: 20)
        cell.selectionStyle = entry.url != nil || entry.copyValue != nil ? .default : .none
        cell.accessoryType = entry.url == nil ? .none : .disclosureIndicator
        if entry.copyValue != nil && entry.url == nil {
            cell.accessibilityHint = "轻点复制".localized
            cell.accessoryView = UIImageView(image: UIImage(systemName: "doc.on.doc"))
            cell.accessoryView?.tintColor = .secondaryLabel
        }
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let entry = entries[indexPath.row]
        if let url = entry.url {
            UIApplication.shared.open(url, options: [:]) { [weak self] opened in
                // A device without Mail can still copy the address.
                if !opened, let value = entry.copyValue {
                    DispatchQueue.main.async { self?.copy(value) }
                }
            }
        } else if let value = entry.copyValue {
            copy(value)
        }
    }
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let entry = entries[indexPath.row]
        guard let value = entry.copyValue ?? entry.url?.absoluteString else { return nil }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            UIMenu(children: [UIAction(title: "复制".localized, image: UIImage(systemName: "doc.on.doc")) { _ in self?.copy(value) }])
        }
    }
    private func copy(_ value: String) {
        UIPasteboard.general.string = value
        let alert = UIAlertController(title: "已复制".localized, message: value, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "完成".localized, style: .default))
        present(alert, animated: true)
    }
    @objc private func close() { dismiss(animated: true) }
}
