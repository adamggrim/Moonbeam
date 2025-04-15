import Foundation
import SwiftUI

// Model for assembling gradient colors into an array
struct GradientColorSliderModel {
    let startColor: Color
    let endColor: Color
    
    let count: Int
    
    /**
     Generates an array of `Color` objects, ranging from `startColor` to
     `endColor`, using `Color.mix()`.
     
     The resulting array contains `count` colors. If `count` is 1, the array
     contains only `startColor`. If `count` is 0 or less, it returns an empty
     array.
     
     - Returns: An array of `Color` objects representing the gradient from
     `startColor` to `endColor`.
     */
    private func generateSliderColors() -> [Color] {
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
}
