
import SwiftUI

/// An isolated view responsible for rendering the floating color preview.
internal struct ColorPreviewView: View {
    let isDragging: Bool
    let currentColor: Color
    let previewMainAxisOffset: CGFloat
    let resolvedPreviewOffset: CGFloat
    let previewScaleAnchor: UnitPoint
    let dimensions: ColorSliderDimensions
    let axis: Axis

    @Environment(\.colorSliderPreviewShape) private var previewShape
    @Environment(\.colorSliderPreviewStroke) private var previewStroke
    @Environment(\.colorSliderPreviewHidden) private var previewHidden
    @Environment(\.colorSliderPreviewShadow) private var previewShadow

    var body: some View {
        let resolvedShape = previewShape ?? AnyShape(RoundedRectangle(cornerRadius: dimensions.previewCornerRadius))

        let dynamicScale: CGFloat = (previewHidden && !isDragging) ? dimensions.scaleRatio : 1.0
        let dynamicOpacity: Double = (previewHidden && !isDragging) ? 0.0 : 1.0

        let xOffset: CGFloat = axis == .horizontal ? previewMainAxisOffset : resolvedPreviewOffset
        let yOffset: CGFloat = axis == .horizontal ? resolvedPreviewOffset : -previewMainAxisOffset

        resolvedShape
            .foregroundColor(currentColor)
            .frame(width: dimensions.previewSize, height: dimensions.previewSize)
            .overlay {
                if let stroke = previewStroke {
                    resolvedShape.stroke(stroke.style, lineWidth: stroke.lineWidth)
                }
            }
            .scaleEffect(dynamicScale, anchor: previewScaleAnchor)
            .opacity(dynamicOpacity)
            .shadow(color: previewShadow.color, radius: previewShadow.radius, x: previewShadow.x, y: previewShadow.y)
            .offset(x: xOffset, y: yOffset)
    }
}
