import SwiftUI

/// Global default metrics for  color sliders.
public enum ColorSliderDefaults {
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

    public static let cornerRadiusMultiplier: CGFloat = 0.225
    public static let scaleRatio: CGFloat = 0.25
    public static let dragScaleMultiplier: CGFloat = 1.1
    public static let accessibilityStepPercentage: Double = 0.05

    public static let shadowRadius: CGFloat = 5.0
    public static let shadowX: CGFloat = 0.0
    public static let shadowY: CGFloat = 0.0
    public static let shadowOpacity: Double = 0.33

    public static let strokeLineWidth: CGFloat = 1.0
    public static let animationDuration: Double = 0.25
}
