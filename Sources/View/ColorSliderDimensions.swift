import Foundation

/**
 Encapsulates various layout dimensions for the color slider and its components.

 The initializer provides default logic for `thumbWidth`, `thumbHeight`, and
 `previewCornerRadius`.
 */
struct ColorSliderDimensions {
    let sliderWidth: CGFloat
    let sliderHeight: CGFloat
    let thumbWidth: CGFloat
    let thumbHeight: CGFloat?
    let previewWidth: CGFloat
    let previewCornerRadius: CGFloat
    let previewOffset: CGFloat
    let shadowRadius: CGFloat
    let scaleRatio: CGFloat = 0.25
    
    init(
        sliderWidth: CGFloat,
        sliderHeight: CGFloat,
        thumbWidth: CGFloat? = nil,
        thumbHeight: CGFloat? = nil,
        previewWidth: CGFloat,
        previewOffset: CGFloat,
        shadowRadius: CGFloat
    ) {
        self.sliderWidth = sliderWidth
        self.sliderHeight = sliderHeight
        self.thumbWidth = thumbWidth ?? sliderHeight
        self.thumbHeight = thumbHeight ?? sliderHeight * 2 // Ignored when thumbStyle is .circle
        self.previewWidth = previewWidth
        self.previewOffset = previewOffset
        self.shadowRadius = shadowRadius
        self.previewCornerRadius = previewWidth * 0.225
    }
}
