import SwiftUI

#Preview("Horizontal HSB spectrum slider") {
    PreviewContainer { selection, progress in
        ColorSlider(selection: selection, progress: progress, axis: .horizontal)
            .colorSliderPreviewStroke(Color.white, lineWidth: 2)
    }
}

#Preview("Vertical HSB spectrum slider (AnyShape)") {
    PreviewContainer { selection, progress in
        ColorSlider(selection: selection, progress: progress, axis: .vertical)
            .startingWith(BlackSection())
            .endingWith(WhiteSection())
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
        ColorSlider(selection: selection, progress: progress, axis: .horizontal)
            .saturationBends {
                OneWayBend(startHue: 0.0, endHue: 40.0 / 360, target: 0.5)
                TwoWayBend(startHue: 200.0 / 360, endHue: 280.0 / 360, target: 0.3)
            }
    }
}

#Preview("Horizontal HSB spectrum slider with simultaneous bends") {
    PreviewContainer { selection, progress in
        ColorSlider(selection: selection, progress: progress, axis: .horizontal)
            .saturationBends {
                TwoWayBend(startHue: 120.0 / 360, endHue: 240.0 / 360, target: 0.3)
            }
            .brightnessBends {
                TwoWayBend(startHue: 200.0 / 360, endHue: 300.0 / 360, target: 0.4)
            }
    }
}

#Preview("Horizontal HSB spectrum slider with monochrome sections") {
    PreviewContainer { selection, progress in
        ColorSlider(selection: selection, progress: progress, axis: .horizontal)
            .startingWith(BlackSection(), WhiteSection())
            .endingWith(BlackSection(), WhiteSection())
    }
}

#Preview("Horizontal HSB spectrum slider with circle thumb") {
    PreviewContainer { selection, progress in
        ColorSlider(selection: selection, progress: progress, axis: .horizontal)
            .startingWith(BlackSection())
            .endingWith(WhiteSection())
            .colorSliderThumbShape(Circle())
            .colorSliderDimensions(thumbLength: 25)
    }
}

#Preview("Vertical HSB spectrum slider with circle thumb") {
    PreviewContainer { selection, progress in
        ColorSlider(selection: selection, progress: progress, axis: .vertical)
            .startingWith(BlackSection())
            .endingWith(WhiteSection())
            .colorSliderThumbShape(Circle())
            .colorSliderDimensions(thumbLength: 25)
    }
}

#Preview("Horizontal HSB spectrum slider with bottom preview") {
    PreviewContainer { selection, progress in
        ColorSlider(selection: selection, progress: progress, axis: .horizontal)
            .colorSliderPreviewPosition(.bottomTrailing, spacing: 20)
    }
}

#Preview("Vertical HSB spectrum slider with leading preview") {
    PreviewContainer { selection, progress in
        ColorSlider(selection: selection, progress: progress, axis: .vertical)
            .colorSliderPreviewPosition(.topLeading)
    }
}

#Preview("Horizontal HSB spectrum slider with Liquid Glass disabled") {
    PreviewContainer { selection, progress in
        ColorSlider(selection: selection, progress: progress, axis: .horizontal)
            .colorSliderDisableLiquidGlass(true)
    }
}
