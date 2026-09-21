import SwiftUI

#Preview("Horizontal OKLCH spectrum slider") {
    PreviewContainer { selection, progress in
        ColorSlider(
            value: progress,
            colorProvider: Spectrum<OKLCH>(startHue: 0.0, endHue: 1.0),
            axis: .horizontal
        )
    }
}
