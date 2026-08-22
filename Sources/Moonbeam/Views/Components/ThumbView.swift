
import SwiftUI

/// An isolated view responsible for rendering the draggable slider thumb.
internal struct ThumbView: View {
    let isDragging: Bool
    let thumbOffset: CGFloat
    let dimensions: ColorSliderDimensions
    let axis: Axis
    let resolvedThumbThickness: CGFloat
    let resolvedThumbLength: CGFloat

    @Environment(\.colorSliderThumbShape) private var thumbShape
    @Environment(\.colorSliderThumbColor) private var thumbColor
    @Environment(\.colorSliderThumbStroke) private var thumbStroke
    @Environment(\.colorSliderThumbShadow) private var thumbShadow
    @Environment(\.colorSliderDisableLiquidGlass) private var disableLiquidGlass

    /// Set to `true` to scale the thumb up during a drag gesture if the
    /// platform supports Liquid Glass effects and it has not been explicitly
    /// disabled.
    private var enableThumbScale: Bool {
        if #available(iOS 26.0, macOS 26.0, *) { return !disableLiquidGlass }
        return false
    }

    var body: some View {
        let thumbWidth: CGFloat = axis == .horizontal ? resolvedThumbThickness : resolvedThumbLength
        let thumbHeight: CGFloat = axis == .horizontal ? resolvedThumbLength : resolvedThumbThickness

        let xOffset: CGFloat = axis == .horizontal ? thumbOffset : 0
        let yOffset: CGFloat = axis == .horizontal ? 0 : -thumbOffset

        let dynamicScale: CGFloat = (isDragging && enableThumbScale) ? ColorSliderDefaults.dragScaleMultiplier : 1.0

        Group {
#if compiler(>=6.2)
            if #available(iOS 26.0, macOS 26.0, *), !disableLiquidGlass {
                Color.clear
                    .glassEffect(isDragging ? .regular.interactive(true) : .identity, in: thumbShape)
                    .overlay(thumbShape.fill(thumbColor).opacity(isDragging ? 0.0 : 1.0))
            } else {
                thumbShape.fill(thumbColor)
            }
#else
            thumbShape.fill(thumbColor)
#endif
        }
        .foregroundColor(thumbColor)
        .frame(width: thumbWidth, height: thumbHeight)
        .scaleEffect(dynamicScale)
        .shadow(color: thumbShadow.color, radius: thumbShadow.radius, x: thumbShadow.x, y: thumbShadow.y)
        .overlay {
            if let stroke = thumbStroke {
                thumbShape.stroke(stroke.style, lineWidth: stroke.lineWidth)
            }
        }
        .offset(x: xOffset, y: yOffset)
    }
}
