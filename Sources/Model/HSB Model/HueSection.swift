import Foundation

/**
 A protocol for a section of the color slider with special conditions for
 saturation or brightness.
 */
protocol BendSection {
    var startHue: CGFloat { get }
    var endHue: CGFloat { get }
    
    var targetSaturation: CGFloat { get }
    var saturationDelta: CGFloat { get }
    var saturationIncrement: CGFloat { get }
    var defaultSaturation: CGFloat { get }
    
    var targetBrightness: CGFloat { get }
    var brightnessDelta: CGFloat { get }
    var brightnessIncrement: CGFloat { get }
    var defaultBrightness: CGFloat { get }
    
    var hueCount: CGFloat { get }
}

/**
 Main section of the color slider, for showing the full spectrum of color
 options
 */
struct HueSection {
    let minHue: CGFloat
    let maxHue: CGFloat
    
    var count: CGFloat {
        maxHue - minHue
    }
    
    var stepSize: CGFloat {
        1.0 / CGFloat(count - 1)
    }
}


/// A bend section that fades into the start or end of a color slider.
struct OneWayBendSection: BendSection {
    let startHue: CGFloat
    let endHue: CGFloat
    
    let targetSaturation: CGFloat
    let defaultSaturation: CGFloat
    let saturationDelta: CGFloat
    let saturationIncrement: CGFloat
    
    let targetBrightness: CGFloat
    let defaultBrightness: CGFloat
    let brightnessDelta: CGFloat
    let brightnessIncrement: CGFloat
    
    var hueCount: CGFloat {
        endHue - startHue
    }
    
    init(
        startHue: CGFloat,
        endHue: CGFloat,
        targetSaturation: CGFloat,
        defaultSaturation: CGFloat,
        targetBrightness: CGFloat,
        defaultBrightness: CGFloat
    ) {
        self.startHue = startHue
        self.endHue = endHue
        
        self.targetSaturation = targetSaturation
        self.defaultSaturation = defaultSaturation
        self.saturationDelta = defaultSaturation - targetSaturation
        
        self.targetBrightness = targetBrightness
        self.defaultBrightness = defaultBrightness
        self.brightnessDelta = defaultBrightness - targetBrightness
        
        self.saturationIncrement = saturationDelta / hueCount
        self.brightnessIncrement = brightnessDelta / hueCount
    }
}
    
    init(startHue: CGFloat, endHue: CGFloat, targetSaturation: CGFloat = 1.0, targetBrightness: CGFloat = 1.0) {
        self.startHue = startHue
        self.endHue = endHue
        
        self.targetSaturation = targetSaturation
        self.saturationDelta = defaultSaturation - targetSaturation
        
        self.targetBrightness = targetBrightness
        self.brightnessDelta = defaultBrightness - targetBrightness
        
        // Take into account whether the bend section is one-way or two-way
        let denominator: CGFloat = {
            if let middleHue {
                return abs(middleHue * 360 - startHue)
            } else {
                return CGFloat(hueCount)
            }
        }()
        
        self.saturationIncrement = saturationDelta / denominator
        self.brightnessIncrement = brightnessDelta / denominator
    }
}
