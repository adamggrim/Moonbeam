import SwiftUI

/// An isolated view for rendering the slider background track.
internal struct TrackView: View {
    let colorProvider: any ColorProvider
    let dimensions: ColorSliderDimensions
    let axis: Axis
    @Environment(\.controlSize) private var controlSize

    var body: some View {
        let thickness = dimensions.thickness ?? ColorSliderDefaults.trackThickness(for: controlSize)
        let size = CGSize(
            width: axis == .horizontal ? (dimensions.length ?? 0) : thickness,
            height: axis == .horizontal ? thickness : (dimensions.length ?? 0)
        )

        Group {
            switch colorProvider.colorSource {
            case .array(let colors):
                hardEdgeTrackView(colors: colors)
            case .function(let colorGenerator):
                Rectangle()
                    .fill(colorGenerator(0.5))
            case .shader(let shaderGenerator, _):
                Rectangle()
                    .fill(Color.white) // Pixels for Metal to paint on.
                    .colorEffect(shaderGenerator(size, axis == .vertical))
            }
        }
        .frame(width: size.width, height: size.height)
        .drawingGroup()
    }

    @ViewBuilder
    private func hardEdgeTrackView(colors: [Color]) -> some View {
        if colors.isEmpty {
            Color.clear
        } else {
            let isHorizontal = axis == .horizontal
            let step = 1.0 / Double(colors.count)

            let stops: [Gradient.Stop] = colors.enumerated().flatMap { index, color in
                [
                    Gradient.Stop(color: color, location: step * Double(index)),
                    Gradient.Stop(color: color, location: step * Double(index + 1))
                ]
            }

            LinearGradient(
                stops: stops,
                startPoint: isHorizontal ? .leading : .bottom,
                endPoint: isHorizontal ? .trailing : .top
            )
        }
    }
}
