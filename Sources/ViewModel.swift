import Foundation
import SwiftUI
import Observation

@Observable
class ColorSliderViewModel {
    var isDragging: Bool = false
    
    /**
     Drag variable to determine the color of the color preview.
     
     This is different from `persistedDrag` whenever the drag extends beyond
     the width of the thumb at the end of the slider.
     */
    private var colorDrag: CGFloat = .zero
    private var persistedDrag: CGFloat = .zero
    private var sliderDrag: CGFloat = .zero
    private var containerDrag: CGFloat = .zero
    private var currentDrag: CGFloat = .zero
    
    let thumbStyle: ThumbStyle
    let sliderColors: [Color]
    let previewHidden: Bool
    let dimensions: ColorSliderDimensions
    
    private let thumbInset: CGFloat
    
    init<DataSource: ColorSliderDataSource>(
        dataSource: DataSource,
        thumbStyle: ThumbStyle,
        previewHidden: Bool,
        dimensions: ColorSliderDimensions
    ) {
        self.sliderColors = dataSource.sliderColors
        self.thumbStyle = thumbStyle
        if thumbStyle == .capsule {
            self.thumbInset = 0.0
        } else {
            self.thumbInset = (dimensions.sliderHeight - dimensions.thumbWidth) / 2
        }
        self.previewHidden = previewHidden
        self.dimensions = dimensions
        
        let hue: CGFloat = 0
        let dragValue = calculateDrag(
            hue: hue,
            sliderWidth: dimensions.sliderWidth
        )
        
        self.persistedDrag = dragValue
        self.sliderDrag = dragValue
        self.containerDrag = dragValue
        self.currentDrag = dragValue
    }
    
    var calculatedColor: Color {
        let calculatedIndex = Int(
            CGFloat(sliderColors.count) * (colorDrag / dimensions.sliderWidth)
        )
        let clampedIndex = max(0, min(sliderColors.count - 1, calculatedIndex))
        return sliderColors[clampedIndex]
    }

    var previewHorizontalOffset: CGFloat {
        let halfPreviewWidth = dimensions.previewWidth / 2
        let halfThumbWidth = dimensions.thumbWidth / 2
        let quarterThumbWidth = halfThumbWidth / 2
        let leftBound = halfPreviewWidth - halfThumbWidth
        let rightBound = dimensions.sliderWidth - halfPreviewWidth - halfThumbWidth
        // Clamp the persistedDrag value within the left and right bounds.
        let clampedValue = min(max(persistedDrag, leftBound), rightBound)
        /// Offset to center the floating color preview above the thumb.
        let halfThumbOffset = thumbOffset + halfThumbWidth
        /**
         Offset to offset the floating color preview at one quarter the length
         of the thumb.
         */
        let quarterThumbOffset = thumbOffset + quarterThumbWidth
        
        if previewHidden && thumbStyle == .capsule {
            // Left edge of the slider
            if !isDragging && halfThumbOffset < halfPreviewWidth {
                return -halfPreviewWidth + halfThumbOffset
            // Right edge of the slider
            } else if !isDragging && halfThumbOffset >
                        dimensions.sliderWidth - halfPreviewWidth {
                return dimensions.sliderWidth - halfPreviewWidth - halfThumbWidth
            } else {
                return clampedValue - halfPreviewWidth + halfThumbWidth
            }
        }
        
        else if previewHidden && thumbStyle == .circle {
            // Left edge of the slider
            if !isDragging && halfThumbOffset < halfPreviewWidth {
                return -halfPreviewWidth + quarterThumbOffset
            // Right edge of the slider
            } else if !isDragging && halfThumbOffset >
                        dimensions.sliderWidth - halfPreviewWidth {
                return dimensions.sliderWidth - halfPreviewWidth - quarterThumbWidth
            } else {
                return clampedValue - halfPreviewWidth + halfThumbWidth
            }
        }
        
        else {
            if halfThumbOffset < halfPreviewWidth {
                // Clamp the color preview to the left edge of the slider.
                return 0
            } else if halfThumbOffset > dimensions.sliderWidth - halfPreviewWidth {
                // Clamp the color preview to the right edge of the slider.
                return dimensions.sliderWidth - dimensions.previewWidth
            } else {
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
    
    private func calculateDrag(hue: CGFloat, sliderWidth: CGFloat) -> CGFloat {
        let calculatedDrag = hue * sliderWidth
        return calculatedDrag
    }
    
    func onDragChanged(_ value: DragGesture.Value) {
        containerDrag = value.translation.width
        currentDrag = sliderDrag + containerDrag
        /*
         Clamp to prevent the drag gesture from displacing the thumb on rebound
         from the left and right edges of the slider.
       */
        colorDrag = min(max(currentDrag, 0), dimensions.sliderWidth)
        persistedDrag = min(
            max(currentDrag, 0 + thumbInset),
            dimensions.sliderWidth - dimensions.thumbWidth - thumbInset
        )
    }
    
    func onDragEnded() {
        sliderDrag = persistedDrag
        containerDrag = .zero
    }
}
