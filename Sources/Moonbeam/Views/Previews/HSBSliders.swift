import SwiftUI

#Preview("Horizontal HSB spectrum slider") {
    PreviewContainer { selection, progress in
        ColorSlider(
            value: progress,
            dataSource: HSBSpectrumModel(),
            onColorChange: { selection.wrappedValue = $0 },
            axis: .horizontal
        )
    }
}

#Preview("Vertical HSB spectrum slider (AnyShape)") {
    PreviewContainer { selection, progress in
        ColorSlider(
            value: progress,
            dataSource: HSBSpectrumModel(
                startSections: [BlackSection()],
                endSections: [WhiteSection()]
            ),
            onColorChange: { selection.wrappedValue = $0 },
            axis: .vertical
        )
        .colorSliderThumbShape(Rectangle())
        .colorSliderPreviewShape(Circle())
        .colorSliderCornerRadius(0)
        .colorSliderTrackStroke(Color.white, lineWidth: 2)
        .colorSliderThumbStroke(Color.white, lineWidth: 2)
        .colorSliderPreviewStroke(Color.white, lineWidth: 2)
    }
}

#Preview("Horizontal HSB spectrum slider with bend sections") {
    PreviewContainer { selection, progress in
        ColorSlider(
            value: progress,
            dataSource: HSBSpectrumModel(
                saturationBends: {
                    OneWayBend(startHue: 0.0, endHue: 40.0 / 360, target: 0.5)
                    TwoWayBend(startHue: 200.0 / 360, endHue: 280.0 / 360, target: 0.3)
                }
            ),
            onColorChange: { selection.wrappedValue = $0 },
            axis: .horizontal
        )
    }
}

#Preview("Horizontal HSB spectrum slider with simultaneous bends") {
    PreviewContainer { selection, progress in
        ColorSlider(
            value: progress,
            dataSource: HSBSpectrumModel(
                saturationBends: {
                    TwoWayBend(startHue: 120.0 / 360, endHue: 240.0 / 360, target: 0.3)
                },
                brightnessBends: {
                    TwoWayBend(startHue: 200.0 / 360, endHue: 300.0 / 360, target: 0.4)
                }
            ),
            onColorChange: { selection.wrappedValue = $0 },
            axis: .horizontal
        )
    }
}

#Preview("Horizontal HSB spectrum slider with monochrome sections") {
    PreviewContainer { selection, progress in
        ColorSlider(
            value: progress,
            dataSource: HSBSpectrumModel(
                startSections: [BlackSection(), WhiteSection()],
                endSections: [BlackSection(), WhiteSection()]
            ),
            onColorChange: { selection.wrappedValue = $0 },
            axis: .horizontal
        )
    }
}

#Preview("Horizontal HSB spectrum slider with circle thumb") {
    PreviewContainer { selection, progress in
        ColorSlider(
            value: progress,
            dataSource: HSBSpectrumModel(
                startSections: [BlackSection()],
                endSections: [WhiteSection()]
            ),
            onColorChange: { selection.wrappedValue = $0 },
            axis: .horizontal
        )
        .colorSliderThumbShape(Circle())
        .colorSliderDimensions(thumbLength: 25)
    }
}

#Preview("Vertical HSB spectrum slider with circle thumb") {
    PreviewContainer { selection, progress in
        ColorSlider(
            value: progress,
            dataSource: HSBSpectrumModel(
                startSections: [BlackSection()],
                endSections: [WhiteSection()]
            ),
            onColorChange: { selection.wrappedValue = $0 },
            axis: .vertical
        )
        .colorSliderThumbShape(Circle())
        .colorSliderDimensions(thumbLength: 25)
    }
}

#Preview("Horizontal HSB spectrum slider with bottom preview") {
    PreviewContainer { selection, progress in
        ColorSlider(
            value: progress,
            dataSource: HSBSpectrumModel(),
            onColorChange: { selection.wrappedValue = $0 },
            axis: .horizontal
        )
        .colorSliderPreviewPosition(.bottomTrailing, spacing: 20)
    }
}

#Preview("Vertical HSB spectrum slider with leading preview") {
    PreviewContainer { selection, progress in
        ColorSlider(
            value: progress,
            dataSource: HSBSpectrumModel(),
            onColorChange: { selection.wrappedValue = $0 },
            axis: .vertical
        )
        .colorSliderPreviewPosition(.topLeading)
    }
}

#Preview("Horizontal HSB spectrum slider with Liquid Glass disabled") {
    PreviewContainer { selection, progress in
        ColorSlider(
            value: progress,
            dataSource: HSBSpectrumModel(),
            onColorChange: { selection.wrappedValue = $0 },
            axis: .horizontal
        )
        .colorSliderDisableLiquidGlass(true)
    }
}
