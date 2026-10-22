import Foundation
import SwiftUI

/// A utility for handling color space conversions.
internal enum ColorSpaceConverter {
    internal enum ColorScience {
        static let sRGBGammaThreshold: CGFloat = 0.0031308
        static let sRGBLinearThreshold: CGFloat = 0.04045
        static let sRGBGammaScale: CGFloat = 12.92
        static let sRGBGammaOffset: CGFloat = 0.055
        static let sRGBGammaHighScale: CGFloat = 1.055
        static let sRGBGammaPower: CGFloat = 1.0 / 2.4
        static let sRGBInverseGammaPower: CGFloat = 2.4

        static let rgbToLMSMatrix = (
            m00: 0.4122214708, m01: 0.5363325363, m02: 0.0514459929,
            m10: 0.2119034982, m11: 0.6806995451, m12: 0.1073969566,
            m20: 0.0883024619, m21: 0.2817188376, m22: 0.6299787005
        )

        static let lmsToOklabMatrix = (
            m00: 0.2104542553, m01: 0.7936177850, m02: -0.0040720468,
            m10: 1.9779984951, m11: -2.4285922050, m12: 0.4505937099,
            m20: 0.0259040371, m21: 0.7827717662, m22: -0.8086757660
        )

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
        static let oklabCubeRootPower: CGFloat = 1.0 / 3.0
        static let achromaticChromaThreshold: CGFloat = 0.0001
        static let maxOklchChroma: CGFloat = 0.4
        static let gamutSearchIterations: Int = 16
    }

    /// Converts an sRGB `Color` into Oklab `(L, a, b)` coordinates and opacity.
    internal static func colorToOklab(
        _ color: Color,
        in environment: EnvironmentValues = EnvironmentValues()
    ) -> (L: CGFloat, a: CGFloat, b: CGFloat, opacity: CGFloat) {
        let resolved = color.resolve(in: environment)

        func sRGBToLinear(_ value: CGFloat) -> CGFloat {
            let clamped = min(max(value, 0.0), 1.0)
            return clamped <= ColorScience.sRGBLinearThreshold
                ? clamped / ColorScience.sRGBGammaScale
                : pow(
                    (clamped + ColorScience.sRGBGammaOffset) / ColorScience.sRGBGammaHighScale,
                    ColorScience.sRGBInverseGammaPower
                )
        }

        let redLinear = sRGBToLinear(CGFloat(resolved.red))
        let greenLinear = sRGBToLinear(CGFloat(resolved.green))
        let blueLinear = sRGBToLinear(CGFloat(resolved.blue))

        let l = ColorScience.rgbToLMSMatrix.m00 * redLinear
            + ColorScience.rgbToLMSMatrix.m01 * greenLinear
            + ColorScience.rgbToLMSMatrix.m02 * blueLinear
        let m = ColorScience.rgbToLMSMatrix.m10 * redLinear
            + ColorScience.rgbToLMSMatrix.m11 * greenLinear
            + ColorScience.rgbToLMSMatrix.m12 * blueLinear
        let s = ColorScience.rgbToLMSMatrix.m20 * redLinear
            + ColorScience.rgbToLMSMatrix.m21 * greenLinear
            + ColorScience.rgbToLMSMatrix.m22 * blueLinear

        let lPrime = l < 0 ? -pow(-l, ColorScience.oklabCubeRootPower) : pow(l, ColorScience.oklabCubeRootPower)
        let mPrime = m < 0 ? -pow(-m, ColorScience.oklabCubeRootPower) : pow(m, ColorScience.oklabCubeRootPower)
        let sPrime = s < 0 ? -pow(-s, ColorScience.oklabCubeRootPower) : pow(s, ColorScience.oklabCubeRootPower)

        let lightness = ColorScience.lmsToOklabMatrix.m00 * lPrime
            + ColorScience.lmsToOklabMatrix.m01 * mPrime
            + ColorScience.lmsToOklabMatrix.m02 * sPrime
        let a = ColorScience.lmsToOklabMatrix.m10 * lPrime
            + ColorScience.lmsToOklabMatrix.m11 * mPrime
            + ColorScience.lmsToOklabMatrix.m12 * sPrime
        let b = ColorScience.lmsToOklabMatrix.m20 * lPrime
            + ColorScience.lmsToOklabMatrix.m21 * mPrime
            + ColorScience.lmsToOklabMatrix.m22 * sPrime

        return (L: lightness, a: a, b: b, opacity: CGFloat(resolved.opacity))
    }

