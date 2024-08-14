import Foundation

import SwiftUI
import Observation

@Observable
class ColorSliderViewModel {
    
    var isDragging: Bool = false
    // Drag variable to get the color of the color preview (different from persistedDrag whenever the drag extends to the width of the thumb at the end of the slider)
    private var colorDrag: CGFloat = .zero
    
    private var persistedDrag: CGFloat = .zero
    private var sliderDrag: CGFloat = .zero
    private var containerDrag: CGFloat = .zero
    private var currentDrag: CGFloat = .zero
    
    var startingColor: Color
    let thumbColor: Color
    let thumbStyle: ThumbStyle
    let thumbInset: CGFloat
    let previewHidden: Bool
    let dimensions: ColorSliderDimensions

    init(startingColor: Color, thumbColor: Color, thumbStyle: ThumbStyle, previewHidden: Bool, dimensions: ColorSliderDimensions) {
        self.startingColor = startingColor
        self.thumbColor = thumbColor
        self.thumbStyle = thumbStyle
        self.thumbInset = (thumbStyle == .capsule) ? 0.0 : (dimensions.sliderHeight - dimensions.thumbWidth) / 2
        self.previewHidden = previewHidden
        self.dimensions = dimensions
        
        let hue: CGFloat = 0
        let dragValue = calculateDrag(hue: hue, sliderWidth: dimensions.sliderWidth)
        
        self.persistedDrag = dragValue
        self.sliderDrag = dragValue
        self.containerDrag = dragValue
        self.currentDrag = dragValue
    }
    
    var calculatedColor: Color {
        let colorIndex = min(sliderColors.count - 1, Int(CGFloat(sliderColors.count) * (colorDrag / dimensions.sliderWidth)))
        return sliderColors[colorIndex]
    }
    
    var previewHorizontalOffset: CGFloat {
        let halfPreviewWidth = dimensions.previewWidth / 2
        let halfThumbWidth = dimensions.thumbWidth / 2
        
        let leftBound = halfPreviewWidth - halfThumbWidth
        let rightBound = dimensions.sliderWidth - halfPreviewWidth - halfThumbWidth
        
        // Clamp the persistedDrag value within the left and right bounds.
        let clampedValue = min(max(persistedDrag, leftBound), rightBound)
        
        // Offset to center the floating color preview above the thumb slider
        let centeredOffset = thumbOffset + halfThumbWidth
        
        if previewHidden {
            if !isDragging && centeredOffset < halfPreviewWidth {
                return -halfPreviewWidth + centeredOffset
            } else if !isDragging && centeredOffset > dimensions.sliderWidth - halfPreviewWidth {
                return dimensions.sliderWidth - halfPreviewWidth - halfThumbWidth
            } else {
                return clampedValue - halfPreviewWidth + halfThumbWidth
            }
        }
        
        else {
            if centeredOffset < halfPreviewWidth {
                // Clamp the color preview to the left edge of the slider.
                return 0
            } else if centeredOffset > dimensions.sliderWidth - halfPreviewWidth {
                // Clamp the color preview to the right edge of the slider.
                return dimensions.sliderWidth - dimensions.previewWidth
            } else {
                // Centered and and clamped to the left and right bounds of the slider.
                return clampedValue - halfPreviewWidth + halfThumbWidth
            }
        }
    }
        
    var thumbOffset: CGFloat {
        let leftBound = thumbInset
        let rightBound = dimensions.sliderWidth - dimensions.thumbWidth - thumbInset
        
        // Clamp the persistedDrag value within the left and right bounds.
        return min(max(persistedDrag, leftBound), rightBound)
    }
    
    func calculateDrag(hue: CGFloat, sliderWidth: CGFloat) -> CGFloat {
        let calculatedDrag = hue * sliderWidth
        
        return calculatedDrag
    }
    
    func onDragChanged(_ value: DragGesture.Value) {
        containerDrag = value.translation.width
        currentDrag = sliderDrag + containerDrag
        
        // Clamp to prevent the drag gesture from displacing the thumb on rebound from the left and right edges of the slider.
        colorDrag = min(max(currentDrag, 0), dimensions.sliderWidth)
        persistedDrag = min(max(currentDrag, 0 + thumbInset), dimensions.sliderWidth - dimensions.thumbWidth - thumbInset)
    }
    
    func onDragEnded() {
        sliderDrag = persistedDrag
        containerDrag = .zero
    }
}
