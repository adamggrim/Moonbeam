import Foundation
import SwiftUI

/// Model for calculating gradient colors on demand.
struct GradientSliderModel: ColorSliderDataSource {
    let startColor: Color
    let endColor: Color

    var colorSource: ColorSourceProvider {
        return .function { position in
            startColor.mix(with: endColor, by: position)
        }
    }

    init(startColor: Color, endColor: Color) {
        self.startColor = startColor
        self.endColor = endColor
    }
}
