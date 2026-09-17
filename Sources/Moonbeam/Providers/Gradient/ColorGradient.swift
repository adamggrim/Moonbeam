import Foundation
import SwiftUI

import MoonbeamShared

/// The color space used to interpolate between starting and ending colors.
public enum GradientColorSpace: Sendable {
    case rgb, oklab, oklch
}

/// Color provider for calculating gradient colors on demand.
public struct ColorGradient: ColorProvider {
    /// The starting color of the gradient.
    public let startColor: Color

    /// The ending color of the gradient.
    public let endColor: Color

    /// The color space used to calculate the interpolation between the starting
    /// and ending colors.
    public let colorSpace: GradientColorSpace

    public let colorSource: ColorSource

    public init(startColor: Color, endColor: Color, colorSpace: GradientColorSpace = .rgb) {
        self.startColor = startColor
        self.endColor = endColor
        self.colorSpace = colorSpace

        let fallback: @Sendable (Double) -> Color = { position in
            switch colorSpace {
            case .rgb: return startColor.mix(with: endColor, by: position)
            case .oklab, .oklch: return startColor.mix(with: endColor, by: position, in: .perceptual)
            }
        }

        self.colorSource = .shader(generator: { size, isVertical in
            let spaceFlag: Float
            switch colorSpace {
            case .oklch: spaceFlag = Float(ColorSpaceOKLCH.rawValue)
            case .oklab: spaceFlag = Float(ColorSpaceOKLAB.rawValue)
            default:     spaceFlag = Float(ColorSpaceRGB.rawValue)
            }
            return ShaderLibrary.bundle(.module).gradientShader(
                .float2(size.width, size.height),
                .color(startColor),
                .color(endColor),
                .float(isVertical ? 1.0 : 0.0),
                .float(spaceFlag)
            )
        }, fallback: fallback)
    }
}
