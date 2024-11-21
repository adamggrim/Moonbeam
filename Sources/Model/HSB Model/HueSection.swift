import Foundation

// Main section of the color slider, for showing the full spectrum of color options
struct HSBHueSection {
    let minHue: CGFloat
    let maxHue: CGFloat
    
    var count: CGFloat {
        maxHue - minHue
    }
    
    var stepSize: CGFloat {
        1.0 / CGFloat(count - 1)
    }
}

// Section of the color slider with special conditions for saturation or brightness
struct BendSection {
    let startHue: CGFloat
    let endHue: CGFloat
    
    let bendSaturation: CGFloat
    let saturationDelta: CGFloat
    let saturationIncrement: CGFloat
    let defaultSaturation: CGFloat
    
    let bendBrightness: CGFloat
    let brightnessDelta: CGFloat
    let brightnessIncrement: CGFloat
    let defaultBrightness: CGFloat
    
    var hueCount: CGFloat {
        endHue - startHue
    }
    
    var middleHue: CGFloat {
        CGFloat(startHue + (hueCount / 2)) / 360
    }
    
    init(startHue: CGFloat, endHue: CGFloat, sectionCount: Int, bendSaturation: CGFloat = 1.0, bendBrightness: CGFloat = 1.0) {
        self.startHue = startHue
        self.endHue = endHue
        self.bendSaturation = bendSaturation
        self.saturationDelta = defaultSaturation - bendSaturation
        self.saturationIncrement = saturationDelta / (CGFloat(hueCount) / 2)
    }
}
