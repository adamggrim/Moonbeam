import Testing
@testable import Moonbeam
import Foundation

@Suite struct SpectrumNameResolverTests {
    let strings: SpectrumAccessibilityStrings = {
        var strings = SpectrumAccessibilityStrings()
        strings.gray = "Grau, teurer Freund, ist alle Theorie"
        strings.black = "No light; but rather darkness visible"
        strings.white = "Hail holy light, offspring of Heaven first-born"
        strings.red = "ἦμος δ᾿ ἠριγένεια φάνη ῥοδοδάκτυλος Ἠώς"
        strings.cyan = "ψάμμῳ κυανέη· τοὺς δὲ χλωρὸν δέος ᾕρει"
        strings.format = "%1$@ %2$@"
        strings.dark = "Thou who didst waken from his summer dreams"
        strings.blue = "The blue Mediterranean, where he lay"
        strings.light = "Tasting of Flora"
        strings.green = "and the country green"
        return strings
    }()

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

    @Test("Resolving base hue names in HSB and Oklch")
    func baseHues() {
        let hsbRed = SpectrumNameResolver.name(
            hue: 0.0, primary: 0.6, secondary: 0.6, colorSpace: .hsb, strings: strings
        )
        #expect(hsbRed == strings.red)

        let hsbCyan = SpectrumNameResolver.name(
            hue: 0.5, primary: 0.6, secondary: 0.6, colorSpace: .hsb, strings: strings
        )
        #expect(hsbCyan == strings.cyan)

        // Pure sRGB red in Oklch sits at ~29.2° (hue ≈ 0.081).
        let oklchRed = SpectrumNameResolver.name(
            hue: 29.2 / 360.0, primary: 0.14, secondary: 0.63, colorSpace: .oklch, strings: strings
        )
        #expect(oklchRed == strings.red)

        // Pure sRGB cyan in Oklch sits at ~194.8° (hue ≈ 0.541).
        let oklchCyan = SpectrumNameResolver.name(
            hue: 194.8 / 360.0, primary: 0.14, secondary: 0.75, colorSpace: .oklch, strings: strings
        )
        #expect(oklchCyan == strings.cyan)
    }

    @Test("Resolving tone modifiers")
    func toneModifiers() {
        // HSB dark boundary: secondary < 0.3
        let darkBlue = SpectrumNameResolver.name(
            hue: 0.65, primary: 0.6, secondary: 0.2, colorSpace: .hsb, strings: strings
        )
        #expect(darkBlue == String(format: strings.format, strings.dark!, strings.blue))

        // Oklch light boundary: secondary > 0.8 && primary < 0.1
        let lightGreen = SpectrumNameResolver.name(
            hue: 0.35, primary: 0.05, secondary: 0.9, colorSpace: .oklch, strings: strings
        )
        #expect(lightGreen == String(format: strings.format, strings.light!, strings.green))
    }
}
