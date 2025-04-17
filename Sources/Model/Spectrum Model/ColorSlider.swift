import Foundation
import SwiftUI

/// Represents the HSB components on the color slider that can bend.
enum BendableComponent {
    case saturation, brightness
}

/// Model for assembling spectrum colors into an array.
struct SpectrumColorSliderModel: ColorSliderDataSource {
    /// Error for when `validateBendSections()` returns `false`
    private struct InvalidBendSectionError: Error {
        let message: String
        init(message: String = "Invalid bend section") {
            self.message = message
        }
    }
    
    /**
     Combines an optional `BlackSection` and `WhiteSection` into an optional
     array of `MonochromeSection` objects.
     
     The order of the objects on the color slider is determined by the
     `positionOnSlider` property of each `MonochromeSection`, not the section
     order in the returned `monochromeSections` array.
     
     - Parameters:
        - blackSection: An optional `BlackSection` of the color slider.
        - whiteSection: An optional `WhiteSection` of the color slider.
     
     - Returns:
        An array of `MonochromeSection` objects, or `nil` if both sections are
        `nil`. If a section exists, it is included in the returned array of
        `MonochromeSection`.
     */
    private func assembleMonochromeSections(
        blackSection: BlackSection?,
        whiteSection: WhiteSection?
    ) -> [MonochromeSection]? {
        let monochromeSections = [
            blackSection as MonochromeSection?,
            whiteSection as MonochromeSection?
        ].compactMap { $0 }
        
        return monochromeSections.isEmpty ? nil : monochromeSections
    }
    
    /**
     Reorders an optional array of `MonochromeSection` objects to place the
     prioritized `MonochromeColor` first.
     
     - Parameters:
        - monochromeSections: An optional array of `MonochromeSection` objects.
        - priorityColor: An optional `MonochromeColor` to prioritize in the
        array.
     
     - Returns:
        A reordered array of `MonochromeSection` objects in which the
        `priorityColor` is first, or `nil` if `monochromeSections` is `nil`.
     */
    private func prioritizeMonochromeSections(
        monochromeSections: [MonochromeSection]?,
        priorityColor: MonochromeColor?
    ) -> [MonochromeSection]? {
            guard let monochromeSections = monochromeSections else {
                return nil
            }
            
            guard let priorityColor = priorityColor,
                  monochromeSections.count == 2 else {
                return monochromeSections
            }
            
            if monochromeSections[0].color == priorityColor {
                return monochromeSections
            }
            else {
                return [monochromeSections[1], monochromeSections[0]]
            }
        }
    
    /**
     Generates an array of `Color` objects representing a `MonochromeSection`
     blending into an adjacent `MonochromeSection`.
     
     - Parameters:
        - hue: The hue value for the entire `MonochromeSection`, equivalent to
        the hue at either the start or end of the `HueSection`.
        - monochromeSection: A `MonochromeSection` object representing the
        color,  position and step size for the monochrome section of the color
        slider.
     
     - Returns:
        An array of `Color` objects representing the `MonochromeSection`
        blending into an adjacent  `MonochromeSection`.
     */
    private func generateMonochromeIntoMonochromeColors(
        hue: CGFloat,
        monochromeSection: MonochromeSection
    ) -> [Color] {
            
            /**
             An array for the brightness values as the `MonochromeSection` gets
             closer to the adjacent `MonochromeSection`.
             */
            let brightnessValues: [CGFloat] = {
                switch (monochromeSection.color,
                        monochromeSection.positionOnSlider) {
                case (.black, .start), (.white, .end):
                    return Array(
                        stride(
                            from: 0.0,
                            through: 1.0,
                            by: monochromeSection.stepSize
                        )
                    )
                case (.white, .start), (.black, .end):
                    return Array(
                        stride(
                            from: 1.0,
                            through: 0.0,
                            by: monochromeSection.stepSize
                        )
                    )
                }
            }()
            
            return brightnessValues.map { brightness in
                return Color(
                    hue: hue,
                    saturation: 0.0,
                    brightness: brightness,
                    opacity: 1.0)
            }
        }
    
