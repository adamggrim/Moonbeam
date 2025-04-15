import SwiftUI

/**
 Protocol shared by `SpectrumColorSliderModel` and `GradientColorSliderModel`.
 **/
protocol ColorSliderDataSource {
    var sliderColors: [Color] { get }
}
