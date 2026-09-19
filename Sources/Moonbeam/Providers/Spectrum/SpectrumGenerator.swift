import SwiftUI

/// A configuration for the static properties of a spectrum.
internal struct SpectrumConfiguration {
    /// Whether to use the HSB or OKLCH color space.
    let colorSpace: SpectrumColorSpace
    /// An array of monochrome sections appearing before the hue spectrum.
    let startSections: [MonochromeSection]
    /// An array of monochrome sections appearing after the hue spectrum.
    let endSections: [MonochromeSection]
    /// The hue at the beginning of the hue section.
    let startHue: Double
    /// The hue at the end of the hue section.
    let endHue: Double
    /// The base primary value (saturation or chroma) applied to the hue
    /// spectrum.
    let primaryValue: Double
    /// The base secondary value (brightness or lightness) applied to the hue
    /// spectrum.
    let secondaryValue: Double
    /// An optional array of `BendSection` objects to modify primary values
    /// across hue ranges.
    let primaryBends: [BendSection]?
    /// An optional array of `BendSection` objects to modify secondary values
    /// across hue ranges.
    let secondaryBends: [BendSection]?
}

/// A utility for generating a spectrum color for a given position, suitable for
/// shaders.
internal struct SpectrumGenerator {

    // MARK: - Core generator

    /// Calculates the color at a specific normalized position on the spectrum.
    ///
    /// - Parameters:
    ///   - position: The normalized position (0.0 to 1.0) on the slider.
    ///   - configuration: The static properties of a spectrum.
    ///
    /// - Returns: A `SwiftUI.Color` representing the computed color at the
    ///   provided position.
    static func color(
        at position: Double,
        configuration: SpectrumConfiguration
    ) -> Color {
        guard let comps = components(
            at: position,
            configuration: configuration
        ) else { return .clear }

        return configuration.colorSpace == .oklch
            ? ColorSpaceConverter.oklchToColor(lightness: comps.secondary, chroma: comps.primary, hue: comps.hue)
            : Color(hue: comps.hue, saturation: comps.primary, brightness: comps.secondary)
    }

    static func components(
        at position: Double,
        configuration: SpectrumConfiguration
    ) -> (hue: Double, primary: Double, secondary: Double)? {
        // Map to local variables to minimize changes to existing internal math.
        let startSections = configuration.startSections
        let endSections = configuration.endSections
        let startHue = configuration.startHue
        let endHue = configuration.endHue
        let primaryValue = configuration.primaryValue
        let secondaryValue = configuration.secondaryValue
        let colorSpace = configuration.colorSpace
        let primaryBends = configuration.primaryBends
        let secondaryBends = configuration.secondaryBends

        let startWeight = startSections.reduce(0) { $0 + $1.weight }
        let hueWeight = abs(endHue - startHue)
        let endWeight = endSections.reduce(0) { $0 + $1.weight }
        let totalWeight = startWeight + hueWeight + endWeight

        guard totalWeight > 0 else { return nil }

        let startBoundary = startWeight / totalWeight
        let hueBoundary = (startWeight + hueWeight) / totalWeight
        let clampedPosition = max(0.0, min(1.0, position))

        if clampedPosition < startBoundary {
            var cumulativeStart: Double = 0.0
            for (index, section) in startSections.enumerated() {
                let sectionEnd = cumulativeStart + (section.weight / totalWeight)
                if clampedPosition < sectionEnd {
                    let relativePosition = (clampedPosition - cumulativeStart) / (sectionEnd - cumulativeStart)
                    if index == startSections.count - 1 {
                        return monochromeToHueColor(
                            relativePosition: relativePosition,
                            isStart: true,
                            monochromeSection: section,
                            configuration: configuration
                        )
                    } else {
                        return monochromeToMonochromeColor(
                            relativePosition: relativePosition,
                            fromSection: section,
                            toSection: startSections[index + 1],
                            hue: startHue
                        )
                    }
                }
                cumulativeStart = sectionEnd
            }
        } else if clampedPosition <= hueBoundary {
            let relativeHuePos = (hueBoundary > startBoundary)
                ? (clampedPosition - startBoundary) / (hueBoundary - startBoundary)
                : 0.0
            let currentHue = startHue + relativeHuePos * (endHue - startHue)

            let primary = calculateBendValue(
                hue: currentHue,
                defaultValue: primaryValue,
                bendSections: primaryBends,
                minHue: startHue
            )
            let secondary = calculateBendValue(
                hue: currentHue,
                defaultValue: secondaryValue,
                bendSections: secondaryBends,
                minHue: startHue
            )

            return (hue: currentHue, primary: primary, secondary: secondary)
        } else {
            var cumulativeEnd = hueBoundary
            for (index, section) in endSections.enumerated() {
                let sectionEnd = cumulativeEnd + (section.weight / totalWeight)
                if clampedPosition <= sectionEnd || (index == endSections.count - 1) {
                    let sectionProgress = (clampedPosition - cumulativeEnd) / (sectionEnd - cumulativeEnd)
                    let relativePosition = min(1.0, max(0.0, sectionProgress))
                    if index == 0 {
                        return monochromeToHueColor(
                            relativePosition: relativePosition,
                            isStart: false,
                            monochromeSection: section,
                            configuration: configuration
                        )
                    } else {
                        return monochromeToMonochromeColor(
                            relativePosition: relativePosition,
                            fromSection: endSections[index - 1],
                            toSection: section,
                            hue: endHue
                        )
                    }
                }
                cumulativeEnd = sectionEnd
            }
        }
        return nil
    }

