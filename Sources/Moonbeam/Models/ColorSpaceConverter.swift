import Foundation
import SwiftUI

/// A utility for handling color space conversions.
internal enum ColorSpaceConverter {
    /// Matrix to convert OKLCH to a linear RGB color.
    ///
    /// Taken from  "A perceptual color space for image processing" by Björn
    /// Ottosson (2020).
    ///
    /// - SeeAlso:
    /// https://bottosson.github.io/posts/oklab/
    internal static func oklchToColor(lightness: CGFloat, chroma: CGFloat, hue: CGFloat) -> Color {
        let hueAngle = hue * 2.0 * .pi
        let a = chroma * cos(hueAngle)
        let b = chroma * sin(hueAngle)

        let longPrime = lightness + 0.3963377774 * a + 0.2158037573 * b
        let mediumPrime = lightness - 0.1055613458 * a - 0.0638541728 * b
        let shortPrime = lightness - 0.0894841775 * a - 1.2914855480 * b

        let longCubed = longPrime < 0 ? -pow(-longPrime, 3.0) : pow(longPrime, 3.0)
        let mediumCubed = mediumPrime < 0 ? -pow(-mediumPrime, 3.0) : pow(mediumPrime, 3.0)
        let shortCubed = shortPrime < 0 ? -pow(-shortPrime, 3.0) : pow(shortPrime, 3.0)

        let redLinear =   4.0767416621 * longCubed - 3.3077115913 * mediumCubed + 0.2309699292 * shortCubed
        let greenLinear = -1.2684380046 * longCubed + 2.6097574011 * mediumCubed - 0.3413193965 * shortCubed
        let blueLinear = -0.0041960863 * longCubed - 0.7034186147 * mediumCubed + 1.7076147010 * shortCubed

        func applyGamma(_ value: CGFloat) -> CGFloat {
            return value <= 0.0031308 ? 12.92 * value : 1.055 * pow(value, 1.0 / 2.4) - 0.055
        }

        let red = min(max(applyGamma(redLinear), 0.0), 1.0)
        let green = min(max(applyGamma(greenLinear), 0.0), 1.0)
        let blue = min(max(applyGamma(blueLinear), 0.0), 1.0)

        return Color(red: red, green: green, blue: blue)
    }
}
