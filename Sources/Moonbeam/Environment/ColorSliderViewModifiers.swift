import SwiftUI

/// The position of the floating color preview relative to the slider.
public enum PreviewPosition: Sendable, Equatable {
    case top, bottom, leading, trailing
}

/// Encapsulates various layout dimensions for the color slider and its components.
public struct ColorSliderDimensions: Sendable, Equatable {
    /// The length of the slider track.
    public var length: CGFloat = 300
    
    /// The thickness of the slider track.
    public var thickness: CGFloat = 24
    
    /// The corner radius of the slider track. If `nil`, the track resolves to a `Capsule` shape.
    public var cornerRadius: CGFloat? = nil
    
    /// The thickness of the slider thumb. If `nil`, falls back to the track's `thickness`.
    public var thumbThickness: CGFloat? = nil
    
    /// The length of the slider thumb. If `nil`, defaults to twice the track's `thickness`.
    public var thumbLength: CGFloat? = nil
    
    /// The width (and height) of the floating color preview.
    public var previewSize: CGFloat = 60
    
    /// The distance between the floating color preview and the slider thumb.
    public var previewOffset: CGFloat? = nil
    
    /// The scale of the preview when it is hidden and not actively being dragged.
    public var scaleRatio: CGFloat = 0.25
    
    /// The corner radius applied to the floating color preview.
    public var previewCornerRadius: CGFloat {
        previewSize * 0.225
    }
}

public struct ColorSliderShadow: Sendable, Equatable {
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
    ///   - color: The color of the shadow. Defaults to a semi-transparent black.
    ///   - radius: The blur radius. Defaults to 5.
    ///   - x: The horizontal offset. Defaults to 0.
    ///   - y: The vertical offset. Defaults to 0.
    public init(color: Color = .black.opacity(0.33), radius: CGFloat = 5, x: CGFloat = 0, y: CGFloat = 0) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

/// Defines the stroke style and width applied to slider components.
public struct TrackStroke: Sendable {
    /// The styling applied to the stroke.
    ///
    /// Because this property accepts `AnyShapeStyle`, it supports any type that conforms
    /// to `ShapeStyle`, including colors (`Color.red`), gradients (`LinearGradient`),
    /// hierarchical styles (`.secondary`) or background materials (`.ultraThinMaterial`).
    public var style: AnyShapeStyle
    
    /// The thickness of the stroke in points.
    public var lineWidth: CGFloat
}

// MARK: - Environment keys

private struct TrackStrokeKey: EnvironmentKey { static let defaultValue: TrackStroke? = nil }

private struct ThumbShapeKey: EnvironmentKey { static let defaultValue = AnyShape(Capsule()) }
private struct ThumbColorKey: EnvironmentKey { static let defaultValue: Color = .white }
private struct ThumbStrokeKey: EnvironmentKey { static let defaultValue: TrackStroke? = nil }
private struct ThumbShadowKey: EnvironmentKey { static let defaultValue = ColorSliderShadow() }

private struct PreviewShapeKey: EnvironmentKey { static let defaultValue: AnyShape? = nil }
private struct PreviewStrokeKey: EnvironmentKey { static let defaultValue: TrackStroke? = nil }
private struct PreviewPositionKey: EnvironmentKey { static let defaultValue: PreviewPosition? = nil }
private struct PreviewSpacingKey: EnvironmentKey { static let defaultValue: CGFloat? = nil }
private struct PreviewHiddenKey: EnvironmentKey { static let defaultValue: Bool = true }
private struct PreviewShadowKey: EnvironmentKey { static let defaultValue = ColorSliderShadow() }

private struct DisableLiquidGlassKey: EnvironmentKey { static let defaultValue: Bool = false }
private struct DimensionsKey: EnvironmentKey { static let defaultValue = ColorSliderDimensions() }
private struct DragMinimumDistanceKey: EnvironmentKey { static let defaultValue: CGFloat = 0 }
private struct AccessibilityStepKey: EnvironmentKey { static let defaultValue: Double = 0.05 }
private struct AnimationKey: EnvironmentKey { static let defaultValue: Animation = .easeInOut(duration: 0.25) }

extension EnvironmentValues {
    var colorSliderTrackStroke: TrackStroke? {
        get { self[TrackStrokeKey.self] }
        set { self[TrackStrokeKey.self] = newValue }
    }
    
