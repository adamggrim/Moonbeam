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

#Preview("Oklch spectrum: Display P3 and sRGB") {
    PreviewContainer { _, progress in
        VStack(spacing: 32) {
            ColorSlider(
                value: progress,
                colorProvider: Spectrum<Oklch>(
                    lightness: 0.7,
                    chroma: 0.3,
                    startHue: 0.0,
                    endHue: 1.0,
                    gamut: .displayP3
                ),
                axis: .horizontal
            )
            ColorSlider(
                value: progress,
                colorProvider: Spectrum<Oklch>(
                    lightness: 0.7,
                    chroma: 0.3,
                    startHue: 0.0,
                    endHue: 1.0,
                    gamut: .sRGB
                ),
                axis: .horizontal
            )
        }
    }
}
