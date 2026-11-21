import Foundation
import SwiftUI

import MoonbeamShared

/// The color space used to interpolate between gradient colors.
public enum GradientColorSpace: Sendable {
    case rgb, oklab, oklch
}

/// Color provider for calculating gradient colors on demand.
public struct ColorGradient: ColorProvider {
    /// The sequence of colors making up the gradient.
    public let colors: [Color]

    /// The color space used to interpolate between colors.
    public let colorSpace: GradientColorSpace

    /// The target RGB color gamut.
    public let gamut: ColorGamut

    /// The Metal shader and Swift fallback used to render the gradient.
    public let colorSource: ColorSource

    /// A flag indicating whether to inset the interpolation bounds so all colors
    /// occupy equal visual widths.
    public let distributeEvenly: Bool

    /// The starting color of the gradient (computed for backward compatibility).
    public var startColor: Color { colors.first ?? .clear }

    /// The ending color of the gradient (computed for backward compatibility).
    public var endColor: Color { colors.last ?? .clear }

    /// Initializes a gradient color provider with multiple colors.
    ///
    /// - Parameters:
    ///   - colors: An array of colors to transition through sequentially.
    ///   - colorSpace: The color space used to interpolate between the colors.
    ///   - distributeEvenly: If `true`, maps the slider track so that all
    ///     colors occupy an equal width.
    ///   - gamut: The target RGB color gamut. Defaults to `.displayP3`.
    public init(
        colors: [Color],
        colorSpace: GradientColorSpace = .rgb,
        distributeEvenly: Bool = false,
        gamut: ColorGamut = .displayP3
    ) {
        precondition(colors.count >= 2, "ColorGradient requires at least two colors.")
        self.colors = colors
        self.colorSpace = colorSpace
        self.distributeEvenly = distributeEvenly
        self.gamut = gamut

        let fallback: @Sendable (Double) -> Color = { position in
            Self.interpolatedColor(
                at: position,
                colors: colors,
                colorSpace: colorSpace,
                distributeEvenly: distributeEvenly,
                gamut: gamut,
                in: EnvironmentValues()
            )
        }

        self.colorSource = .shader(generator: { size, isVertical in
            let spaceFlag: Float
            switch colorSpace {
            case .oklch: spaceFlag = Float(ColorSpaceOklch.rawValue)
            case .oklab: spaceFlag = Float(ColorSpaceOklab.rawValue)
            default:     spaceFlag = Float(ColorSpaceRGB.rawValue)
            }
            return ShaderLibrary.bundle(.module).gradientShader(
                .float2(size.width, size.height),
                .colorArray(colors),
                .float(isVertical ? 1.0 : 0.0),
                .float(spaceFlag),
                .float(distributeEvenly ? 1.0 : 0.0),
                .float(Float(gamut.shaderFlag))
            )
        }, fallback: fallback)
    }

    public func color(at position: Double, in environment: EnvironmentValues) -> Color {
        Self.interpolatedColor(
            at: position,
            colors: colors,
            colorSpace: colorSpace,
            distributeEvenly: distributeEvenly,
            gamut: gamut,
            in: environment
        )
    }

    private static func interpolatedColor(
        at position: Double,
        colors: [Color],
        colorSpace: GradientColorSpace,
        distributeEvenly: Bool,
        gamut: ColorGamut,
        in environment: EnvironmentValues
    ) -> Color {
        var adjustedPosition = max(0.0, min(1.0, position))
        if distributeEvenly {
            let inset = 0.5 / Double(colors.count)
            adjustedPosition = min(max(adjustedPosition, inset), 1.0 - inset)
            adjustedPosition = (adjustedPosition - inset) / (1.0 - 2.0 * inset)
        }

        let step = 1.0 / Double(colors.count - 1)
        let scaledPosition = adjustedPosition / step
        let index = min(Int(scaledPosition), colors.count - 2)
        let localRatio = scaledPosition - Double(index)

        let start = colors[index]
        let end = colors[index + 1]

        switch colorSpace {
        case .rgb:
            let mixed = start.mix(with: end, by: localRatio)
            return gamut == .sRGB
                ? ColorSpaceConverter.clampToSRGB(mixed, in: environment)
                : mixed
        case .oklab:
            return ColorSpaceConverter.interpolateOklab(
                from: start,
                to: end,
                at: localRatio,
                gamut: gamut,
                in: environment
            )
        case .oklch:
            return ColorSpaceConverter.interpolateOklch(
                from: start,
                to: end,
                at: localRatio,
                gamut: gamut,
                in: environment
            )
        }
    }
}
