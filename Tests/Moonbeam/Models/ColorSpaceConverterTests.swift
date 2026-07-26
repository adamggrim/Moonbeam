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

    @Test("OKLCH out-of-bounds chroma")
    func oklchExtremeChroma() {
        let color = ColorSpaceConverter.oklchToColor(lightness: 0.5, chroma: 1.5, hue: 0.5)
        #expect(color != .clear)
    }
}
