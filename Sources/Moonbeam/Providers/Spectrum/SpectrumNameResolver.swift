import Foundation

/// An explicit configuration object that allows host apps to override default
/// VoiceOver translations.
public struct SpectrumAccessibilityStrings: Sendable {
    public let black: String
    public let white: String
    public let gray: String
    public let red: String
    public let orange: String
    public let yellow: String
    public let green: String
    public let cyan: String
    public let blue: String
    public let purple: String
    public let pink: String
    public let dark: String
    public let pale: String
    public let vibrant: String
    public let format: String

    public init(
        black: String? = nil, white: String? = nil, gray: String? = nil,
        red: String? = nil, orange: String? = nil, yellow: String? = nil,
        green: String? = nil, cyan: String? = nil, blue: String? = nil,
        purple: String? = nil, pink: String? = nil, dark: String? = nil,
        pale: String? = nil, vibrant: String? = nil, format: String? = nil
    ) {
        self.black = black ?? String(localized: "black", bundle: .module)
        self.white = white ?? String(localized: "white", bundle: .module)
        self.gray = gray ?? String(localized: "gray", bundle: .module)
        self.red = red ?? String(localized: "red", bundle: .module)
        self.orange = orange ?? String(localized: "orange", bundle: .module)
        self.yellow = yellow ?? String(localized: "yellow", bundle: .module)
        self.green = green ?? String(localized: "green", bundle: .module)
        self.cyan = cyan ?? String(localized: "cyan", bundle: .module)
        self.blue = blue ?? String(localized: "blue", bundle: .module)
        self.purple = purple ?? String(localized: "purple", bundle: .module)
        self.pink = pink ?? String(localized: "pink", bundle: .module)
        self.dark = dark ?? String(localized: "dark", bundle: .module)
        self.pale = pale ?? String(localized: "pale", bundle: .module)
        self.vibrant = vibrant ?? String(localized: "vibrant", bundle: .module)
        self.format = format ?? String(localized: "color_name_format", defaultValue: "%1$@ %2$@", bundle: .module)
    }
}

/// Mapping utility that returns color names based on hue and intensity values.
internal struct SpectrumNameResolver {
    static func name(
        hue: Double,
        primary: Double,
        secondary: Double,
        colorSpace: SpectrumColorSpace,
        strings: SpectrumAccessibilityStrings
    ) -> String {
        let h = hue.truncatingRemainder(dividingBy: 1.0)
        let degrees = (h < 0 ? h + 1.0 : h) * 360.0

        let isGray: Bool
        let isDark: Bool
        let isPale: Bool
        let isVibrant: Bool

        if colorSpace == .oklch {
            isGray = primary < 0.02
            isDark = secondary < 0.35
            isPale = secondary > 0.8 && primary < 0.1
            isVibrant = primary > 0.15
        } else {
            isGray = primary < 0.05
            isDark = secondary < 0.3
            isPale = secondary > 0.8 && primary < 0.5
            isVibrant = primary > 0.8
        }

        if isGray {
            if secondary < 0.15 { return strings.black }
            if secondary > 0.85 { return strings.white }
            return strings.gray
        }

        let baseName: String
        switch degrees {
        case 0..<25: baseName = strings.red
        case 25..<60: baseName = strings.orange
        case 60..<110: baseName = strings.yellow
        case 110..<160: baseName = strings.green
        case 160..<210: baseName = strings.cyan
        case 210..<280: baseName = strings.blue
        case 280..<330: baseName = strings.purple
        default: baseName = strings.pink
        }

        let adjective: String? = {
            if isDark { return strings.dark }
            if isPale { return strings.pale }
            if isVibrant { return strings.vibrant }
            return nil
        }()

        if let adj = adjective {
            return String(format: strings.format, adj, baseName)
        }
        return baseName
    }
}
