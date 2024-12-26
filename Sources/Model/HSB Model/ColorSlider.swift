import Foundation
import SwiftUI

/// Model for assembling the HSB color slider values into an array.
struct HSBColorSliderModel {
    
    /**
     Combines an optional `BlackSection` and `WhiteSection` into an optional
     array of `MonochromeSection`.
     
     - Parameters:
        - blackSection: An optional `BlackSection` of the color slider.
        - whiteSection: An optional `WhiteSection` of the color slider.

     - Returns:
        An array of `MonochromeSection`. If either section exists, it is
        included in the returned array of `MonochromeSection`. The function
        returns an empty array if both sections are `nil`.
     */
    func getMonochromeSections(
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
     Reorders an optional array of two `MonochromeSection` objects to place the
     prioritized `MonochromeColor` first.
     
     - Parameters:
        - monochromeSections: An optional array containing two
        `MonochromeSection` objects. If the array does not have exactly two
        elements, it remains unchanged.
        - prioritySection: An optional `MonochromeColor` to prioritize in the
        array,

     - Returns: A reordered array of `MonochromeSection` objects in which the
     `prioritySection` is first, or the original optional array if
     `monochromeSections` does not have exactly two elements.
     */
    func prioritizeMonochromeSections(
        monochromeSections: [MonochromeSection]?,
        prioritySection: MonochromeColor?) -> [MonochromeSection]? {
            guard let monochromeSections = monochromeSections,
                  let prioritySection = prioritySection,
                  monochromeSections.count == 2 else {
                return monochromeSections
            }
            
            if monochromeSections[0].color == prioritySection {
                return monochromeSections
            }
            else {
                return [monochromeSections[1], monochromeSections[0]]
            }
        }
    
    let minHue: CGFloat
    let maxHue: CGFloat
    
    /// The saturation anywhere there is no saturation bend.
    let defaultSaturation: CGFloat
    /// The brightness anywhere there is no brightness bend.
    let defaultBrightness: CGFloat
    
    let hueSection: HueSection
    let blackSection: BlackSection?
    let whiteSection: WhiteSection?
    let bendSections: [BendSection]?
    let prioritySection: MonochromeColor?
    
    let monochromeSections: [MonochromeSection]?
    
    let monochromeStartSections: [MonochromeSection]?
    let monochromeEndSections: [MonochromeSection]?
    
    let monochromeStartColors: [Color]?
    let monochromeEndColors: [Color]?
    
    init(
        minHue: CGFloat,
        maxHue: CGFloat,
        defaultSaturation: CGFloat,
        defaultBrightness: CGFloat,
        hueSection: HueSection,
        blackSection: BlackSection?,
        whiteSection: WhiteSection?,
        bendSections: [BendSection]?,
        prioritySection: MonochromeColor?
    ) {
        self.minHue = minHue
        self.maxHue = maxHue
        self.defaultSaturation = defaultSaturation
        self.defaultBrightness = defaultBrightness
        self.hueSection = hueSection
        self.blackSection = blackSection
        self.whiteSection = whiteSection
        self.bendSections = bendSections
        self.prioritySection = prioritySection
        
        self.monochromeSections = getMonochromeSections(
            blackSection: self.blackSection,
            whiteSection: self.whiteSection
        )
        self.monochromeStartSections = prioritizeMonochromeSections(
            monochromeSections: self.monochromeSections?.filter {
                $0.positionOnSlider == .start
            },
            prioritySection: self.prioritySection
        )
        self.monochromeEndSections = prioritizeMonochromeSections(
            monochromeSections: self.monochromeSections?.filter {
                $0.positionOnSlider == .end
            },
            prioritySection: self.prioritySection
        )
        self.monochromeStartColors = getMonochromeColors(
            monochromeSections: self.monochromeStartSections
        )
        self.monochromeEndColors = getMonochromeColors(
            monochromeSections: self.monochromeEndSections
        )
    }
    
    var sliderColors: [Color] {
        
        /**
         Generates an array of `Color` objects representing a
         `MonochromeSection` blending into an adjacent `MonochromeSection`.
         
         - Parameters:
            - hue: The hue value for the entire `MonochromeSection`,
            equivalent to the hue at either the start or end of the color slider.
            `HueSection`.
            - monochromeSection: A `MonochromeSection` object representing the
            color,  position and step size for the monochrome section of the
            color slider.
         
          - Returns: An array of `Color` objects representing the
            `MonochromeSection` blending into an adjacent  `MonochromeSection`.
         */
        func blendIntoMonochromeColor(
            hue: CGFloat,
            monochromeSection: MonochromeSection) -> [Color] {
                
                /**
                 An array for the brightness values as the `MonochromeSection`
                 gets closer to the adjacent `MonochromeSection`.
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
         Generates an array of `Color` objects representing a
         `MonochromeSection` blending into the start or end of a `HueSection`.
         
         This function accounts for any brightness or saturation bends that
         border the `MonochromeSection`.

         - Parameters:
            - monochromeSection: A `MonochromeSection` object representing the
            color, position and step size for the monochrome section of the
            color slider.

         - Returns:
            An array of `Color` objects representing the colors of the
            `MonochromeSection`.
         */
        func blendIntoHue(
            monochromeSection: MonochromeSection) -> [Color] {
            
            struct BendAdjustment {
                var startBrightness: CGFloat
                var endBrightness: CGFloat
                var startSaturation: CGFloat
                var endSaturation: CGFloat
            }
            
            /**
             Without accounting for any saturation bends, generates an array of
             `Color` objects representing a `MonochromeSection` blending into
             the start or end of a `HueSection`.
             
             The `color` property of the `MonochromeSection` determines whether
             the gradient to or from the monochrome color affects brightness
             (for black sections) or saturation (for white sections).
             
             - Parameters:
                - startValue: A value representing either starting brightness or
                starting saturation.
                - endValue: A value representing either ending brightness or
                ending saturation.
                - hue: The hue value for the entire `MonochromeSection`,
                equivalent to the hue at either the start or end of the
                `HueSection`.
                - monochromeSection: A `MonochromeSection` object representing
                the color, position and step size for the monochrome section of
                the color slider.
             
             - Returns:
                An array of `Color` objects representing the colors of the
                `MonochromeSection`.
             */
            func getBlendIntoHueColors(
                startValue: CGFloat,
                endValue: CGFloat,
                hue: CGFloat,
                monochromeSection: MonochromeSection) -> [Color] {
                    
                    /**
                     An array for whatever value is changing (either brightness
                     or saturation) as the `MonochromeSection` gets farther
                     from the `HueSection`.
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
            
            var bendAdjustment = BendAdjustment(startBrightness: defaultBrightness,
                                                endBrightness: defaultBrightness,
                                                startSaturation: defaultSaturation,
                                                endSaturation: defaultSaturation)
            
            /*
             Adjust starting brightness and saturation values if the bend
             mode is one-way and the bendSection begins at minHue or ends
             at maxHue.
            */
            if let bendSections = bendSections {
                for bendSection in bendSections where
                    bendSection.bendMode == .oneWay &&
                    (bendSection.startHue == minHue
                        || bendSection.endHue == maxHue) {
                    
                    if bendSection.startHue == minHue {
                        bendAdjustment.startBrightness = bendSection.targetBrightness
                        bendAdjustment.startSaturation = bendSection.targetSaturation
                    }
                    else if bendSection.endHue == maxHue {
                        bendAdjustment.endBrightness = bendSection.targetBrightness
                        bendAdjustment.endSaturation = bendSection.targetSaturation
                    }
                }
            }
            
            return getBlendIntoHueColors(
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
        
        let firstSectionColors: [Color]
        let secondSectionColors: [Color]
        
        if let sections = monochromeStartSections ?? monochromeEndSections,
           sections.count == 2 {
            firstSectionColors = getFirstSectionColors(sections: sections)
            secondSectionColors = getSecondSectionColors(sections: sections)
        /**
         Determines which helper function to use to generate an array of `Color`
         objects from two adjacent `MonochromeSection` objects.
         
         For each section, the function will  blend colors into either the
         adjacent `MonochromeSection` or the start or end of the `HueSection`.
         To blend into the adjacent `MonochromeSection`, it uses the function
         `blendIntoMonochromeColor`. To blend into the `HueSection`, it uses
         the function `blendIntoHue`.
         
         - Parameters:
            - monochromeSections: An array of `MonochromeSection` representing
            the available monochrome sections.
            - positionOnSlider: The position of the `MonochromeSection` objects on the color slider, either `.start` or `.end`.
         
         - Returns: An array of `Color` objects representing the colors of both
         sections. Returns an empty array if `monochromeSections` is an empty
         array.
         */
        func blendAdjacentMonochromeSections(
            monochromeSections: [MonochromeSection],
            positionOnSlider: PositionOnSlider
        ) -> [Color] {
            let hue = (positionOnSlider == .start) ? minHue : maxHue
            var adjacentMonochromeColors: [Color] = []
            
            for sectionIndex in 0..<monochromeSections.count {
                var sectionColors: [Color] = []
                
                switch positionOnSlider {
                case .start:
                    /*
                     If the color is the last of the start sections, blend into
                     the HueSection.
                     */
                    if sectionIndex == (monochromeSections.count - 1) {
                        sectionColors = blendIntoHue(
                            monochromeSection: monochromeSections[sectionIndex]
                        )
                    }
                    // Otherwise, blend into the other monochromeSection.
                    else {
                        sectionColors = blendIntoMonochromeColor(
                            hue: minHue,
                            monochromeSection: monochromeSections[sectionIndex]
                        )
                    }
                case .end:
                    /*
                     If the color is the first of the end sections, blend into
                     the HueSection.
                     */
                    if sectionIndex == 0 {
                        sectionColors = blendIntoHue(
                            monochromeSection: monochromeSections[sectionIndex]
                        )
                    }
                    // Otherwise, blend into the other monochromeSection.
                    else {
                        sectionColors = blendIntoMonochromeColor(
                            hue: maxHue,
                            monochromeSection: monochromeSections[sectionIndex]
                        )
                    }
                }
                adjacentMonochromeColors.append(contentsOf: sectionColors)
            }
            return adjacentMonochromeColors
        }
        
        else {
            if let monochromeStartSections {
                monochromeStartColors = getAdjustedMonochromeColors(
                    monochromeSection: monochromeStartSections[0]
                )
            }
            else {
                monochromeStartColors = nil
            }
            
            if let monochromeEndSections {
                monochromeEndColors = getAdjustedMonochromeColors(
                    monochromeSection: monochromeEndSections[0]
                )
            }
            else {
                monochromeEndColors = nil
            }
        }
        
        let hueColors: [Color] = stride(
            from: minHue,
            to: maxHue,
            by: hueSection.stepSize
        ).enumerated().map { (index, hue) in
            let normalizedHue = CGFloat(hue) / CGFloat(maxHue)
            let calculatedSaturation = calculateValues(
                index: index,
                hue: normalizedHue,
                defaultSaturation: defaultSaturation,
                bendSections: bendSections
            )
            
            return Color(hue: normalizedHue, saturation: calculatedSaturation, brightness: 1.0, opacity: 1.0)
        }
        
        return [monochromeStartColors, hueColors, monochromeEndColors].compactMap { $0 }.flatMap { $0 }
    }
}

