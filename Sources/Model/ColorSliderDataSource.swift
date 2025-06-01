import SwiftUI

enum ColorSourceProvider {
    /**
     Provides colors as a pre-computed array.
     
     Used for hard-edge colors.
     */
    case precomputed([Color])
    
    /**
     Dynamically calculates a color based on normalized position (0.0 to 1.0).
    
     Used for spectrums and gradients.
     */
    case dynamic((_ position: Double) -> Color)
}

/// Protocol shared by `SpectrumSliderModel` and `GradientSliderModel`.
protocol ColorSliderDataSource {
    var colorSource: ColorSourceProvider { get }

}
