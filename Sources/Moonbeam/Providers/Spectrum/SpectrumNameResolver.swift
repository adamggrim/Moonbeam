import Foundation

/// An explicit configuration object that allows host apps to override default
/// VoiceOver translations.
public struct SpectrumAccessibilityStrings: Sendable {
    /// The localized accessibility string for black colors.
    public let black: String
    /// The localized accessibility string for white colors.
    public let white: String
    /// The localized accessibility string for gray colors.
    public let gray: String
    /// The localized accessibility string for red colors.
    public let red: String
    /// The localized accessibility string for orange colors.
    public let orange: String
    /// The localized accessibility string for yellow colors.
    public let yellow: String
    /// The localized accessibility string for green colors.
    public let green: String
    /// The localized accessibility string for cyan colors.
    public let cyan: String
    /// The localized accessibility string for blue colors.
    public let blue: String
    /// The localized accessibility string for purple colors.
    public let purple: String
    /// The localized accessibility string for pink colors.
    public let pink: String

    /// The localized adjective for dark colors.
    public let dark: String
    /// The localized adjective for pale colors.
    public let pale: String
    /// The localized adjective for vibrant colors.
    public let vibrant: String

    /// The format string used to combine adjectives and base color names.
    public let format: String

    public init(
        black: String? = nil,
        white: String? = nil,
        gray: String? = nil,
        red: String? = nil,
        orange: String? = nil,
        yellow: String? = nil,
        green: String? = nil,
        cyan: String? = nil,
        blue: String? = nil,
        purple: String? = nil,
        pink: String? = nil,

        dark: String? = nil,
        pale: String? = nil,
        vibrant: String? = nil,

        format: String? = nil
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

/// Thresholds for VoiceOver color descriptions.
internal enum ColorThresholds {

    /// Thresholds for HSB spectrum sliders.
    ///
    /// Manually calibrated because HSB is not perceptually uniform.
    enum HSB {
        static let grayMaxSaturation = 0.05
        static let darkMaxBrightness = 0.3
        static let paleMinBrightness = 0.8
        static let paleMaxSaturation = 0.5
        static let vibrantMinSaturation = 0.8
        static let blackMaxBrightness = 0.15
        static let whiteMinBrightness = 0.85
    }

    /// Thresholds for OKLCH spectrum sliders.
    enum OKLCH {
        static let grayMaxChroma = 0.02
        static let darkMaxLightness = 0.35
        static let paleMinLightness = 0.8
        static let paleMaxChroma = 0.1
        static let vibrantMinChroma = 0.15
        static let blackMaxLightness = 0.15
        static let whiteMinLightness = 0.85
    }
}

internal enum HueDegrees {
    static let redEnd = 25.0
    static let orangeEnd = 60.0
    static let yellowEnd = 110.0
    static let greenEnd = 160.0
    static let cyanEnd = 210.0
    static let blueEnd = 280.0
    static let purpleEnd = 330.0
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
        let isBlack: Bool
        let isWhite: Bool

        if colorSpace == .oklch {
            isGray = primary < ColorThresholds.OKLCH.grayMaxChroma
            isDark = secondary < ColorThresholds.OKLCH.darkMaxLightness
            isPale = secondary > ColorThresholds.OKLCH.paleMinLightness && primary < ColorThresholds.OKLCH.paleMaxChroma
            isVibrant = primary > ColorThresholds.OKLCH.vibrantMinChroma
            isBlack = secondary < ColorThresholds.OKLCH.blackMaxLightness
            isWhite = secondary > ColorThresholds.OKLCH.whiteMinLightness
        } else {
            isGray = primary < ColorThresholds.HSB.grayMaxSaturation
            isDark = secondary < ColorThresholds.HSB.darkMaxBrightness
            isPale = secondary > ColorThresholds.HSB.paleMinBrightness
                && primary < ColorThresholds.HSB.paleMaxSaturation
            isVibrant = primary > ColorThresholds.HSB.vibrantMinSaturation
            isBlack = secondary < ColorThresholds.HSB.blackMaxBrightness
            isWhite = secondary > ColorThresholds.HSB.whiteMinBrightness
        }

        if isGray {
            if isBlack { return strings.black }
            if isWhite { return strings.white }
            return strings.gray
        }

        let baseName: String
        switch degrees {
        case 0..<HueDegrees.redEnd: baseName = strings.red
        case HueDegrees.redEnd..<HueDegrees.orangeEnd: baseName = strings.orange
        case HueDegrees.orangeEnd..<HueDegrees.yellowEnd: baseName = strings.yellow
        case HueDegrees.yellowEnd..<HueDegrees.greenEnd: baseName = strings.green
        case HueDegrees.greenEnd..<HueDegrees.cyanEnd: baseName = strings.cyan
        case HueDegrees.cyanEnd..<HueDegrees.blueEnd: baseName = strings.blue
        case HueDegrees.blueEnd..<HueDegrees.purpleEnd: baseName = strings.purple
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
