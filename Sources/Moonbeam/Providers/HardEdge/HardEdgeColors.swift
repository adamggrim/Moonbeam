import Foundation
import SwiftUI

/// Color provider for a slider with discrete color blocks.
///
/// Supports explicit and implicit hard-edge sliders:
/// 1. **Explicit**: Initialize the slider using a custom array of `Color`
///   objects.
/// 2. **Implicit**: Apply the `.hardEdge(into:)` modifier to convert a
///   `Spectrum<HSB>`, `Spectrum<Oklch>` or `ColorGradient` into
///   discrete color blocks sampled from the center of each block.
public struct HardEdgeColors: ColorProvider {
    /// The sequence of colors that make up the discrete blocks on the slider.
    public let colors: [Color]

    /// The color array used to render the track as discrete blocks.
    public let colorSource: ColorSource

    /// Creates a hard-edge slider model using a discrete array of colors.
    ///
    /// - Parameter colors: The sequence of colors constituting the discrete
    ///   blocks.
    public init(colors: [Color]) {
        self.colors = colors
        self.colorSource = .array(colors)
    }
}

public extension ColorProvider {
    /// Converts a continuous color slider into a hard-edge slider with discrete
    /// color blocks.
    ///
    /// - Parameters:
    ///   - steps: The number of discrete color blocks to generate.
    ///   - environment: The environment used to resolve dynamic colors.
    ///     Defaults to `EnvironmentValues()`.
    /// - Returns: A `HardEdgeColors` provider containing the sampled colors.
    func hardEdge(
        into steps: Int,
        in environment: EnvironmentValues = EnvironmentValues()
    ) -> HardEdgeColors {
        guard steps > 1 else { return HardEdgeColors(colors: []) }

        switch self.colorSource {
        case .array(let colors):
            return HardEdgeColors(colors: colors)

        case .shader:
            let generatedColors = (0..<steps).map { i in
                // Sample from the center of the discrete color block's
                // position.
                let position = (Double(i) + 0.5) / Double(steps)
                return self.color(at: position, in: environment)
            }
            return HardEdgeColors(colors: generatedColors)
        }
    }
}
