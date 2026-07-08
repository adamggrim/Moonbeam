import Foundation
import SwiftUI

/// Model for a slider with discrete color blocks.
///
/// Supports explicit and implicit hard-edge sliders:
/// 1. **Explicit**: Initialize the slider using a custom array of `Color` objects.
/// 2. **Implicit**: Apply the `.hardEdge(into:)` modifier to convert a `SpectrumSliderModel` or `GradientSliderModel` into discrete color blocks sampled from the center of each block.
public struct HardEdgeSliderModel: ColorSliderDataSource {
    /// The sequence of colors that make up the discrete blocks on the slider.
    ///
    /// This property uses a non-optional array to guarantee that the slider track always has
    /// valid data to render.
    public let colors: [Color]
    
    /// Provides the model's color source as a discrete array, ensuring the slider track
    /// renders as discrete color blocks.
    public var colorSource: ColorSourceProvider {
        return .array(colors)
    }
    
    /// Creates a hard-edge slider model using an discrete array of colors.
    public init(colors: [Color]) {
        self.colors = colors.isEmpty ? [.clear] : colors
    }
}
