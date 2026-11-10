# 构建与签名

## 本地构建

使用 Xcode 打开工程，为主 App 与键盘扩展选择开发者团队。两个目标需要各自唯一的 Bundle ID，扩展使用主 App 标识下的子标识；两者必须启用同一个 App Group。

工程生成器支持以下环境变量：

- `IPA_BUNDLE_IDENTIFIER`：主 App 标识，扩展使用其 `.Keyboard` 子标识。
- `IPA_APP_GROUP_IDENTIFIER`：两个目标共用的 App Group。
- `IPA_MARKETING_VERSION`、`IPA_BUILD_NUMBER`：版本与构建号。
- `APPLE_TEAM_ID`：签名团队。

生成器的默认标识用于本地开发。分发构建需使用开发者账号中注册的标识和配置。

## 未签名 IPA

`ios.yml` 运行数据检查、Swift 单元测试和 UI 测试，归档主 App 与扩展并发布未签名 IPA。模拟器从已安装且满足工程最低系统要求的运行时中选择，可通过 `IPA_SIMULATOR_DEVICE_TYPE` 指定兼容设备类型。

重签时必须同时签名 App 和 `PlugIns/IPAKeyboardExtension.appex`，保留资源及共享组权限。两个目标的 `com.apple.security.application-groups` entitlement 与 Info.plist 中的 `IPASettingsAppGroup` 必须一致。缺少共享容器时，App 中的偏好不能同步到系统键盘。

## TestFlight 自动化

`testflight.yml` 使用手动分发签名，支持验证导出或上传到 App Store Connect。`release-testflight.yml` 将成功发布的版本交给该工作流。自动分发限制在上游仓库的 main 分支；派生仓库需要按自己的发布策略调整仓库限制并配置独立的签名环境。

在受保护的 `testflight` 环境中配置凭据。仓库变量包括 `APPLE_TEAM_ID`，以及需要覆盖的 `IPA_BUNDLE_IDENTIFIER`、`IPA_APP_GROUP_IDENTIFIER`。环境 Secrets 包括：

| 名称 | 用途 |
| --- | --- |
| `SIGNING_P12_BASE64`、`SIGNING_P12_PASSWORD` | 含私钥的分发证书及密码 |
| `APP_PROFILE_BASE64`、`EXT_PROFILE_BASE64` | 主 App 与扩展的 App Store 描述文件 |
| `ASC_KEY_ID`、`ASC_ISSUER_ID`、`ASC_PRIVATE_KEY` | App Store Connect 上传 API 凭据 |

证书、描述文件和 API 私钥不得提交到仓库。工作流将凭据写入临时存储，在上传前核对双目标签名、版本、共享组与隐私清单，结束后清理临时文件。

自动上传的版本来自发布标签，构建号来自工作流运行序号和重试序号。手动运行可指定版本与已发布提交，关闭 `upload` 可仅验证签名导出。上传成功后仍需等待 Apple 处理，并在 App Store Connect 配置测试组。当前导出方式为内部 TestFlight 测试，不包含外部测试或 App Store 审核提交。

参阅 [Apple TestFlight 文档](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview)。
