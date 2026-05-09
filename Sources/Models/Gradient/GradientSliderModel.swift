import Foundation
import SwiftUI

/// Model for calculating gradient colors on demand.
public struct GradientSliderModel: ColorSliderDataSource {
    public let startColor: Color
    public let endColor: Color

    public var colorSource: ColorSourceProvider {
        return .function { position in
            startColor.mix(with: endColor, by: position)
        }
    }

    public init(startColor: Color, endColor: Color) {
        self.startColor = startColor
        self.endColor = endColor
    }
}
