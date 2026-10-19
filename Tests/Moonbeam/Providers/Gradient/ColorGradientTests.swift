import Testing
@testable import Moonbeam
import SwiftUI

@Suite struct ColorGradientTests {
    @Test("Gradient interpolation resolving to a valid color")
    func gradientInterpolation() {
        let gradient = ColorGradient(startColor: .black, endColor: .white, colorSpace: .rgb)

        guard case .shader(_, let fallback) = gradient.colorSource else {
            Issue.record("Expected shader color source with a pure-Swift fallback.")
            return
        }

        let midColor = fallback(0.5)
        let expectedColor = Color.black.mix(with: .white, by: 0.5)

        #expect(midColor == expectedColor)
    }

    @Test("Property-based gradient interpolation across random bounds")
    func gradientInterpolationProperties() {
        let gradient = ColorGradient(startColor: .black, endColor: .white, colorSpace: .rgb)

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
        let gradient = ColorGradient(startColor: .purple, endColor: .white, colorSpace: .oklch)
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
        let oklchGradient = ColorGradient(startColor: .blue, endColor: .red, colorSpace: .oklch)
        let oklabGradient = ColorGradient(startColor: .blue, endColor: .red, colorSpace: .oklab)

        let oklchMidLab = ColorSpaceConverter.colorToOklab(oklchGradient.color(at: 0.5))
        let oklabMidLab = ColorSpaceConverter.colorToOklab(oklabGradient.color(at: 0.5))

        let oklchMidChroma = hypot(oklchMidLab.a, oklchMidLab.b)
        let oklabMidChroma = hypot(oklabMidLab.a, oklabMidLab.b)

        #expect(oklchMidChroma > oklabMidChroma + 0.05)
    }
}
