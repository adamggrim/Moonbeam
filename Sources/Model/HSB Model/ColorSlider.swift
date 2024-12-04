import Foundation
import SwiftUI

/// Model for assembling the HSB color slider values into an array
struct HSBColorSliderModel {
    /// Enum for prioritizing which monochrome section to display first if the black and white sections are on the same side of the color slider.
    enum PrioritySection {
        case black
        case white
    }
    
    /// Struct for pairing a MonochromeSection with an array of colors.
    struct SectionColors {
        let section: MonochromeSection
        let colors: [Color]
    }
    
    let minHue: CGFloat
    let maxHue: CGFloat
    
    /// The saturation anywhere there is no saturation bend.
    let defaultSaturation: CGFloat
    /// The brightness anywhere there is no brightness bend.
    let defaultBrightness: CGFloat
    let monochromeSections: [MonochromeSection]?
    let hueSection: HueSection
    let bendSections: [BendSection]?
    let prioritySection: PrioritySection?
    
    var sliderColors: [Color] {
        
        /// Generates an array of `Color` representing a monochrome color fading into or away from the start or end of a hue section.
        ///
        /// The `color` property of the `monochromeSection` determines whether the gradient to or from the monochrome color affects brightness (for white) or saturation (for black).
        ///
        /// - Parameters:
        ///   - startValue: A value representing either starting brightness or starting saturation.
        ///   - endValue: A value representing either ending brightness or ending saturation.
        ///   - huePosition: The hue value for the entire monochrome section, equivalent to the hue at the start or end of the hue section.
        ///   - monochromeSection: A `MonochromeSection` instance defining the color, position and step size for the monochrome section of the slider.
        ///
        /// - Returns: An array of `Color` instances representing the monochrome section.
        func getMonochromeColors(
            startValue: CGFloat,
            endValue: CGFloat,
            huePosition: CGFloat,
            monochromeSection: MonochromeSection) -> [Color] {
                let values: [CGFloat] = {
                    switch monochromeSection.position {
                    case .start:
                        return Array(stride(from: 0.0, through: startValue, by: monochromeSection.stepSize))
                    case .end:
                        return Array(stride(from: endValue, through: 0.0, by: monochromeSection.stepSize))
                    }
                }()
                
                return values.map { value in
                    switch monochromeSection.color {
                    case .black:
                        return Color(hue: huePosition, saturation: value, brightness: defaultBrightness, opacity: 1.0)
                    case .white:
                        return Color(hue: huePosition, saturation: defaultSaturation, brightness: value, opacity: 1.0)
                    }
                }
            }
        
        func processMonochromeSections(monochromeSections: [MonochromeSection]?) -> [[Color]]? {
            return monochromeSections?.map { monochromeSection in
                // Where in the hue range to insert the monochrome section
            /// Combines an optional `BlackSection` and `WhiteSection` into an optional array of `MonochromeSection`.
            ///
            /// - Parameters:
            ///   - blackSection: An optional `BlackSection` of the color slider
            ///   - whiteSection: An optional `WhiteSection` of the color slider
            ///
            /// - Returns:
            ///     An array of `MonochromeSection`. If either section exists, it is included in the returned array of `MonochromeSection`.
            ///     The function returns an empty array if both sections are `nil`.
            func getMonochromeSections(blackSection: BlackSection?, whiteSection: WhiteSection?) -> [MonochromeSection]? {
                let monochromeSections = [blackSection as MonochromeSection?, whiteSection as MonochromeSection?].compactMap { $0 }
                return monochromeSections.isEmpty ? nil : monochromeSections
            }
            
            let monochromeSections = getMonochromeSections(blackSection: blackSection, whiteSection: whiteSection)
            
            return monochromeSections?.compactMap { monochromeSection in
                
                /// Where in the hue range to insert the monochrome section.
                let huePosition = monochromeSection.position == .start ? minHue : maxHue
                
                struct BendAdjustment {
                    var startBrightness: CGFloat
                    var endBrightness: CGFloat
                    var startSaturation: CGFloat
                    var endSaturation: CGFloat
                }
                
                var bendAdjustment = BendAdjustment(startBrightness: defaultBrightness,
                                                    endBrightness: defaultBrightness,
                                                    startSaturation: defaultSaturation,
                                                    endSaturation: defaultSaturation)
                
                // Adjust starting brightness and saturation values if the bend mode is one-way and the bendSection begins at minHue or ends at maxHue
                if let bendSections = bendSections {
                    for bendSection in bendSections where bendSection.bendMode == .oneWay && (bendSection.startHue == minHue || bendSection.endHue == maxHue) {
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
                
                return getMonochromeColors(startValue: monochromeSection.color == .black ? bendAdjustment.startBrightness : bendAdjustment.startSaturation,
                                           endValue: monochromeSection.color == .black ? bendAdjustment.endBrightness : bendAdjustment.endSaturation,
                                           huePosition: huePosition,
                                           monochromeSection: monochromeSection)
            }
        }
        
        let monochromeStartSections = monochromeSections?.filter { $0.position == .start }
        let monochromeEndSections = monochromeSections?.filter { $0.position == .end }
        
        let monochromeStartColors = processMonochromeSections(monochromeSections: monochromeStartSections)
        let monochromeEndColors = processMonochromeSections(monochromeSections: monochromeEndSections)

        let hueValues = Array(stride(from: minHue, to: maxHue, by: hueSection.stepSize))
        let hueColors: [Color] = hueValues.enumerated().map { (index, hue) in
            let normalizedHue = CGFloat(hue) / CGFloat(maxHue)
            let calculatedSaturation = calculateSaturation(index: index, hue: normalizedHue, defaultSaturation: defaultSaturation, bendSections: bendSections)
            
            return Color(hue: normalizedHue, saturation: calculatedSaturation, brightness: 1.0, opacity: 1.0)
        }
        
        return monochromeStartColors + hueColors + monochromeEndColors
    }
}

