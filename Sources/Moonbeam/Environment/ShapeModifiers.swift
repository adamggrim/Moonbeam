import SwiftUI

// MARK: - Shared types

/// Defines the stroke style and width applied to slider components.
public struct ShapeStroke: Sendable {
    /// The styling applied to the stroke.
    ///
    /// Because this property accepts `AnyShapeStyle`, it supports any type that
    /// conforms to `ShapeStyle`, including colors (`Color.red`), gradients
    /// (`LinearGradient`), hierarchical styles (`.secondary`) or background
    /// materials (`.ultraThinMaterial`).
    public var style: AnyShapeStyle

    /// The thickness of the stroke in points.
    public var lineWidth: CGFloat
}

/// Defines the shadow applied to slider components.
public struct ShapeShadow: Sendable, Equatable {
    /// The color of the shadow.
    public var color: Color

    /// The blur radius of the shadow.
    public var radius: CGFloat

    /// The horizontal offset of the shadow.
    public var x: CGFloat

    /// The vertical offset of the shadow.
    public var y: CGFloat

    /// Initializes new shadow properties.
    ///
    /// - Parameters:
    ///   - color: The color of the shadow. Defaults to a semi-transparent
    ///     black.
    ///   - radius: The blur radius. Defaults to 5.
    ///   - x: The horizontal offset. Defaults to 0.
    ///   - y: The vertical offset. Defaults to 0.
    public init(
        color: Color = .black.opacity(ColorSliderDefaults.shadowOpacity),
        radius: CGFloat = ColorSliderDefaults.shadowRadius,
        x: CGFloat = ColorSliderDefaults.shadowX,
        y: CGFloat = ColorSliderDefaults.shadowY
    ) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

// MARK: - View modifiers

public extension View {

    // MARK: Track

    /// Adds a stroke to the slider track.
    func colorSliderTrackStroke<S: ShapeStyle>(
        _ style: S,
        lineWidth: CGFloat = ColorSliderDefaults.strokeLineWidth
    ) -> some View {
        let stroke = ShapeStroke(style: AnyShapeStyle(style), lineWidth: lineWidth)
        return environment(\.colorSliderTrackStroke, stroke)
    }

    /// Changes the corner radius so the slider track appears as a
    /// `RoundedRectangle` instead of a `Capsule`.
    func colorSliderCornerRadius(_ radius: CGFloat) -> some View {
        transformEnvironment(\.colorSliderDimensions) { dimensions in
            dimensions.cornerRadius = radius
        }
    }

    // MARK: Thumb

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
        let stroke = ShapeStroke(style: AnyShapeStyle(style), lineWidth: lineWidth)
        return environment(\.colorSliderThumbStroke, stroke)
    }

    /// Sets the shadow for the thumb.
    func colorSliderThumbShadow(
        color: Color = .black.opacity(ColorSliderDefaults.shadowOpacity),
        radius: CGFloat = ColorSliderDefaults.shadowRadius,
        x: CGFloat = ColorSliderDefaults.shadowX,
        y: CGFloat = ColorSliderDefaults.shadowY
    ) -> some View {
        environment(\.colorSliderThumbShadow, ShapeShadow(color: color, radius: radius, x: x, y: y))
    }

    // MARK: Preview

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
        let stroke = ShapeStroke(style: AnyShapeStyle(style), lineWidth: lineWidth)
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
        environment(\.colorSliderPreviewShadow, ShapeShadow(color: color, radius: radius, x: x, y: y))
    }
}
