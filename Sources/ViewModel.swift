import Foundation
import SwiftUI
import Observation

@Observable
class ColorSliderViewModel {
    /// Indicates whether a drag gesture is currently active.
    var isDragging: Bool = false
    
    /**
     The current horizontal drag within the parent container view, equivalent
     to the `value.translation.width` of the `DragGesture`.
     
     Can extend beyond the end of the slider.
     */
    private var liveContainerDrag: CGFloat = .zero
    
    /**
     The persisted horizontal position of the start of the thumb on the slider.
     
     Cannot extend beyond the thumb's leading edge at the end of the slider.
     */
    private var persistedThumbPosition: CGFloat = .zero
    
    /**
     The current `liveContainerDrag` combined with the
     `persistedThumbPosition`. Equivalent to the horizontal position of the
     thumb's leading edge during a `DragGesture`.
     
     This is an intermediate value calculated during an active drag.
     
     Like `liveContainerDrag`, can extend beyond the end of the slider.
     */
    private var liveContainerThumbDrag: CGFloat = .zero
    
    /**
     The clamped horizontal position of the current selected color on the
     slider.
     
     For most of the slider, corresponds with the horizontal position of the
     thumb's center. At the start or end of the slider, can extend beyond the
     thumb's center to the start or end of the thumb.
     */
    private var liveColorPosition: CGFloat = .zero
    
    /**
     The clamped horizontal position of the start of the thumb during an active
     drag.
     
     Cannot extend beyond the thumb's leading edge at the end of the slider.
     */
    private var liveThumbPosition: CGFloat = .zero
    
    /**
     The position of the selected color in the slider, normalized to a range
     from 0.0 to 1.0.
     */
    private var positionRatio: CGFloat
    
    private let previewHidden: Bool
    
    /**
     Stores various layout dimensions for the color slider, as defined by
     `ColorSliderDimensions`.
     */
    private let dimensions: ColorSliderDimensions
    private let halfThumbWidth: CGFloat
    
    /**
     Inset to adjust the left and right bounds of the thumb.
     
     Used when `thumbStyle` is `.circle`.
     */
    private let thumbInset: CGFloat
    
    /// Whether the thumb is a `.capsule` or `.circle`.
    let thumbStyle: ThumbStyle
    /// An array of the colors in the slider.
    let sliderColors: [Color]
    
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
        
        self.halfThumbWidth = dimensions.thumbWidth / 2
        
        let position = calculatePosition(
            positionRatio: positionRatio,
            sliderWidth: dimensions.sliderWidth
        )
        
        self.liveContainerDrag = position
        self.persistedThumbPosition = position
        self.liveContainerThumbDrag = position
        self.liveThumbPosition = position
    }
    
    /**
     The color calculated from the current `liveColorPosition` on the slider.
     
     Determines which color from `sliderColors` corresponds with the thumb's
     current position.
     */
    var calculatedColor: Color {
        let calculatedIndex = Int(
            CGFloat(sliderColors.count) * (liveColorPosition / dimensions.sliderWidth)
        )
        let clampedIndex = max(0, min(sliderColors.count - 1, calculatedIndex))
        return sliderColors[clampedIndex]
    }
    
    /**
     The horizontal offset for the color preview.
     
     Except at the ends of the slider, the color preview is centered above the
     thumb's center.
     */
    var previewHorizontalOffset: CGFloat {
        let halfPreviewWidth = dimensions.previewWidth / 2
        let quarterThumbWidth = halfThumbWidth / 2
        let leftBound = halfPreviewWidth - halfThumbWidth
        let rightBound = dimensions.sliderWidth - halfPreviewWidth - halfThumbWidth
        // Clamp the liveThumbPosition value within the left and right bounds.
        let clampedValue = min(max(liveThumbPosition, leftBound), rightBound)
        
        /**
         The offset that centers the floating color preview above the thumb.
         */
        let halfThumbOffset = thumbOffset + halfThumbWidth
        
        /**
         The offset that positions the floating color preview at one quarter
         the length of the thumb.
         
         Used when `thumbStyle` is `.circle`.
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
    
    /// The offset of the thumb's leading edge.
    var thumbOffset: CGFloat {
        let leftBound = thumbInset
        let rightBound = dimensions.sliderWidth - dimensions.thumbWidth - thumbInset
        // Clamp the liveThumbPosition value within the left and right bounds.
        return min(max(liveThumbPosition, leftBound), rightBound)
    }
    
    /**
     Calculates the horizontal position of the selected color in the slider.
     
     - Parameters:
       - positionRatio: A `CGFloat` representing the normalized position on the
        slider: 0.0 for the left edge, 1.0 for the right.
       - sliderWidth: The width of the slider in points.
     - Returns:
        A `CGFloat` representing the calculated horizontal offset in points
        from the slider's start.
     */
    private func calculatePosition(
        positionRatio: CGFloat,
        sliderWidth: CGFloat
    ) -> CGFloat {
        let calculatedPosition = positionRatio * sliderWidth
        return calculatedPosition
    }
    
    /**
     Updates the ViewModel's state when the position of the `DragGesture`
     changes.
     
     Called continuously while the user is dragging the thumb. Calculates
     `liveContainerThumbDrag`, `liveColorPosition` and`liveThumbPosition`.
     
     - Parameter value: The current value of the `DragGesture`.
     */
    func onDragChanged(_ value: DragGesture.Value) {
        liveContainerDrag = value.translation.width
        liveContainerThumbDrag = persistedThumbPosition + liveContainerDrag
        /*
         Clamp to prevent the drag gesture from displacing the thumb on rebound
         from the left and right edges of the slider.
       */
        liveColorPosition = min(
            max(liveContainerThumbDrag + halfThumbWidth, 0), dimensions.sliderWidth
        )
        liveThumbPosition = min(
            max(liveContainerThumbDrag, 0 + thumbInset),
            dimensions.sliderWidth - dimensions.thumbWidth - thumbInset
        )
    }
    
    /**
     Finalizes the ViewModel's state when the drag gesture ends, updating
     `persistedThumbPosition` with the thumb's last valid clamped position
     and resetting `liveContainerDrag` to zero.
     */
    func onDragEnded() {
        persistedThumbPosition = liveThumbPosition
        liveContainerDrag = .zero
    }
}