    var colorSliderThumbShape: AnyShape {
        get { self[ThumbShapeKey.self] }
        set { self[ThumbShapeKey.self] = newValue }
    }
    var colorSliderThumbColor: Color {
        get { self[ThumbColorKey.self] }
        set { self[ThumbColorKey.self] = newValue }
    }
    var colorSliderThumbStroke: TrackStroke? {
            get { self[ThumbStrokeKey.self] }
            set { self[ThumbStrokeKey.self] = newValue }
        }
    var colorSliderThumbShadow: ColorSliderShadow {
        get { self[ThumbShadowKey.self] }
        set { self[ThumbShadowKey.self] = newValue }
    }
    
    var colorSliderPreviewShape: AnyShape? {
        get { self[PreviewShapeKey.self] }
        set { self[PreviewShapeKey.self] = newValue }
    }
    var colorSliderPreviewStroke: TrackStroke? {
        get { self[PreviewStrokeKey.self] }
        set { self[PreviewStrokeKey.self] = newValue }
    }
    var colorSliderPreviewPosition: PreviewPosition? {
        get { self[PreviewPositionKey.self] }
        set { self[PreviewPositionKey.self] = newValue }
    }
    var colorSliderPreviewSpacing: CGFloat? {
        get { self[PreviewSpacingKey.self] }
        set { self[PreviewSpacingKey.self] = newValue }
    }
    var colorSliderPreviewHidden: Bool {
        get { self[PreviewHiddenKey.self] }
        set { self[PreviewHiddenKey.self] = newValue }
    }
    var colorSliderPreviewShadow: ColorSliderShadow {
        get { self[PreviewShadowKey.self] }
        set { self[PreviewShadowKey.self] = newValue }
    }
    
    var colorSliderDisableLiquidGlass: Bool {
        get { self[DisableLiquidGlassKey.self] }
        set { self[DisableLiquidGlassKey.self] = newValue }
    }
    var colorSliderDimensions: ColorSliderDimensions {
        get { self[DimensionsKey.self] }
        set { self[DimensionsKey.self] = newValue }
    }
    var colorSliderDragMinimumDistance: CGFloat {
        get { self[DragMinimumDistanceKey.self] }
        set { self[DragMinimumDistanceKey.self] = newValue }
    }
    var colorSliderAccessibilityStep: Double {
        get { self[AccessibilityStepKey.self] }
        set { self[AccessibilityStepKey.self] = newValue }
    }
    var colorSliderAnimation: Animation {
        get { self[AnimationKey.self] }
        set { self[AnimationKey.self] = newValue }
    }
}

// MARK: - View modifiers

public extension View {
    
    // MARK: Track modifiers
    
    /// Adds a stroke to the slider track.
    func colorSliderTrackStroke<S: ShapeStyle>(_ style: S, lineWidth: CGFloat = 1) -> some View {
        let stroke = TrackStroke(style: AnyShapeStyle(style), lineWidth: lineWidth)
        return environment(\.colorSliderTrackStroke, stroke)
    }
    
    /// Changes the corner radius so the slider track appears as a `RoundedRectangle` instead of a `Capsule`.
    func colorSliderCornerRadius(_ radius: CGFloat) -> some View {
            var newDimensions = ColorSliderDimensions()
            newDimensions.cornerRadius = radius
            return environment(\.colorSliderDimensions, newDimensions)
        }

    // MARK: Thumb modifiers
    
    /// The visual shape of the thumb. Defaults to `Capsule`.
    func colorSliderThumbShape<S: Shape>(_ shape: S) -> some View {
        environment(\.colorSliderThumbShape, AnyShape(shape))
    }

