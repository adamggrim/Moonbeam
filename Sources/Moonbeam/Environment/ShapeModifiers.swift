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

    /// Initializes a new stroke definition.
    ///
    /// - Parameters:
    ///   - style: The styling applied to the stroke.
    ///   - lineWidth: The thickness of the stroke in points.
    public init(style: AnyShapeStyle, lineWidth: CGFloat) {
        self.style = style
        self.lineWidth = lineWidth
    }
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
