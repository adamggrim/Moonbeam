import SwiftUI

/// A configuration for the static properties of a spectrum.
internal struct SpectrumConfiguration {
    /// Whether to use the HSB or Oklch color space.
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
    private static let hueComparisonTolerance: Double = 0.0001

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
        let startSections = configuration.startSections
        let endSections = configuration.endSections
        let startHue = configuration.startHue
        let endHue = configuration.endHue
        let primaryValue = configuration.primaryValue
        let secondaryValue = configuration.secondaryValue
        let primaryBends = configuration.primaryBends
        let secondaryBends = configuration.secondaryBends

        let startFraction = startSections.reduce(0) { $0 + $1.fraction }
        let endFraction = endSections.reduce(0) { $0 + $1.fraction }

        let startBoundary = startFraction
        let hueBoundary = 1.0 - endFraction
        let clampedPosition = max(0.0, min(1.0, position))

        if clampedPosition < startBoundary {
            var cumulativeStart: Double = 0.0
            for (index, section) in startSections.enumerated() {
                let sectionEnd = cumulativeStart + section.fraction
                if clampedPosition < sectionEnd || (index == startSections.count - 1) {
                    let sectionProgress = (clampedPosition - cumulativeStart) / (sectionEnd - cumulativeStart)
                    let relativePosition = min(1.0, max(0.0, sectionProgress))
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
            let rawHue = startHue + relativeHuePos * (endHue - startHue)
            let currentHue = min(max(rawHue, min(startHue, endHue)), max(startHue, endHue))

            let primary = calculateBendValue(
                hue: currentHue,
                defaultValue: primaryValue,
                bendSections: primaryBends,
                spectrumStartHue: startHue,
                spectrumEndHue: endHue,
                colorSpace: configuration.colorSpace
            )
            let secondary = calculateBendValue(
                hue: currentHue,
                defaultValue: secondaryValue,
                bendSections: secondaryBends,
                spectrumStartHue: startHue,
                spectrumEndHue: endHue,
                colorSpace: configuration.colorSpace
            )

            return (hue: currentHue, primary: primary, secondary: secondary)
        } else {
            var cumulativeEnd = hueBoundary
            for (index, section) in endSections.enumerated() {
                let sectionEnd = cumulativeEnd + section.fraction
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
        let isReversedSpectrum = startHue > endHue
        let rawFactor = min(max(isStart ? relativePosition : (1.0 - relativePosition), 0.0), 1.0)
        let hasAdjacentMonochrome = isStart
            ? (configuration.startSections.count > 1)
            : (configuration.endSections.count > 1)
        let interpolationFactor = hasAdjacentMonochrome
            ? smoothstep(rawFactor)
            : rawFactor * (1.0 + rawFactor * (1.0 - rawFactor))

        var startTargetPrimary = primaryValue, startTargetSecondary = secondaryValue
        var endTargetPrimary = primaryValue, endTargetSecondary = secondaryValue

        if let primaryBends = primaryBends {
            for bend in primaryBends {
                if let oneWay = bend as? OneWayBend {
                    let leadingEdge = isReversedSpectrum ? max(oneWay.startHue, oneWay.endHue) : min(oneWay.startHue, oneWay.endHue)
                    let trailingEdge = isReversedSpectrum ? min(oneWay.startHue, oneWay.endHue) : max(oneWay.startHue, oneWay.endHue)
                    if abs(leadingEdge - startHue) < hueComparisonTolerance {
                        startTargetPrimary = oneWay.targetValue
                    } else if abs(trailingEdge - endHue) < hueComparisonTolerance {
                        endTargetPrimary = oneWay.targetValue
                    }
                }
            }
        }

        if let secondaryBends = secondaryBends {
            for bend in secondaryBends {
                if let oneWay = bend as? OneWayBend {
                    let leadingEdge = isReversedSpectrum ? max(oneWay.startHue, oneWay.endHue) : min(oneWay.startHue, oneWay.endHue)
                    let trailingEdge = isReversedSpectrum ? min(oneWay.startHue, oneWay.endHue) : max(oneWay.startHue, oneWay.endHue)
                    if abs(leadingEdge - startHue) < hueComparisonTolerance {
                        startTargetSecondary = oneWay.targetValue
                    } else if abs(trailingEdge - endHue) < hueComparisonTolerance {
                        endTargetSecondary = oneWay.targetValue
                    }
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

    /// Generates a Hermite-smoothed gradient between two monochrome sections.
    private static func monochromeToMonochromeColor(
        relativePosition: Double,
        fromSection: MonochromeSection,
        toSection: MonochromeSection,
        hue: Double
    ) -> (hue: Double, primary: Double, secondary: Double) {
        let startBrightness: Double = (fromSection.color == .white) ? 1.0 : 0.0
        let endBrightness: Double = (toSection.color == .white) ? 1.0 : 0.0
        let smoothT = smoothstep(relativePosition)

        let brightness = startBrightness + (endBrightness - startBrightness) * smoothT
        return (hue: hue, primary: 0.0, secondary: brightness)
    }

    private static func smoothstep(_ x: Double) -> Double {
        let clamped = min(max(x, 0.0), 1.0)
        return clamped * clamped * (3.0 - 2.0 * clamped)
    }

    private static func hermiteTwoWayBend(
        _ u: Double,
        defaultValue: Double,
        targetValue: Double,
        hueCount: Double,
        colorSpace: SpectrumColorSpace
    ) -> Double {
        let clampedU = min(max(u, 0.0), 1.0)
        let valueDelta = defaultValue - targetValue

        let peakSlope: Double
        if colorSpace == .hsb && valueDelta > hueComparisonTolerance {
            let idealSlope = (1.5 * hueCount * targetValue) / valueDelta
            peakSlope = min(max(idealSlope, 0.0), 2.0)
        } else {
            peakSlope = 0.0
        }

        return clampedU * clampedU * ((3.0 - peakSlope) - (2.0 - peakSlope) * clampedU)
    }

    private static func calculateBendValue(
        hue: Double,
        defaultValue: Double,
        bendSections: [BendSection]?,
        spectrumStartHue: Double,
        spectrumEndHue: Double,
        colorSpace: SpectrumColorSpace
    ) -> Double {
        guard let bends = bendSections,
              let bend = bends.first(where: {
                  min($0.startHue, $0.endHue) <= hue && hue <= max($0.startHue, $0.endHue)
              })
        else {
            return defaultValue
        }

        let isReversedSpectrum = spectrumStartHue > spectrumEndHue
        let entryHue = isReversedSpectrum ? max(bend.startHue, bend.endHue) : min(bend.startHue, bend.endHue)
        let valueDelta = defaultValue - bend.targetValue
        let offset = abs(hue - entryHue)
        let position = min(max(bend.hueCount != 0 ? (offset / bend.hueCount) : 0, 0.0), 1.0)

        if bend is OneWayBend {
            let touchesLeadingEdge = abs(entryHue - spectrumStartHue) < hueComparisonTolerance
            if touchesLeadingEdge {
                let easeOut = position * (1.0 + position * (1.0 - position))
                return bend.targetValue + (valueDelta * easeOut)
            } else {
                let easeIn = position * position * (2.0 - position)
                return defaultValue - (valueDelta * easeIn)
            }
        } else if bend is TwoWayBend {
            let linearProgress = 1.0 - abs(position * 2.0 - 1.0)
            let hermiteProgress = hermiteTwoWayBend(
                linearProgress,
                defaultValue: defaultValue,
                targetValue: bend.targetValue,
                hueCount: bend.hueCount,
                colorSpace: colorSpace
            )
            return defaultValue - (valueDelta * hermiteProgress)
        }
        return defaultValue
    }
}
