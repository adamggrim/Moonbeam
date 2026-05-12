import SwiftUI

private struct PreviewContainer: View {
    let dataSource: ColorSliderDataSource
    var axis: Axis = .horizontal

    @State private var selectedColor: Color = .clear

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            ColorSliderView(
                selectedColor: $selectedColor,
                dataSource: dataSource,
                axis: axis
            )
        }
    }
}

#Preview("Horizontal Slider") {
    let spectrumModel = try! SpectrumSliderModel {
        BlackSection()
        HueSection(minHue: 0.0, maxHue: 1.0)
        WhiteSection()
    }
    PreviewContainer(dataSource: spectrumModel)
}

#Preview("Vertical Slider") {
    let spectrumModel = try! SpectrumSliderModel {
        BlackSection()
        HueSection(minHue: 0.0, maxHue: 1.0)
        WhiteSection()
    }
    PreviewContainer(dataSource: spectrumModel, axis: .vertical)
}

#Preview("Spectrum with BendSections") {
    let spectrumModel = try! SpectrumSliderModel {
        HueSection(
            minHue: 0.0,
            maxHue: 1.0,
            saturationBends: {
                OneWayBend(hue: 0.0...(40.0 / 360), target: 0.5)
                TwoWayBend(hue: (200.0 / 360)...(280.0 / 360), target: 0.3)
            }
        )
    }

    PreviewContainer(dataSource: spectrumModel)
}

#Preview("Spectrum with MonochromeSections") {
    let spectrumModel = try! SpectrumSliderModel {
        BlackSection()
        WhiteSection()

        HueSection(minHue: 0.0, maxHue: 1.0)

        BlackSection()
        WhiteSection()

    }

    PreviewContainer(dataSource: spectrumModel)
}

#Preview("Gradient") {
    let gradientModel = GradientSliderModel(
        startColor: .cyan,
        endColor: .purple
    )

    PreviewContainer(dataSource: gradientModel)
}

#Preview("Overlapping Bends (Saturation & Brightness)") {
    let spectrumModel = try! SpectrumSliderModel {
        HueSection(
            minHue: 0.0,
            maxHue: 1.0,
            saturationBends: {
                TwoWayBend(hue: (120.0 / 360)...(240.0 / 360), target: 0.3)
            },
            brightnessBends: {
                TwoWayBend(hue: (200.0 / 360)...(300.0 / 360), target: 0.4)
            }
        )
    }

    PreviewContainer(dataSource: spectrumModel)
}

#Preview("Circle Thumb (Horizontal)") {
    let spectrumModel = try! SpectrumSliderModel {
        BlackSection()
        HueSection(minHue: 0.0, maxHue: 1.0)
        WhiteSection()
    }
    PreviewContainer(dataSource: spectrumModel)
        .colorSliderThumbStyle(.circle)
}

#Preview("Circle Thumb (Vertical)") {
    let spectrumModel = try! SpectrumSliderModel {
        BlackSection()
        HueSection(minHue: 0.0, maxHue: 1.0)
        WhiteSection()
    }
    PreviewContainer(dataSource: spectrumModel, axis: .vertical)
        .colorSliderThumbStyle(.circle)
}

#Preview("Glass Disabled") {
    let spectrumModel = try! SpectrumSliderModel {
        HueSection(minHue: 0.0, maxHue: 1.0)
    }

    PreviewContainer(dataSource: spectrumModel)
        .colorSliderDisableLiquidGlass(true)
}

#Preview("Custom Dimensions") {
    let gradientModel = GradientSliderModel(
        startColor: .green,
        endColor: .yellow
    )

    PreviewContainer(dataSource: gradientModel)
        .colorSliderDimensions(
            thickness: 40,
            length: 200,
            previewOffset: -100
        )
}
