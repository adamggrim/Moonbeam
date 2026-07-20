import Foundation
import SwiftUI

/// Model for a slider with discrete color blocks.
///
/// Supports explicit and implicit hard-edge sliders:
/// 1. **Explicit**: Initialize the slider using a custom array of `Color`
///   objects.
/// 2. **Implicit**: Apply the `.hardEdge(into:)` modifier to convert an
///   `HSBSpectrumModel`, `OKLCHSpectrumModel` or `GradientSliderModel` into
///   discrete color blocks sampled from the center of each block.
internal struct HardEdgeSliderModel: ColorSliderDataSource {
    /// The sequence of colors that make up the discrete blocks on the slider.
    let colors: [Color]

    /// Provides the model's color source as a discrete array, ensuring the
    /// slider track renders as discrete color blocks.
    let colorSource: ColorSourceProvider

    /// Creates a hard-edge slider model using an discrete array of colors.
    init(colors: [Color]) {
        self.colors = colors
        self.colorSource = .array(colors)
    }
}
