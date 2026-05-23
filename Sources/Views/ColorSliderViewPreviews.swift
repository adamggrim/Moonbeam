import SwiftUI

private struct PreviewContainer: View {
    let dataSource: ColorSliderDataSource
    var axis: Axis = .horizontal
    var backgroundColor: Color = .black

    @State private var selectedColor: Color = .clear

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            ColorSliderView(
                selectedColor: $selectedColor,
                dataSource: dataSource,
                axis: axis
            )
        }
    }
}

#Preview("Horizontal Slider") {
    let spectrumModel = SpectrumSliderModel {
        BlackSection()
        HueSection(minHue: 0.0, maxHue: 1.0)
        WhiteSection()
    }
    PreviewContainer(dataSource: spectrumModel)
}

#Preview("Vertical Slider") {
    let spectrumModel = SpectrumSliderModel {
        BlackSection()
        HueSection(minHue: 0.0, maxHue: 1.0)
        WhiteSection()
    }
    PreviewContainer(dataSource: spectrumModel, axis: .vertical)
}

#Preview("Spectrum with BendSections") {
    let spectrumModel = SpectrumSliderModel {
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
    let spectrumModel = SpectrumSliderModel {
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

#Preview("Hard-Edge (Explicit)") {
    let customStops = HardEdgeSliderModel(colors: [
        .green, .yellow, .orange, .red, .purple, .blue
    ])

    PreviewContainer(dataSource: customStops)
}

#Preview("Hard-Edge Spectrum (Implicit)") {
    let chunkySpectrum = SpectrumSliderModel {
        HueSection(minHue: 0.0, maxHue: 1.0)
    }.hardEdge(into: 10)
    
    PreviewContainer(dataSource: chunkySpectrum)
}

#Preview("Hard-Edge Gradient (Implicit)") {
    let chunkyGradient = GradientSliderModel(
        startColor: .cyan,
        endColor: .purple
    ).hardEdge(into: 6)

    PreviewContainer(dataSource: chunkyGradient)
}

#Preview("Hard-Edge Spectrum with BendSections") {
    let bentSpectrum = SpectrumSliderModel {
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
    .hardEdge(into: 8)

    PreviewContainer(dataSource: bentSpectrum)
}
#Preview("Simultaneous Bends (Saturation & Brightness)") {
    let spectrumModel = SpectrumSliderModel {
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
    let spectrumModel = SpectrumSliderModel {
        BlackSection()
        HueSection(minHue: 0.0, maxHue: 1.0)
        WhiteSection()
    }
    PreviewContainer(dataSource: spectrumModel)
        .colorSliderThumbShape(Circle())
        .colorSliderDimensions(thumbLength: 25)
}

#Preview("Circle Thumb (Vertical)") {
    let spectrumModel = SpectrumSliderModel {
        BlackSection()
        HueSection(minHue: 0.0, maxHue: 1.0)
        WhiteSection()
    }
    PreviewContainer(dataSource: spectrumModel, axis: .vertical)
        .colorSliderThumbShape(Circle())
        .colorSliderDimensions(thumbLength: 25)
}

#Preview("Glass Disabled") {
    let spectrumModel = SpectrumSliderModel {
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

#Preview("Preview Position (Horizontal Bottom)") {
    let spectrumModel = SpectrumSliderModel {
        HueSection(minHue: 0.0, maxHue: 1.0)
    }
    PreviewContainer(dataSource: spectrumModel)
        .colorSliderPreviewPosition(.bottom, spacing: 20)
}

#Preview("Preview Position (Vertical Leading)") {
    let spectrumModel = SpectrumSliderModel {
        HueSection(minHue: 0.0, maxHue: 1.0)
    }
    PreviewContainer(dataSource: spectrumModel, axis: .vertical)
        .colorSliderPreviewPosition(.leading)
}
