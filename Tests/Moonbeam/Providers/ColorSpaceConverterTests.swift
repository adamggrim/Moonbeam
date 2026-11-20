import Testing
@testable import Moonbeam
import SwiftUI

@Suite struct ColorSpaceConverterTests {
    @Test("Oklch zero lightness resolves to black")
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

    @Test("Oklch maximum lightness resolves to white")
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

    @Test(
        "Oklch Display P3 clamping preserves a wider chroma than sRGB",
        arguments: [0.08, 0.4, 0.5]
    )
    func oklchExtremeChromaDisplayP3(hue: CGFloat) {
        let p3Color = ColorSpaceConverter.oklchToColor(
            lightness: 0.5,
            chroma: 1.5,
            hue: hue,
            gamut: .displayP3
        )
        let sRGBColor = ColorSpaceConverter.oklchToColor(
            lightness: 0.5,
            chroma: 1.5,
            hue: hue,
            gamut: .sRGB
        )

        #expect(p3Color.exceedsSRGB())
        #expect(sRGBColor.isWithinSRGB())
        #expect(p3Color.oklabChroma() > sRGBColor.oklabChroma())
    }

    @Test(
        "colorToOklab preserves wide-gamut Display P3 inputs without sRGB clipping",
        arguments: [
            (1.0, 0.0, 0.0),
            (0.0, 1.0, 0.0),
            (0.0, 0.0, 1.0),
        ]
    )
    func colorToOklabPreservesDisplayP3(red: Double, green: Double, blue: Double) {
        let p3Color = Color(.displayP3, red: red, green: green, blue: blue)
        let sRGBColor = Color(.sRGB, red: red, green: green, blue: blue)

        #expect(p3Color.exceedsSRGB())
        #expect(p3Color.oklabChroma() > sRGBColor.oklabChroma())
    }

    @Test(
        "HSB conversion emits Display P3 or sRGB colors based on gamut",
        arguments: [
            (0.0, 1.0, 0.0, 0.0),
            (1.0 / 3.0, 0.0, 1.0, 0.0),
            (2.0 / 3.0, 0.0, 0.0, 1.0),
        ]
    )
    func hsbToColorGamuts(hue: CGFloat, red: Double, green: Double, blue: Double) {
        let environment = EnvironmentValues()
        let p3Color = ColorSpaceConverter.hsbToColor(
            hue: hue,
            saturation: 1.0,
            brightness: 1.0,
            gamut: .displayP3
        )
        let sRGBColor = ColorSpaceConverter.hsbToColor(
            hue: hue,
            saturation: 1.0,
            brightness: 1.0,
            gamut: .sRGB
        )

        let expectedP3 = Color(.displayP3, red: red, green: green, blue: blue).resolve(in: environment)
        let resolvedP3 = p3Color.resolve(in: environment)

        #expect(abs(resolvedP3.red - expectedP3.red) < 0.0001)
        #expect(abs(resolvedP3.green - expectedP3.green) < 0.0001)
        #expect(abs(resolvedP3.blue - expectedP3.blue) < 0.0001)
        #expect(sRGBColor == Color(hue: Double(hue), saturation: 1.0, brightness: 1.0))
        #expect(p3Color.exceedsSRGB(in: environment))
        #expect(sRGBColor.isWithinSRGB(in: environment))
    }

    @Test(
        "Oklab interpolation preserves Display P3 gamut and clamps in sRGB",
        arguments: [
            (
                Color(.displayP3, red: 0.0, green: 1.0, blue: 0.0),
                Color(.displayP3, red: 0.0, green: 1.0, blue: 1.0),
                0.5
            ),
            (
                Color(.displayP3, red: 1.0, green: 0.0, blue: 0.0),
                Color(.displayP3, red: 0.0, green: 1.0, blue: 0.0),
                0.05
            ),
        ]
    )
    func interpolateOklabGamuts(start: Color, end: Color, position: Double) {
        let p3Color = ColorSpaceConverter.interpolateOklab(
            from: start,
            to: end,
            at: position,
            gamut: .displayP3
        )
        let sRGBColor = ColorSpaceConverter.interpolateOklab(
            from: start,
            to: end,
            at: position,
            gamut: .sRGB
        )

        #expect(p3Color.exceedsSRGB())
        #expect(sRGBColor.isWithinSRGB())
        #expect(p3Color.oklabChroma() > sRGBColor.oklabChroma())
    }

    @Test(
        "clampToSRGB clamps extended wide-gamut components to [0, 1]",
        arguments: [
            Color(.displayP3, red: 1.0, green: 0.0, blue: 0.0),
            Color(.displayP3, red: 0.0, green: 1.0, blue: 0.0),
            Color(.displayP3, red: 0.0, green: 0.0, blue: 1.0),
        ]
    )
    func clampToSRGBBounds(wideGamutColor: Color) {
        let clamped = ColorSpaceConverter.clampToSRGB(wideGamutColor)

        #expect(wideGamutColor.exceedsSRGB())
        #expect(clamped.isWithinSRGB())
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

    @Test("Oklch interpolation preserves lightness and interpolates opacity")
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
