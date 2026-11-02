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
