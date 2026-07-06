import SwiftUI

/// A model for generating a spectrum color for a given position, suitable for shaders.
internal struct SpectrumGenerator {
    
    /// Matrix to convert OKLCH to a Display P3 color.
    ///
    /// Taken from  "A perceptual color space for image processing" by Björn Ottosson (2020).
    ///
    /// - SeeAlso:
    /// https://bottosson.github.io/posts/oklab/
    private static func oklchToColor(lightness: CGFloat, chroma: CGFloat, hue: CGFloat) -> Color {
        let hueAngle = hue * 2.0 * .pi
        let a = chroma * cos(hueAngle)
        let b = chroma * sin(hueAngle)
        
        let lightnessPrime = lightness + 0.3963377774 * a + 0.2158037573 * b
        let mediumPrime = lightness - 0.1055613458 * a - 0.0638541728 * b
        let smallPrime = lightness - 0.0894841775 * a - 1.2914855480 * b
        
        let lightnessCubed = lightnessPrime < 0 ? -pow(-lightnessPrime, 3.0) : pow(lightnessPrime, 3.0)
        let mediumCubed = mediumPrime < 0 ? -pow(-mediumPrime, 3.0) : pow(mediumPrime, 3.0)
        let smallCubed = smallPrime < 0 ? -pow(-smallPrime, 3.0) : pow(smallPrime, 3.0)
        
        let redLinear =  2.7015367 * lightnessCubed - 1.6373796 * mediumCubed - 0.0641571 * smallCubed
        let greenLinear = -0.3150531 * lightnessCubed + 1.3415174 * mediumCubed - 0.0264643 * smallCubed
        let blueLinear =  0.0384799 * lightnessCubed - 0.0635483 * mediumCubed + 1.0250684 * smallCubed
        
        func applyGamma(_ value: CGFloat) -> CGFloat {
            return value <= 0.0031308 ? 12.92 * value : 1.055 * pow(value, 1.0 / 2.4) - 0.055
        }
        
        let red = min(max(applyGamma(redLinear), 0.0), 1.0)
        let green = min(max(applyGamma(greenLinear), 0.0), 1.0)
        let blue = min(max(applyGamma(blueLinear), 0.0), 1.0)
        
        return Color(.displayP3, red: red, green: green, blue: blue)
    }
    
    /// Calculates the color at a specific normalized position on the spectrum.
    ///
    /// This function re-implements the logic from `SpectrumSliderModel` to calculate a single
    /// color on-demand without pre-generating an array, making it suitable for use in
    /// a SwiftUI `Shader`.
    ///
    /// - Parameters:
    ///   - position: The normalized position (0.0 to 1.0) on the slider.
    ///   - startSections: An array of monochrome sections appearing before the hue spectrum.
    ///   - endSections: An array of monochrome sections appearing after the hue spectrum.
    ///   - startHue: The hue at the beginning of the hue section.
    ///   - endHue: The hue at the end of the hue section.
    ///   - primaryValue: The base primary value (saturation or chroma) applied to the hue spectrum.
    ///   - secondaryValue: The base secondary value (brightness or lightness) applied to the hue spectrum.
    ///   - colorSpace:Whether to use HSB or OKLCH as the color space.
    ///   - primaryBends: An optional array of `BendSection` objects to modify primary values across hue ranges.
    ///   - secondaryBends: An optional array of `BendSection` objects to modify secondary values across hue ranges.
    ///
    /// - Returns: A `SwiftUI.Color` representing the computed color at the provided position.
    static func color(
        at position: CGFloat,
        startSections: [MonochromeSection],
        endSections: [MonochromeSection],
        startHue: Double,
        endHue: Double,
        primaryValue: Double, // Saturation or Chroma
        secondaryValue: Double, // Brightness or Lightness
        colorSpace: SpectrumColorSpace,
        primaryBends: [BendSection]?,
        secondaryBends: [BendSection]?
    ) -> Color {
        
        let startWeight = startSections.reduce(0) { $0 + $1.weight }
        let hueWeight = abs(endHue - startHue)
        let endWeight = endSections.reduce(0) { $0 + $1.weight }
        let totalWeight = startWeight + hueWeight + endWeight
        
        guard totalWeight > 0 else { return .clear }
        
        let startBoundary = startWeight / totalWeight
        let hueBoundary = (startWeight + hueWeight) / totalWeight
        let clampedPosition = max(0.0, min(1.0, position))
        
        if clampedPosition < startBoundary {
            var cumulativeStart: CGFloat = 0.0
            for (index, section) in startSections.enumerated() {
                let sectionEnd = cumulativeStart + (section.weight / totalWeight)
                if clampedPosition < sectionEnd {
                    let relativePos = (clampedPosition - cumulativeStart) / (sectionEnd - cumulativeStart)
                    return (index == startSections.count - 1)
                    ? monoToHueColor(relativePosition: relativePos, isStart: true, monochromeSection: section, startHue: startHue, endHue: endHue, primaryValue: primaryValue, secondaryValue: secondaryValue, colorSpace: colorSpace, primaryBends: primaryBends, secondaryBends: secondaryBends)
                    : monoToMonoColor(relativePosition: relativePos, fromColor: section.color, toColor: startSections[index + 1].color, hue: startHue)
                }
                cumulativeStart = sectionEnd
            }
        } else if clampedPosition <= hueBoundary {
            let relativeHuePos = (hueBoundary > startBoundary) ? (clampedPosition - startBoundary) / (hueBoundary - startBoundary) : 0.0
            let currentHue = startHue + relativeHuePos * (endHue - startHue)
            
            let primary = calculateBendValue(hue: currentHue, defaultValue: primaryValue, bendSections: primaryBends, minHue: startHue)
            let secondary = calculateBendValue(hue: currentHue, defaultValue: secondaryValue, bendSections: secondaryBends, minHue: startHue)
            
            return colorSpace == .oklch
            ? oklchToColor(lightness: secondary, chroma: primary, hue: currentHue)
            : Color(hue: currentHue, saturation: primary, brightness: secondary)
        } else {
            var cumulativeEnd = hueBoundary
            for (index, section) in endSections.enumerated() {
                let sectionEnd = cumulativeEnd + (section.weight / totalWeight)
                if clampedPosition <= sectionEnd || (index == endSections.count - 1) {
                    let relativePos = min(1.0, max(0.0, (clampedPosition - cumulativeEnd) / (sectionEnd - cumulativeEnd)))
                    return (index == 0)
                    ? monoToHueColor(relativePosition: relativePos, isStart: false, monochromeSection: section, startHue: startHue, endHue: endHue, primaryValue: primaryValue, secondaryValue: secondaryValue, colorSpace: colorSpace, primaryBends: primaryBends, secondaryBends: secondaryBends)
                    : monoToMonoColor(relativePosition: relativePos, fromColor: endSections[index - 1].color, toColor: section.color, hue: endHue)
                }
                cumulativeEnd = sectionEnd
            }
        }
        return .clear
    }
    
