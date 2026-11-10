# IPA Keyboard

使用 Swift 和 UIKit 开发的 iOS 国际音标输入法，包含键盘扩展与符号设置 App。

## 功能

- 轻点输入字母，四向滑动输入音标变体，长按滑选完整候选。
- 支持现版 IPA、中国通用音标、旧版及非标准 IPA、extIPA 和 Unicode 语音补充。
- 独立符号面板提供上标、下标、组合附加符号及最近使用，支持连续横向浏览。
- 数字和标点页支持长按变体；长按空格后左右拖动可移动光标。
- 可设置符号来源、面板内容、逐键滑动映射，以及声音和触感。
- 符号参考支持分类浏览、搜索、Unicode 编码和注释。
- 支持浅色、深色外观和 VoiceOver 操作。

## 安装与使用

[Releases](https://github.com/ghehyoein/IPAkeyboardios/releases) 提供未签名的 `IPAKeyboard-unsigned.ipa`。安装前需为主 App 和键盘扩展签名；自行构建也需要配置开发者团队与 App Group，见[构建与签名](Reference/SIGNING.md)。

安装后，在系统「设置 → 通用 → 键盘 → 键盘 → 添加新键盘」中启用 IPA Keyboard。打开 App 可调整符号与输入偏好，切回键盘后生效。

`◌̃` 打开符号面板，`ABC` 返回字母。虚线圆圈仅用于展示附加符号，不会输入正文。组合形式依次输入，例如 `a` + U+0303 → `ã`、`t` + `ʰ` → `tʰ`。

面板中每个符号仅保留一个分类，标准 IPA 分类优先，附加符号排在普通字符之前。面板显示开关分为主键盘无法输入的符号、主键盘可输入的附加符号、主键盘可输入的普通符号；这些开关不改变主键盘候选。

## 隐私与兼容性

键盘不联网，不收集输入正文或周围文本。设置通过 App Group 在 App 与扩展之间同步；最近使用仅保存在本地。基本输入和设置的只读同步无需完全访问，扩展按键声音需要完全访问。

第三方键盘在密码框、部分输入框或禁止扩展的应用中不可用。字符显示与组合效果取决于目标应用及其字体；系统字体缺少字形时，候选显示 Unicode 编码，实际输入仍是原始字符。

## 开发

当前工程使用 Xcode 26，最低部署版本为 iOS 26。用 Xcode 打开 `IPAKeyboard.xcodeproj`。本地数据生成与检查：

```sh
python3 tools/build_catalog.py
python3 tools/generate_project.py
python3 -m unittest discover -s Tests -p 'test_*.py' -v
```

`generate_project.py` 会重建工程配置。GitHub Actions 提供模拟器测试、截图、未签名 IPA 构建与可选的 TestFlight 分发。模拟器按工程部署要求从可用运行时中选择兼容的 iPhone，不限定某款个人设备。

## 数据来源与许可

音标清单、Unicode 数据及其适用许可见 [Reference/SOURCES.md](Reference/SOURCES.md) 和 [Unicode 许可](Reference/Unicode/LICENSE.txt)。来源清单和 Unicode 快照用于离线生成与覆盖校验。键位分配和候选顺序属于本项目设计，不代表标准机构的官方映射。