    /**
     While accounting for any saturation or brightness bends, generates an array
     of `Color` objects representing a `MonochromeSection` blending into the
     start or end of a `HueSection`.
     
     - Parameter monochromeSection: A `MonochromeSection` object representing
     the color, position and step size for the monochrome section of the color
     slider.
     
     - Returns:
        An array of `Color` objects representing the `MonochromeSection`
        blending into the start or end of the `HueSection`.
     */
    private func generateMonochromeIntoHueColors(
        monochromeSection: MonochromeSection
    ) -> [Color] {
        struct BendAdjustment {
            var startSaturation: CGFloat
            var endSaturation: CGFloat
            var startBrightness: CGFloat
            var endBrightness: CGFloat
        }
        
        /**
         Generates an array of `Color` objects representing a
         `MonochromeSection` blending into the start or end of a `HueSection`.
         
         The `color` property of the `MonochromeSection` determines whether the
         gradient to or from the `MonochromeColor` affects brightness (for black
         sections) or saturation (for white sections).
         
         - Parameters:
            - startValue: A value representing either starting brightness or
            starting saturation.
            - endValue: A value representing either ending brightness or ending
            saturation.
            - hue: The hue value for the entire `MonochromeSection`, equivalent
            to the hue at either the start or end of the `HueSection`.
            - monochromeSection: A `MonochromeSection` object representing the
            color, position and step size for the monochrome section of the
            color slider.
         
         - Returns:
            An array of `Color` objects representing the `MonochromeSection`
            blending into the start or end of the `HueSection`.
         */
        func blendIntoHue(
            startValue: CGFloat,
            endValue: CGFloat,
            hue: CGFloat,
            monochromeSection: MonochromeSection
        ) -> [Color] {
                
            /**
             An array for whatever value is changing (either brightness or
             saturation) as the `MonochromeSection` gets farther from the
             `HueSection`.
             */
            let values: [CGFloat] = {
                switch monochromeSection.positionOnSlider {
                case .start:
                    return Array(
                        stride(from: 0.0,
                               through: startValue,
                               by: monochromeSection.stepSize))
                case .end:
                    return Array(
                        stride(from: endValue,
                               through: 0.0,
                               by: monochromeSection.stepSize))
                }
            }()
            
            return values.map { value in
                switch monochromeSection.color {
                case .black:
                    return Color(
                        hue: hue,
                        saturation: defaultSaturation,
                        brightness: value,
                        opacity: 1.0
                    )
                case .white:
                    return Color(
                        hue: hue,
                        saturation: value,
                        brightness: defaultBrightness,
                        opacity: 1.0
                    )
                }
            }
        }
        
        let hue = monochromeSection.positionOnSlider == .start ? minHue : maxHue
        
        var bendAdjustment = BendAdjustment(
            startSaturation: defaultSaturation,
            endSaturation: defaultSaturation,
            startBrightness: defaultBrightness,
            endBrightness: defaultBrightness
        )
        
        if let bendSections = bendSections {
            for bendSection in bendSections {
                guard bendSection.startHue == minHue ||
                        bendSection.endHue == maxHue
                else {
                    continue
                }
                
                /*
                 Adjust starting saturation and brightness values if the bend
                 mode is one-way and the bendSection begins at minHue or ends
                 at maxHue.
                 */
                if let oneWaySection = bendSection as? OneWayBendSection {
                    if bendSection.startHue == minHue {
                        bendAdjustment.startSaturation = bendSection.targetSaturation
                        bendAdjustment.startBrightness = bendSection.targetBrightness
                    }
                    else if bendSection.endHue == maxHue {
                        bendAdjustment.endSaturation = bendSection.targetSaturation
                        bendAdjustment.endBrightness = bendSection.targetBrightness
                    }
                }
            }
        }
        
        return blendIntoHue(
            startValue: monochromeSection.color == .black
                ? bendAdjustment.startBrightness
                : bendAdjustment.startSaturation,
            endValue: monochromeSection.color == .black
                ? bendAdjustment.endBrightness
                : bendAdjustment.endSaturation,
            hue: hue,
            monochromeSection: monochromeSection
        )
    }
    
