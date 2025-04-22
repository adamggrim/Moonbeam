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

/// An extension for computed properties shared among all BendSection structs.
extension BendSection {
    var hueCount: CGFloat {endHue - startHue}
    var saturationDelta: CGFloat {defaultSaturation - targetSaturation}
    var brightnessDelta: CGFloat {defaultBrightness - targetBrightness}
}

/**
 The color section of the color slider, for showing the full spectrum of color
 options.
 */
struct HueSection {
    let minHue: CGFloat
    let maxHue: CGFloat
    
    let count: CGFloat
    let stepSize: CGFloat
    
    init(minHue: CGFloat, maxHue: CGFloat) {
        self.minHue = minHue
        self.maxHue = maxHue
        
        let calculatedCount = maxHue - minHue
        self.count = calculatedCount
        
        if calculatedCount - 1 > 0 {
            self.stepSize = 1.0 / (calculatedCount - 1)
        } else {
            self.stepSize = 0.0
        }
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
        
        self.targetBrightness = targetBrightness
        self.defaultBrightness = defaultBrightness
        
        self.saturationIncrement = saturationDelta / hueCount
        self.brightnessIncrement = brightnessDelta / hueCount
    }
}

/// A bend section that occurs in the middle of a color slider.
struct TwoWayBendSection: BendSection {
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
    
    let middleHue: CGFloat
    
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
        
        self.targetBrightness = targetBrightness
        self.defaultBrightness = defaultBrightness
        
        self.middleHue = (startHue + hueCount / 2) / 360
        
        /* Calculate increments based on half the hueCount for
         TwoWayBendSection.
         */
        let denominator = abs(middleHue * 360 - startHue)
        self.saturationIncrement = saturationDelta / denominator
        self.brightnessIncrement = brightnessDelta / denominator
    }
}
