import SwiftUI

/// Represents whether the colors are defined by an array or function.
public enum ColorSourceProvider {
    /**
     Provides colors as a precomputed array.

     Designed for hard-edge color sliders.
     */
    case array([Color])

    /**
     Dynamically calculates a color based on normalized position (ie., 0.0 to
     1.0).

     Designed for spectrum and gradient color sliders.
     */
    case function((_ position: Double) -> Color)
}

/// Protocol shared by `SpectrumSliderModel` and `GradientSliderModel`.
public protocol ColorSliderDataSource {
    var colorSource: ColorSourceProvider { get }
}
