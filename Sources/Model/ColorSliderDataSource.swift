import SwiftUI

/// Protocol shared by `SpectrumModel` and `GradientModel`.
protocol ColorSliderDataSource {
    var sliderColors: [Color] { get }
}
