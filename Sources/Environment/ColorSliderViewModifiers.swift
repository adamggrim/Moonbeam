import SwiftUI

public enum ThumbStyle: Sendable {
    case capsule, circle
}

/// Encapsulates various layout dimensions for the color slider and its components.
public struct ColorSliderDimensions: Sendable {
    public var thickness: CGFloat = 25
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

private struct ThumbStyleKey: EnvironmentKey { static let defaultValue: ThumbStyle = .capsule }
private struct ThumbColorKey: EnvironmentKey { static let defaultValue: Color = .white }
private struct PreviewHiddenKey: EnvironmentKey { static let defaultValue: Bool = true }
private struct DisableLiquidGlassKey: EnvironmentKey { static let defaultValue: Bool = false }
private struct DimensionsKey: EnvironmentKey { static let defaultValue = ColorSliderDimensions() }
private struct HardEdgeInnerShadowKey: EnvironmentKey { static let defaultValue: Bool = true }

extension EnvironmentValues {
    var colorSliderThumbStyle: ThumbStyle {
        get { self[ThumbStyleKey.self] }
        set { self[ThumbStyleKey.self] = newValue }
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
}

// MARK: - View Modifiers
public extension View {
    /// The visual shape of the thumb (`.capsule` or `.circle`). Defaults to `.capsule`.
    func colorSliderThumbStyle(_ style: ThumbStyle) -> some View {
        environment(\.colorSliderThumbStyle, style)
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
    ///   - thickness: The thickness of the slider. Defaults to 25.
    ///   - length: The length of the slider. Defaults to 300.
    ///   - thumbThickness: The thickness of the draggable thumb. Defaults to the slider thickness.
    ///   - thumbLength: The length of the draggable thumb. Defaults to twice slider thickness for capsules.
    ///   - previewSize: The width and height of the floating color preview. Defaults to 60.
    ///   - previewOffset: The offset of the preview from the slider. Defaults to -70.
    ///   - shadowRadius: The blur radius for the shadows applied to the thumb and preview. Defaults to 5.
    func colorSliderDimensions(
        thickness: CGFloat = 25,
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
}
