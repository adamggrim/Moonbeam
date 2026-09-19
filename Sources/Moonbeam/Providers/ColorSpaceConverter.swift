import Foundation
import SwiftUI

/// A utility for handling color space conversions.
internal enum ColorSpaceConverter {
    internal enum ColorScience {
        static let sRGBGammaThreshold: CGFloat = 0.0031308
        static let sRGBGammaScale: CGFloat = 12.92
        static let sRGBGammaOffset: CGFloat = 0.055
        static let sRGBGammaPower: CGFloat = 1.0 / 2.4

        static let oklabLMSMatrix = (
            m00: 0.3963377774, m01: 0.2158037573,
            m10: -0.1055613458, m11: -0.0638541728,
            m20: -0.0894841775, m21: -1.2914855480
        )

        static let oklabRGBMatrix = (
            m00: 4.0767416621, m01: -3.3077115913, m02: 0.2309699292,
            m10: -1.2684380046, m11: 2.6097574011, m12: -0.3413193965,
            m20: -0.0041960863, m21: -0.7034186147, m22: 1.7076147010
        )

        static let fullCircleRadians: CGFloat = 2.0 * .pi
            static let oklabPower: CGFloat = 3.0
    }

    /// Matrix to convert OKLCH to a linear RGB color.
    ///
    /// Taken from  "A perceptual color space for image processing" by Björn
    /// Ottosson (2020).
    ///
    /// - SeeAlso:
    /// https://bottosson.github.io/posts/oklab/
    internal static func oklchToColor(lightness: CGFloat, chroma: CGFloat, hue: CGFloat) -> Color {
        let hueAngle = hue * ColorScience.fullCircleRadians
        let a = chroma * cos(hueAngle)
        let b = chroma * sin(hueAngle)

        let longPrime = lightness + ColorScience.oklabLMSMatrix.m00 * a + ColorScience.oklabLMSMatrix.m01 * b
        let mediumPrime = lightness + ColorScience.oklabLMSMatrix.m10 * a + ColorScience.oklabLMSMatrix.m11 * b
        let shortPrime = lightness + ColorScience.oklabLMSMatrix.m20 * a + ColorScience.oklabLMSMatrix.m21 * b

        let longCubed = longPrime < 0
            ? -pow(-longPrime, ColorScience.oklabPower)
            : pow(longPrime, ColorScience.oklabPower)
        let mediumCubed = mediumPrime < 0
            ? -pow(-mediumPrime, ColorScience.oklabPower)
            : pow(mediumPrime, ColorScience.oklabPower)
        let shortCubed = shortPrime < 0
            ? -pow(-shortPrime, ColorScience.oklabPower)
            : pow(shortPrime, ColorScience.oklabPower)

        let redLinear = ColorScience.oklabRGBMatrix.m00 * longCubed
            + ColorScience.oklabRGBMatrix.m01 * mediumCubed
            + ColorScience.oklabRGBMatrix.m02 * shortCubed
        let greenLinear = ColorScience.oklabRGBMatrix.m10 * longCubed
            + ColorScience.oklabRGBMatrix.m11 * mediumCubed
            + ColorScience.oklabRGBMatrix.m12 * shortCubed
        let blueLinear = ColorScience.oklabRGBMatrix.m20 * longCubed
            + ColorScience.oklabRGBMatrix.m21 * mediumCubed
            + ColorScience.oklabRGBMatrix.m22 * shortCubed
        
        func applyGamma(_ value: CGFloat) -> CGFloat {
            return value <= ColorScience.sRGBGammaThreshold
                ? ColorScience.sRGBGammaScale * value
                : 1.055 * pow(value, ColorScience.sRGBGammaPower) - ColorScience.sRGBGammaOffset
        }

        let red = min(max(applyGamma(redLinear), 0.0), 1.0)
        let green = min(max(applyGamma(greenLinear), 0.0), 1.0)
        let blue = min(max(applyGamma(blueLinear), 0.0), 1.0)

        return Color(red: red, green: green, blue: blue)
    }
}
