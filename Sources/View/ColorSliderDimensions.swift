import Foundation

/// Encapsulates various layout dimensions for the color slider and its components.
struct ColorSliderDimensions {
    let length: CGFloat
    let thickness: CGFloat
    let thumbLength: CGFloat
    let thumbThickness: CGFloat
    let previewSize: CGFloat
    let previewCornerRadius: CGFloat
    let previewOffset: CGFloat
    let shadowRadius: CGFloat
    let scaleRatio: CGFloat = 0.25

    init(
        length: CGFloat,
        thickness: CGFloat,
        thumbLength: CGFloat? = nil,
        thumbThickness: CGFloat? = nil,
        previewSize: CGFloat,
        previewOffset: CGFloat,
        shadowRadius: CGFloat
    ) {
        self.length = length
        self.thickness = thickness
        self.thumbLength = thumbLength ?? thickness * 2 // Default capsule length
        self.thumbThickness = thumbThickness ?? thickness
        self.previewSize = previewSize
        self.previewOffset = previewOffset
        self.shadowRadius = shadowRadius
        self.previewCornerRadius = previewSize * 0.225
    }
}