    /**
     Determines which helper function to use to generate an array of `Color`
     objects from two adjacent `MonochromeSection` objects.
     
     For each section, the function will  blend colors into either the adjacent
     `MonochromeSection` or the start or end of the `HueSection`. To blend into
     the adjacent `MonochromeSection`, it uses the function
     `generateMonochromeIntoMonochromeColors`. To blend into the
     `HueSection`, it uses the function
     `generateMonochromeIntoHueColors`.
     
     - Parameter monochromeSections: An array of `MonochromeSection`.
     
     - Returns:
        An array of `Color` objects representing the colors of both sections.
        Returns an empty array if `monochromeSections` is empty.
     */
    private func generateAdjacentMonochromeColors(
        monochromeSections: [MonochromeSection]
    ) -> [Color] {
        guard let positionOnSlider = monochromeSections.first?.positionOnSlider,
              monochromeSections.allSatisfy({ $0.positionOnSlider == positionOnSlider }) else {
            return []
        }
        
        let hue = (positionOnSlider == .start) ? minHue : maxHue
        var adjacentMonochromeColors: [Color] = []
        
        for sectionIndex in 0..<monochromeSections.count {
            var sectionColors: [Color] = []
            
            switch positionOnSlider {
            case .start:
                /*
                 If the color is the last of the start sections, blend into the
                 HueSection.
                 */
                if sectionIndex == (monochromeSections.count - 1) {
                    sectionColors = generateMonochromeIntoHueColors(
                        monochromeSection: monochromeSections[sectionIndex]
                    )
                }
                // Otherwise, blend into the other monochromeSection.
                else {
                    sectionColors = generateMonochromeIntoMonochromeColors(
                        hue: minHue,
                        monochromeSection: monochromeSections[sectionIndex]
                    )
                }
            case .end:
                /*
                 If the color is the first of the end sections, blend into the
                 HueSection.
                 */
                if sectionIndex == 0 {
                    sectionColors = generateMonochromeIntoHueColors(
                        monochromeSection: monochromeSections[sectionIndex]
                    )
                }
                // Otherwise, blend into the other monochromeSection.
                else {
                    sectionColors = generateMonochromeIntoMonochromeColors(
                        hue: maxHue,
                        monochromeSection: monochromeSections[sectionIndex]
                    )
                }
            }
            adjacentMonochromeColors.append(contentsOf: sectionColors)
        }
        
        return adjacentMonochromeColors
    }
    
    /**
     Extracts a list of `Color` objects from an array of `MonochromeSection`.
     
     - Parameter monochromeSections: An optional array of `MonochromeSection`.
     
     - Returns:
        An optional array of `Color` objects representing the extracted colors.
        Returns `nil` if the input `monochromeSections` is `nil`, or if the
        number of sections is not one or two.
     */
    private func generateMonochromeColors(
        monochromeSections: [MonochromeSection]?
    ) -> [Color]? {
        guard let monochromeSections = monochromeSections else {
            return nil
        }
        
        switch monochromeSections.count {
        case 1:
            if let monochromeSection = monochromeSections.first {
                return generateMonochromeIntoHueColors(
                    monochromeSection: monochromeSection
                )
            }
        case 2:
            return generateAdjacentMonochromeColors(
                monochromeSections: monochromeSections
            )
        default:
            break
        }
        
        return nil
    }
    
    /**
     Validates an array of `BendSection` objects to ensure that the array is
     not empty and no two `BendSection` objects overlap.
     
     - Parameter bendSections: An array of `BendSection` objects.
     - Returns: `true` no two `BendSection` objects overlap. Otherwise, returns
     `false`.
     */
    private func validateBendSections(
        bendSections: [BendSection]
    ) -> Bool {
        // An empty bendSections array is invalid.
        guard bendSections.count > 0 else { return false }
        // A single bendSection is valid.
        guard bendSections.count > 1 else { return true }
        
        let sortedBendSections = bendSections.sorted {
            $0.startHue < $1.startHue
        }
        
        for (currentSection, nextSection) in zip(
            sortedBendSections,
            sortedBendSections.dropFirst()
        ) {
            // Check whether the bend sections overlap.
            if currentSection.endHue > nextSection.startHue {
                return false
            }
        }
        return true
    }
    
