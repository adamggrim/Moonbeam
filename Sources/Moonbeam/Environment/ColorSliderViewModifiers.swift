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

/// Determines the visual rendering style of the draggable thumb.
public enum ColorSliderThumbStyle: Sendable, Equatable {
    /// The standard solid draggable thumb shape.
    case standard

    /// An outline wrapping the selected discrete color section of a hard-edge
    /// slider.
    ///
    /// - Parameters:
    ///   - lineWidth: The thickness of the outline stroke.
    ///   - padding: The empty space between the color section and the outline.
    case colorOutline(lineWidth: CGFloat = 2.0, padding: CGFloat = 4.0)
}

/// Determines when the Liquid Glass effect is applied to the slider thumb.
public enum LiquidGlassThumb: Sendable, Equatable {
    /// Always renders the draggable thumb with Liquid Glass.
    case always
    /// Only renders Liquid Glass during an active drag.
    case dragging
    /// Never renders the draggable thumb with Liquid Glass.
    case disabled
}

/// Encapsulates the boundary resistance parameters applied when dragging past
/// the ends of the slider track.
internal struct ColorSliderRubberBandingConfiguration: Sendable, Equatable {
    /// Indicates whether boundary rubber banding is enabled.
    var isEnabled: Bool = false
    /// The asymptotic maximum displacement in points past a track boundary.
    var limit: CGFloat = ColorSliderDefaults.rubberBandLimit
    /// The resistance coefficient controlling drag deceleration past a
    /// boundary.
    var resistance: CGFloat = ColorSliderDefaults.rubberBandResistance
}

// MARK: - Environment keys

private struct LiquidGlassThumbKey: EnvironmentKey { static let defaultValue: LiquidGlassThumb = .dragging }
private struct DimensionsKey: EnvironmentKey { static let defaultValue = ColorSliderDimensions() }
private struct DragMinimumDistanceKey: EnvironmentKey { static let defaultValue: CGFloat = 0 }
private struct AccessibilityStepKey: EnvironmentKey {
    static let defaultValue: Double = ColorSliderDefaults.accessibilityStepPercentage
}
private struct AnimationKey: EnvironmentKey {
    static let defaultValue: Animation = .easeInOut(duration: ColorSliderDefaults.animationDuration)
}
private struct PreviewPositionKey: EnvironmentKey { static let defaultValue: PreviewPosition? = nil }
private struct PreviewSpacingKey: EnvironmentKey { static let defaultValue: CGFloat? = nil }
private struct AccessibilityPercentageHiddenKey: EnvironmentKey { static let defaultValue: Bool = false }
private struct AccessibilityFormatterKey: EnvironmentKey {
    static let defaultValue: (@Sendable (Double, String?) -> String)? = nil
}
private struct ThumbStyleKey: EnvironmentKey { static let defaultValue: ColorSliderThumbStyle = .standard }
private struct SnapToColorKey: EnvironmentKey { static let defaultValue: Bool? = nil }
private struct ThumbBounceKey: EnvironmentKey { static let defaultValue: Bool = false }
private struct SpringDurationKey: EnvironmentKey {
    static let defaultValue: Double = ColorSliderDefaults.thumbBounceDuration
}
private struct SpringBounceKey: EnvironmentKey {
    static let defaultValue: Double = ColorSliderDefaults.thumbBounce
}
private struct ThumbScaleBounceKey: EnvironmentKey { static let defaultValue: Bool = true }
private struct RubberBandingKey: EnvironmentKey {
    static let defaultValue = ColorSliderRubberBandingConfiguration()
}
private struct TapToSeekKey: EnvironmentKey { static let defaultValue: Bool = false }

extension EnvironmentValues {
    var colorSliderThumbStyle: ColorSliderThumbStyle {
        get { self[ThumbStyleKey.self] }
        set { self[ThumbStyleKey.self] = newValue }
    }

    var colorSliderSnapsToColor: Bool? {
        get { self[SnapToColorKey.self] }
        set { self[SnapToColorKey.self] = newValue }
    }

    var colorSliderThumbBounce: Bool {
        get { self[ThumbBounceKey.self] }
        set { self[ThumbBounceKey.self] = newValue }
    }

    var colorSliderSpringDuration: Double {
        get { self[SpringDurationKey.self] }
        set { self[SpringDurationKey.self] = newValue }
    }

    var colorSliderSpringBounce: Double {
        get { self[SpringBounceKey.self] }
        set { self[SpringBounceKey.self] = newValue }
    }

    var colorSliderThumbScaleBounce: Bool {
        get { self[ThumbScaleBounceKey.self] }
        set { self[ThumbScaleBounceKey.self] = newValue }
    }

