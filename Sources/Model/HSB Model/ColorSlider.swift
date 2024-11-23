import Foundation
import SwiftUI

// Model for assembling the HSB color slider values into an array
struct HSBColorSliderModel {
    let minHue: CGFloat
    let maxHue: CGFloat
    // The saturation anywhere there is no saturation bend
    let defaultSaturation: CGFloat
    // The brightness anywhere there is no brightness bend
    let defaultBrightness: CGFloat
    let monochromeSections: [MonochromeSection]?
    let hueSection: HueSection
    let bendSections: [BendSection]?
    
    init(minHue: CGFloat,
         maxHue: CGFloat,
         defaultSaturation: CGFloat,
         defaultBrightness: CGFloat,
         monochromeSections: [MonochromeSection]?,
         hueSection: HueSection,
         bendSections: [BendSection]?) {
        
        self.minHue = minHue
        self.maxHue = maxHue
        self.defaultSaturation = defaultSaturation
        self.defaultBrightness = defaultBrightness
        self.monochromeSections = monochromeSections
        self.hueSection = hueSection
        self.bendSections = bendSections
    }
    
    var sliderColors: [Color] {
                return values.map { value in
                    if adjustBrightness {
                        return Color(hue: hue, saturation: defaultSaturation, brightness: value, opacity: 1.0)
                    } else {
                        return Color(hue: hue, saturation: value, brightness: defaultBrightness, opacity: 1.0)
                    }
                }
            }
        
        let monochromeColors: [[Color]]? = monochromeSections?.map { monochromeSection in
            // Where in the hue range to insert the monochrome section
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
            
            switch monochromeSection.color {
            case .black:
                let monochromeBrightnesses: [CGFloat]
                
                switch monochromeSection.position {
                case .start:
                    monochromeBrightnesses = Array(stride(from: 0.0, through: bendAdjustment.startBrightness, by: -monochromeSection.stepSize))
                case .end:
                    monochromeBrightnesses = Array(stride(from: bendAdjustment.endBrightness, through: 0.0, by: monochromeSection.stepSize))
                }
                
                return monochromeBrightnesses.map {
                    Color(hue: huePosition, saturation: defaultSaturation, brightness: $0, opacity: 1.0)
                }
                
            case .white:
                let monochromeSaturations: [CGFloat]
                
                switch monochromeSection.position {
                case .start:
                    monochromeSaturations = Array(stride(from: 0.0, through: bendAdjustment.startSaturation, by: -monochromeSection.stepSize))
                case .end:
                    monochromeSaturations = Array(stride(from: bendAdjustment.endSaturation, through: 0.0, by: monochromeSection.stepSize))
                }
                
                return monochromeSaturations.map {
                    Color(hue: huePosition, saturation: $0, brightness: defaultBrightness, opacity: 1.0)
                }
            }
        }
        
        let hueValues = Array(stride(from: minHue, to: maxHue, by: hueSection.stepSize))
        
        let hueColors: [Color] = hueValues.enumerated().map { (index, hue) in
            let normalizedHue = CGFloat(hue) / CGFloat(maxHue)
            let calculatedSaturation = calculateSaturation(index: index, hue: normalizedHue, defaultSaturation: defaultSaturation, bendSections: bendSections)
            
            return Color(hue: normalizedHue, saturation: calculatedSaturation, brightness: 1.0, opacity: 1.0)
        }
        
        let startSections = monochromeSections?.filter { $0.position == .start } ?? []
        let endSections = monochromeSections?.filter { $0.position == .end } ?? []
        
        return hueColors
    }
}

