import SwiftUI

#Preview("Horizontal explicit hard-edge slider") {
    PreviewContainer { selection, progress in
        ColorSlider(
            value: progress,
            color: selection,
            colorProvider: HardEdgeColors(colors: [.green, .yellow, .orange, .red, .purple, .blue]),
            axis: .horizontal
        )
    }
}

#Preview("Vertical explicit hard-edge slider") {
    PreviewContainer { selection, progress in
        ColorSlider(
            value: progress,
            color: selection,
            colorProvider: HardEdgeColors(colors: [.green, .yellow, .orange, .red, .purple, .blue]),
            axis: .vertical
        )
    }
}

#Preview("Horizontal hard-edge HSB spectrum slider with bend sections") {
    PreviewContainer { selection, progress in
        let colorProvider = HSBSpectrum(
            saturationBends: {
                TwoWayBend(startHue: 120.0 / 360, endHue: 240.0 / 360, target: 0.3)
            },
            brightnessBends: {
                TwoWayBend(startHue: 200.0 / 360, endHue: 300.0 / 360, target: 0.4)
            }
        ).hardEdge(into: 8)

        ColorSlider(
            value: progress,
            color: selection,
            colorProvider: colorProvider,
            axis: .horizontal
        )
    }
}
