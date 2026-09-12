import SwiftUI

#Preview("Horizontal RGB gradient slider") {
    PreviewContainer { selection, progress in
        ColorSlider(
            value: progress,
            dataSource: GradientSliderModel(startColor: .orange, endColor: .blue, colorSpace: .rgb),
            onColorChange: { selection.wrappedValue = $0 },
            axis: .horizontal
        )
    }
}

#Preview("Horizontal OKLAB gradient slider") {
    PreviewContainer { selection, progress in
        ColorSlider(
            value: progress,
            dataSource: GradientSliderModel(startColor: .blue, endColor: .red, colorSpace: .oklab),
            onColorChange: { selection.wrappedValue = $0 },
            axis: .horizontal
        )
    }
}

#Preview("Horizontal OKLCH gradient slider") {
    PreviewContainer { selection, progress in
        ColorSlider(
            value: progress,
            dataSource: GradientSliderModel(startColor: .purple, endColor: .white, colorSpace: .oklch),
            onColorChange: { selection.wrappedValue = $0 },
            axis: .horizontal
        )
    }
}

#Preview("Horizontal gradient slider with custom dimensions") {
    PreviewContainer { selection, progress in
        ColorSlider(
            value: progress,
            dataSource: GradientSliderModel(startColor: .green, endColor: .yellow),
            onColorChange: { selection.wrappedValue = $0 },
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
