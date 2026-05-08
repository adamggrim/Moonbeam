import Foundation

public enum ThumbStyle {
    case capsule, circle
}

/// Encapsulates various layout dimensions for the color slider and its components.
struct ColorSliderDimensions {
    let thickness: CGFloat
    let length: CGFloat
    let thumbThickness: CGFloat
    let thumbLength: CGFloat
    let previewSize: CGFloat
    let previewCornerRadius: CGFloat
    let previewOffset: CGFloat
    let shadowRadius: CGFloat
    let scaleRatio: CGFloat = 0.25

    init(
        thickness: CGFloat,
        length: CGFloat,
        thumbThickness: CGFloat? = nil,
        thumbLength: CGFloat? = nil,
        previewSize: CGFloat,
        previewOffset: CGFloat,
        shadowRadius: CGFloat
    ) {
        self.thickness = thickness
        self.length = length
        self.thumbThickness = thumbThickness ?? thickness
        self.thumbLength = thumbLength ?? thickness * 2
        self.previewSize = previewSize
        self.previewOffset = previewOffset
        self.shadowRadius = shadowRadius
        self.previewCornerRadius = previewSize * 0.225
    }
}
