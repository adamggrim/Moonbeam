import SwiftUI

/// A model for generating a spectrum color for a given position, suitable for shaders.
struct SpectrumGenerator {
    
    /// Error for when `validateBendSections()` returns `false`
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
        minHue: CGFloat,
        maxHue: CGFloat,
        blackSection: BlackSection? = nil,
        whiteSection: WhiteSection? = nil,
        bendSections: [BendSection]? = nil,
        priorityColor: MonochromeColor? = nil,
        baseSaturation: CGFloat = 1.0,
        baseBrightness: CGFloat = 1.0
    ) -> Color {
        let allMono = assembleMonochromeSections(blackSection: blackSection, whiteSection: whiteSection)
        let startSections = prioritizeMonochromeSections(monochromeSections: allMono?.filter { $0.positionOnSlider == .start }, priorityColor: priorityColor) ?? []
        let endSections = prioritizeMonochromeSections(monochromeSections: allMono?.filter { $0.positionOnSlider == .end }, priorityColor: priorityColor) ?? []
        let hueSection = HueSection(minHue: minHue, maxHue: maxHue)
        
        let startCount = startSections.reduce(0) { $0 + $1.count }
        let hueCount = hueSection.count
        let endCount = endSections.reduce(0) { $0 + $1.count }
        let totalCount = startCount + hueCount + endCount
        
        guard totalCount > 0 else {
            return .clear
        }
        
        let startBoundary = CGFloat(startCount) / CGFloat(totalCount)
        let hueBoundary = CGFloat(startCount + hueCount) / CGFloat(totalCount)
        let clampedPosition = max(0.0, min(1.0, position))
        
        if clampedPosition < startBoundary {
            var cumulativeStart: CGFloat = 0.0
            for (index, section) in startSections.enumerated() {
                let sectionEnd = cumulativeStart + (CGFloat(section.count) / CGFloat(totalCount))
                if clampedPosition < sectionEnd {
                    let relativePos = (clampedPosition - cumulativeStart) / (sectionEnd - cumulativeStart)
                    let isLastStartSection = (index == startSections.count - 1)
                    return isLastStartSection
                    ? monoToHueColor(relativePosition: relativePos, monochromeSection: section, minHue: minHue, maxHue: maxHue, bendSections: bendSections, baseSaturation: baseSaturation, baseBrightness: baseBrightness)
                    : monoToMonoColor(relativePosition: relativePos, monochromeSection: section, hue: minHue)
                }
                cumulativeStart = sectionEnd
            }
            // Fix 1: Change strictly less than (<) to less than or equal to (<=)
        } else if clampedPosition <= hueBoundary {
            // Prevent theoretical divide-by-zero if there is no hue section
            let relativeHuePos = (hueBoundary > startBoundary) ? (clampedPosition - startBoundary) / (hueBoundary - startBoundary) : 0.0
            let currentHue = minHue + relativeHuePos * (maxHue - minHue)
            
            let saturation = (try? calculateBendValue(hue: currentHue, defaultValue: baseSaturation, bendSections: bendSections, bendableComponent: .saturation, minHue: minHue, maxHue: maxHue)) ?? baseSaturation
            let brightness = (try? calculateBendValue(hue: currentHue, defaultValue: baseBrightness, bendSections: bendSections, bendableComponent: .brightness, minHue: minHue, maxHue: maxHue)) ?? baseBrightness
            
            return Color(hue: currentHue, saturation: saturation, brightness: brightness)
            
        } else {
            var cumulativeEnd = hueBoundary
            for (index, section) in endSections.enumerated() {
                let sectionEnd = cumulativeEnd + (CGFloat(section.count) / CGFloat(totalCount))
                
                let isLastSection = (index == endSections.count - 1)
                
                if clampedPosition <= sectionEnd || isLastSection {
                    let relativePos = (clampedPosition - cumulativeEnd) / (sectionEnd - cumulativeEnd)
                    // Clamp to 1.0 in case floating-point math exceeded the boundary.
                    let clampedRelativePos = min(1.0, max(0.0, relativePos))
                    let isFirstEndSection = (index == 0)
                    
                    return isFirstEndSection
                    ? monoToHueColor(relativePosition: clampedRelativePos, monochromeSection: section, minHue: minHue, maxHue: maxHue, bendSections: bendSections, baseSaturation: baseSaturation, baseBrightness: baseBrightness)
                    : monoToMonoColor(relativePosition: clampedRelativePos, monochromeSection: section, hue: maxHue)
                }
                cumulativeEnd = sectionEnd
            }
        }
        
        return .clear
    }
    
    // MARK: - Private Helper Functions
    
    /// Generates a color for a monochrome section blending into the main hue spectrum.
    private static func monoToHueColor(relativePosition: CGFloat, monochromeSection: MonochromeSection, minHue: CGFloat, maxHue: CGFloat, bendSections: [BendSection]?, baseSaturation: CGFloat, baseBrightness: CGFloat) -> Color {
        let positionOnSlider = monochromeSection.positionOnSlider
        let hue = (positionOnSlider == .start) ? minHue : maxHue
        let interpolationFactor = (positionOnSlider == .start) ? relativePosition : (1.0 - relativePosition)
        
        // Determine target values at the hue boundary, considering bends.
        var startTargetSaturation = baseSaturation, startTargetBrightness = baseBrightness
        var endTargetSaturation = baseSaturation, endTargetBrightness = baseBrightness
        
        if let bendSections = bendSections {
            for bend in bendSections {
                if let oneWay = bend as? OneWayBend {
                    if oneWay.startHue == minHue {
                        startTargetSaturation = oneWay.targetSaturation
                        startTargetBrightness = oneWay.targetBrightness
                    } else if oneWay.endHue == maxHue {
                        endTargetSaturation = oneWay.targetSaturation
                        endTargetBrightness = oneWay.targetBrightness
                    }
                }
            }
        }
        
        switch monochromeSection.color {
        case .black:
            let targetBrightness = (positionOnSlider == .start) ? startTargetBrightness : endTargetBrightness
            let finalBrightness = interpolationFactor * targetBrightness
            return Color(hue: hue, saturation: baseSaturation, brightness: finalBrightness)
        case .white:
            let targetSaturation = (positionOnSlider == .start) ? startTargetSaturation : endTargetSaturation
            let finalSaturation = interpolationFactor * targetSaturation
            return Color(hue: hue, saturation: finalSaturation, brightness: baseBrightness)
        }
    }
    
    /// Generates a color for a monochrome section blending into another monochrome section.
    private static func monoToMonoColor(relativePosition: CGFloat, monochromeSection: MonochromeSection, hue: CGFloat) -> Color {
        let brightness: CGFloat
        switch (monochromeSection.color, monochromeSection.positionOnSlider) {
        case (.black, .start), (.white, .end): // Fading in
            brightness = relativePosition
        case (.white, .start), (.black, .end): // Fading out
            brightness = 1.0 - relativePosition
        }
        return Color(hue: hue, saturation: 0.0, brightness: brightness)
    }
    
    private static func assembleMonochromeSections(blackSection: BlackSection?, whiteSection: WhiteSection?) -> [MonochromeSection]? {
        let sections = [blackSection as MonochromeSection?, whiteSection as MonochromeSection?].compactMap { $0 }
        return sections.isEmpty ? nil : sections
    }
    
    private static func prioritizeMonochromeSections(monochromeSections: [MonochromeSection]?, priorityColor: MonochromeColor?) -> [MonochromeSection]? {
        guard let sections = monochromeSections else { return nil }
        guard let priority = priorityColor, sections.count == 2 else { return sections }
        return sections[0].color == priority ? sections : [sections[1], sections[0]]
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
        minHue: CGFloat,
        maxHue: CGFloat
    ) throws -> CGFloat {
        guard let bendSections = bendSections, !bendSections.isEmpty else { return defaultValue }
        guard validateBendSections(bendSections: bendSections) else { throw InvalidBendSectionError() }
        guard let relevantBend = bendSections.first(where: { $0.startHue <= hue && hue <= $0.endHue }) else { return defaultValue }

        let targetValue = bendableComponent == .saturation ? relevantBend.targetSaturation : relevantBend.targetBrightness
        let valueDelta = defaultValue - targetValue
        let offset = hue - relevantBend.startHue

        if let oneWay = relevantBend as? OneWayBend {
            let valueIncrement = oneWay.hueCount != 0 ? (valueDelta / oneWay.hueCount) : 0
            
            if oneWay.startHue == minHue {
                // If starting at the minimum end, interpolate up to the default value.
                return targetValue + (valueIncrement * offset)
            } else {
                // Otherwise, interpolate down.
                let numIncrements = valueIncrement * offset
                return defaultValue - numIncrements
            }
        } else if let twoWay = relevantBend as? TwoWayBend {
            // Smooth sine-wave interpolation for TwoWayBends
            let position = (hue - twoWay.startHue) / twoWay.hueCount
            let curveProgress = sin(position * .pi)
            
            return defaultValue - (valueDelta * curveProgress)
        }

        return defaultValue
    }
}
