import Testing
@testable import Moonbeam
import SwiftUI

@Suite struct ColorSpaceConverterTests {
    @Test("Oklch zero lightness boundary")
    func oklchBlackBoundary() {
        let p3Color = ColorSpaceConverter.oklchToColor(lightness: 0.0, chroma: 0.0, hue: 0.0)
        #expect(p3Color == Color(.displayP3, red: 0, green: 0, blue: 0))

        let sRGBColor = ColorSpaceConverter.oklchToColor(
            lightness: 0.0,
            chroma: 0.0,
            hue: 0.0,
            gamut: .sRGB
        )
        #expect(sRGBColor == Color(.sRGB, red: 0, green: 0, blue: 0))
    }

    @Test("Oklch maximum lightness boundary")
    func oklchWhiteBoundary() {
        let p3Color = ColorSpaceConverter.oklchToColor(lightness: 1.0, chroma: 0.0, hue: 0.0)
        #expect(p3Color == Color(.displayP3, red: 1, green: 1, blue: 1))

        let sRGBColor = ColorSpaceConverter.oklchToColor(
            lightness: 1.0,
            chroma: 0.0,
            hue: 0.0,
            gamut: .sRGB
        )
        #expect(sRGBColor == Color(.sRGB, red: 1, green: 1, blue: 1))
    }

    @Test("Oklch out-of-bounds chroma clamps to valid sRGB")
    func oklchExtremeChromaSRGB() throws {
        let color = ColorSpaceConverter.oklchToColor(
            lightness: 0.5,
            chroma: 1.5,
            hue: 0.5,
            gamut: .sRGB
        )

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

    @Test("Oklch Display P3 clamping preserves wider chroma than sRGB")
    func oklchExtremeChromaDisplayP3() {
        let p3Color = ColorSpaceConverter.oklchToColor(
            lightness: 0.5,
            chroma: 1.5,
            hue: 0.5,
            gamut: .displayP3
        )
        let sRGBColor = ColorSpaceConverter.oklchToColor(
            lightness: 0.5,
            chroma: 1.5,
            hue: 0.5,
            gamut: .sRGB
        )

        let p3Lab = ColorSpaceConverter.colorToOklab(p3Color)
        let sRGBLab = ColorSpaceConverter.colorToOklab(sRGBColor)
        let p3Chroma = hypot(p3Lab.a, p3Lab.b)
        let sRGBChroma = hypot(sRGBLab.a, sRGBLab.b)

        #expect(p3Chroma > sRGBChroma + 0.02)

        let resolvedP3 = p3Color.resolve(in: EnvironmentValues())
        #expect(resolvedP3.red < 0.0)
    }

    @Test("colorToOklab preserves wide-gamut Display P3 inputs without sRGB clipping")
    func colorToOklabPreservesDisplayP3() {
        let p3Red = Color(.displayP3, red: 1.0, green: 0.0, blue: 0.0)
        let sRGBRed = Color(.sRGB, red: 1.0, green: 0.0, blue: 0.0)

        let p3Lab = ColorSpaceConverter.colorToOklab(p3Red)
        let sRGBLab = ColorSpaceConverter.colorToOklab(sRGBRed)

        let p3Chroma = hypot(p3Lab.a, p3Lab.b)
        let sRGBChroma = hypot(sRGBLab.a, sRGBLab.b)

        #expect(p3Chroma > sRGBChroma + 0.03)
    }

    @Test("HSB conversion emits Display P3 or sRGB colors based on gamut")
    func hsbToColorGamuts() {
        let p3Red = ColorSpaceConverter.hsbToColor(
            hue: 0.0,
            saturation: 1.0,
            brightness: 1.0,
            gamut: .displayP3
        )
        let sRGBRed = ColorSpaceConverter.hsbToColor(
            hue: 0.0,
            saturation: 1.0,
            brightness: 1.0,
            gamut: .sRGB
        )

        #expect(p3Red == Color(.displayP3, red: 1.0, green: 0.0, blue: 0.0))
        #expect(sRGBRed == Color(hue: 0.0, saturation: 1.0, brightness: 1.0))

        let resolvedP3 = p3Red.resolve(in: EnvironmentValues())
        #expect(resolvedP3.red > 1.0)
    }

    @Test("Oklab interpolation preserves Display P3 chroma and clamps in sRGB")
    func interpolateOklabGamuts() {
        let p3Red = Color(.displayP3, red: 1.0, green: 0.0, blue: 0.0)
        let p3Green = Color(.displayP3, red: 0.0, green: 1.0, blue: 0.0)

        let p3Mid = ColorSpaceConverter.interpolateOklab(
            from: p3Red,
            to: p3Green,
            at: 0.05,
            gamut: .displayP3
        )
        let sRGBMid = ColorSpaceConverter.interpolateOklab(
            from: p3Red,
            to: p3Green,
            at: 0.05,
            gamut: .sRGB
        )

        let p3Lab = ColorSpaceConverter.colorToOklab(p3Mid)
        let sRGBLab = ColorSpaceConverter.colorToOklab(sRGBMid)

        #expect(hypot(p3Lab.a, p3Lab.b) > hypot(sRGBLab.a, sRGBLab.b) + 0.02)
    }

    @Test("clampToSRGB clamps extended wide-gamut components to [0, 1]")
    func clampToSRGBBounds() {
        let p3Red = Color(.displayP3, red: 1.0, green: 0.0, blue: 0.0)
        let clamped = ColorSpaceConverter.clampToSRGB(p3Red)
        let resolved = clamped.resolve(in: EnvironmentValues())

        #expect(resolved.red >= 0.0 && resolved.red <= 1.0)
        #expect(resolved.green >= 0.0 && resolved.green <= 1.0)
        #expect(resolved.blue >= 0.0 && resolved.blue <= 1.0)
    }

    @Test("Dynamic color resolution adapts to light and dark mode environments")
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
