/// Mapping utility that returns color names based on  hue and intensity values.
internal struct SpectrumNameResolver {
    static func name(hue: Double, primary: Double, secondary: Double, colorSpace: SpectrumColorSpace) -> String {
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
            if secondary < 0.15 { return String(localized: "black") }
            if secondary > 0.85 { return String(localized: "white") }
            return String(localized: "gray")
        }

        let baseName: String
        switch degrees {
        case 0..<25: baseName = String(localized: "red")
        case 25..<60: baseName = String(localized: "orange")
        case 60..<110: baseName = String(localized: "yellow")
        case 110..<160: baseName = String(localized: "green")
        case 160..<210: baseName = String(localized: "cyan")
        case 210..<280: baseName = String(localized: "blue")
        case 280..<330: baseName = String(localized: "purple")
        default: baseName = String(localized: "pink")
        }

        let adjective: String? = {
            if isDark { return String(localized: "dark") }
            if isPale { return String(localized: "pale") }
            if isVibrant { return String(localized: "vibrant") }
            return nil
        }()

        if let adj = adjective {
            let format = String(localized: "color_name_format", defaultValue: "%1$@ %2$@")
            return String(format: format, adj, baseName)
        }
        return baseName
    }
}
