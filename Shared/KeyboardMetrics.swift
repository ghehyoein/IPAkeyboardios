import UIKit

/// Geometry is based on the current input window, including iPad split/floating widths.
struct KeyboardMetrics {
    let width: CGFloat
    let isTablet: Bool
    let landscape: Bool
    var spacious: Bool { isTablet && width >= 600 }
    var rowPitch: CGFloat { spacious ? (landscape ? 60 : 66) : (landscape && width > 600 ? 40 : 56) }
    var letterContentHeight: CGFloat { rowPitch * 4 + 5 }
    var symbolKeyHeight: CGFloat { spacious ? 44 : (landscape && width > 600 ? 22 : 36) }
    var demoBottomInset: CGFloat { landscape && !spacious ? 20 : 72 }
    var symbolGridHeight: CGFloat { symbolKeyHeight * 5 + 24 }
    var symbolContentHeight: CGFloat { symbolGridHeight + 101 }
    var symbolColumns: Int { Self.symbolColumns(for: width) }
    static func symbolColumns(for width: CGFloat) -> Int { max(10, min(18, Int(width / 50))) }
    static func usesInlineGlobe(isTablet: Bool, screen: CGSize) -> Bool {
        !isTablet && max(screen.width, screen.height) <= 736
    }
}
