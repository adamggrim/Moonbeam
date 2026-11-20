import SwiftUI

#Preview("Horizontal RGB gradient slider") {
    PreviewContainer { selection, progress in
        ColorSlider(
            value: progress,
            colorProvider: ColorGradient(colors: [.orange, .blue], colorSpace: .rgb),
            axis: .horizontal
        )
    }
}

#Preview("Horizontal Oklab gradient slider") {
    PreviewContainer { selection, progress in
        ColorSlider(
            value: progress,
            colorProvider: ColorGradient(colors: [.blue, .red], colorSpace: .oklab),
            axis: .horizontal
        )
    }
}

#Preview("Horizontal Oklch gradient slider") {
    PreviewContainer { selection, progress in
        ColorSlider(
            value: progress,
            colorProvider: ColorGradient(colors: [.purple, .white], colorSpace: .oklch),
            axis: .horizontal
        )
    }
}

#Preview("Horizontal gradient slider with custom dimensions") {
    PreviewContainer { selection, progress in
        ColorSlider(
            value: progress,
            colorProvider: ColorGradient(colors: [.green, .yellow]),
            axis: .horizontal
        )
        .colorSliderDimensions(
            length: 200,
            thickness: 40,
            previewSize: 100,
            previewOffset: 110
        )
    }
}

#Preview("Oklch gradient: Display P3 and sRGB") {
    let p3Red = Color(.displayP3, red: 1.0, green: 0.0, blue: 0.0)
    let p3Green = Color(.displayP3, red: 0.0, green: 1.0, blue: 0.0)

    PreviewContainer { _, progress in
        VStack(spacing: 32) {
            ColorSlider(
                value: progress,
                colorProvider: ColorGradient(
                    colors: [p3Red, p3Green],
                    colorSpace: .oklch,
                    gamut: .displayP3
                ),
                axis: .horizontal
            )
            ColorSlider(
                value: progress,
                colorProvider: ColorGradient(
                    colors: [p3Red, p3Green],
                    colorSpace: .oklch,
                    gamut: .sRGB
                ),
                axis: .horizontal
            )
        }
    }
}
