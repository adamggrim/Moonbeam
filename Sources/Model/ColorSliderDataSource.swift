import SwiftUI

enum ColorSourceProvider {
    /**
     Provides colors as a precomputed array.
     
     Used for hard-edge color color sliders.
     */
    case array([Color])
    
    /**
     Dynamically calculates a color based on normalized position (i.e., 0.0 to
     1.0).
    
     Used for spectrum and gradient color sliders.
     */
    case dynamic((_ position: Double) -> Color)
}

/// Protocol shared by `SpectrumSliderModel` and `GradientSliderModel`.
protocol ColorSliderDataSource {
    var colorSource: ColorSourceProvider { get }
}