    /// Interpolates between two colors in the cylindrical Oklch color space
    /// using CSS Color 4 achromatic hue carry-over and gamut-mapped chroma
    /// clamping.
    internal static func interpolateOklch(
        from startColor: Color,
        to endColor: Color,
        at position: Double,
        in environment: EnvironmentValues = EnvironmentValues()
    ) -> Color {
        let t = CGFloat(min(max(position, 0.0), 1.0))
        let labStart = colorToOklab(startColor, in: environment)
        let labEnd = colorToOklab(endColor, in: environment)

        let cStart = hypot(labStart.a, labStart.b)
        var hStart = atan2(labStart.b, labStart.a)
        if hStart < 0.0 { hStart += ColorScience.fullCircleRadians }

        let cEnd = hypot(labEnd.a, labEnd.b)
        var hEnd = atan2(labEnd.b, labEnd.a)
        if hEnd < 0.0 { hEnd += ColorScience.fullCircleRadians }

        let startIsAchromatic = cStart < ColorScience.achromaticChromaThreshold
        let endIsAchromatic = cEnd < ColorScience.achromaticChromaThreshold

        if startIsAchromatic && endIsAchromatic {
            hStart = 0.0
            hEnd = 0.0
        } else if startIsAchromatic {
            hStart = hEnd
        } else if endIsAchromatic {
            hEnd = hStart
        } else {
            let hDelta = (hEnd - hStart) / ColorScience.fullCircleRadians
            if hDelta > 0.5 {
                hStart += ColorScience.fullCircleRadians
            } else if hDelta < -0.5 {
                hStart -= ColorScience.fullCircleRadians
            }
        }

        let lightness = labStart.L + (labEnd.L - labStart.L) * t
        let chroma = cStart + (cEnd - cStart) * t
        let hue = (hStart + (hEnd - hStart) * t) / ColorScience.fullCircleRadians
        let opacity = labStart.opacity + (labEnd.opacity - labStart.opacity) * t

        return oklchToColor(lightness: lightness, chroma: chroma, hue: hue).opacity(opacity)
    }

    private static func oklabToLinearRGB(
        lightness: CGFloat,
        a: CGFloat,
        b: CGFloat
    ) -> (red: CGFloat, green: CGFloat, blue: CGFloat) {
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

        return (red: redLinear, green: greenLinear, blue: blueLinear)
    }

    private static func isLinearRGBInGamut(_ linear: (red: CGFloat, green: CGFloat, blue: CGFloat)) -> Bool {
        linear.red >= 0.0 && linear.red <= 1.0
            && linear.green >= 0.0 && linear.green <= 1.0
            && linear.blue >= 0.0 && linear.blue <= 1.0
    }

    /// Converts an Oklch color to an sRGB `Color`, clamping chroma to the
    /// maximum in-gamut value at `(lightness, hue)` before channel clamping.
    ///
    /// Taken from "A perceptual color space for image processing" by Björn
    /// Ottosson (2020).
    ///
    /// - SeeAlso:
    /// https://bottosson.github.io/posts/oklab/
    internal static func oklchToColor(lightness: CGFloat, chroma: CGFloat, hue: CGFloat) -> Color {
        if lightness <= 0.0 { return Color(red: 0.0, green: 0.0, blue: 0.0) }
        if lightness >= 1.0 { return Color(red: 1.0, green: 1.0, blue: 1.0) }

        let hueAngle = hue * ColorScience.fullCircleRadians
        let cosH = cos(hueAngle)
        let sinH = sin(hueAngle)

        let clampedChroma = max(chroma, 0.0)
        var linear = oklabToLinearRGB(
            lightness: lightness,
            a: clampedChroma * cosH,
            b: clampedChroma * sinH
        )

        if !isLinearRGBInGamut(linear) {
            var low: CGFloat = 0.0
            var high: CGFloat = min(clampedChroma, ColorScience.maxOklchChroma)
            let achromaticLinear = pow(lightness, ColorScience.oklabPower)
            linear = (red: achromaticLinear, green: achromaticLinear, blue: achromaticLinear)

            for _ in 0..<ColorScience.gamutSearchIterations {
                let mid = 0.5 * (low + high)
                let candidate = oklabToLinearRGB(
                    lightness: lightness,
                    a: mid * cosH,
                    b: mid * sinH
                )
                if isLinearRGBInGamut(candidate) {
                    low = mid;
                    linear = candidate
                } else {
                    high = mid
                }
            }
        }

        func applyGamma(_ value: CGFloat) -> CGFloat {
            return value <= ColorScience.sRGBGammaThreshold
                ? ColorScience.sRGBGammaScale * value
                : 1.055 * pow(value, ColorScience.sRGBGammaPower) - ColorScience.sRGBGammaOffset
        }

        let red = min(max(applyGamma(linear.red), 0.0), 1.0)
        let green = min(max(applyGamma(linear.green), 0.0), 1.0)
        let blue = min(max(applyGamma(linear.blue), 0.0), 1.0)

        return Color(red: red, green: green, blue: blue)
    }
}
