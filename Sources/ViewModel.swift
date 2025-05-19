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
    
    init(
        positionRatio: CGFloat,
        thumbStyle: ThumbStyle,
        previewHidden: Bool,
        dimensions: ColorSliderDimensions,
        dataSource: ColorSliderDataSource
    ) {
        self.positionRatio = positionRatio
        self.sliderColors = dataSource.sliderColors
        self.thumbStyle = thumbStyle
        if thumbStyle == .capsule {
            self.thumbInset = 0.0
        } else {
            self.thumbInset = (dimensions.sliderHeight - dimensions.thumbWidth) / 2
        }
        self.previewHidden = previewHidden
        self.dimensions = dimensions
        
        let position = calculatePosition(
            positionRatio: positionRatio,
            sliderWidth: dimensions.sliderWidth
        )
        
        self.persistedDrag = position
        self.sliderDrag = position
        self.containerDrag = position
        self.currentDrag = position
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
        
        let leftEdgeLimit: CGFloat
        let rightEdgeLimit: CGFloat
        let offsetAdjustment: CGFloat
        
        if previewHidden {
            switch thumbStyle {
            case .capsule:
                leftEdgeLimit = -halfPreviewWidth + halfThumbOffset
                rightEdgeLimit = (
                    dimensions.sliderWidth - halfPreviewWidth - halfThumbWidth
                )
                offsetAdjustment = halfThumbWidth
            case .circle:
                leftEdgeLimit = -halfPreviewWidth + quarterThumbOffset
                rightEdgeLimit = (
                    dimensions.sliderWidth - halfPreviewWidth - quarterThumbWidth
                )
                offsetAdjustment = halfThumbWidth
            }
            
            if !isDragging && halfThumbOffset < halfPreviewWidth {
                return leftEdgeLimit
            } else if (
                !isDragging && halfThumbOffset > dimensions.sliderWidth - halfPreviewWidth
            ) {
                return rightEdgeLimit
            } else {
                return clampedValue - halfPreviewWidth + offsetAdjustment
            }
        } else {
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
    
    /**
     Calculates the horizontal position of the selected color in the slider.
     */
    private func calculatePosition(
        positionRatio: CGFloat,
        sliderWidth: CGFloat
    ) -> CGFloat {
        let calculatedPosition = positionRatio * sliderWidth
        return calculatedPosition
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
