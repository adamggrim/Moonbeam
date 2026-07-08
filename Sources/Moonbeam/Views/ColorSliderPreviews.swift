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

#Preview("Horizontal HSB spectrum slider") {
    let spectrumModel = HSBSpectrumModel(
        startSections: [BlackSection()],
        endSections: [WhiteSection()],
        startHue: 0.0,
        endHue: 1.0,
        saturation: 1.0,
        brightness: 1.0
    )
    PreviewContainer(dataSource: spectrumModel)
}

#Preview("Vertical HSB spectrum slider (AnyShape)") {
    let spectrumModel = HSBSpectrumModel(
        startSections: [BlackSection()],
        endSections: [WhiteSection()],
        startHue: 0.0,
        endHue: 1.0,
        saturation: 1.0,
        brightness: 1.0
    )
    PreviewContainer(dataSource: spectrumModel, axis: .vertical)
        .colorSliderThumbShape(Rectangle())
        .colorSliderPreviewShape(Circle())
        .colorSliderCornerRadius(0)
        .colorSliderTrackStroke(Color.white, lineWidth: 2)
        .colorSliderThumbStroke(Color.white, lineWidth: 2)
        .colorSliderPreviewStroke(Color.white, lineWidth: 2)
}

#Preview("Horizontal HSB spectrum slider with bend sections") {
    let spectrumModel = HSBSpectrumModel(
        startHue: 0.0,
        endHue: 1.0,
        saturation: 1.0,
        brightness: 1.0,
        saturationBends: {
            OneWayBend(startHue: 0.0, endHue: 40.0 / 360, target: 0.5)
            TwoWayBend(startHue: 200.0 / 360, endHue: 280.0 / 360, target: 0.3)
        }
    )

    PreviewContainer(dataSource: spectrumModel)
}

#Preview("Horizontal HSB spectrum slider with monochrome sections") {
    let spectrumModel = HSBSpectrumModel(
        startSections: [BlackSection(), WhiteSection()],
        endSections: [BlackSection(), WhiteSection()],
        startHue: 0.0,
        endHue: 1.0,
        saturation: 1.0,
        brightness: 1.0
    )

    PreviewContainer(dataSource: spectrumModel)
}

#Preview("Horizontal OKLCH spectrum slider") {
    let oklchModel = OKLCHSpectrumModel(
        lightness: 0.75,
        chroma: 0.8,
        startHue: 0.0,
        endHue: 1.0
    )

    PreviewContainer(dataSource: oklchModel)
}

#Preview("Horizontal RGB gradient slider") {
    let gradientModel = GradientSliderModel(
        startColor: .orange,
        endColor: .blue,
        colorSpace: .rgb
    )

    PreviewContainer(dataSource: gradientModel)
}

#Preview("Horizontal OKLAB gradient slider") {
    let gradientModel = GradientSliderModel(
        startColor: .blue,
        endColor: .red,
        colorSpace: .oklab
    )

    PreviewContainer(dataSource: gradientModel)
}

#Preview("Horizontal explicit hard-edge slider") {
    let customStops = HardEdgeSliderModel(colors: [
        .green, .yellow, .orange, .red, .purple, .blue
    ])

    PreviewContainer(dataSource: customStops)
}

#Preview("Vertical explicit hard-edge slider") {
    let customStops = HardEdgeSliderModel(colors: [
        .green, .yellow, .orange, .red, .purple, .blue
    ])

    PreviewContainer(dataSource: customStops, axis: .vertical)
}

#Preview("Horizontal hard-edge HSB spectrum slider with bend sections") {
    let bentSpectrum = HSBSpectrumModel(
        startHue: 0.0,
        endHue: 1.0,
        saturation: 1.0,
        brightness: 1.0,
        saturationBends: {
            TwoWayBend(startHue: 120.0 / 360, endHue: 240.0 / 360, target: 0.3)
        },
        brightnessBends: {
            TwoWayBend(startHue: 200.0 / 360, endHue: 300.0 / 360, target: 0.4)
        }
    ).hardEdge(into: 8)

    PreviewContainer(dataSource: bentSpectrum)
}

#Preview("Horizontal HSB spectrum slider with simultaneous bends") {
    let spectrumModel = HSBSpectrumModel(
        startHue: 0.0,
        endHue: 1.0,
        saturation: 1.0,
        brightness: 1.0,
        saturationBends: {
            TwoWayBend(startHue: 120.0 / 360, endHue: 240.0 / 360, target: 0.3)
        },
        brightnessBends: {
            TwoWayBend(startHue: 200.0 / 360, endHue: 300.0 / 360, target: 0.4)
        }
    )

    PreviewContainer(dataSource: spectrumModel)
}

#Preview("Horizontal HSB spectrum slider with circle thumb") {
    let spectrumModel = HSBSpectrumModel(
        startSections: [BlackSection()],
        endSections: [WhiteSection()],
        startHue: 0.0,
        endHue: 1.0,
        saturation: 1.0,
        brightness: 1.0
    )
    PreviewContainer(dataSource: spectrumModel)
        .colorSliderThumbShape(Circle())
        .colorSliderDimensions(thumbLength: 25)
}

#Preview("Vertical HSB spectrum slider with circle thumb") {
    let spectrumModel = HSBSpectrumModel(
        startSections: [BlackSection()],
        endSections: [WhiteSection()],
        startHue: 0.0,
        endHue: 1.0,
        saturation: 1.0,
        brightness: 1.0
    )
    PreviewContainer(dataSource: spectrumModel, axis: .vertical)
        .colorSliderThumbShape(Circle())
        .colorSliderDimensions(thumbLength: 25)
}

#Preview("Horizontal HSB spectrum slider with Liquid Glass disabled") {
    let spectrumModel = HSBSpectrumModel(
        startHue: 0.0,
        endHue: 1.0,
        saturation: 1.0,
        brightness: 1.0
    )

    PreviewContainer(dataSource: spectrumModel)
        .colorSliderDisableLiquidGlass(true)
}

#Preview("Horizontal gradient slider with custom dimensions") {
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

#Preview("Horizontal HSB spectrum slider with bottom preview") {
    let spectrumModel = HSBSpectrumModel(
        startHue: 0.0,
        endHue: 1.0,
        saturation: 1.0,
        brightness: 1.0
    )
    PreviewContainer(dataSource: spectrumModel)
        .colorSliderPreviewPosition(.bottomTrailing, spacing: 20)
}

#Preview("Vertical HSB spectrum slider with leading preview") {
    let spectrumModel = HSBSpectrumModel(
        startHue: 0.0,
        endHue: 1.0,
        saturation: 1.0,
        brightness: 1.0
    )
    PreviewContainer(dataSource: spectrumModel, axis: .vertical)
        .colorSliderPreviewPosition(.topLeading)
}
