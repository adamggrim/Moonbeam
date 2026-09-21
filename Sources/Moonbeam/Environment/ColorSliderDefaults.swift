import SwiftUI

/// Global default metrics for  color sliders.
public enum ColorSliderDefaults {
    /// Returns the default track thickness for a given control size.
    public static func trackThickness(for controlSize: ControlSize) -> CGFloat {
        switch controlSize {
        case .mini: return 12.0
        case .small: return 16.0
        case .regular: return 24.0
        case .large: return 32.0
        case .extraLarge: return 40.0
        @unknown default: return 24.0
        }
    }

    /// Returns the default floating color preview size for a given control
    /// size.
    public static func previewSize(for controlSize: ControlSize) -> CGFloat {
        switch controlSize {
        case .mini: return 32.0
        case .small: return 44.0
        case .regular: return 60.0
        case .large: return 80.0
        case .extraLarge: return 100.0
        @unknown default: return 60.0
        }
    }

    /// Returns the default spacing offset between the track and the floating
    /// color preview.
    public static func previewOffset(for controlSize: ControlSize) -> CGFloat {
        switch controlSize {
        case .mini: return 40.0
        case .small: return 52.0
        case .regular: return 70.0
        case .large: return 94.0
        case .extraLarge: return 118.0
        @unknown default: return 70.0
        }
    }

    /// The multiplier used to calculate the corner radius of the preview based
    /// on its size.
    public static let cornerRadiusMultiplier: CGFloat = 0.225
    /// The default scale ratio of the floating color preview when not actively
    /// dragged.
    public static let previewScale: CGFloat = 0.25
    /// The scale applied to the thumb during an active drag interaction.
    public static let thumbDragScale: CGFloat = 1.1
    /// The default percentage step for VoiceOver adjustments.
    public static let accessibilityStepPercentage: Double = 0.05

    /// The default blur radius applied to component shadows.
    public static let shadowRadius: CGFloat = 5.0
    /// The default horizontal offset applied to component shadows.
    public static let shadowX: CGFloat = 0.0
    /// The default vertical offset applied to component shadows.
    public static let shadowY: CGFloat = 0.0
    /// The default opacity applied to component shadows.
    public static let shadowOpacity: Double = 0.33

    /// The default line width applied to component strokes.
    public static let strokeLineWidth: CGFloat = 1.0
    /// The default duration for slider animation in seconds.
    public static let animationDuration: Double = 0.25
}
