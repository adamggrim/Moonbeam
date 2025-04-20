import Foundation
import SwiftUI

/// Model for assembling gradient colors into an array.
struct GradientModel: ColorSliderDataSource {
    let startColor: Color
    let endColor: Color
    
    let count: Int
    
    /**
     Generates an array of `Color` objects, ranging from `startColor` to
     `endColor`, using `Color.mix()`.
     
     The resulting array contains `count` colors. If `count` is 1, the array
     contains only `startColor`. If `count` is 0 or less, it returns an empty
     array.
     
     - Parameters:
        - startColor: The starting color of the gradient.
        - endColor: The ending color of the gradient.
        - count: The number of colors in the slider, including `startColor`
        and `endColor`.
     
     - Returns: An array of `Color` objects representing a gradient from
     `startColor` to `endColor`.
     */
    private static func generateSliderColors(
        startColor: Color,
        endColor: Color,
        count: Int
    ) -> [Color] {
        guard count > 0 else { return [] }
        
        if count == 1 { return [startColor] }
        
        var colors: [Color] = []
        let steps = count - 1
        
        for i in 0..<count {
            let gradientRatio = Double(i) / Double(steps)
            let middleColor = startColor.mix(
                with: endColor,
                by: gradientRatio
            )
            colors.append(middleColor)
        }
        
        return colors
    }
    
    let sliderColors: [Color]
    
    init(startColor: Color, endColor: Color, count: Int) {
        self.startColor = startColor
        self.endColor = endColor
        self.count = count
        self.sliderColors = Self.generateSliderColors(
            startColor: self.startColor,
            endColor: self.endColor,
            count: self.count
        )
    }
}
