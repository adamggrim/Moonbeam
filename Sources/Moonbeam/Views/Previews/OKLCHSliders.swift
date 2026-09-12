import SwiftUI

#Preview("Horizontal OKLCH spectrum slider") {
    PreviewContainer { selection, progress in
        ColorSlider(
            value: progress,
            dataSource: OKLCHSpectrumModel(startHue: 0.0, endHue: 1.0),
            onColorChange: { selection.wrappedValue = $0 },
            axis: .horizontal
        )
    }
}
