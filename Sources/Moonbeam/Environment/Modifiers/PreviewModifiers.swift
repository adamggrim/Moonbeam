
import SwiftUI


public extension View {
    /// The visual shape of the floating color preview. If nil, defaults to
    /// `RoundedRectangle`.
    func colorSliderPreviewShape<S: Shape>(_ shape: S) -> some View {
        environment(\.colorSliderPreviewShape, AnyShape(shape))
    }

    /// Adds a stroke to the floating color preview.
    func colorSliderPreviewStroke<S: ShapeStyle>(
        _ style: S,
        lineWidth: CGFloat = ColorSliderDefaults.strokeLineWidth
    ) -> some View {
        let stroke = TrackStroke(style: AnyShapeStyle(style), lineWidth: lineWidth)
        return environment(\.colorSliderPreviewStroke, stroke)
    }

    /// The position of the floating color preview in relation to the slider.
    func colorSliderPreviewPosition(_ position: PreviewPosition, spacing: CGFloat? = nil) -> some View {
        self.environment(\.colorSliderPreviewPosition, position)
            .environment(\.colorSliderPreviewSpacing, spacing)
    }

    /// A boolean for whether the floating color preview should appear only
    /// during active dragging. Defaults to `true`.
    func colorSliderPreviewHidden(_ hidden: Bool) -> some View {
        environment(\.colorSliderPreviewHidden, hidden)
    }

    /// Sets the shadow for the floating color preview.
    func colorSliderPreviewShadow(
        color: Color = .black.opacity(ColorSliderDefaults.shadowOpacity),
        radius: CGFloat = ColorSliderDefaults.shadowRadius,
        x: CGFloat = ColorSliderDefaults.shadowX,
        y: CGFloat = ColorSliderDefaults.shadowY
    ) -> some View {
        environment(\.colorSliderPreviewShadow, ColorSliderShadow(color: color, radius: radius, x: x, y: y))
    }
}
