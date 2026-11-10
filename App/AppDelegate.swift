import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        var root: UIViewController = SymbolSettingsViewController()
        #if DEBUG
        // The preview exists only as an explicitly launched test harness.
        if CommandLine.arguments.contains("--ui-testing") || CommandLine.arguments.contains("--screenshot") {
            root = SandboxViewController()
        }
        #endif
        window.rootViewController = UINavigationController(rootViewController: root)
        window.makeKeyAndVisible(); self.window = window
        return true
    }
}
