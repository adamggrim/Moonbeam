import SwiftUI

#Preview("Horizontal RGB gradient slider") {
    PreviewContainer { selection, progress in
        ColorSlider(value: progress, onColorChange: { selection.wrappedValue = $0 }, axis: .horizontal)
            .gradient(from: .orange, to: .blue, space: .rgb)
    }
}

#Preview("Horizontal OKLAB gradient slider") {
    PreviewContainer { selection, progress in
        ColorSlider(value: progress, onColorChange: { selection.wrappedValue = $0 }, axis: .horizontal)
            .gradient(from: .blue, to: .red, space: .oklab)
    }
}

#Preview("Horizontal OKLCH gradient slider") {
    PreviewContainer { selection, progress in
        ColorSlider(value: progress, onColorChange: { selection.wrappedValue = $0 }, axis: .horizontal)
            .gradient(from: .purple, to: .white, space: .oklch)
    }
}

#Preview("Horizontal gradient slider with custom dimensions") {
    PreviewContainer { selection, progress in
        ColorSlider(value: progress, onColorChange: { selection.wrappedValue = $0 }, axis: .horizontal)
            .gradient(from: .green, to: .yellow)
            .colorSliderDimensions(
                length: 200,
                thickness: 40,
                previewSize: 100,
                previewOffset: 110
            )
    }
}
