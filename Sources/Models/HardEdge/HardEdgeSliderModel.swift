import Foundation
import SwiftUI

/// Model for a slider with discrete color blocks.
///
///Supports explicit and implicit hard-edge sliders:
/// 1. **Explicit**: Initialize the slider using a custom array of `Color` objects.
/// 2. **Implicit**: Apply the `.hardEdge(into:)` modifier to convert a `SpectrumSliderModel` or `GradientSliderModel` into discrete color blocks.
public struct HardEdgeSliderModel: ColorSliderDataSource {
    public let colors: [Color]
    
    public var colorSource: ColorSourceProvider {
        return .array(colors)
    }
    
    public init(colors: [Color]) {
        self.colors = colors.isEmpty ? [.clear] : colors
    }
}
