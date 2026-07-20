import Foundation

/// A factory for determining the appropriate color slider data source based on
/// the provided configuration.
internal enum DataSourceFactory {

    /// Resolves and returns the `ColorSliderDataSource` for the given
    /// configuration.
    ///
    /// - Parameter configuration: The data configuration built by the view
    ///   modifiers.
    /// - Returns: An object conforming to `ColorSliderDataSource`.
    static func resolve(from configuration: ColorSliderConfiguration) -> any ColorSliderDataSource & Sendable {
        let baseSource: any ColorSliderDataSource & Sendable

        if configuration.colorSpace == .oklch {
            let currentChromaBends: () -> [BendSection] = { configuration.chromaBends }
            let currentLightnessBends: () -> [BendSection] = { configuration.lightnessBends }

            return OKLCHSpectrumModel(
                startSections: configuration.startSections,
                endSections: configuration.endSections,
                lightness: configuration.baseLightness ?? 0.75,
                chroma: configuration.baseChroma ?? 0.15,
                startHue: configuration.hueRange.lowerBound,
                endHue: configuration.hueRange.upperBound,
                lightnessBends: currentLightnessBends,
                chromaBends: currentChromaBends
            )
        } else {
            let currentSaturationBends: () -> [BendSection] = { configuration.saturationBends }
            let currentBrightnessBends: () -> [BendSection] = { configuration.brightnessBends }

            return HSBSpectrumModel(
                startSections: configuration.startSections,
                endSections: configuration.endSections,
                startHue: configuration.hueRange.lowerBound,
                endHue: configuration.hueRange.upperBound,
                saturation: configuration.baseSaturation ?? 1.0,
                brightness: configuration.baseBrightness ?? 1.0,
                saturationBends: currentSaturationBends,
                brightnessBends: currentBrightnessBends
            )
        }
    }
}
