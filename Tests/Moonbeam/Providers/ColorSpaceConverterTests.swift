import Testing
@testable import Moonbeam
import SwiftUI

@Suite struct ColorSpaceConverterTests {
    @Test("OKLCH zero lightness boundary")
    func oklchBlackBoundary() {
        let color = ColorSpaceConverter.oklchToColor(lightness: 0.0, chroma: 0.0, hue: 0.0)
        #expect(color == Color(red: 0, green: 0, blue: 0))
    }

    @Test("OKLCH maximum lightness boundary")
    func oklchWhiteBoundary() {
        let color = ColorSpaceConverter.oklchToColor(lightness: 1.0, chroma: 0.0, hue: 0.0)
        #expect(color == Color(red: 1, green: 1, blue: 1))
    }

    @Test("OKLCH out-of-bounds chroma clamping to valid RGB")
    func oklchExtremeChroma() throws {
        let color = ColorSpaceConverter.oklchToColor(lightness: 0.5, chroma: 1.5, hue: 0.5)

        let cgColor = try #require(color.cgColor)
        let components = try #require(cgColor.components)

        #expect(components.count >= 3)

        let red = components[0]
        let green = components[1]
        let blue = components[2]

        #expect(abs(red - 0.0) < 0.001) // Red resolves to 0.0.
        #expect(abs(green - (212.0 / 255.0)) < 0.01) // Green resolves to ~0.831.
        #expect(abs(blue - (133.0 / 255.0)) < 0.01) // Blue resolves to ~0.521.
    }
}
