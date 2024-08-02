import Foundation

import SwiftUI
import Observation

@Observable
class ColorSliderViewModel {
    
    // Drag variable to get the color of the color preview (different from persistedDrag whenever the drag extends to the width of the thumb at the end of the slider)
    var colorDrag: CGFloat = .zero
    var isDragging: Bool = false
    
    var persistedDrag: CGFloat = .zero
    var sliderDrag: CGFloat = .zero
    var containerDrag: CGFloat = .zero
    var newDrag: CGFloat = .zero
    
    var color: Color
    let thumbColor: Color
    let thumbStyle: ThumbStyle
    let previewHidden: Bool
    let dimensions: ColorSliderDimensions
    
    init(color: Color, thumbColor: Color, thumbStyle: ThumbStyle, previewHidden: Bool, dimensions: ColorSliderDimensions) {
        self.color = color
        self.thumbColor = thumbColor
        self.thumbStyle = thumbStyle
        self.previewHidden = previewHidden
        self.dimensions = dimensions
        
        let uiColor = UIColor(color)
        var hue: CGFloat = 0
        
        uiColor.getHue(&hue, saturation: nil, brightness: nil, alpha: nil)
        let dragValue = calculateDrag(hue: hue, sliderWidth: dimensions.sliderWidth)
        
        self.persistedDrag = dragValue
        self.sliderDrag = dragValue
        self.containerDrag = dragValue
        self.newDrag = dragValue
    }
    
    var calculatedColor: Color {
        let colorIndex = min(sliderColors.count - 1, Int(CGFloat(sliderColors.count) * (colorDrag / dimensions.sliderWidth)))
        return sliderColors[colorIndex]
    }
    
    var colorPreviewHorizontalOffset: CGFloat {
        let halfColorPreviewWidth = dimensions.colorPreviewWidth / 2
        let halfThumbWidth = dimensions.thumbWidth / 2
        
        let leftBound = halfColorPreviewWidth - halfThumbWidth
        let rightBound = dimensions.sliderWidth - halfColorPreviewWidth - halfThumbWidth
        
        // Clamp the persistedDrag value within the left and right bounds.
        let clampedValue = min(max(persistedDrag, leftBound), rightBound)
        
        // Offset to center the floating color preview above the thumb slider
        let centeredOffset = thumbOffset + halfThumbWidth
        
        if previewHidden {
            if !isDragging && centeredOffset < halfColorPreviewWidth {
                return -halfColorPreviewWidth + centeredOffset
            } else if !isDragging && centeredOffset > dimensions.sliderWidth - halfColorPreviewWidth {
                return dimensions.sliderWidth - halfColorPreviewWidth - halfThumbWidth
            } else {
                return clampedValue - halfColorPreviewWidth + halfThumbWidth
            }
        }
        
        else {
            if centeredOffset < halfColorPreviewWidth {
                // Clamp the color preview to the left edge of the slider.
                return 0
            } else if centeredOffset > dimensions.sliderWidth - halfColorPreviewWidth {
                // Clamp the color preview to the right edge of the slider.
                return dimensions.sliderWidth - dimensions.colorPreviewWidth
            } else {
                // Centered and and clamped to the left and right bounds of the slider.
                return clampedValue - halfColorPreviewWidth + halfThumbWidth
            }
        }
    }
    
    var colorPreviewVerticalOffset: CGFloat {
        return -dimensions.sliderHeight * 3.3333
    }
    
    var thumbOffset: CGFloat {
        let leftBound = 0.0
        let rightBound = dimensions.sliderWidth - dimensions.thumbWidth
        
        // Clamp the persistedDrag value within the left and right bounds.
        return min(max(persistedDrag, leftBound), rightBound)
    }
    
    func calculateDrag(hue: CGFloat, sliderWidth: CGFloat) -> CGFloat {
        
        let calculatedDrag = hue * sliderWidth
        
        return calculatedDrag
    }
    
    func onDragChanged(_ value: DragGesture.Value) {
        
        containerDrag = value.translation.width
        newDrag = sliderDrag + containerDrag
        
        // Clamp to prevent the drag gesture from displacing the thumb on rebound from the left and right edges of the slider.
        colorDrag = min(max(newDrag, 0), dimensions.sliderWidth)
        persistedDrag = min(max(newDrag, 0), dimensions.sliderWidth - dimensions.thumbWidth)
    }
    
    func onDragEnded() {
        sliderDrag = persistedDrag
        containerDrag = .zero
    }
}