    private static func monoToHueColor(
        relativePosition: CGFloat,
        isStart: Bool,
        monochromeSection: MonochromeSection,
        startHue: Double,
        endHue: Double,
        primaryValue: Double,
        secondaryValue: Double,
        colorSpace: SpectrumColorSpace,
        primaryBends: [BendSection]?,
        secondaryBends: [BendSection]?
    ) -> Color {
        let hue = isStart ? startHue : endHue
        let interpolationFactor = isStart ? relativePosition : (1.0 - relativePosition)
        
        var startTargetPrimary = primaryValue, startTargetSecondary = secondaryValue
        var endTargetPrimary = primaryValue, endTargetSecondary = secondaryValue
        
        if let primaryBends = primaryBends {
            for bend in primaryBends {
                if let oneWay = bend as? OneWayBend {
                    if oneWay.startHue == startHue { startTargetPrimary = oneWay.targetValue }
                    else if oneWay.endHue == endHue { endTargetPrimary = oneWay.targetValue }
                }
            }
        }
        
        if let secondaryBends = secondaryBends {
            for bend in secondaryBends {
                if let oneWay = bend as? OneWayBend {
                    if oneWay.startHue == startHue { startTargetSecondary = oneWay.targetValue }
                    else if oneWay.endHue == endHue { endTargetSecondary = oneWay.targetValue }
                }
            }
        }
        
        switch monochromeSection.color {
        case .black:
            let finalSecondary = interpolationFactor * (isStart ? startTargetSecondary : endTargetSecondary)
            return colorSpace == .oklch
            ? oklchToColor(lightness: finalSecondary, chroma: primaryValue, hue: hue)
            : Color(hue: hue, saturation: primaryValue, brightness: finalSecondary)
        case .white:
            let finalPrimary = interpolationFactor * (isStart ? startTargetPrimary : endTargetPrimary)
            let finalSecondary = colorSpace == .oklch ? 1.0 - (interpolationFactor * (1.0 - secondaryValue)) : secondaryValue
            return colorSpace == .oklch
            ? oklchToColor(lightness: finalSecondary, chroma: finalPrimary, hue: hue)
            : Color(hue: hue, saturation: finalPrimary, brightness: finalSecondary)
        }
    }
    
    /// Generates a smooth gradient between two monochrome sections.
    private static func monoToMonoColor(relativePosition: CGFloat, fromColor: MonochromeColor, toColor: MonochromeColor, hue: CGFloat) -> Color {
        let startBrightness: CGFloat = (fromColor == .white) ? 1.0 : 0.0
        let endBrightness: CGFloat = (toColor == .white) ? 1.0 : 0.0
        let brightness = startBrightness + (endBrightness - startBrightness) * relativePosition
        return oklchToColor(lightness: brightness, chroma: 0.0, hue: hue)
    }
    
    private static func calculateBendValue(hue: CGFloat, defaultValue: CGFloat, bendSections: [BendSection]?, minHue: Double) -> CGFloat {
        guard let bends = bendSections, let bend = bends.first(where: { min($0.startHue, $0.endHue) <= hue && hue <= max($0.startHue, $0.endHue) }) else { return defaultValue }
        
        let valueDelta = defaultValue - bend.targetValue
        let offset = hue - bend.startHue
        
        if let oneWay = bend as? OneWayBend {
            let valueIncrement = oneWay.hueCount != 0 ? (valueDelta / oneWay.hueCount) : 0
            if oneWay.startHue == minHue { return bend.targetValue + (valueIncrement * offset) }
            else { return defaultValue - (valueIncrement * offset) }
        } else if let twoWay = bend as? TwoWayBend {
            let position = (hue - twoWay.startHue) / twoWay.hueCount
            return defaultValue - (valueDelta * sin(position * .pi))
        }
        return defaultValue
    }
}
