import SwiftUI

#Preview("Horizontal OKLCH spectrum slider") {
    PreviewContainer { selection, progress in
        ColorSlider(value: progress, onColorChange: { selection.wrappedValue = $0 }, axis: .horizontal)
            .spectrum(space: .oklch, range: 0.0...1.0)
    }
}
