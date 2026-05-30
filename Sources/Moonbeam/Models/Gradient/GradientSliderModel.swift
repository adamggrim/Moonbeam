import Foundation
import SwiftUI

public enum GradientColorSpace {
    case rgb, oklab, oklch
}

/// Model for calculating gradient colors on demand.
public struct GradientSliderModel: ColorSliderDataSource {
    public let startColor: Color
    public let endColor: Color
    public let colorSpace: GradientColorSpace

    public var colorSource: ColorSourceProvider {
        let fallback: (Double) -> Color = { position in
            switch colorSpace {
            case .rgb: return startColor.mix(with: endColor, by: position)
            case .oklab, .oklch: return startColor.mix(with: endColor, by: position, in: .perceptual)
            }
        }

        return .shader(generator: { size, isVertical in
            let spaceFlag: Float = colorSpace == .oklch ? 2.0 : (colorSpace == .oklab ? 1.0 : 0.0)
            return ShaderLibrary.bundle(.module).gradientShader(
                .float2(size.width, size.height),
                .color(startColor),
                .color(endColor),
                .float(isVertical ? 1.0 : 0.0),
                .float(spaceFlag)
            )
        }, fallback: fallback)
    }

    public init(startColor: Color, endColor: Color, colorSpace: GradientColorSpace = .rgb) {
        self.startColor = startColor
        self.endColor = endColor
        self.colorSpace = colorSpace
    }
}
