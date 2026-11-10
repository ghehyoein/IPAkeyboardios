import UIKit

/// Public adaptive system material; no private keyboard views or alpha on blur views.
@MainActor enum KeyboardMaterial {
    static var key: UIColor { UIColor { traits in
        if UIAccessibility.isReduceTransparencyEnabled { return traits.userInterfaceStyle == .dark ? UIColor(white: 0.30, alpha: 1) : .white }
        return traits.userInterfaceStyle == .dark ? UIColor(white: 0.58, alpha: 0.25) : UIColor(white: 1, alpha: 0.82)
    } }
    static var utility: UIColor { UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(white: 0.18, alpha: 0.9) : UIColor(red: 0.78, green: 0.81, blue: 0.85, alpha: 0.55)
    } }
    static func install(in view: UIView) -> UIVisualEffectView {
        let material = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
        material.isUserInteractionEnabled = false
        material.frame = view.bounds
        material.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(material, at: 0)
        return material
    }
}
