
import SwiftUI

/// An isolated view for rendering the slider background track.
internal struct TrackView: View {
    let dataSource: any ColorSliderDataSource & Sendable
    let dimensions: ColorSliderDimensions
    let axis: Axis

    @Environment(\.colorSliderTrackStroke) private var trackStroke

    private var trackShape: AnyShape {
        if let radius = dimensions.cornerRadius {
            return AnyShape(RoundedRectangle(cornerRadius: radius))
        } else {
            return AnyShape(Capsule())
        }
    }

    var body: some View {
        let size = CGSize(
            width: axis == .horizontal ? dimensions.length : dimensions.thickness,
            height: axis == .horizontal ? dimensions.thickness : dimensions.length
        )

        Group {
            switch dataSource.colorSource {
            case .array(let colors):
                hardEdgeTrackView(colors: colors)
                    .clipShape(trackShape)
            case .function(let colorGenerator):
                trackShape.fill(colorGenerator(0.5))
            case .shader(let shaderGenerator, _):
                trackShape
                    .fill(Color.white) // Pixels for Metal to paint on.
                    .colorEffect(shaderGenerator(size, axis == .vertical))
            }
        }
        .frame(width: size.width, height: size.height)
        .overlay {
            if let stroke = trackStroke {
                trackShape.stroke(stroke.style, lineWidth: stroke.lineWidth)
            }
        }
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
