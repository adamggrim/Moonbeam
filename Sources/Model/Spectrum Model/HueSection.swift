import Foundation

/**
 A protocol for a section of the color slider with special conditions for
 saturation or brightness.
 */
protocol BendSection {
    var startHue: CGFloat { get }
    var endHue: CGFloat { get }
    
    var targetSaturation: CGFloat { get }
    var defaultSaturation: CGFloat { get }
    var saturationIncrement: CGFloat { get }
    
    var targetBrightness: CGFloat { get }
    var defaultBrightness: CGFloat { get }
    var brightnessIncrement: CGFloat { get }
    
    var hueCount: CGFloat { get }
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
    let saturationIncrement: CGFloat
    
    let targetBrightness: CGFloat
    let defaultBrightness: CGFloat
    let brightnessIncrement: CGFloat
    
    let hueCount: CGFloat
    
    init(
        startHue: CGFloat,
        endHue: CGFloat,
        targetSaturation: CGFloat,
        defaultSaturation: CGFloat,
        targetBrightness: CGFloat,
        defaultBrightness: CGFloat
    ) {
        let hueCount = endHue - startHue
        let saturationDelta = defaultSaturation - targetSaturation
        let brightnessDelta = defaultBrightness - targetBrightness
        
        self.startHue = startHue
        self.endHue = endHue
        
        self.targetSaturation = targetSaturation
        self.defaultSaturation = defaultSaturation
        self.saturationIncrement = hueCount != 0 ? saturationDelta / hueCount : 0
        
        self.targetBrightness = targetBrightness
        self.defaultBrightness = defaultBrightness
        self.brightnessIncrement = hueCount != 0 ? brightnessDelta / hueCount : 0
        
        self.hueCount = hueCount
    }
}

/// A bend section that occurs in the middle of a color slider.
struct TwoWayBendSection: BendSection {
    let startHue: CGFloat
    let endHue: CGFloat
    
    let targetSaturation: CGFloat
    let defaultSaturation: CGFloat
    let saturationIncrement: CGFloat
    
    let targetBrightness: CGFloat
    let defaultBrightness: CGFloat
    let brightnessIncrement: CGFloat
    
    let hueCount: CGFloat
    let middleHue: CGFloat
    
    init(
        startHue: CGFloat,
        endHue: CGFloat,
        targetSaturation: CGFloat,
        defaultSaturation: CGFloat,
        targetBrightness: CGFloat,
        defaultBrightness: CGFloat
    ) {
        let hueCount = endHue - startHue
        let middleHue: CGFloat = (startHue + hueCount) / 2
        let denominator = abs(middleHue * 360 - startHue)
        let saturationDelta = defaultSaturation - targetSaturation
        let brightnessDelta = defaultBrightness - targetBrightness
        
        self.startHue = startHue
        self.endHue = endHue
        
        self.targetSaturation = targetSaturation
        self.defaultSaturation = defaultSaturation
        self.saturationIncrement = denominator != 0 ? saturationDelta / denominator : 0
        
        self.targetBrightness = targetBrightness
        self.defaultBrightness = defaultBrightness
        self.brightnessIncrement = denominator != 0 ? brightnessDelta / denominator : 0
        
        self.hueCount = hueCount
        self.middleHue = middleHue
    }
}
