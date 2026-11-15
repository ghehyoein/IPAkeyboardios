import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        #if DEBUG
        if CommandLine.arguments.contains("--reset-settings") { SymbolSettingsStore.shared.resetForTesting() }
        #endif
        let visibility = SymbolSettingsStore.shared.load()
        // Resolve older automatic preferences once; the app now offers four explicit languages.
        SymbolSettingsStore.shared.save(visibility)
        L10n.selection = visibility.language
        let window = UIWindow(frame: UIScreen.main.bounds)
        var root: UIViewController = SymbolSettingsViewController()
        #if DEBUG
        // Screenshot and UI-test launch shortcuts; the demo is also available in Settings.
        if CommandLine.arguments.contains("--ui-testing") || CommandLine.arguments.contains("--screenshot") {
            root = DemoViewController()
        }
        #endif
        window.rootViewController = UINavigationController(rootViewController: root)
        window.tintColor = .label
        window.makeKeyAndVisible(); self.window = window
        return true
    }
}
