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

/**
 Section of the color slider with special conditions for saturation or
 brightness
 */
struct BendSection {
    let startHue: CGFloat
    let endHue: CGFloat
    
    let targetSaturation: CGFloat
    let saturationDelta: CGFloat
    let saturationIncrement: CGFloat
    let defaultSaturation: CGFloat
    
    let targetBrightness: CGFloat
    let brightnessDelta: CGFloat
    let brightnessIncrement: CGFloat
    let defaultBrightness: CGFloat
    
    var hueCount: CGFloat {
        endHue - startHue
    }
    
    var bendMode: BendMode
    var middleHue: CGFloat? {
        guard bendMode == .twoWay else { return nil }
        return CGFloat(startHue + (hueCount / 2)) / 360
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