    /**
     Calculates the amount by which a given value (i.e., saturation or
     brightness) should change at each hue.
     
     - Parameters:
        - valueIncrement: The amount the value should change at each hue.
        - offsetFromStartHue: The difference between the current hue and the
        starting hue of the `BendSection`.
     - Returns:
        - The calculated number of increments, used to adjust the base value
        (i.e., saturation or brightness).
     */
    private func calculateNumberOfIncrements(
        valueIncrement: CGFloat,
        offsetFromStartHue: CGFloat
    ) -> CGFloat {
        return valueIncrement * offsetFromStartHue
    }
    
    /**
     Calculates the saturation or brightness for a given hue based on the
     provided bend sections.
     
     - Parameters:
        - hue: The hue for which to calculate the bend value.
        - defaultValue: The default value where there is no valid bend section.
        - bendSections: An optional array of `BendSection` objects defining the
        bending behavior across the `HueSection`. Throws an error if any bend
        sections overlap.
        - bendableComponent: The HSB component calculated for the bend (e.g.,
        saturation or brightness).
     
     - Throws:
        - `InvalidBendSectionError`: If `validateBendSections` is `false`.
     
     - Returns: The calculated bend value as a `CGFloat`.
     */
    private func calculateBendValue(
        hue: CGFloat,
        defaultValue: CGFloat,
        bendSections: [BendSection]?,
        bendableComponent: BendableComponent
    ) throws -> CGFloat {
        // Return defaultValue if bendSections is nil.
        guard let bendSections = bendSections else {
            return defaultValue
        }
        // Ensure that no two BendSection objects overlap.
        guard validateBendSections(bendSections: bendSections) else {
            throw InvalidBendSectionError()
        }
        
        // Find the bend section that bends the given hue.
        guard let relevantBendSection = bendSections.first(where: {
                $0.startHue <= hue && hue <= $0.endHue
        }) else {
            return defaultValue
        }
        
        let valueIncrement = bendableComponent == .saturation
            ? relevantBendSection.saturationIncrement
            : relevantBendSection.brightnessIncrement
        
        let offsetFromStartHue = hue - relevantBendSection.startHue
        
        switch relevantBendSection {
        case let oneWayBendSection as OneWayBendSection:
            let numberOfIncrements = calculateNumberOfIncrements(
                valueIncrement: valueIncrement,
                offsetFromStartHue: offsetFromStartHue)
            return CGFloat(defaultValue - numberOfIncrements)
        
        case let twoWayBendSection as TwoWayBendSection:
            let middleHue = twoWayBendSection.middleHue
            if twoWayBendSection.startHue < middleHue {
                let numberOfIncrements = calculateNumberOfIncrements(
                    valueIncrement: valueIncrement,
                    offsetFromStartHue: offsetFromStartHue)
                return CGFloat(defaultValue - numberOfIncrements)
            } else if hue < twoWayBendSection.endHue {
                return CGFloat(
                    twoWayBendSection.targetSaturation
                    + (valueIncrement * offsetFromStartHue
                    - (twoWayBendSection.hueCount / 2)))
            } else {
                return defaultValue
            }
        default:
            return defaultValue
        }
    }
    
    /**
     Generates an array of `Color` objects for a given `HueSection`, accounting
     for any bends in saturation or brightness.
     
     - Parameters:
        - hueSection: A `HueSection` defining the `minHue`, `maxHue`, `range`
        and `stepSize` for the `HueSection` of the color slider.
        - bendSections: An optional array of `BendSection` objects defining the
          bending behavior across the `HueSection`.
     
     - Throws:
        - `InvalidBendSectionError`: If `validateBendSections` is `false`.
     
     - Returns: An array of `Color` objects representing the `HueSection` of
     the color slider.
     */
    private func generateHueColors(
        hueSection: HueSection,
        bendSections: [BendSection]?
    ) throws -> [Color] {
        return try stride(
            from: minHue,
            to: maxHue,
            by: hueSection.stepSize
        ).enumerated().map { (index, hue) -> Color in
            let normalizedHue = CGFloat(hue) / CGFloat(maxHue)
            let calculatedSaturation: CGFloat
            let calculatedBrightness: CGFloat
            
            do {
                calculatedSaturation = try calculateBendValue(
                    hue: normalizedHue,
                    defaultValue: defaultSaturation,
                    bendSections: bendSections,
                    bendableComponent: .saturation
                )
                calculatedBrightness = try calculateBendValue(
                    hue: normalizedHue,
                    defaultValue: defaultBrightness,
                    bendSections: bendSections,
                    bendableComponent: .brightness
                )
            } catch { throw error }
            
            return Color(
                hue: normalizedHue,
                saturation: calculatedSaturation,
                brightness: calculatedBrightness,
                opacity: 1.0
            )
        }
    }
    
