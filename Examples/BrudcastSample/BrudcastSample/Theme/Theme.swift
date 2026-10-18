import SwiftUI
import UIKit
import CoreText

/// The sample's colours, each resolving to its light or dark value with the device's appearance.
enum Palette {
    static let background = Color(light: 0xFFFFFF, dark: 0x131313)
    static let foreground = Color(light: 0x131313, dark: 0xFFFFFF)
    static let mutedForeground = Color(light: 0x4B5563, dark: 0x9CA3AF)
    static let foregroundSubtle = Color(light: 0x8A8A8F, dark: 0x6E6E73)
    static let card = Color(light: 0xFFFFFF, dark: 0x161616)

    /// Filled surfaces: buttons, badges.
    static let primary = Color(light: 0x365AED, dark: 0x3151D5)
    static let primaryForeground = Color.white
    /// Ink on a surface: links and text accents.
    static let brand = Color(light: 0x365AED, dark: 0x889EFF)
    static let brandSubtle = Color(light: 0x365AED, lightAlpha: 0.06, dark: 0x889EFF, darkAlpha: 0.08)

    static let border = Color(light: 0xEAEAEC, dark: 0x262626)
    static let borderStrong = Color(light: 0xD4D4D8, dark: 0x343437)
    static let inputActive = Color(light: 0xD4D4D4, dark: 0x262626, darkAlpha: 0.8)

    static let success = Color(light: 0xF0FDF4, dark: 0x16A34A, darkAlpha: 0.15)
    static let successForeground = Color(light: 0x16A34A, dark: 0x4ADE80)
    static let warning = Color(light: 0xFFFBEB, dark: 0xF59E0B, darkAlpha: 0.15)
    static let warningForeground = Color(light: 0xF59E0B, dark: 0xFBBF24)
    static let destructive = Color(light: 0xFEF2F2, dark: 0xEF4444, darkAlpha: 0.15)
    static let destructiveForeground = Color(light: 0xEF4444, dark: 0xF87171)

    /// The primary blue as a `UIColor`, for the SDK's in-app message buttons.
    static let primaryUIColor = UIColor(red: 0x36 / 255, green: 0x5A / 255, blue: 0xED / 255, alpha: 1)
}

/// The sample's type scale: Gabarito for headings and metric numerals, Hanken Grotesk for
/// everything else, at exact variable weights, scaled with Dynamic Type.
enum Typography {
    static var pageTitle: Font { make("Gabarito", size: 24, weight: 500, style: .title2) }
    static var metric: Font { make("Gabarito", size: 24, weight: 600, style: .title2).monospacedDigit() }
    static var sectionTitle: Font { make("Gabarito", size: 16, weight: 400, style: .headline) }
    static var subheading: Font { make("Hanken Grotesk", size: 14, weight: 500, style: .subheadline) }
    static var body: Font { make("Hanken Grotesk", size: 14, weight: 450, style: .body) }
    static var description: Font { make("Hanken Grotesk", size: 13, weight: 400, style: .footnote) }
    static var label: Font { make("Hanken Grotesk", size: 13, weight: 500, style: .footnote) }
    static var button: Font { make("Hanken Grotesk", size: 14, weight: 500, style: .body) }
    static var micro: Font { make("Hanken Grotesk", size: 12, weight: 500, style: .caption1) }

    private static let weightAxis = NSNumber(value: 0x7767_6874)

    private static func make(_ family: String, size: CGFloat, weight: CGFloat, style: UIFont.TextStyle) -> Font {
        let variation = UIFontDescriptor.AttributeName(rawValue: kCTFontVariationAttribute as String)
        let descriptor = UIFontDescriptor(fontAttributes: [.family: family, variation: [weightAxis: weight]])
        return Font(UIFontMetrics(forTextStyle: style).scaledFont(for: UIFont(descriptor: descriptor, size: size)))
    }
}

/// The sample's corner radii.
enum Radius {
    static let button: CGFloat = 8
    static let input: CGFloat = 10
    static let panel: CGFloat = 14
}

private extension Color {
    init(light: UInt32, lightAlpha: CGFloat = 1, dark: UInt32, darkAlpha: CGFloat = 1) {
        self.init(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark, alpha: darkAlpha) : UIColor(hex: light, alpha: lightAlpha)
        })
    }
}

private extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}
