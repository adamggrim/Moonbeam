import SwiftUI

private struct PreviewContainer: View {
    let dataSource: ColorSliderDataSource
    var axis: Axis = .horizontal
    var backgroundColor: Color = .black

    @State private var selection: CGColor = CGColor(gray: 1, alpha: 1)
    @State private var progress: Double = 0.5

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            ColorSlider(
                selection: $selection,
                progress: $progress,
                dataSource: dataSource,
                axis: axis
            )
        }
    }
}

#Preview("Horizontal Slider") {
    let spectrumModel = HSBSpectrumModel(
        startSections: [BlackSection()],
        endSections: [WhiteSection()],
        startHue: 0.0,
        endHue: 1.0
    )
    PreviewContainer(dataSource: spectrumModel)
}

#Preview("Vertical Slider (AnyShape)") {
    let spectrumModel = HSBSpectrumModel(
        startSections: [BlackSection()],
        endSections: [WhiteSection()],
        startHue: 0.0,
        endHue: 1.0
    )
    PreviewContainer(dataSource: spectrumModel, axis: .vertical)
        .colorSliderThumbShape(Rectangle())
        .colorSliderPreviewShape(Circle())
        .colorSliderCornerRadius(0)
        .colorSliderTrackStroke(Color.white, lineWidth: 2)
        .colorSliderThumbStroke(Color.white, lineWidth: 2)
        .colorSliderPreviewStroke(Color.white, lineWidth: 2)
}

#Preview("Spectrum with BendSections") {
    let spectrumModel = HSBSpectrumModel(
        startHue: 0.0,
        endHue: 1.0,
        saturationBends: {
            OneWayBend(startHue: 0.0, endHue: 40.0 / 360, target: 0.5)
            TwoWayBend(startHue: 200.0 / 360, endHue: 280.0 / 360, target: 0.3)
        }
    )

    PreviewContainer(dataSource: spectrumModel)
}

#Preview("Spectrum with MonochromeSections") {
    let spectrumModel = HSBSpectrumModel(
        startSections: [BlackSection(), WhiteSection()],
        endSections: [BlackSection(), WhiteSection()],
        startHue: 0.0,
        endHue: 1.0
    )

    PreviewContainer(dataSource: spectrumModel)
}

#Preview("OKLCH Spectrum") {
    let oklchModel = OKLCHSpectrumModel(
        lightness: 0.75,
        chroma: 0.8,
        startHue: 0.0,
        endHue: 1.0
    )

    PreviewContainer(dataSource: oklchModel)
}

#Preview("RGB Gradient") {
    let gradientModel = GradientSliderModel(
        startColor: .orange,
        endColor: .blue
    )

    PreviewContainer(dataSource: gradientModel)
}

#Preview("OKLAB Gradient") {
    let gradientModel = GradientSliderModel(
        startColor: .blue,
        endColor: .red,
        colorSpace: .oklab
    )

    PreviewContainer(dataSource: gradientModel)
}

#Preview("Hard-Edge (Explicit)") {
    let customStops = HardEdgeSliderModel(colors: [
        .green, .yellow, .orange, .red, .purple, .blue
    ])

    PreviewContainer(dataSource: customStops)
}

#Preview("Hard-Edge Spectrum with BendSections") {
    let bentSpectrum = HSBSpectrumModel(
        startHue: 0.0,
        endHue: 1.0,
        saturationBends: {
            TwoWayBend(startHue: 120.0 / 360, endHue: 240.0 / 360, target: 0.3)
        },
        brightnessBends: {
            TwoWayBend(startHue: 200.0 / 360, endHue: 300.0 / 360, target: 0.4)
        }
    ).hardEdge(into: 8)

    PreviewContainer(dataSource: bentSpectrum)
}

#Preview("Simultaneous Bends (Saturation & Brightness)") {
    let spectrumModel = HSBSpectrumModel(
        startHue: 0.0,
        endHue: 1.0,
        saturationBends: {
            TwoWayBend(startHue: 120.0 / 360, endHue: 240.0 / 360, target: 0.3)
        },
        brightnessBends: {
            TwoWayBend(startHue: 200.0 / 360, endHue: 300.0 / 360, target: 0.4)
        }
    )

    PreviewContainer(dataSource: spectrumModel)
}

#Preview("Circle Thumb (Horizontal)") {
    let spectrumModel = HSBSpectrumModel(
        startSections: [BlackSection()],
        endSections: [WhiteSection()],
        startHue: 0.0,
        endHue: 1.0
    )
    PreviewContainer(dataSource: spectrumModel)
        .colorSliderThumbShape(Circle())
        .colorSliderDimensions(thumbLength: 25)
}

#Preview("Circle Thumb (Vertical)") {
    let spectrumModel = HSBSpectrumModel(
        startSections: [BlackSection()],
        endSections: [WhiteSection()],
        startHue: 0.0,
        endHue: 1.0
    )
    PreviewContainer(dataSource: spectrumModel, axis: .vertical)
        .colorSliderThumbShape(Circle())
        .colorSliderDimensions(thumbLength: 25)
}

#Preview("Glass Disabled") {
    let spectrumModel = HSBSpectrumModel(
        startHue: 0.0,
        endHue: 1.0
    )

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
            length: 200,
            thickness: 40,
            previewSize: 100,
            previewOffset: 110
        )
}

#Preview("Preview Position (Horizontal Bottom)") {
    let spectrumModel = HSBSpectrumModel(
        startHue: 0.0,
        endHue: 1.0
    )
    PreviewContainer(dataSource: spectrumModel)
        .colorSliderPreviewPosition(.bottom, spacing: 20)
}

#Preview("Preview Position (Vertical Leading)") {
    let spectrumModel = HSBSpectrumModel(
        startHue: 0.0,
        endHue: 1.0
    )
    PreviewContainer(dataSource: spectrumModel, axis: .vertical)
        .colorSliderPreviewPosition(.leading)
}
