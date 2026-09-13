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
        .colorSliderStyle(DefaultColorSliderStyle(
            trackShape: AnyShape(Rectangle()),
            trackStroke: ShapeStroke(style: AnyShapeStyle(.white), lineWidth: 2),
            thumbShape: AnyShape(Rectangle()),
            thumbStroke: ShapeStroke(style: AnyShapeStyle(.white), lineWidth: 2),
            previewShape: AnyShape(Circle()),
            previewStroke: ShapeStroke(style: AnyShapeStyle(.white), lineWidth: 2)
        ))
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
        .colorSliderStyle(DefaultColorSliderStyle(
            thumbShape: AnyShape(Circle())
        ))
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
        .colorSliderStyle(DefaultColorSliderStyle(
            thumbShape: AnyShape(Circle())
        ))
        .colorSliderDimensions(thumbLength: 25)
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
        .colorSliderStyle(DefaultColorSliderStyle(
            disableLiquidGlass: true
        ))
    }
}
