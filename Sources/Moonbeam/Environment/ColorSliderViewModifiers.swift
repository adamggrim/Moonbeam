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

/// Determines when the Liquid Glass effect is applied to the slider thumb.
public enum LiquidGlassThumb: Sendable, Equatable {
    /// Always renders the draggable thumb with Liquid Glass.
    case always
    /// Only renders Liquid Glass during an active drag.
    case dragging
    /// Never renders the draggable thumb with Liquid Glass.
    case disabled
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

extension EnvironmentValues {
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
}

// MARK: - View modifiers

public extension View {

    // MARK: Global modifiers

    /// Customizes the layout dimensions of the color slider.
    func colorSliderDimensions(
        length: CGFloat? = nil,
        thickness: CGFloat? = nil,
        cornerRadius: CGFloat? = nil,
        thumbThickness: CGFloat? = nil,
        thumbLength: CGFloat? = nil,
        previewSize: CGFloat? = nil,
        previewOffset: CGFloat? = nil,
        scaleRatio: CGFloat = ColorSliderDefaults.scaleRatio
    ) -> some View {
        let dimensions = ColorSliderDimensions(
            length: length,
            thickness: thickness,
            cornerRadius: cornerRadius,
            thumbThickness: thumbThickness,
            thumbLength: thumbLength,
            previewSize: previewSize,
            previewOffset: previewOffset,
            scaleRatio: scaleRatio
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
}
