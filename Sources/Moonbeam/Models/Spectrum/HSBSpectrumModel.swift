import SwiftUI

import MoonbeamShared

/// Model for calculating standard HSB spectrum colors dynamically.
internal struct HSBSpectrumModel: ColorSliderDataSource {
    let startSections: [MonochromeSection]
    let endSections: [MonochromeSection]
    let startHue: Double
    let endHue: Double
    let saturation: Double
    let brightness: Double
    let saturationBends: [BendSection]
    let brightnessBends: [BendSection]
    let colorSource: ColorSourceProvider

    /// Creates a dynamically generated spectrum based on the HSB (Hue,
    /// Saturation, Brightness) color space.
    ///
    /// - Parameters:
    ///   - startSections: Monochrome sections that fade into the
    ///     beginning of the hue spectrum. Capped at `MAX_MONOCHROME_SECTIONS`.
    ///   - endSections: Monochrome sections that fade out of the end of the hue
    ///     spectrum.
    ///   - startHue: The starting hue value in degrees normalized to 0.0 to 1.0
    ///     (e.g., 180° = 0.5).
    ///   - endHue: The ending hue value in degrees normalized to 0.0 - 1.0.
    ///   - saturation: The baseline saturation applied to the entire hue range
    ///     (0.0 to 1.0).
    ///   - brightness: The baseline brightness applied to the entire hue range
    ///     (0.0 to 1.0).
    ///   - saturationBends: A result builder providing sections where the
    ///     baseline saturation increases or decreases to a `targetValue`.
    ///   - brightnessBends: A result builder providing sections where the
    ///     baseline brightness increases or decreases to a `targetValue`.
    init(
        startSections: [MonochromeSection] = [],
        endSections: [MonochromeSection] = [],
        startHue: Double = 0.0,
        endHue: Double = 1.0,
        saturation: Double = 1.0,
        brightness: Double = 1.0,
        @BendSectionBuilder saturationBends: () -> [BendSection] = { [] },
        @BendSectionBuilder brightnessBends: () -> [BendSection] = { [] }
    ) {
        let validStart = validateMonochromeSections(startSections, name: "HSB Start")
        let validEnd = validateMonochromeSections(endSections, name: "HSB End")
        let validSaturationBends = validateBends(saturationBends(), name: "HSB Saturation")
        let validBrightnessBends = validateBends(brightnessBends(), name: "HSB Brightness")

        self.startSections = validStart
        self.endSections = validEnd
        self.startHue = startHue
        self.endHue = endHue
        self.saturation = saturation
        self.brightness = brightness
        self.saturationBends = validSaturationBends
        self.brightnessBends = validBrightnessBends

        let fallback: @Sendable (Double) -> Color = { position in
            SpectrumGenerator.color(
                at: position,
                startSections: validStart,
                endSections: validEnd,
                startHue: startHue,
                endHue: endHue,
                primaryValue: saturation,
                secondaryValue: brightness,
                colorSpace: .hsb,
                primaryBends: validSaturationBends,
                secondaryBends: validBrightnessBends
            )
        }
        let shaderData = encodeSpectrumData(
            startSections: validStart,
            endSections: validEnd,
            startHue: startHue,
            endHue: endHue,
            primaryValue: saturation,
            secondaryValue: brightness,
            colorSpace: .hsb,
            primaryBendsCount: validSaturationBends.count,
            secondaryBendsCount: validBrightnessBends.count
        )

        let saturationBendsMapped = validSaturationBends.map { ShaderBend(bend: $0) }
        let nonEmptySaturationBends = saturationBendsMapped.isEmpty ? [ShaderBend.empty] : saturationBendsMapped
        let saturationBendsData = nonEmptySaturationBends.withUnsafeBufferPointer { Data(buffer: $0) }

        let brightnessBendsMapped = validBrightnessBends.map { ShaderBend(bend: $0) }
        let nonEmptyBrightnessBends = brightnessBendsMapped.isEmpty ? [ShaderBend.empty] : brightnessBendsMapped
        let brightnessBendsData = nonEmptyBrightnessBends.withUnsafeBufferPointer { Data(buffer: $0) }

        self.colorSource = .shader(generator: { size, isVertical in
            ShaderLibrary.bundle(.module)
                .spectrumShader(
                    .float2(size.width, size.height),
                    .float(isVertical ? 1.0 : 0.0),
                    .data(shaderData),
                    .data(saturationBendsData),
                    .data(brightnessBendsData)
                )
        }, fallback: fallback)
    }
}
