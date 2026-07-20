import SwiftUI

import MoonbeamShared

/// Model for calculating perceptually uniform OKLCH spectrum colors dynamically.
internal struct OKLCHSpectrumModel: ColorSliderDataSource {
    let startSections: [MonochromeSection]
    let endSections: [MonochromeSection]
    let lightness: Double
    let chroma: Double
    let startHue: Double
    let endHue: Double
    let lightnessBends: [BendSection]
    let chromaBends: [BendSection]
    let colorSource: ColorSourceProvider

    /// Creates a dynamically generated spectrum based on the perceptually
    /// uniform OKLCH color space.
    ///
    /// - Parameters:
    ///   - startSections: Monochrome sections that fade into the beginning of
    ///     the hue spectrum. Capped at
    ///     `MAX_MONOCHROME_SECTIONS`.
    ///   - endSections: Monochrome sections that fade out of the end of the hue
    ///     spectrum.
    ///   - lightness: The perceived brightness of the color. Standard range is
    ///     0.0 to 1.0. Defaults to 0.75.
    ///   - chroma: The intensity of the color. Range depends on the device
    ///     gamut, typically 0.0 to 0.4. Defaults to 0.15.
    ///   - startHue: The starting hue, normalized to 0.0 through 1.0.
    ///   - endHue: The ending hue, normalized to 0.0 through 1.0.
    ///   - lightnessBends: Sections where the baseline lightness bends toward
    ///     a target value.
    ///   - chromaBends: Sections where the baseline chroma bends toward a
    ///     target value.
    public init(
        startSections: [MonochromeSection] = [],
        endSections: [MonochromeSection] = [],
        lightness: Double = 0.75,
        chroma: Double = 0.15,
        startHue: Double = 0.0,
        endHue: Double = 1.0,
        @BendSectionBuilder lightnessBends: () -> [BendSection] = { [] },
        @BendSectionBuilder chromaBends: () -> [BendSection] = { [] }
    ) {
        let validStart = validateMonochromeSections(startSections, name: "OKLCH Start")
        let validEnd = validateMonochromeSections(endSections, name: "OKLCH End")
        let validLightnessBends = validateBends(lightnessBends(), name: "OKLCH Lightness")
        let validChromaBends = validateBends(chromaBends(), name: "OKLCH Chroma")

        self.startSections = validStart
        self.endSections = validEnd
        self.lightness = lightness
        self.chroma = chroma
        self.startHue = startHue
        self.endHue = endHue
        self.lightnessBends = validLightnessBends
        self.chromaBends = validChromaBends

        let fallback: @Sendable (Double) -> Color = { position in
            SpectrumGenerator.color(
                at: position,
                startSections: validStart,
                endSections: validEnd,
                startHue: startHue,
                endHue: endHue,
                primaryValue: chroma,
                secondaryValue: lightness,
                colorSpace: .oklch,
                primaryBends: validChromaBends,
                secondaryBends: validLightnessBends
            )
        }
        let shaderData = encodeSpectrumData(
            startSections: validStart,
            endSections: validEnd,
            startHue: startHue,
            endHue: endHue,
            primaryValue: chroma,
            secondaryValue: lightness,
            colorSpace: .oklch,
            primaryBendsCount: validChromaBends.count,
            secondaryBendsCount: validLightnessBends.count
        )

        let chromaBendsMapped = validChromaBends.map { ShaderBend(bend: $0) }
        let nonEmptyChromaBends = chromaBendsMapped.isEmpty ? [ShaderBend.empty] : chromaBendsMapped
        let chromaBendsData = nonEmptyChromaBends.withUnsafeBufferPointer { Data(buffer: $0) }

        let lightnessBendsMapped = validLightnessBends.map { ShaderBend(bend: $0) }
        let nonEmptyLightnessBends = lightnessBendsMapped.isEmpty ? [ShaderBend.empty] : lightnessBendsMapped
        let lightnessBendsData = nonEmptyLightnessBends.withUnsafeBufferPointer { Data(buffer: $0) }

        self.colorSource = .shader(generator: { size, isVertical in
            ShaderLibrary.bundle(.module)
                .spectrumShader(
                    .float2(size.width, size.height),
                    .float(isVertical ? 1.0 : 0.0),
                    .data(shaderData),
                    .data(chromaBendsData),
                    .data(lightnessBendsData)
                )
        }, fallback: fallback)
    }
}