    // MARK: - Private helpers

    private static func monochromeToHueColor(
        relativePosition: Double,
        isStart: Bool,
        monochromeSection: MonochromeSection,
        configuration: SpectrumConfiguration
    ) -> (hue: Double, primary: Double, secondary: Double) {
        let startHue = configuration.startHue
        let endHue = configuration.endHue
        let primaryValue = configuration.primaryValue
        let secondaryValue = configuration.secondaryValue
        let colorSpace = configuration.colorSpace
        let primaryBends = configuration.primaryBends
        let secondaryBends = configuration.secondaryBends

        let hue = isStart ? startHue : endHue
        let linearFactor = isStart ? relativePosition : (1.0 - relativePosition)

        let interpolationFactor: Double
        switch monochromeSection.easing {
        case .linear:
            interpolationFactor = linearFactor
        case .cubic:
            interpolationFactor = linearFactor * linearFactor * (3.0 - 2.0 * linearFactor)
        }

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
            let finalSecondaryValue = interpolationFactor * (isStart ? startTargetSecondary : endTargetSecondary)
            let finalPrimaryValue = isStart ? startTargetPrimary : endTargetPrimary
            return (hue: hue, primary: finalPrimaryValue, secondary: finalSecondaryValue)
        case .white:
            let finalPrimaryValue = interpolationFactor * (isStart ? startTargetPrimary : endTargetPrimary)
            let finalTargetSecondary = isStart ? startTargetSecondary : endTargetSecondary
            let finalSecondaryValue = colorSpace == .oklch
                ? 1.0 - (interpolationFactor * (1.0 - finalTargetSecondary))
                : finalTargetSecondary
            return (hue: hue, primary: finalPrimaryValue, secondary: finalSecondaryValue)
        }
    }

    /// Generates a smooth gradient between two monochrome sections.
    private static func monochromeToMonochromeColor(
        relativePosition: Double,
        fromSection: MonochromeSection,
        toSection: MonochromeSection,
        hue: Double
    ) -> (hue: Double, primary: Double, secondary: Double) {
        let startBrightness: Double = (fromSection.color == .white) ? 1.0 : 0.0
        let endBrightness: Double = (toSection.color == .white) ? 1.0 : 0.0

        let curveProgress: Double
        switch toSection.easing {
        case .linear:
            curveProgress = relativePosition
        case .cubic:
            curveProgress = relativePosition * relativePosition * (3.0 - 2.0 * relativePosition)
        }

        let brightness = startBrightness + (endBrightness - startBrightness) * curveProgress
        return (hue: hue, primary: 0.0, secondary: brightness)
    }

    private static func calculateBendValue(
        hue: Double,
        defaultValue: Double,
        bendSections: [BendSection]?,
        minHue: Double
    ) -> Double {
        guard let bends = bendSections,
              let bend = bends.first(where: {
                  min($0.startHue, $0.endHue) <= hue && hue <= max($0.startHue, $0.endHue)
              })
        else {
            return defaultValue
        }

        let valueDelta = defaultValue - bend.targetValue
        let offset = hue - bend.startHue

        if let oneWay = bend as? OneWayBend {
            let position = oneWay.hueCount != 0 ? (offset / oneWay.hueCount) : 0
            let curveProgress: Double
            switch oneWay.easing {
            case .linear:
                curveProgress = position
            case .cubic:
                curveProgress = position * position * (3.0 - 2.0 * position)
            }

            if oneWay.startHue == minHue {
                return bend.targetValue + (valueDelta * curveProgress)
            } else {
                return defaultValue - (valueDelta * curveProgress)
            }
        } else if let twoWay = bend as? TwoWayBend {
            let position = (hue - twoWay.startHue) / twoWay.hueCount
            let linearProgress = 1.0 - abs(position * 2.0 - 1.0)
            let smoothProgress: Double
            switch twoWay.easing {
            case .linear:
                smoothProgress = linearProgress
            case .cubic:
                smoothProgress = linearProgress * linearProgress * (3.0 - 2.0 * linearProgress)
            }
            return defaultValue - (valueDelta * smoothProgress)
        }
        return defaultValue
    }
}
