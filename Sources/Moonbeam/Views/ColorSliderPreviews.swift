import SwiftUI

// MARK: - Helper

private struct PreviewContainer<Content: View>: View {
    var backgroundColor: Color = .black
    @ViewBuilder let content: (Binding<CGColor>, Binding<Double>) -> Content

    @State private var selection: CGColor = CGColor(gray: 1, alpha: 1)
    @State private var progress: Double = 0.5

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            content($selection, $progress)
        }
    }
}

// MARK: - HSB sliders

#Preview("Horizontal HSB spectrum slider") {
    PreviewContainer { selection, progress in
        ColorSlider(selection: selection, progress: progress, axis: .horizontal)
    }
}

#Preview("Vertical HSB spectrum slider (AnyShape)") {
    PreviewContainer { selection, progress in
        ColorSlider(selection: selection, progress: progress, axis: .vertical)
            .startingWith(BlackSection())
            .endingWith(WhiteSection())
            .colorSliderThumbShape(Rectangle())
            .colorSliderPreviewShape(Circle())
            .colorSliderCornerRadius(0)
            .colorSliderTrackStroke(Color.white, lineWidth: 2)
            .colorSliderThumbStroke(Color.white, lineWidth: 2)
            .colorSliderPreviewStroke(Color.white, lineWidth: 2)
    }
}

#Preview("Horizontal HSB spectrum slider with bend sections") {
    PreviewContainer { selection, progress in
        ColorSlider(selection: selection, progress: progress, axis: .horizontal)
            .saturationBends {
                OneWayBend(startHue: 0.0, endHue: 40.0 / 360, target: 0.5)
                TwoWayBend(startHue: 200.0 / 360, endHue: 280.0 / 360, target: 0.3)
            }
    }
}

#Preview("Horizontal HSB spectrum slider with simultaneous bends") {
    PreviewContainer { selection, progress in
        ColorSlider(selection: selection, progress: progress, axis: .horizontal)
            .saturationBends {
                TwoWayBend(startHue: 120.0 / 360, endHue: 240.0 / 360, target: 0.3)
            }
            .brightnessBends {
                TwoWayBend(startHue: 200.0 / 360, endHue: 300.0 / 360, target: 0.4)
            }
    }
}

#Preview("Horizontal HSB spectrum slider with monochrome sections") {
    PreviewContainer { selection, progress in
        ColorSlider(selection: selection, progress: progress, axis: .horizontal)
            .startingWith(BlackSection(), WhiteSection())
            .endingWith(BlackSection(), WhiteSection())
    }
}

#Preview("Horizontal HSB spectrum slider with circle thumb") {
    PreviewContainer { selection, progress in
        ColorSlider(selection: selection, progress: progress, axis: .horizontal)
            .startingWith(BlackSection())
            .endingWith(WhiteSection())
            .colorSliderThumbShape(Circle())
            .colorSliderDimensions(thumbLength: 25)
    }
}

#Preview("Vertical HSB spectrum slider with circle thumb") {
    PreviewContainer { selection, progress in
        ColorSlider(selection: selection, progress: progress, axis: .vertical)
            .startingWith(BlackSection())
            .endingWith(WhiteSection())
            .colorSliderThumbShape(Circle())
            .colorSliderDimensions(thumbLength: 25)
    }
}

#Preview("Horizontal HSB spectrum slider with bottom preview") {
    PreviewContainer { selection, progress in
        ColorSlider(selection: selection, progress: progress, axis: .horizontal)
            .colorSliderPreviewPosition(.bottomTrailing, spacing: 20)
    }
}

#Preview("Vertical HSB spectrum slider with leading preview") {
    PreviewContainer { selection, progress in
        ColorSlider(selection: selection, progress: progress, axis: .vertical)
            .colorSliderPreviewPosition(.topLeading)
    }
}

#Preview("Horizontal HSB spectrum slider with Liquid Glass disabled") {
    PreviewContainer { selection, progress in
        ColorSlider(selection: selection, progress: progress, axis: .horizontal)
            .colorSliderDisableLiquidGlass(true)
    }
}

// MARK: - OKLCH Previews

#Preview("Horizontal OKLCH spectrum slider") {
    PreviewContainer { selection, progress in
        ColorSlider(selection: selection, progress: progress, axis: .horizontal)
            .spectrum(space: .oklch, range: 0.0...1.0)
    }
}

// MARK: - Gradient previews

#Preview("Horizontal RGB gradient slider") {
    PreviewContainer { selection, progress in
        ColorSlider(selection: selection, progress: progress, axis: .horizontal)
            .gradient(from: .orange, to: .blue, space: .rgb)
    }
}

#Preview("Horizontal OKLAB gradient slider") {
    PreviewContainer { selection, progress in
        ColorSlider(selection: selection, progress: progress, axis: .horizontal)
            .gradient(from: .blue, to: .red, space: .oklab)
    }
}

#Preview("Horizontal OKLCH gradient slider") {
    PreviewContainer { selection, progress in
        ColorSlider(selection: selection, progress: progress, axis: .horizontal)
            .gradient(from: .purple, to: .white, space: .oklch)
    }
}

#Preview("Horizontal gradient slider with custom dimensions") {
    PreviewContainer { selection, progress in
        ColorSlider(selection: selection, progress: progress, axis: .horizontal)
            .gradient(from: .green, to: .yellow)
            .colorSliderDimensions(
                length: 200,
                thickness: 40,
                previewSize: 100,
                previewOffset: 110
            )
    }
}

// MARK: - Hard-edge sliders

#Preview("Horizontal explicit hard-edge slider") {
    PreviewContainer { selection, progress in
        ColorSlider(selection: selection, progress: progress, axis: .horizontal)
            .colors([.green, .yellow, .orange, .red, .purple, .blue])
    }
}

#Preview("Vertical explicit hard-edge slider") {
    PreviewContainer { selection, progress in
        ColorSlider(selection: selection, progress: progress, axis: .vertical)
            .colors([.green, .yellow, .orange, .red, .purple, .blue])
    }
}

#Preview("Horizontal hard-edge HSB spectrum slider with bend sections") {
    PreviewContainer { selection, progress in
        ColorSlider(selection: selection, progress: progress, axis: .horizontal)
            .saturationBends {
                TwoWayBend(startHue: 120.0 / 360, endHue: 240.0 / 360, target: 0.3)
            }
            .brightnessBends {
                TwoWayBend(startHue: 200.0 / 360, endHue: 300.0 / 360, target: 0.4)
            }
            .hardEdge(into: 8)
    }
}
