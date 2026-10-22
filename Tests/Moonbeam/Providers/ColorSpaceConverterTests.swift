import Testing
@testable import Moonbeam
import SwiftUI

@Suite struct ColorSpaceConverterTests {
    @Test("Oklch zero lightness boundary")
    func oklchBlackBoundary() {
        let color = ColorSpaceConverter.oklchToColor(lightness: 0.0, chroma: 0.0, hue: 0.0)
        #expect(color == Color(red: 0, green: 0, blue: 0))
    }

    @Test("Oklch maximum lightness boundary")
    func oklchWhiteBoundary() {
        let color = ColorSpaceConverter.oklchToColor(lightness: 1.0, chroma: 0.0, hue: 0.0)
        #expect(color == Color(red: 1, green: 1, blue: 1))
    }

    @Test("Oklch out-of-bounds chroma clamping to valid RGB")
    func oklchExtremeChroma() throws {
        let color = ColorSpaceConverter.oklchToColor(lightness: 0.5, chroma: 1.5, hue: 0.5)

        let cgColor = try #require(color.cgColor)
        let components = try #require(cgColor.components)

        #expect(components.count >= 3)

        let red = components[0]
        let green = components[1]
        let blue = components[2]

        #expect(abs(red - 0.0) < 0.001) // Red reaches the 0.0 gamut boundary at C ≈ 0.0907.
        #expect(abs(green - (116.0 / 255.0)) < 0.01) // Green resolves to ~0.454, preserving L = 0.5.
        #expect(abs(blue - (101.0 / 255.0)) < 0.01) // Blue resolves to ~0.397, preserving L = 0.5.
    }

    @Test("Dynamic color resolution adapts to Light and Dark Mode environments")
    func colorToOklabEnvironmentResolution() {
        var lightEnvironment = EnvironmentValues()
        lightEnvironment.colorScheme = .light

        var darkEnvironment = EnvironmentValues()
        darkEnvironment.colorScheme = .dark

        let lightOklab = ColorSpaceConverter.colorToOklab(.primary, in: lightEnvironment)
        let darkOklab = ColorSpaceConverter.colorToOklab(.primary, in: darkEnvironment)

        #expect(lightOklab.L < 0.2)
        #expect(darkOklab.L > 0.8)
    }

    @Test("Oklch interpolation preserves unpremultiplied lightness and interpolates opacity")
    func interpolateOklchTranslucentColors() {
        let startColor = Color(red: 1.0, green: 0.0, blue: 0.0).opacity(0.2)
        let endColor = Color(red: 0.0, green: 0.0, blue: 1.0).opacity(0.8)

        let midTranslucent = ColorSpaceConverter.interpolateOklch(
            from: startColor,
            to: endColor,
            at: 0.5
        )
        let midOpaque = ColorSpaceConverter.interpolateOklch(
            from: Color(red: 1.0, green: 0.0, blue: 0.0),
            to: Color(red: 0.0, green: 0.0, blue: 1.0),
            at: 0.5
        )

        let translucentLab = ColorSpaceConverter.colorToOklab(midTranslucent)
        let opaqueLab = ColorSpaceConverter.colorToOklab(midOpaque)

        #expect(abs(translucentLab.opacity - 0.5) < 0.001)
        #expect(abs(translucentLab.L - opaqueLab.L) < 0.001)
        #expect(abs(translucentLab.a - opaqueLab.a) < 0.001)
        #expect(abs(translucentLab.b - opaqueLab.b) < 0.001)
    }
}
