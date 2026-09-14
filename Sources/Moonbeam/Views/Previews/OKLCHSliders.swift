import SwiftUI

#Preview("Horizontal OKLCH spectrum slider") {
    PreviewContainer { selection, progress in
        ColorSlider(
            value: progress,
            color: selection,
            colorProvider: OKLCHSpectrum(startHue: 0.0, endHue: 1.0),
            axis: .horizontal
        )
    }
}
