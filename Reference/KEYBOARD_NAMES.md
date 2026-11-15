# System keyboard naming

Apple documents that Settings uses the containing app's display name for the
keyboard group, and the extension's display name for the individual keyboard and
globe menu. Public reports describe a `Keyboard — App` composite when the names
do not match. Both targets therefore use the same literal CFBundleName and
CFBundleDisplayName fallback, as well as identical localized names. Internal
product/executable names remain separate and never become naming fallbacks.

The app's in-app language preference changes its UI only. It must not rewrite
bundle metadata or replace Apple's system language selection. Tests compare both
built bundles for four localizations, regional language preferences, unsupported
language fallbacks and mixed preference lists. A Settings UI test also installs the keyboard and checks the actual list in
English, Simplified Chinese, Traditional Chinese and Japanese system environments,
with a different language in the app. It excludes the status-bar return-to-app
link and verifies that each installed keyboard label contains the brand once.

The OS owns installed-keyboard metadata and caching; these checks do not guarantee
that every already-running host refreshes its cached label immediately on upgrade.

References:
- https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/CustomKeyboard.html (Table 8-3)
- https://stackoverflow.com/questions/33217473/custom-keyboard-name-without-keyboardname-hostappname-scheme
- https://stackoverflow.com/questions/37453001/how-to-edit-custom-keyboard-name-in-keyboard-selection-menu
