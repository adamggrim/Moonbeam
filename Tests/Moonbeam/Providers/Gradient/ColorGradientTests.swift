import Testing
@testable import Moonbeam
import SwiftUI

@Suite struct ColorGradientTests {
    @Test("Gradient interpolation resolves to a valid color")
    func gradientInterpolation() {
        let gradient = ColorGradient(colors: [.black, .white], colorSpace: .rgb)

        guard case .shader(_, let fallback) = gradient.colorSource else {
            Issue.record("Expected shader color source with a pure-Swift fallback.")
            return
        }

        let midColor = fallback(0.5)
        let expectedColor = Color.black.mix(with: .white, by: 0.5)

        #expect(midColor == expectedColor)
    }

    @Test("Property-based gradient interpolates across random bounds")
    func gradientInterpolationProperties() {
        let gradient = ColorGradient(colors: [.black, .white], colorSpace: .rgb)

        guard case .shader(_, let fallback) = gradient.colorSource else {
            Issue.record("Expected shader color source with a pure-Swift fallback.")
            return
        }

        for _ in 0..<100 {
            let position = Double.random(in: 0.0...1.0)
            let calculatedColor = fallback(position)
            let expectedColor = Color.black.mix(with: .white, by: position)

            #expect(calculatedColor == expectedColor)
        }
    }

    @Test("Oklch purple-to-white gradient carries over hue without spiraling")
    func oklchAchromaticHueCarryOver() {
        let gradient = ColorGradient(colors: [.purple, .white], colorSpace: .oklch)
        let startLab = ColorSpaceConverter.colorToOklab(.purple)
        let expectedHue = atan2(startLab.b, startLab.a)

        for step in 1..<10 {
            let position = Double(step) / 10.0
            let sampleLab = ColorSpaceConverter.colorToOklab(gradient.color(at: position))
            let sampleChroma = hypot(sampleLab.a, sampleLab.b)

            if sampleChroma > ColorSpaceConverter.ColorScience.achromaticChromaThreshold {
                let sampleHue = atan2(sampleLab.b, sampleLab.a)
                let hueDelta = abs(atan2(sin(sampleHue - expectedHue), cos(sampleHue - expectedHue)))
                #expect(hueDelta < 0.02)
            }
        }
    }

    @Test("Oklch chromatic gradient interpolates along polar hue arc instead of Cartesian Oklab")
    func oklchPolarVsOklabCartesian() {
        let oklchGradient = ColorGradient(colors: [.blue, .red], colorSpace: .oklch)
        let oklabGradient = ColorGradient(colors: [.blue, .red], colorSpace: .oklab)

        let oklchMidLab = ColorSpaceConverter.colorToOklab(oklchGradient.color(at: 0.5))
        let oklabMidLab = ColorSpaceConverter.colorToOklab(oklabGradient.color(at: 0.5))

        let oklchMidChroma = hypot(oklchMidLab.a, oklchMidLab.b)
        let oklabMidChroma = hypot(oklabMidLab.a, oklabMidLab.b)

        #expect(oklchMidChroma > oklabMidChroma + 0.05)
    }

    @Test("Oklch gradient resolves dynamic colors using the provided EnvironmentValues")
    func oklchEnvironmentAwareResolution() {
        let gradient = ColorGradient(colors: [.primary, .primary], colorSpace: .oklch)

        var lightEnvironment = EnvironmentValues()
        lightEnvironment.colorScheme = .light

        var darkEnvironment = EnvironmentValues()
        darkEnvironment.colorScheme = .dark

        let lightMidColor = gradient.color(at: 0.5, in: lightEnvironment)
        let darkMidColor = gradient.color(at: 0.5, in: darkEnvironment)

        let lightLab = ColorSpaceConverter.colorToOklab(lightMidColor, in: lightEnvironment)
        let darkLab = ColorSpaceConverter.colorToOklab(darkMidColor, in: darkEnvironment)

        #expect(lightLab.L < 0.2)
        #expect(darkLab.L > 0.8)
    }

    @Test("Oklab gradient resolves dynamic colors using the provided EnvironmentValues")
    func oklabEnvironmentAwareResolution() {
        let gradient = ColorGradient(colors: [.primary, .primary], colorSpace: .oklab)

        var lightEnvironment = EnvironmentValues()
        lightEnvironment.colorScheme = .light

        var darkEnvironment = EnvironmentValues()
        darkEnvironment.colorScheme = .dark

        let lightMidColor = gradient.color(at: 0.5, in: lightEnvironment)
        let darkMidColor = gradient.color(at: 0.5, in: darkEnvironment)

        let lightLab = ColorSpaceConverter.colorToOklab(lightMidColor, in: lightEnvironment)
        let darkLab = ColorSpaceConverter.colorToOklab(darkMidColor, in: darkEnvironment)

        #expect(lightLab.L < 0.2)
        #expect(darkLab.L > 0.8)
    }

    @Test("RGB gradient preserves wide-gamut colors in Display P3 and clamps in sRGB")
    func rgbGradientGamutClamping() {
        let p3Red = Color(.displayP3, red: 1.0, green: 0.0, blue: 0.0)
        let p3Green = Color(.displayP3, red: 0.0, green: 1.0, blue: 0.0)

        let p3Gradient = ColorGradient(colors: [p3Red, p3Green], colorSpace: .rgb)
        let sRGBGradient = ColorGradient(colors: [p3Red, p3Green], colorSpace: .rgb, gamut: .sRGB)

        #expect(p3Gradient.gamut == .displayP3)
        #expect(sRGBGradient.gamut == .sRGB)
        #expect(p3Gradient.color(at: 0.1).exceedsSRGB())
        #expect(sRGBGradient.color(at: 0.1).isWithinSRGB())
    }

    @Test(
        "Perceptual gradients preserve Display P3 gamut and clamp in sRGB",
        arguments: [
            (
                GradientColorSpace.oklab,
                Color(.displayP3, red: 0.0, green: 1.0, blue: 0.0),
                Color(.displayP3, red: 0.0, green: 1.0, blue: 1.0)
            ),
            (
                GradientColorSpace.oklch,
                Color(.displayP3, red: 1.0, green: 0.0, blue: 0.0),
                Color(.displayP3, red: 0.0, green: 1.0, blue: 0.0)
            ),
            (
                GradientColorSpace.oklch,
                Color(.displayP3, red: 0.0, green: 1.0, blue: 0.0),
                Color(.displayP3, red: 0.0, green: 1.0, blue: 1.0)
            ),
        ]
    )
    func perceptualGradientDisplayP3VsSRGB(
        colorSpace: GradientColorSpace,
        start: Color,
        end: Color
    ) {
        let p3Gradient = ColorGradient(colors: [start, end], colorSpace: colorSpace)
        let sRGBGradient = ColorGradient(colors: [start, end], colorSpace: colorSpace, gamut: .sRGB)

        let p3Color = p3Gradient.color(at: 0.5)
        let sRGBColor = sRGBGradient.color(at: 0.5)

        #expect(p3Gradient.gamut == .displayP3)
        #expect(sRGBGradient.gamut == .sRGB)
        #expect(p3Color.exceedsSRGB())
        #expect(sRGBColor.isWithinSRGB())
        #expect(p3Color.oklabChroma() > sRGBColor.oklabChroma())
    }
}