    /**
     Generates an array of `Color` objects for the  color slider, combining
     `monochromeStartColors`, `hueColors` and `monochromeEndColors`.
     
     - Parameters:
        - monochromeStartColors: An optional array of `Color` objects
        representing the `monochromeStartSections` of the color slider.
        - monochromeEndColors: An optional array of `Color` objects
        representing the `monochromeStartSections` of the color slider.
        - hueColors: An array of `Color` objects representing the `HueSection`
        of the color slider.
     */
    private func generateSliderColors(
        monochromeStartColors: [Color]?,
        monochromeEndColors: [Color]?,
        hueColors: [Color]
    ) -> [Color] {
        let startColors = monochromeStartColors ?? []
        let endColors = monochromeEndColors ?? []
        
        return startColors + hueColors + endColors
    }
    
    private let minHue: CGFloat
    private let maxHue: CGFloat
    
    /// The saturation anywhere there is no saturation bend.
    private let defaultSaturation: CGFloat = 1.0
    /// The brightness anywhere there is no brightness bend.
    private let defaultBrightness: CGFloat = 1.0
    
    private let hueSection: HueSection
    private let blackSection: BlackSection?
    private let whiteSection: WhiteSection?
    private let bendSections: [BendSection]?
    private let priorityColor: MonochromeColor?
    
    private let monochromeSections: [MonochromeSection]?
    
    private let monochromeStartSections: [MonochromeSection]?
    private let monochromeEndSections: [MonochromeSection]?
    
    private let monochromeStartColors: [Color]?
    private let monochromeEndColors: [Color]?
    private let hueColors: [Color]
    
    let sliderColors: [Color]
    
    init(
        minHue: CGFloat,
        maxHue: CGFloat,
        hueSection: HueSection,
        blackSection: BlackSection? = nil,
        whiteSection: WhiteSection? = nil,
        bendSections: [BendSection]? = nil,
        priorityColor: MonochromeColor? = nil
    ) throws {
        self.minHue = minHue
        self.maxHue = maxHue
        self.hueSection = hueSection
        self.blackSection = blackSection
        self.whiteSection = whiteSection
        self.bendSections = bendSections
        self.priorityColor = priorityColor
        
        self.monochromeSections = assembleMonochromeSections(
            blackSection: self.blackSection,
            whiteSection: self.whiteSection
        )
        self.monochromeStartSections = prioritizeMonochromeSections(
            monochromeSections: self.monochromeSections?.filter {
                $0.positionOnSlider == .start
            },
            priorityColor: self.priorityColor
        )
        self.monochromeEndSections = prioritizeMonochromeSections(
            monochromeSections: self.monochromeSections?.filter {
                $0.positionOnSlider == .end
            },
            priorityColor: self.priorityColor
        )
        self.monochromeStartColors = generateMonochromeColors(
            monochromeSections: self.monochromeStartSections
        )
        self.monochromeEndColors = generateMonochromeColors(
            monochromeSections: self.monochromeEndSections
        )
        self.hueColors = try generateHueColors(
            hueSection: hueSection,
            bendSections: bendSections
        )
        self.sliderColors = generateSliderColors(
            monochromeStartColors: self.monochromeStartColors,
            monochromeEndColors: self.monochromeEndColors,
            hueColors: self.hueColors
        )
    }
}
