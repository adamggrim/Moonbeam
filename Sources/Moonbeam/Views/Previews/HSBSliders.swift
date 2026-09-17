import SwiftUI

#Preview("Horizontal HSB spectrum slider") {
    PreviewContainer { selection, progress in
        ColorSlider(
            value: progress,
            color: selection,
            colorProvider: Spectrum<HSB>(),
            axis: .horizontal
        )
    }
}

#Preview("Vertical HSB spectrum slider (AnyShape)") {
    PreviewContainer { selection, progress in
        ColorSlider(
            value: progress,
            color: selection,
            colorProvider: Spectrum<HSB>(
                startSections: [BlackSection()],
                endSections: [WhiteSection()]
            ),
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
            color: selection,
            colorProvider: Spectrum<HSB>(
                saturationBends: {
                    OneWayBend(startHue: 0.0, endHue: 40.0 / 360, target: 0.5)
                    TwoWayBend(startHue: 200.0 / 360, endHue: 280.0 / 360, target: 0.3)
                }
            ),
            axis: .horizontal
        )
    }
}

#Preview("Horizontal HSB spectrum slider with simultaneous bends") {
    PreviewContainer { selection, progress in
        ColorSlider(
            value: progress,
            color: selection,
            colorProvider: Spectrum<HSB>(
                saturationBends: {
                    TwoWayBend(startHue: 120.0 / 360, endHue: 240.0 / 360, target: 0.3)
                },
                brightnessBends: {
                    TwoWayBend(startHue: 200.0 / 360, endHue: 300.0 / 360, target: 0.4)
                }
            ),
            axis: .horizontal
        )
    }
}

#Preview("Horizontal HSB spectrum slider with monochrome sections") {
    PreviewContainer { selection, progress in
        ColorSlider(
            value: progress,
            color: selection,
            colorProvider: Spectrum<HSB>(
                startSections: [BlackSection(), WhiteSection()],
                endSections: [BlackSection(), WhiteSection()]
            ),
            axis: .horizontal
        )
    }
}

#Preview("Horizontal HSB spectrum slider with circle thumb") {
    PreviewContainer { selection, progress in
        ColorSlider(
            value: progress,
            color: selection,
            colorProvider: Spectrum<HSB>(
                startSections: [BlackSection()],
                endSections: [WhiteSection()]
            ),
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
            color: selection,
            colorProvider: Spectrum<HSB>(
                startSections: [BlackSection()],
                endSections: [WhiteSection()]
            ),
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
            color: selection,
            colorProvider: Spectrum<HSB>(),
            axis: .horizontal
        )
        .colorSliderStyle(DefaultColorSliderStyle(
            disableLiquidGlass: true
        ))
    }
}
