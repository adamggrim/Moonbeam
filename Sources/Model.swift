import Foundation
import SwiftUI

let maxWhite = 119
let maxHue = 359

let whiteCount = 120
let hueCount = 360
let colorCount = 480

let whitesRatio = CGFloat(whiteCount) / CGFloat(colorCount)
let huesRatio = CGFloat(hueCount) / CGFloat(colorCount)
let whitesStepSize = 1.0 / CGFloat(maxWhite)

let blueSaturation = 0.5
let defaultSaturation = 0.75

struct SaturationBend {
    let startingHue: Int
    // Number of hues in the bend section
    let sectionCount: Int
    // Saturation at the center of the bend
    let targetSaturation: CGFloat
}

// Section of the color slider with special conditions for saturation
struct HueSection {
    let index: Int
    let start: Int
//  The total number of hues in the section
    let sectionCount: Int
    let hueSaturation: CGFloat
    
    let hueIndex: Int
    let saturationDifference: CGFloat
    let saturationIncrement: CGFloat
    
    init(index: Int, start: Int, sectionCount: Int, hueSaturation: CGFloat) {
        
        self.index = index
        self.start = start
        self.sectionCount = sectionCount
        self.hueSaturation = hueSaturation
        
        self.hueIndex = index - self.start
        self.saturationDifference = defaultSaturation - hueSaturation
        self.saturationIncrement = saturationDifference / (CGFloat(sectionCount) / 2)
    }
}

struct HueRatios {
    let hueStart: Int
    let hueSectionCount: Int
    
    var start: CGFloat {
        CGFloat(hueStart) / 360
    }
    
    var middle: CGFloat {
        CGFloat(hueStart + (hueSectionCount / 2)) / 360
    }
    
    var end: CGFloat {
        CGFloat(hueStart + hueSectionCount) / 360
    }
}

let sliderColors: [Color] = {
    let hueValues = Array(0...maxHue)
    let whiteValues = Array(stride(from: 0.0, through: defaultSaturation, by: whitesStepSize))
    
    let whitesArray: [Color] = whiteValues.map {
        Color(hue: 0.0,
              saturation: $0,
              brightness: 1.0,
              opacity: 1.0)
    }
    
    let huesArray: [Color] = hueValues.enumerated().map { (index, hue) in
        let normalizedHue = CGFloat(hue) / CGFloat(maxHue)
        let calculatedSaturation = calculateSaturation(index: index, hue: normalizedHue)
        
        return Color(hue: normalizedHue,
              saturation: calculatedSaturation,
              brightness: 1.0,
              opacity: 1.0)
    }
    
    // Combined array has 480 elements.
    return whitesArray + huesArray
}()

let toggleTintColors: [Color] = {
    let hueValues = Array(0...maxHue)
    let whiteValues = Array(stride(from: 0.0, through: defaultSaturation, by: whitesStepSize))
    
    let whitesArray: [Color] = whiteValues.map {
        
        Color(hue: 0.0,
              saturation: $0,
              brightness: 1.0,
              opacity: 1.0)
    }
    
    let huesArray: [Color] = hueValues.enumerated().map { (index, hue) in
        let normalizedHue = CGFloat(hue) / CGFloat(maxHue)
        let calculatedSaturation = calculateSaturation(index: index, hue: normalizedHue)
        
        return Color(hue: normalizedHue,
              saturation: calculatedSaturation,
              brightness: 1.0,
              opacity: 1.0)
    }
    
    // Combined array has 480 elements.
    return whitesArray + huesArray
}()

//  Function to incrementally reduce, then increase, the saturation of certain hues on ColorSliderView to improve legibility
func calculateSaturation(index: Int, hue: CGFloat) -> CGFloat {
    let blueRatios = HueRatios(hueStart: 180, hueSectionCount: 120)
    let blueSection = HueSection(index: index, start: blueRatios.hueStart, sectionCount: blueRatios.hueSectionCount, hueSaturation: blueSaturation)
    
    switch hue {
    
//  Increasingly blue
    case blueRatios.start ..< blueRatios.middle:
        return CGFloat(defaultSaturation - (blueSection.saturationIncrement * CGFloat(blueSection.hueIndex)))
    
//  Decreasingly blue
    case blueRatios.middle ..< blueRatios.end:
        return CGFloat(blueSection.hueSaturation + (blueSection.saturationIncrement * CGFloat(blueSection.hueIndex - (blueSection.sectionCount / 2))))
    
    default:
        return CGFloat(defaultSaturation)
    }
}
