import SwiftUI
import UIKit

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }

    init(light: UInt32, dark: UInt32, alpha: Double = 1) {
        self.init(
            UIColor { trait in
                let hex = trait.userInterfaceStyle == .dark ? dark : light
                return UIColor(
                    red: CGFloat((hex >> 16) & 0xFF) / 255,
                    green: CGFloat((hex >> 8) & 0xFF) / 255,
                    blue: CGFloat(hex & 0xFF) / 255,
                    alpha: alpha
                )
            }
        )
    }

    static let rewindBackground = Color(light: 0xFAFAFA, dark: 0x0E0E0F)
    static let rewindSurface = Color(light: 0xFFFFFF, dark: 0x1A1A1C)
    static let rewindTextPrimary = Color(light: 0x1A1A1A, dark: 0xF5F5F5)
    static let rewindTextSecondary = Color(light: 0x6B6B6B, dark: 0x9A9A9E)
    static let rewindBorder = Color(light: 0xEBEBEB, dark: 0x2A2A2C)
    static let rewindDelete = Color(light: 0xFF6B4A, dark: 0xFF7D5C)
    static let rewindKeep = Color(light: 0x3ECF8E, dark: 0x4FD99A)
}

enum RewindFont {
    static let title = Font.system(size: 28, weight: .semibold, design: .rounded)
    static let heading = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 16, weight: .regular, design: .rounded)
    static let caption = Font.system(size: 13, weight: .regular, design: .rounded)
}

enum RewindSpring {
    static let snappy = Animation.spring(response: 0.35, dampingFraction: 0.8)
    static let standard = Animation.spring(response: 0.4, dampingFraction: 0.8)
    static let hero = Animation.spring(response: 0.45, dampingFraction: 0.8)
}

enum RewindShape {
    static let cardRadius: CGFloat = 24
    static let sheetRadius: CGFloat = 28
    static let restShadow = (color: Color.black.opacity(0.06), radius: CGFloat(12), y: CGFloat(2))
    static let liftShadow = (color: Color.black.opacity(0.14), radius: CGFloat(32), y: CGFloat(12))
}
