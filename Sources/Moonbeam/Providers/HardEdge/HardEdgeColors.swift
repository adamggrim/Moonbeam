import Foundation
import SwiftUI

/// Color provider for a slider with discrete color blocks.
///
/// Supports explicit and implicit hard-edge sliders:
/// 1. **Explicit**: Initialize the slider using a custom array of `Color`
///   objects.
/// 2. **Implicit**: Apply the `.hardEdge(into:)` modifier to convert an
///   `Spectrum<HSB>`, `Spectrum<OKLCH>` or `ColorGradient` into
///   discrete color blocks sampled from the center of each block.
public struct HardEdgeColors: ColorProvider {
    /// The sequence of colors that make up the discrete blocks on the slider.
    public let colors: [Color]

    /// Provides the model's color source as a discrete array, ensuring the
    /// slider track renders as discrete color blocks.
    public let colorSource: ColorSource

    /// Creates a hard-edge slider model using an discrete array of colors.
    public init(colors: [Color]) {
        self.colors = colors
        self.colorSource = .array(colors)
    }
}

public extension ColorProvider {
    /// Converts a continuous color slider into a hard-edge slider with discrete
    /// color blocks.
    func hardEdge(into steps: Int) -> HardEdgeColors {
        guard steps > 1 else { return HardEdgeColors(colors: []) }

        switch self.colorSource {
        case .array(let colors):
            return HardEdgeColors(colors: colors)

        case .function(let colorGenerator), .shader(_, let colorGenerator):
            let generatedColors = (0..<steps).map { i in
                // Sample from the center of the color block's position.
                let position = (Double(i) + 0.5) / Double(steps)
                return colorGenerator(position)
            }
            return HardEdgeColors(colors: generatedColors)
        }
    }
}