    var colorSliderRubberBanding: ColorSliderRubberBandingConfiguration {
        get { self[RubberBandingKey.self] }
        set { self[RubberBandingKey.self] = newValue }
    }

    var colorSliderTapToSeek: Bool {
        get { self[TapToSeekKey.self] }
        set { self[TapToSeekKey.self] = newValue }
    }

    var colorSliderAccessibilityFormatter: (@Sendable (Double, String?) -> String)? {
        get { self[AccessibilityFormatterKey.self] }
        set { self[AccessibilityFormatterKey.self] = newValue }
    }

    var colorSliderLiquidGlassThumb: LiquidGlassThumb {
        get { self[LiquidGlassThumbKey.self] }
        set { self[LiquidGlassThumbKey.self] = newValue }
    }

    var colorSliderPreviewPosition: PreviewPosition? {
        get { self[PreviewPositionKey.self] }
        set { self[PreviewPositionKey.self] = newValue }
    }

    var colorSliderPreviewSpacing: CGFloat? {
        get { self[PreviewSpacingKey.self] }
        set { self[PreviewSpacingKey.self] = newValue }
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

    var colorSliderAccessibilityPercentageHidden: Bool {
        get { self[AccessibilityPercentageHiddenKey.self] }
        set { self[AccessibilityPercentageHiddenKey.self] = newValue }
    }
}

// MARK: - View modifiers

public extension View {
    /// Customizes the layout dimensions of the color slider.
    ///
    /// Only non-`nil` parameters override values inherited from ancestor views.
    ///
    /// - Parameters:
    ///   - length: The length of the slider track along the main axis.
    ///   - thickness: The thickness of cross axis.
    ///   - cornerRadius: The corner radius of the slider track.
    ///   - thumbThickness: The thickness of the draggable thumb.
    ///   - thumbLength: The length of the draggable thumb.
    ///   - previewSize: The width and height of the floating color preview.
    ///   - previewOffset: The distance between the floating color preview and
    ///     the thumb.
    ///   - previewScale: The scale of the preview when not actively being
    ///     dragged.
    ///   - thumbDragScale: The scale applied to the thumb during an active
    ///     drag.
    func colorSliderDimensions(
        length: CGFloat? = nil,
        thickness: CGFloat? = nil,
        cornerRadius: CGFloat? = nil,
        thumbThickness: CGFloat? = nil,
        thumbLength: CGFloat? = nil,
        previewSize: CGFloat? = nil,
        previewOffset: CGFloat? = nil,
        previewScale: CGFloat? = nil,
        thumbDragScale: CGFloat? = nil
    ) -> some View {
        transformEnvironment(\.colorSliderDimensions) { dimensions in
            dimensions.merge(
                length: length,
                thickness: thickness,
                cornerRadius: cornerRadius,
                thumbThickness: thumbThickness,
                thumbLength: thumbLength,
                previewSize: previewSize,
                previewOffset: previewOffset,
                previewScale: previewScale,
                thumbDragScale: thumbDragScale
            )
        }
    }

    /// Customizes the minimum distance to drag the thumb before the slider
    /// recognizes the drag. Defaults to 0.
    func colorSliderDragMinimumDistance(_ distance: CGFloat) -> some View {
        environment(\.colorSliderDragMinimumDistance, distance)
    }

    /// Customizes the step percentage used when adjusting the slider via
    /// VoiceOver or keyboard arrow keys.
    func colorSliderAccessibilityStep(_ step: Double) -> some View {
        environment(\.colorSliderAccessibilityStep, step)
    }

    /// Sets the animation used for drag start and end transitions.
    func colorSliderAnimation(_ animation: Animation) -> some View {
        environment(\.colorSliderAnimation, animation)
    }

    /// Configures thumb and preview positional movement to use an ease-in,
    /// ease-out timing curve with no positional overshoot.
    ///
    /// - Parameter duration: The duration of the easing curve in seconds.
    ///   Defaults to `ColorSliderDefaults.animationDuration`.
    func colorSliderEaseInOut(
        duration: Double = ColorSliderDefaults.animationDuration
    ) -> some View {
        self
            .environment(\.colorSliderAnimation, .easeInOut(duration: duration))
            .environment(\.colorSliderThumbBounce, false)
    }

