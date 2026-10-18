import SwiftUI

#Preview("Horizontal Oklch spectrum slider") {
    PreviewContainer { selection, progress in
        ColorSlider(
            value: progress,
            colorProvider: Spectrum<Oklch>(startHue: 0.0, endHue: 1.0),
            axis: .horizontal
        )
    }
}
