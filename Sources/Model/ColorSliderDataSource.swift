import SwiftUI

/// Protocol shared by `SpectrumSliderModel` and `GradientSliderModel`.
protocol ColorSliderDataSource {
    var sliderColors: [Color] { get }
}
