import SwiftUI

#Preview("Horizontal explicit hard-edge slider") {
    PreviewContainer { selection, progress in
        ColorSlider(
            value: progress,
            colorProvider: HardEdgeColors(colors: [.green, .yellow, .orange, .red, .purple, .blue]),
            axis: .horizontal
        )
    }
}

#Preview("Horizontal explicit hard-edge slider with outline") {
    PreviewContainer { selection, progress in
        ColorSlider(
            value: progress,
            colorProvider: HardEdgeColors(colors: [.green, .yellow, .orange, .red, .purple, .blue]),
            axis: .horizontal
        )
        .colorSliderThumbStyle(.colorOutline(lineWidth: 3, padding: 4))
    }
}

#Preview("Vertical explicit hard-edge slider") {
    PreviewContainer { selection, progress in
        ColorSlider(
            value: progress,
            colorProvider: HardEdgeColors(colors: [.green, .yellow, .orange, .red, .purple, .blue]),
            axis: .vertical
        )
    }
}

#Preview("Horizontal hard-edge HSB spectrum slider with bend sections") {
    PreviewContainer { selection, progress in
        let colorProvider = Spectrum<HSB>(
            saturationBends: {
                TwoWayBend(startHue: 120.0 / 360, endHue: 240.0 / 360, target: 0.3)
            },
            brightnessBends: {
                TwoWayBend(startHue: 200.0 / 360, endHue: 300.0 / 360, target: 0.4)
            }
        ).hardEdge(into: 8)

        ColorSlider(
            value: progress,
            colorProvider: colorProvider,
            axis: .horizontal
        )
    }
}
