import SwiftUI

#Preview("Horizontal OKLCH spectrum slider") {
    PreviewContainer { selection, progress in
        ColorSlider(selection: selection, progress: progress, axis: .horizontal)
            .spectrum(space: .oklch, range: 0.0...1.0)
    }
}
