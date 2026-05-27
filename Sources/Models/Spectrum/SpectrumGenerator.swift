import SwiftUI

/// A model for generating a spectrum color for a given position, suitable for shaders.
struct SpectrumGenerator {
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
    ///   - minHue: The minimum hue of the main color spectrum.
    ///   - maxHue: The maximum hue of the main color spectrum.
    ///   - blackSection: An optional configuration for a black monochrome section.
    ///   - whiteSection: An optional configuration for a white monochrome section.
    ///   - bendSections: An optional array of sections that modify saturation/brightness.
    ///   - priorityColor: An optional monochrome color to place first if both black and white sections exist at the same end.
    ///   - baseSaturation: The saturation for areas with no bends.
    ///   - baseBrightness: The brightness for areas with no bends.
    ///   - Returns: A `SwiftUI.Color` for the specified position.
    static func color(
        at position: CGFloat,
        startSections: [MonochromeSection],
        endSections: [MonochromeSection],
        hueSection: HueSection
    ) -> Color {
        
        let startWeight = startSections.reduce(0) { $0 + $1.weight }
        let hueWeight = hueSection.weight
        let endWeight = endSections.reduce(0) { $0 + $1.weight }
        let totalWeight = startWeight + hueWeight + endWeight

        guard totalWeight > 0 else {
            return .clear
        }

        let startBoundary = startWeight / totalWeight
        let hueBoundary = (startWeight + hueWeight) / totalWeight
        let clampedPosition = max(0.0, min(1.0, position))
        
        if clampedPosition < startBoundary {
            var cumulativeStart: CGFloat = 0.0
            for (index, section) in startSections.enumerated() {
                let sectionEnd = cumulativeStart + (section.weight / totalWeight)
                if clampedPosition < sectionEnd {
                    let relativePos = (clampedPosition - cumulativeStart) / (sectionEnd - cumulativeStart)
                    let isLastStartSection = (index == startSections.count - 1)

                    return isLastStartSection
                        ? monoToHueColor(relativePosition: relativePos, isStart: true, monochromeSection: section, hueSection: hueSection)
                        : monoToMonoColor(relativePosition: relativePos, fromColor: section.color, toColor: startSections[index + 1].color, hue: hueSection.minHue)
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
                let isLastSection = (index == endSections.count - 1)

                if clampedPosition <= sectionEnd || isLastSection {
                    let relativePos = (clampedPosition - cumulativeEnd) / (sectionEnd - cumulativeEnd)
                    let clampedRelativePos = min(1.0, max(0.0, relativePos))
                    let isFirstEndSection = (index == 0)

                    return isFirstEndSection
                        ? monoToHueColor(relativePosition: clampedRelativePos, isStart: false, monochromeSection: section, hueSection: hueSection)
                        : monoToMonoColor(relativePosition: clampedRelativePos, fromColor: endSections[index - 1].color, toColor: section.color, hue: hueSection.maxHue)
                }
                cumulativeEnd = sectionEnd
            }
        }
        return .clear
    }

    // MARK: - Private Helper Functions

    private static func monoToHueColor(relativePosition: CGFloat, isStart: Bool, monochromeSection: MonochromeSection, hueSection: HueSection) -> Color {
        let hue = isStart ? hueSection.minHue : hueSection.maxHue
        let interpolationFactor = isStart ? relativePosition : (1.0 - relativePosition)

        var startTargetPrimary = hueSection.primaryValue, startTargetSecondary = hueSection.secondaryValue
        var endTargetPrimary = hueSection.primaryValue, endTargetSecondary = hueSection.secondaryValue

        if let primaryBends = hueSection.primaryBends {
        
        
            for bend in primaryBends {
                if let oneWay = bend as? OneWayBend {
                    if oneWay.startHue == hueSection.minHue { startTargetPrimary = oneWay.targetValue }
                    else if oneWay.endHue == hueSection.maxHue { endTargetPrimary = oneWay.targetValue }
                }
            }
        }
        
        if let secondaryBends = hueSection.secondaryBends {
            for bend in secondaryBends {
                if let oneWay = bend as? OneWayBend {
                    if oneWay.startHue == hueSection.minHue { startTargetSecondary = oneWay.targetValue }
                    else if oneWay.endHue == hueSection.maxHue { endTargetSecondary = oneWay.targetValue }
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

    private static func calculateBendValue(
            hue: CGFloat,
            defaultValue: CGFloat,
            bendSections: [BendSection]?,
            hueSection: HueSection
        ) -> CGFloat {
            guard let bends = bendSections, !bends.isEmpty else { return defaultValue }
            guard let bend = bends.first(where: { $0.startHue <= hue && hue <= $0.endHue }) else { return defaultValue }

        let targetValue = bend.targetValue
        let valueDelta = defaultValue - targetValue
        let offset = hue - bend.startHue
        
        if let oneWay = bend as? OneWayBend {
            let valueIncrement = oneWay.hueCount != 0 ? (valueDelta / oneWay.hueCount) : 0

            if oneWay.startHue == hueSection.minHue {
                return targetValue + (valueIncrement * offset)
            } else {
                let numIncrements = valueIncrement * offset
                return defaultValue - numIncrements
            }
        } else if let twoWay = bend as? TwoWayBend {
            let position = (hue - twoWay.startHue) / twoWay.hueCount
            let curveProgress = sin(position * .pi)

            return defaultValue - (valueDelta * curveProgress)
        }
        return defaultValue
    }
}
