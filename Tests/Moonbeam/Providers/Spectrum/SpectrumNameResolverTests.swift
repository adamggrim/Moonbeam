import Testing
@testable import Moonbeam
import Foundation

@Suite struct SpectrumNameResolverTests {
    let strings = SpectrumAccessibilityStrings()

    @Test("Resolving pure gray in HSB")
    func hsbGray() {
        // Gray threshold: primary < 0.05
        let name = SpectrumNameResolver.name(
            hue: 0.0, primary: 0.0, secondary: 0.5, colorSpace: .hsb, strings: strings
        )
        #expect(name == strings.gray)
    }

    @Test("Resolving black and white boundaries")
    func blackAndWhite() {
        let black = SpectrumNameResolver.name(
            hue: 0.0, primary: 0.0, secondary: 0.1, colorSpace: .hsb, strings: strings
        )
        #expect(black == strings.black)

        let white = SpectrumNameResolver.name(
            hue: 0.0, primary: 0.0, secondary: 0.9, colorSpace: .hsb, strings: strings
        )
        #expect(white == strings.white)
    }

    @Test("Resolving base hue names")
    func baseHues() {
        let red = SpectrumNameResolver.name(
            hue: 0.0, primary: 0.6, secondary: 0.6, colorSpace: .hsb, strings: strings
        )
        #expect(red == strings.red)

        let cyan = SpectrumNameResolver.name(
            hue: 0.5, primary: 0.6, secondary: 0.6, colorSpace: .hsb, strings: strings
        )
        #expect(cyan == strings.cyan)
    }

    @Test("Resolving combined adjectives")
    func adjectives() {
        // HSB dark boundary: secondary < 0.3
        let darkBlue = SpectrumNameResolver.name(
            hue: 0.65, primary: 0.6, secondary: 0.2, colorSpace: .hsb, strings: strings
        )
        #expect(darkBlue == String(format: strings.format, strings.dark, strings.blue))

        // OKLCH pale boundary: secondary > 0.8 && primary < 0.1
        let paleGreen = SpectrumNameResolver.name(
            hue: 0.35, primary: 0.05, secondary: 0.9, colorSpace: .oklch, strings: strings
        )
        #expect(paleGreen == String(format: strings.format, strings.pale, strings.green))
    }
}
