import SwiftUI

public extension View {
    /// The visual shape of the thumb. Defaults to `Capsule`.
    func colorSliderThumbShape<S: Shape>(_ shape: S) -> some View {
        environment(\.colorSliderThumbShape, AnyShape(shape))
    }

    /// The fill color of the thumb. Defaults to `.white`.
    func colorSliderThumbColor(_ color: Color) -> some View {
        environment(\.colorSliderThumbColor, color)
    }

    /// Adds a stroke to the thumb.
    func colorSliderThumbStroke<S: ShapeStyle>(
        _ style: S,
        lineWidth: CGFloat = ColorSliderDefaults.strokeLineWidth
    ) -> some View {
        let stroke = TrackStroke(style: AnyShapeStyle(style), lineWidth: lineWidth)
        return environment(\.colorSliderThumbStroke, stroke)
    }

    /// Sets the shadow for the thumb.
    func colorSliderThumbShadow(
        color: Color = .black.opacity(ColorSliderDefaults.shadowOpacity),
        radius: CGFloat = ColorSliderDefaults.shadowRadius,
        x: CGFloat = ColorSliderDefaults.shadowX,
        y: CGFloat = ColorSliderDefaults.shadowY
    ) -> some View {
        environment(\.colorSliderThumbShadow, ColorSliderShadow(color: color, radius: radius, x: x, y: y))
    }
}
