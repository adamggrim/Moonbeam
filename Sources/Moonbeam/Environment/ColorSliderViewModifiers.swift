import SwiftUI

/// The position of the floating color preview relative to the slider.
public enum PreviewPosition: Sendable, Equatable {
    /// Positions the floating color preview above a horizontal slider, or to
    /// the left of a vertical slider.
    case topLeading

    /// Positions the floating color preview below a horizontal slider, or to
    /// the right of a vertical slider.
    case bottomTrailing
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
private struct AccessibilityStepKey: EnvironmentKey {
    static let defaultValue: Double = ColorSliderDefaults.accessibilityStepPercentage
}
private struct AnimationKey: EnvironmentKey {
    static let defaultValue: Animation = .easeInOut(duration: ColorSliderDefaults.animationDuration)
}

private struct ColorSliderConfigurationKey: EnvironmentKey {
    static let defaultValue = ColorSliderConfiguration()
}

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

    var colorSliderConfiguration: ColorSliderConfiguration {
        get { self[ColorSliderConfigurationKey.self] }
        set { self[ColorSliderConfigurationKey.self] = newValue }
    }
}

// MARK: - View modifiers

public extension View {

    // MARK: Global modifiers

    /// Set to `true` to disable the liquid glass styling on the thumb. On
    /// operating systems that do not support Liquid Glass, this flag is ignored
    /// and falls back to a standard filled shape. Defaults to `false`.
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
        let dimensions = ColorSliderDimensions(
            length: length,
            thickness: thickness,
            thumbThickness: thumbThickness,
            thumbLength: thumbLength,
            previewSize: previewSize,
            previewOffset: previewOffset
        )
        return environment(\.colorSliderDimensions, dimensions)
    }

    /// Customizes the minimum distance to drag the thumb before the slider
    /// recognizes the drag. Defaults to 0.
    func colorSliderDragMinimumDistance(_ distance: CGFloat) -> some View {
        environment(\.colorSliderDragMinimumDistance, distance)
    }

    /// Customizes the step percentage used when adjusting the slider via
    /// VoiceOver.
    func colorSliderAccessibilityStep(_ step: Double) -> some View {
        environment(\.colorSliderAccessibilityStep, step)
    }

    /// Sets the animation used when the drag gesture starts and ends.
    func colorSliderAnimation(_ animation: Animation) -> some View {
        environment(\.colorSliderAnimation, animation)
    }
}
