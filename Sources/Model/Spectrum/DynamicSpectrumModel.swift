import SwiftUI

/// A model for generating a spectrum color for a given position, suitable for shaders.
struct SpectrumGenerator {

    private struct InvalidBendSectionError: Error {}

    /**
     Calculates the color at a specific normalized position on the spectrum.
     
     This function re-implements the logic from `SpectrumSliderModel` to calculate a single
     color on-demand without pre-generating an array, making it suitable for use in
     a SwiftUI `Shader`.
     
     - Parameters:
     - position: The normalized position (0.0 to 1.0) on the slider.
     - minHue: The minimum hue of the main color spectrum.
     - maxHue: The maximum hue of the main color spectrum.
     - blackSection: An optional configuration for a black monochrome section.
     - whiteSection: An optional configuration for a white monochrome section.
     - bendSections: An optional array of sections that modify saturation/brightness.
     - priorityColor: An optional monochrome color to place first if both black and white sections exist at the same end.
     - baseSaturation: The saturation for areas with no bends.
     - baseBrightness: The brightness for areas with no bends.
     - Returns: A `SwiftUI.Color` for the specified position.
     */
    static func color(
        at position: CGFloat,
        startSections: [MonochromeSection],
        endSections: [MonochromeSection],
        hueSection: HueSection
    ) -> Color {
        
        let startCount = startSections.reduce(0) { $0 + $1.count }
        let hueCount = hueSection.count
        let endCount = endSections.reduce(0) { $0 + $1.count }
        let totalCount = startCount + hueCount + endCount

        guard totalCount > 0 else {
            return .clear
        }

        let startBoundary = startCount / totalCount
        let hueBoundary = (startCount + hueCount) / totalCount
        let clampedPosition = max(0.0, min(1.0, position))

        if clampedPosition < startBoundary {
            var cumulativeStart: CGFloat = 0.0
            for (index, section) in startSections.enumerated() {
                let sectionEnd = cumulativeStart + (section.count / totalCount)
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
            let currentHue = hueSection.minHue + relativeHuePos * (hueSection.maxHue - hueSection.minHue)

            let saturation = (try? calculateBendValue(hue: currentHue, defaultValue: hueSection.baseSaturation, bendSections: hueSection.bendSections, bendableComponent: .saturation, hueSection: hueSection)) ?? hueSection.baseSaturation
            let brightness = (try? calculateBendValue(hue: currentHue, defaultValue: hueSection.baseBrightness, bendSections: hueSection.bendSections, bendableComponent: .brightness, hueSection: hueSection)) ?? hueSection.baseBrightness

            return Color(hue: currentHue, saturation: saturation, brightness: brightness)

        } else {
            var cumulativeEnd = hueBoundary
            for (index, section) in endSections.enumerated() {
                let sectionEnd = cumulativeEnd + (section.count / totalCount)
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

        var startTargetSat = hueSection.baseSaturation, startTargetBright = hueSection.baseBrightness
        var endTargetSat = hueSection.baseSaturation, endTargetBright = hueSection.baseBrightness

        if let bends = hueSection.bendSections {
            for bend in bends {
                if let oneWay = bend as? OneWayBend {
                    if oneWay.startHue == hueSection.minHue {
                        startTargetSat = oneWay.targetSaturation
                        startTargetBright = oneWay.targetBrightness
                    } else if oneWay.endHue == hueSection.maxHue {
                        endTargetSat = oneWay.targetSaturation
                        endTargetBright = oneWay.targetBrightness
                    }
                }
            }
        }

        switch monochromeSection.color {
        case .black:
            let targetBrightness = isStart ? startTargetBright : endTargetBright
            let finalBrightness = interpolationFactor * targetBrightness
            return Color(hue: hue, saturation: hueSection.baseSaturation, brightness: finalBrightness)
        case .white:
            let targetSaturation = isStart ? startTargetSat : endTargetSat
            let finalSaturation = interpolationFactor * targetSaturation
            return Color(hue: hue, saturation: finalSaturation, brightness: hueSection.baseBrightness)
        }
    }

    /// Generates a smooth gradient directly between two monochrome sections.
    private static func monoToMonoColor(relativePosition: CGFloat, fromColor: MonochromeColor, toColor: MonochromeColor, hue: CGFloat) -> Color {
        let startBrightness: CGFloat = (fromColor == .white) ? 1.0 : 0.0
        let endBrightness: CGFloat = (toColor == .white) ? 1.0 : 0.0
        
        let brightness = startBrightness + (endBrightness - startBrightness) * relativePosition
        return Color(hue: hue, saturation: 0.0, brightness: brightness)
    }

    private static func validateBendSections(bendSections: [BendSection]) -> Bool {
        guard bendSections.count > 1 else { return true }
        let sorted = bendSections.sorted { $0.startHue < $1.startHue }
        for (current, next) in zip(sorted, sorted.dropFirst()) {
            if current.endHue > next.startHue { return false }
        }
        return true
    }

    private static func calculateBendValue(
        hue: CGFloat,
        defaultValue: CGFloat,
        bendSections: [BendSection]?,
        bendableComponent: BendableComponent,
        hueSection: HueSection
    ) throws -> CGFloat {
        guard let bends = bendSections, !bends.isEmpty else { return defaultValue }
        guard validateBendSections(bendSections: bends) else { throw InvalidBendSectionError() }
        guard let bend = bends.first(where: { $0.startHue <= hue && hue <= $0.endHue }) else { return defaultValue }

        let targetValue = bendableComponent == .saturation ? bend.targetSaturation : bend.targetBrightness
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
