import SwiftUI

/// Represents whether the colors are defined by an array, a function or a Metal
/// shader.
internal enum ColorSourceProvider: Sendable {
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

/// Protocol shared by `SpectrumSliderModel`, `GradientSliderModel` and `HardEdgeSliderModel`.
internal protocol ColorSliderDataSource: Sendable {

    /// Determines how the slider track is drawn on screen.
    var colorSource: ColorSourceProvider { get }
}

internal extension ColorSliderDataSource {
    /// Converts a continuous color slider into a hard-edge slider with discrete
    /// color blocks.
    func hardEdge(into steps: Int) -> HardEdgeSliderModel {
        guard steps > 1 else { return HardEdgeSliderModel(colors: []) }

        switch self.colorSource {
        case .array(let colors):
            return HardEdgeSliderModel(colors: colors)

        case .function(let colorGenerator), .shader(_, let colorGenerator):
            let generatedColors = (0..<steps).map { i in
                // Sample from the center of the color block's position on the
                // spectrum.
                let position = (Double(i) + 0.5) / Double(steps)
                return colorGenerator(position)
            }
            return HardEdgeSliderModel(colors: generatedColors)
        }
    }
}
