import SwiftUI

/// The placement of the floating color preview relative to the slider.
public enum PreviewPosition: Sendable {
    case top, bottom, leading, trailing
}

/// Encapsulates various layout dimensions for the color slider and its components.
public struct ColorSliderDimensions: Sendable {
    public var thickness: CGFloat = 24
    public var length: CGFloat = 300
    public var thumbThickness: CGFloat? = nil
    public var thumbLength: CGFloat? = nil
    public var previewSize: CGFloat = 60
    public var previewOffset: CGFloat? = nil
    public var shadowRadius: CGFloat = 5
    public let scaleRatio: CGFloat = 0.25
    
    public var previewCornerRadius: CGFloat {
        previewSize * 0.225
    }
}

public struct SliderStroke: Sendable {
    public var style: AnyShapeStyle
    public var lineWidth: CGFloat
}

// MARK: - Environment Keys

private struct ThumbShapeKey: EnvironmentKey { static let defaultValue = AnyShape(Capsule()) }
private struct TrackStrokeKey: EnvironmentKey { static let defaultValue: SliderStroke? = nil }
private struct ThumbStrokeKey: EnvironmentKey { static let defaultValue: SliderStroke? = nil }
private struct ThumbColorKey: EnvironmentKey { static let defaultValue: Color = .white }
private struct PreviewHiddenKey: EnvironmentKey { static let defaultValue: Bool = true }
private struct DisableLiquidGlassKey: EnvironmentKey { static let defaultValue: Bool = false }
private struct DimensionsKey: EnvironmentKey { static let defaultValue = ColorSliderDimensions() }
private struct HardEdgeInnerShadowKey: EnvironmentKey { static let defaultValue: Bool = true }
private struct AnimationKey: EnvironmentKey { static let defaultValue: Animation = .easeInOut(duration: 0.25) }
private struct PreviewPositionKey: EnvironmentKey { static let defaultValue: PreviewPosition? = nil }
private struct PreviewSpacingKey: EnvironmentKey { static let defaultValue: CGFloat? = nil }

extension EnvironmentValues {
    var colorSliderThumbShape: AnyShape {
        get { self[ThumbShapeKey.self] }
        set { self[ThumbShapeKey.self] = newValue }
    }
    var colorSliderThumbColor: Color {
        get { self[ThumbColorKey.self] }
        set { self[ThumbColorKey.self] = newValue }
    }
    var colorSliderPreviewHidden: Bool {
        get { self[PreviewHiddenKey.self] }
        set { self[PreviewHiddenKey.self] = newValue }
    }
    var colorSliderDisableLiquidGlass: Bool {
        get { self[DisableLiquidGlassKey.self] }
        set { self[DisableLiquidGlassKey.self] = newValue }
    }
    var colorSliderDimensions: ColorSliderDimensions {
        get { self[DimensionsKey.self] }
        set { self[DimensionsKey.self] = newValue }
    }
    var colorSliderHardEdgeInnerShadow: Bool {
        get { self[HardEdgeInnerShadowKey.self] }
        set { self[HardEdgeInnerShadowKey.self] = newValue }
    }
    var colorSliderAnimation: Animation {
        get { self[AnimationKey.self] }
        set { self[AnimationKey.self] = newValue }
    }
    var colorSliderTrackStroke: SliderStroke? {
        get { self[TrackStrokeKey.self] }
        set { self[TrackStrokeKey.self] = newValue }
    }
    var colorSliderThumbStroke: SliderStroke? {
        get { self[ThumbStrokeKey.self] }
        set { self[ThumbStrokeKey.self] = newValue }
    }
    var colorSliderPreviewPosition: PreviewPosition? {
        get { self[PreviewPositionKey.self] }
        set { self[PreviewPositionKey.self] = newValue }
    }
    var colorSliderPreviewSpacing: CGFloat? {
        get { self[PreviewSpacingKey.self] }
        set { self[PreviewSpacingKey.self] = newValue }
    }
}

// MARK: - View Modifiers
public extension View {
    /// The visual shape of the thumb. Defaults to `Capsule`.
    func colorSliderThumbShape<S: Shape>(_ shape: S) -> some View {
        environment(\.colorSliderThumbShape, AnyShape(shape))
    }
    
    /// The fill color of the draggable thumb. Defaults to `.white`.
    func colorSliderThumbColor(_ color: Color) -> some View {
        environment(\.colorSliderThumbColor, color)
    }
    
    /// A boolean determining if the preview should only appear during active dragging. Defaults to `true`.
    func colorSliderPreviewHidden(_ hidden: Bool) -> some View {
        environment(\.colorSliderPreviewHidden, hidden)
    }
    
    /// Set to `true` to disable the liquid glass styling on the thumb. On operating systems that do not support Liquid Glass, this flag is ignored and falls back to a standard filled shape. Defaults to `false`.
    func colorSliderDisableLiquidGlass(_ disable: Bool) -> some View {
        environment(\.colorSliderDisableLiquidGlass, disable)
    }
    
    /// Customizes the layout dimensions of the color slider.
    ///
    /// - Parameters:
    ///   - thickness: The thickness of the slider. Defaults to 24.
    ///   - length: The length of the slider. Defaults to 300.
    ///   - thumbThickness: The thickness of the draggable thumb. If `nil`, defaults to the slider thickness.
    ///   - thumbLength: The length of the draggable thumb. If `nil`, defaults to twice the slider thickness.
    ///   - previewSize: The width and height of the floating color preview. Defaults to 60.
    func colorSliderDimensions(
        thickness: CGFloat = 24,
        length: CGFloat = 300,
        thumbThickness: CGFloat? = nil,
        thumbLength: CGFloat? = nil,
        previewSize: CGFloat = 60,
        previewOffset: CGFloat? = nil,
        shadowRadius: CGFloat = 5
    ) -> some View {
        let dim = ColorSliderDimensions(
            thickness: thickness,
            length: length,
            thumbThickness: thumbThickness,
            thumbLength: thumbLength,
            previewSize: previewSize,
            previewOffset: previewOffset,
            shadowRadius: shadowRadius
        )
        return environment(\.colorSliderDimensions, dim)
    }
    
    /// Adds an inset shadow to each discrete color block in a hard-edge slider. Defaults to `true`.
    func colorSliderHardEdgeInnerShadow(_ enabled: Bool = true) -> some View {
            environment(\.colorSliderHardEdgeInnerShadow, enabled)
        }

    /// Sets the animation used when the drag gesture starts and ends.
    func colorSliderAnimation(_ animation: Animation) -> some View {
        environment(\.colorSliderAnimation, animation)
    }

    /// Adds a stroke to the slider track.
    func colorSliderTrackStroke<S: ShapeStyle>(_ style: S, lineWidth: CGFloat = 1) -> some View {
        let stroke = SliderStroke(style: AnyShapeStyle(style), lineWidth: lineWidth)
        return environment(\.colorSliderTrackStroke, stroke)
    }

    /// Adds a stroke to the draggable thumb.
    func colorSliderThumbStroke<S: ShapeStyle>(_ style: S, lineWidth: CGFloat = 1) -> some View {
        let stroke = SliderStroke(style: AnyShapeStyle(style), lineWidth: lineWidth)
        return environment(\.colorSliderThumbStroke, stroke)
    }
    
    /// The position of the floating color preview in relation to the slider.
    func colorSliderPreviewPosition(_ position: PreviewPosition, spacing: CGFloat? = nil) -> some View {
        self.environment(\.colorSliderPreviewPosition, position)
            .environment(\.colorSliderPreviewSpacing, spacing)
    }
}