    /// The fill color of the thumb. Defaults to `.white`.
    func colorSliderThumbColor(_ color: Color) -> some View {
        environment(\.colorSliderThumbColor, color)
    }
    
    /// Adds a stroke to the thumb.
    func colorSliderThumbStroke<S: ShapeStyle>(_ style: S, lineWidth: CGFloat = 1) -> some View {
        let stroke = TrackStroke(style: AnyShapeStyle(style), lineWidth: lineWidth)
        return environment(\.colorSliderThumbStroke, stroke)
    }

    /// Sets the shadow for the thumb.
        func colorSliderThumbShadow(color: Color = .black.opacity(0.33), radius: CGFloat = 5, x: CGFloat = 0, y: CGFloat = 0) -> some View {
            environment(\.colorSliderThumbShadow, ColorSliderShadow(color: color, radius: radius, x: x, y: y))
        }
    
    // MARK: Preview modifiers
    
    /// The visual shape of the floating color preview. If nil, defaults to `RoundedRectangle`.
    func colorSliderPreviewShape<S: Shape>(_ shape: S) -> some View {
        environment(\.colorSliderPreviewShape, AnyShape(shape))
    }

    /// Adds a stroke to the floating color preview.
    func colorSliderPreviewStroke<S: ShapeStyle>(_ style: S, lineWidth: CGFloat = 1) -> some View {
        let stroke = TrackStroke(style: AnyShapeStyle(style), lineWidth: lineWidth)
        return environment(\.colorSliderPreviewStroke, stroke)
    }

    /// The position of the floating color preview in relation to the slider.
    func colorSliderPreviewPosition(_ position: PreviewPosition, spacing: CGFloat? = nil) -> some View {
        self.environment(\.colorSliderPreviewPosition, position)
            .environment(\.colorSliderPreviewSpacing, spacing)
    }
    
    /// A boolean determining if the preview should only appear during active dragging. Defaults to `true`.
    func colorSliderPreviewHidden(_ hidden: Bool) -> some View {
        environment(\.colorSliderPreviewHidden, hidden)
    }
    
    /// Sets the shadow for the floating color preview.
    func colorSliderPreviewShadow(color: Color = .black.opacity(0.33), radius: CGFloat = 5, x: CGFloat = 0, y: CGFloat = 0) -> some View {
        environment(\.colorSliderPreviewShadow, ColorSliderShadow(color: color, radius: radius, x: x, y: y))
    }

    // MARK: Global modifiers
        
    /// Set to `true` to disable the liquid glass styling on the thumb. On operating systems that do not support Liquid Glass, this flag is ignored and falls back to a standard filled shape. Defaults to `false`.
    func colorSliderDisableLiquidGlass(_ disable: Bool) -> some View {
        environment(\.colorSliderDisableLiquidGlass, disable)
    }
    
    /// Customizes the layout dimensions of the color slider.
    func colorSliderDimensions(
        length: CGFloat = 300,
        thickness: CGFloat = 24,
        thumbThickness: CGFloat? = nil,
        thumbLength: CGFloat? = nil,
        previewSize: CGFloat = 60,
        previewOffset: CGFloat? = nil
    ) -> some View {
        let dim = ColorSliderDimensions(
            length: length,
            thickness: thickness,
            thumbThickness: thumbThickness,
            thumbLength: thumbLength,
            previewSize: previewSize,
            previewOffset: previewOffset
        )
        return environment(\.colorSliderDimensions, dim)
    }
    
    /// Customizes the minimum distance to drag the thumb before the slider recognizes the drag. Defaults to 0.
    func colorSliderDragMinimumDistance(_ distance: CGFloat) -> some View {
        environment(\.colorSliderDragMinimumDistance, distance)
    }

    /// Customizes the step percentage used when adjusting the slider via VoiceOver.
    func colorSliderAccessibilityStep(_ step: Double) -> some View {
        environment(\.colorSliderAccessibilityStep, step)
    }

    /// Sets the animation used when the drag gesture starts and ends.
    func colorSliderAnimation(_ animation: Animation) -> some View {
        environment(\.colorSliderAnimation, animation)
    }
}
