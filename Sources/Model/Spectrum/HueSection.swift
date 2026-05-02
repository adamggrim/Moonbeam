import Foundation

/**
 A protocol for a section of the color slider with special conditions for
 saturation or brightness.
 */
protocol BendSection {
    var startHue: CGFloat { get }
    var endHue: CGFloat { get }
    
    var targetSaturation: CGFloat { get }
    var baseSaturation: CGFloat { get }
    
    var targetBrightness: CGFloat { get }
    var baseBrightness: CGFloat { get }
    
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
    let baseSaturation: CGFloat
    let saturationIncrement: CGFloat
    
    let targetBrightness: CGFloat
    let baseBrightness: CGFloat
    let brightnessIncrement: CGFloat
    
    let hueCount: CGFloat
    
    init(
        startHue: CGFloat,
        endHue: CGFloat,
        targetSaturation: CGFloat,
        baseSaturation: CGFloat,
        targetBrightness: CGFloat,
        baseBrightness: CGFloat
    ) {
        let hueCount = endHue - startHue
        let saturationDelta = baseSaturation - targetSaturation
        let brightnessDelta = baseBrightness - targetBrightness
        
        self.startHue = startHue
        self.endHue = endHue
        
        self.targetSaturation = targetSaturation
        self.baseSaturation = baseSaturation
        self.saturationIncrement = hueCount != 0 ? saturationDelta / hueCount : 0
        
        self.targetBrightness = targetBrightness
        self.baseBrightness = baseBrightness
        self.brightnessIncrement = hueCount != 0 ? brightnessDelta / hueCount : 0
        
        self.hueCount = hueCount
    }
}

/// A bend section that occurs in the middle of a color slider.
struct TwoWayBendSection: BendSection {
    let startHue: CGFloat
    let endHue: CGFloat
    
    let targetSaturation: CGFloat
    let baseSaturation: CGFloat
    
    let targetBrightness: CGFloat
    let baseBrightness: CGFloat
    
    let hueCount: CGFloat
    
    init(
        startHue: CGFloat,
        endHue: CGFloat,
        targetSaturation: CGFloat,
        baseSaturation: CGFloat,
        targetBrightness: CGFloat,
        baseBrightness: CGFloat
    ) {
        self.startHue = startHue
        self.endHue = endHue
        
        self.targetSaturation = targetSaturation
        self.baseSaturation = baseSaturation
        
        self.targetBrightness = targetBrightness
        self.baseBrightness = baseBrightness
        
        self.hueCount = endHue - startHue
    }
}
