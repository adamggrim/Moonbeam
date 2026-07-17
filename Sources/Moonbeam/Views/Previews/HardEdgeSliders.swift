import SwiftUI

#Preview("Horizontal explicit hard-edge slider") {
    PreviewContainer { selection, progress in
        ColorSlider(selection: selection, progress: progress, axis: .horizontal)
            .colors([.green, .yellow, .orange, .red, .purple, .blue])
    }
}

#Preview("Vertical explicit hard-edge slider") {
    PreviewContainer { selection, progress in
        ColorSlider(selection: selection, progress: progress, axis: .vertical)
            .colors([.green, .yellow, .orange, .red, .purple, .blue])
    }
}

#Preview("Horizontal hard-edge HSB spectrum slider with bend sections") {
    PreviewContainer { selection, progress in
        ColorSlider(selection: selection, progress: progress, axis: .horizontal)
            .saturationBends {
                TwoWayBend(startHue: 120.0 / 360, endHue: 240.0 / 360, target: 0.3)
            }
            .brightnessBends {
                TwoWayBend(startHue: 200.0 / 360, endHue: 300.0 / 360, target: 0.4)
            }
            .hardEdge(into: 8)
    }
}
