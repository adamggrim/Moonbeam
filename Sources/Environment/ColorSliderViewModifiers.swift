import SwiftUI

/// The position of the floating color preview relative to the slider.
public enum PreviewPosition: Sendable, Equatable {
    case top, bottom, leading, trailing
}

/// Encapsulates various layout dimensions for the color slider and its components.
public struct ColorSliderDimensions: Sendable, Equatable {
    public var length: CGFloat = 300
    public var thickness: CGFloat = 24
    public var cornerRadius: CGFloat? = nil
    public var thumbThickness: CGFloat? = nil
    public var thumbLength: CGFloat? = nil
    public var previewSize: CGFloat = 60
    public var previewOffset: CGFloat? = nil
    public var shadowRadius: CGFloat = 5
    public var scaleRatio: CGFloat = 0.25
    
    public var previewCornerRadius: CGFloat {
        previewSize * 0.225
    }
}

public struct SliderStroke: Sendable {
    public var style: AnyShapeStyle
    public var lineWidth: CGFloat
}

// MARK: - Environment Keys

private struct TrackStrokeKey: EnvironmentKey { static let defaultValue: SliderStroke? = nil }

private struct ThumbShapeKey: EnvironmentKey { static let defaultValue = AnyShape(Capsule()) }
private struct ThumbColorKey: EnvironmentKey { static let defaultValue: Color = .white }
private struct ThumbStrokeKey: EnvironmentKey { static let defaultValue: SliderStroke? = nil }

private struct PreviewShapeKey: EnvironmentKey { static let defaultValue: AnyShape? = nil }
private struct PreviewStrokeKey: EnvironmentKey { static let defaultValue: SliderStroke? = nil }
private struct PreviewPositionKey: EnvironmentKey { static let defaultValue: PreviewPosition? = nil }
private struct PreviewSpacingKey: EnvironmentKey { static let defaultValue: CGFloat? = nil }
private struct PreviewHiddenKey: EnvironmentKey { static let defaultValue: Bool = true }

private struct DisableLiquidGlassKey: EnvironmentKey { static let defaultValue: Bool = false }
private struct DimensionsKey: EnvironmentKey { static let defaultValue = ColorSliderDimensions() }
private struct HardEdgeInnerShadowRadiusKey: EnvironmentKey { static let defaultValue: CGFloat = 0 }
private struct HardEdgeInnerShadowOpacityKey: EnvironmentKey { static let defaultValue: Double = 0 }
private struct AnimationKey: EnvironmentKey { static let defaultValue: Animation = .easeInOut(duration: 0.25) }

extension EnvironmentValues {
    var colorSliderTrackStroke: SliderStroke? {
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
    var colorSliderThumbStroke: SliderStroke? {
        get { self[ThumbStrokeKey.self] }
        set { self[ThumbStrokeKey.self] = newValue }
    }
    
    var colorSliderPreviewShape: AnyShape? {
        get { self[PreviewShapeKey.self] }
        set { self[PreviewShapeKey.self] = newValue }
    }
    var colorSliderPreviewStroke: SliderStroke? {
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
    
    var colorSliderDisableLiquidGlass: Bool {
        get { self[DisableLiquidGlassKey.self] }
        set { self[DisableLiquidGlassKey.self] = newValue }
    }
    var colorSliderDimensions: ColorSliderDimensions {
        get { self[DimensionsKey.self] }
        set { self[DimensionsKey.self] = newValue }
    }
    var colorSliderHardEdgeInnerShadowRadius: CGFloat {
        get { self[HardEdgeInnerShadowRadiusKey.self] }
        set { self[HardEdgeInnerShadowRadiusKey.self] = newValue }
    }
    var colorSliderHardEdgeInnerShadowOpacity: Double {
        get { self[HardEdgeInnerShadowOpacityKey.self] }
        set { self[HardEdgeInnerShadowOpacityKey.self] = newValue }
    }
    var colorSliderAnimation: Animation {
        get { self[AnimationKey.self] }
        set { self[AnimationKey.self] = newValue }
    }
}

// MARK: - View Modifiers

public extension View {
    // MARK: Track Modifiers
    /// Adds a stroke to the slider track.
    func colorSliderTrackStroke<S: ShapeStyle>(_ style: S, lineWidth: CGFloat = 1) -> some View {
        let stroke = SliderStroke(style: AnyShapeStyle(style), lineWidth: lineWidth)
        return environment(\.colorSliderTrackStroke, stroke)
    }
    
    /// Changes the corner radius so the slider track appears as a `RoundedRectangle` instead of a `Capsule`.
    func colorSliderCornerRadius(_ radius: CGFloat) -> some View {
            var newDimensions = ColorSliderDimensions()
            newDimensions.cornerRadius = radius
            return environment(\.colorSliderDimensions, newDimensions)
        }

    // MARK: Thumb Modifiers
    /// The visual shape of the thumb. Defaults to `Capsule`.
    func colorSliderThumbShape<S: Shape>(_ shape: S) -> some View {
        environment(\.colorSliderThumbShape, AnyShape(shape))
    }

    /// The fill color of the draggable thumb. Defaults to `.white`.
    func colorSliderThumbColor(_ color: Color) -> some View {
        environment(\.colorSliderThumbColor, color)
    }
    
    /// Adds a stroke to the draggable thumb.
    func colorSliderThumbStroke<S: ShapeStyle>(_ style: S, lineWidth: CGFloat = 1) -> some View {
        let stroke = SliderStroke(style: AnyShapeStyle(style), lineWidth: lineWidth)
        return environment(\.colorSliderThumbStroke, stroke)
    }

    // MARK: Preview Modifiers
    /// The visual shape of the floating color preview. If nil, defaults to `RoundedRectangle`.
    func colorSliderPreviewShape<S: Shape>(_ shape: S) -> some View {
        environment(\.colorSliderPreviewShape, AnyShape(shape))
    }

    /// Adds a stroke to the floating color preview.
    func colorSliderPreviewStroke<S: ShapeStyle>(_ style: S, lineWidth: CGFloat = 1) -> some View {
        let stroke = SliderStroke(style: AnyShapeStyle(style), lineWidth: lineWidth)
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

    // MARK: Global Modifiers
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
        previewOffset: CGFloat? = nil,
        shadowRadius: CGFloat = 5
    ) -> some View {
        let dim = ColorSliderDimensions(
            length: length,
            thickness: thickness,
            thumbThickness: thumbThickness,
            thumbLength: thumbLength,
            previewSize: previewSize,
            previewOffset: previewOffset,
            shadowRadius: shadowRadius
        )
        return environment(\.colorSliderDimensions, dim)
    }

    /// Adds an inset shadow to each discrete color block in a hard-edge slider. By default, sliders do not have an inner shadow.
    /// - Parameters:
    ///   - radius: The blur radius of the inner shadow. Defaults to `3`.
    ///   - opacity: The opacity of the black shadow. Defaults to `0.3`.
    func colorSliderHardEdgeInnerShadow(radius: CGFloat = 3, opacity: Double = 0.3) -> some View {
        self.environment(\.colorSliderHardEdgeInnerShadowRadius, radius)
            .environment(\.colorSliderHardEdgeInnerShadowOpacity, opacity)
    }

    /// Sets the animation used when the drag gesture starts and ends.
    func colorSliderAnimation(_ animation: Animation) -> some View {
        environment(\.colorSliderAnimation, animation)
    }
}
