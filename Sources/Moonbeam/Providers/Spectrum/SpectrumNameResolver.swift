import Foundation

/// An explicit configuration object that allows host apps to override default
/// VoiceOver translations.
public struct SpectrumAccessibilityStrings: Sendable {
    /// The localized accessibility string for gray colors.
    public var gray: String = String(localized: "gray", bundle: .module)
    /// The localized accessibility string for white colors.
    public var white: String = String(localized: "white", bundle: .module)
    /// The localized accessibility string for black colors.
    public var black: String = String(localized: "black", bundle: .module)

    /// The localized accessibility string for red colors.
    public var red: String = String(localized: "red", bundle: .module)
    /// The localized accessibility string for orange colors.
    public var orange: String = String(localized: "orange", bundle: .module)
    /// The localized accessibility string for yellow colors.
    public var yellow: String = String(localized: "yellow", bundle: .module)
    /// The localized accessibility string for green colors.
    public var green: String = String(localized: "green", bundle: .module)
    /// The localized accessibility string for cyan colors.
    public var cyan: String = String(localized: "cyan", bundle: .module)
    /// The localized accessibility string for blue colors.
    public var blue: String = String(localized: "blue", bundle: .module)
    /// The localized accessibility string for purple colors.
    public var purple: String = String(localized: "purple", bundle: .module)
    /// The localized accessibility string for pink colors.
    public var pink: String = String(localized: "pink", bundle: .module)

    /// The localized adjective for light colors.
    public var light: String? = String(localized: "light", bundle: .module)
    /// The localized adjective for dark colors.
    public var dark: String? = String(localized: "dark", bundle: .module)
    /// The localized adjective for bright colors.
    public var bright: String? = String(localized: "bright", bundle: .module)
    /// The localized adjective for dull colors.
    public var dull: String? = String(localized: "dull", bundle: .module)

    /// The format string used to combine adjectives and base color names.
    public var format: String = String(localized: "color_name_format", defaultValue: "%1$@ %2$@", bundle: .module)

    public init() {}
}

/// Thresholds for VoiceOver color descriptions.
internal enum ColorThresholds {
    /// Thresholds for HSB spectrum sliders.
    ///
    /// Manually calibrated because HSB is not perceptually uniform.
    enum HSB {
        static let grayMaxSaturation = 0.05
        static let whiteMinBrightness = 0.85
        static let blackMaxBrightness = 0.15

        static let lightMinBrightness = 0.8
        static let lightMaxSaturation = 0.5
        static let darkMaxBrightness = 0.3

        static let brightMinSaturation = 0.8
        static let dullMaxSaturation = 0.35
    }

    /// Thresholds for OKLCH spectrum sliders.
    enum OKLCH {
        static let grayMaxChroma = 0.02
        static let whiteMinLightness = 0.85
        static let blackMaxLightness = 0.15

        static let lightMinLightness = 0.8
        static let lightMaxChroma = 0.1
        static let darkMaxLightness = 0.35

        static let brightMinChroma = 0.15
        static let dullMaxChroma = 0.06
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
        let isWhite: Bool
        let isBlack: Bool

        let isLight: Bool
        let isDark: Bool
        let isBright: Bool
        let isDull: Bool

        if colorSpace == .oklch {
            isGray = primary < ColorThresholds.OKLCH.grayMaxChroma
            isWhite = secondary > ColorThresholds.OKLCH.whiteMinLightness
            isBlack = secondary < ColorThresholds.OKLCH.blackMaxLightness

            isLight = secondary > ColorThresholds.OKLCH.lightMinLightness
                && primary < ColorThresholds.OKLCH.lightMaxChroma
            isDark = secondary < ColorThresholds.OKLCH.darkMaxLightness

            isBright = primary > ColorThresholds.OKLCH.brightMinChroma
            isDull = primary < ColorThresholds.OKLCH.dullMaxChroma && !isGray
        } else {
            isGray = primary < ColorThresholds.HSB.grayMaxSaturation
            isWhite = secondary > ColorThresholds.HSB.whiteMinBrightness
            isBlack = secondary < ColorThresholds.HSB.blackMaxBrightness

            isLight = secondary > ColorThresholds.HSB.lightMinBrightness
                && primary < ColorThresholds.HSB.lightMaxSaturation
            isDark = secondary < ColorThresholds.HSB.darkMaxBrightness

            isBright = primary > ColorThresholds.HSB.brightMinSaturation
            isDull = primary < ColorThresholds.HSB.dullMaxSaturation && !isGray
        }

        if isGray {
            if isWhite { return strings.white }
            if isBlack { return strings.black }
            return strings.gray
        }

        let baseHueName: String
        switch degrees {
        case 0..<HueDegrees.redEnd: baseHueName = strings.red
        case HueDegrees.redEnd..<HueDegrees.orangeEnd: baseHueName = strings.orange
        case HueDegrees.orangeEnd..<HueDegrees.yellowEnd: baseHueName = strings.yellow
        case HueDegrees.yellowEnd..<HueDegrees.greenEnd: baseHueName = strings.green
        case HueDegrees.greenEnd..<HueDegrees.cyanEnd: baseHueName = strings.cyan
        case HueDegrees.cyanEnd..<HueDegrees.blueEnd: baseHueName = strings.blue
        case HueDegrees.blueEnd..<HueDegrees.purpleEnd: baseHueName = strings.purple
        default: baseHueName = strings.pink
        }

        let toneModifierName: String? = {
            if isLight { return strings.light }
            if isDark { return strings.dark }
            if isBright { return strings.bright }
            if isDull { return strings.dull }
            return nil
        }()

        if let toneModifierName, !toneModifierName.isEmpty {
            return String(format: strings.format, toneModifierName, baseHueName)
        }
        return baseHueName
    }
}