    /// Configures thumb and preview positional movement to use a spring curve
    /// with customizable duration and bounce.
    ///
    /// - Parameters:
    ///   - duration: The perceptual duration of the spring in seconds. Defaults
    ///     to `ColorSliderDefaults.thumbBounceDuration`.
    ///   - bounce: The spring bounce factor (`0.0` for critically damped with
    ///     no overshoot, positive values for underdamped spring overshoot).
    ///     Defaults to `ColorSliderDefaults.thumbBounce`.
    func colorSliderSpring(
        duration: Double = ColorSliderDefaults.thumbBounceDuration,
        bounce: Double = ColorSliderDefaults.thumbBounce
    ) -> some View {
        self
            .environment(\.colorSliderThumbBounce, true)
            .environment(\.colorSliderSpringDuration, max(0.0, duration))
            .environment(\.colorSliderSpringBounce, bounce)
    }

    /// Customizes the position and spacing of the floating color preview.
    func colorSliderPreviewPosition(_ position: PreviewPosition, spacing: CGFloat? = nil) -> some View {
        self
            .environment(\.colorSliderPreviewPosition, position)
            .environment(\.colorSliderPreviewSpacing, spacing)
    }

    /// Customizes when to render the draggable thumb with Liquid Glass.
    func colorSliderLiquidGlassThumb(_ mode: LiquidGlassThumb) -> some View {
        environment(\.colorSliderLiquidGlassThumb, mode)
    }

    /// Determines whether the slider announces its value as a percentage in
    /// VoiceOver.
    func colorSliderAccessibilityPercentageHidden(_ hidden: Bool = true) -> some View {
        environment(\.colorSliderAccessibilityPercentageHidden, hidden)
    }

    /// Sets a custom VoiceOver formatter to override default descriptions.
    func colorSliderAccessibilityFormatter(_ formatter: @escaping @Sendable (Double, String?) -> String) -> some View {
        environment(\.colorSliderAccessibilityFormatter, formatter)
    }

    /// Sets the visual style of the draggable thumb.
    ///
    /// Defaults to `.standard`. Selecting `.colorOutline` automatically enables
    /// discrete color snapping (for hard-edge tracks).
    func colorSliderThumbStyle(_ style: ColorSliderThumbStyle) -> some View {
        environment(\.colorSliderThumbStyle, style)
    }

    /// Determines whether the slider automatically snaps to the center of the
    /// nearest discrete color block when a drag or tap ends.
    ///
    /// Applies only to discrete color providers such as `HardEdgeColors`.
    /// Defaults to `true` for `.colorOutline` thumbs and `false` for
    /// `.standard` thumbs.
    func colorSliderSnapsToColor(_ snaps: Bool) -> some View {
        environment(\.colorSliderSnapsToColor, snaps)
    }

    /// Determines whether thumb and preview positional movement uses spring
    /// overshoot along the slider axis.
    ///
    /// Respects the system `accessibilityReduceMotion` setting. Defaults to
    /// `false`.
    func colorSliderThumbBounce(_ bounces: Bool = true) -> some View {
        environment(\.colorSliderThumbBounce, bounces)
    }

    /// Determines whether the draggable thumb's scale transition uses a spring
    /// overshoot when starting and ending a drag.
    ///
    /// Unlike `colorSliderThumbBounce(_:)`, the spring overshoot animates the
    /// thumb's scale without overshooting its horizontal or vertical position.
    /// Respects the system `accessibilityReduceMotion` setting. Defaults to
    /// `true`.
    func colorSliderThumbScaleBounce(_ bounces: Bool = true) -> some View {
        environment(\.colorSliderThumbScaleBounce, bounces)
    }

    /// Determines whether dragging past the start or end of the slider track
    /// applies asymptotic rubber banding.
    ///
    /// - Parameters:
    ///   - enabled: Whether boundary rubber banding is active. Defaults to
    ///     `true`.
    ///   - limit: The asymptotic maximum over-pull distance in points. Defaults
    ///     to `ColorSliderDefaults.rubberBandLimit`.
    ///   - resistance: The drag resistance coefficient controlling how quickly
    ///     the thumb slows down past the edge. Defaults to
    ///     `ColorSliderDefaults.rubberBandResistance`.
    func colorSliderRubberBanding(
        _ enabled: Bool = true,
        limit: CGFloat = ColorSliderDefaults.rubberBandLimit,
        resistance: CGFloat = ColorSliderDefaults.rubberBandResistance
    ) -> some View {
        environment(
            \.colorSliderRubberBanding,
            ColorSliderRubberBandingConfiguration(
                isEnabled: enabled,
                limit: max(0.0, limit),
                resistance: max(0.0, resistance)
            )
        )
    }

    /// Determines whether tapping directly on the slider track jumps to that
    /// position.
    ///
    /// Respects discrete color snapping and thumb bounce settings when enabled.
    /// Defaults to `false`.
    func colorSliderTapToSeek(_ enabled: Bool = true) -> some View {
        environment(\.colorSliderTapToSeek, enabled)
    }
}
