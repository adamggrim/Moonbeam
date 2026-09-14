import SwiftUI

/// Represents whether the colors are defined by an array, a function or a Metal
/// shader.
public enum ColorSource: Sendable {
    /// Provides colors as a precomputed array.
    ///
    /// Designed for hard-edge color sliders.
    case array([Color])

    /// Dynamically calculates a color based on normalized position (i.e., 0.0
    /// to 1.0).
    ///
    /// Designed for spectrum and gradient color sliders.
    case function(@Sendable (_ position: Double) -> Color)

    /// Renders the background using a Metal shader.
    case shader(generator: @Sendable (
        _ size: CGSize, _ isVertical: Bool
    ) -> Shader, fallback: @Sendable (_ position: Double) -> Color)
}

/// Protocol shared by `SpectrumColorProvider`, `ColorGradient` and `HardEdgeColors`.
public protocol ColorProvider: Sendable {

    /// Determines how the slider track is drawn on screen.
    var colorSource: ColorSource { get }

    /// Resolves a descriptive color name for VoiceOver.
    func accessibilityColorName(for value: Double) -> String?
}

public extension ColorProvider {
    /// A default that returns `nil` to indicate the data source does not
    /// provide color names.
    func accessibilityColorName(for value: Double) -> String? { return nil }

    /// Converts a continuous color slider into a hard-edge slider with discrete
    /// color blocks.
    func hardEdge(into steps: Int) -> HardEdgeColors {
        guard steps > 1 else { return HardEdgeColors(colors: []) }

        switch self.colorSource {
        case .array(let colors):
            return HardEdgeColors(colors: colors)

        case .function(let colorGenerator), .shader(_, let colorGenerator):
            let generatedColors = (0..<steps).map { i in
                // Sample from the center of the color block's position on the
                // spectrum.
                let position = (Double(i) + 0.5) / Double(steps)
                return colorGenerator(position)
            }
            return HardEdgeColors(colors: generatedColors)
        }
    }
}
