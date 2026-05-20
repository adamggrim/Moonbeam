import Foundation
import SwiftUI

/// Model for calculating gradient colors on demand.
public struct GradientSliderModel: ColorSliderDataSource {
    public let startColor: Color
    public let endColor: Color

    public var colorSource: ColorSourceProvider {
        let fallback: (Double) -> Color = { position in
            startColor.mix(with: endColor, by: position)
        }

        return .shader(generator: { size, isVertical in
            ShaderLibrary.bundle(.module).gradientShader(
                .float2(size.width, size.height),
                .color(startColor),
                .color(endColor),
                .float(isVertical ? 1.0 : 0.0)
            )
        }, fallback: fallback)
    }

    public init(startColor: Color, endColor: Color) {
        self.startColor = startColor
        self.endColor = endColor
    }
}
