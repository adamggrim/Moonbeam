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
    
    let targetBrightness: CGFloat
    let defaultBrightness: CGFloat
    
    var saturationDelta: CGFloat {
        targetSaturation - defaultSaturation
    }
    
    var brightnessDelta: CGFloat {
        targetBrightness - defaultBrightness
    }
    
    var hueCount: CGFloat {
        endHue - startHue
    }
    
    var saturationIncrement: CGFloat {
        guard hueCount != 0 else { return 0 }
        return saturationDelta / hueCount
    }
    
    var brightnessIncrement: CGFloat {
        guard hueCount != 0 else { return 0 }
        return brightnessDelta / hueCount
    }
}

/// A bend section that occurs in the middle of a color slider.
struct TwoWayBendSection: BendSection {
    let startHue: CGFloat
    let endHue: CGFloat
    
    let targetSaturation: CGFloat
    let defaultSaturation: CGFloat
    
    let targetBrightness: CGFloat
    let defaultBrightness: CGFloat
    
    var middleHue: CGFloat {
        (startHue + endHue / 2) / 360
    }
    
    /* Calculate increments based on half the hueCount for
     TwoWayBendSection.
     */
    var denominator: CGFloat {
        abs(middleHue * 360 - startHue)
    }
    
    var saturationIncrement: CGFloat {
        saturationDelta / denominator
    }

    var brightnessIncrement: CGFloat {
        brightnessDelta / denominator
    }
}
