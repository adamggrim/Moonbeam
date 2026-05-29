import SwiftUI

/// A view model that isolates layout mathematics, `DragGesture` processing and state
/// normalization away from the `ColorSlider` view.
@Observable
internal class ColorSliderViewModel {
    
    // MARK: - Injected Configuration
    
    var dimensions: ColorSliderDimensions = ColorSliderDimensions()
    var axis: Axis = .horizontal
    var previewPosition: PreviewPosition? = nil
    var previewSpacing: CGFloat? = nil
    var previewHidden: Bool = true
    
    /// Updates the view model with the latest environment properties from the view.
    ///
    /// The `ColorSlider` view must explicitly push these properties to
    /// `ColorSliderViewModel` via this method during `onAppear` and `onChange`
    /// events.
    func update(
        dimensions: ColorSliderDimensions,
        axis: Axis,
        previewPosition: PreviewPosition?,
        previewSpacing: CGFloat?,
        previewHidden: Bool
    ) {
        self.dimensions = dimensions
        self.axis = axis
        self.previewPosition = previewPosition
        self.previewSpacing = previewSpacing
        self.previewHidden = previewHidden
    }

    // MARK: - Constants
    
    private enum Metrics {
        static let defaultPreviewOffset: CGFloat = 70.0
        static let dragScaleMultiplier: CGFloat = 1.1
    }
    
    // MARK: - State
    
    /// Indicates whether a drag gesture is currently active.
    var isDragging: Bool = false
    
    ///  The current horizontal drag within the parent container view, equivalent
    ///  to the `value.translation.width` of the `DragGesture`.
    ///
    ///  Can extend beyond the end of the slider.
    var liveContainerDrag: CGFloat = .zero
    
    /// The persisted horizontal position of the start of the thumb on the slider.
    ///
    /// Cannot extend beyond the thumb's leading edge at the end of the slider.
    var persistedThumbPosition: CGFloat = .zero

    // MARK: - Layout Calculations
    
    var resolvedThumbThickness: CGFloat { dimensions.thumbThickness ?? dimensions.thickness }
    var resolvedThumbLength: CGFloat { dimensions.thumbLength ?? dimensions.thickness * 2 }
    
    var resolvedPreviewOffset: CGFloat {
        // Use absolute offset to avoid overwriting position modifiers with a negative offset.
        let fallbackOffset = abs(dimensions.previewOffset ?? Metrics.defaultPreviewOffset)
        
        let spacingOffset: CGFloat
        if let spacing = previewSpacing {
            spacingOffset = (dimensions.thickness / 2) + (dimensions.previewSize / 2) + abs(spacing)
        } else {
            spacingOffset = fallbackOffset
        }
        
        if axis == .horizontal {
            // Negative is top, positive is bottom.
            return previewPosition == .bottom ? spacingOffset : -spacingOffset
        } else {
            // Negative is leading, positive is trailing.
            return previewPosition == .leading ? -spacingOffset : spacingOffset
        }
    }
    
    var halfThumbThickness: CGFloat { resolvedThumbThickness / 2 }
        
    /// Inset to adjust the left and right bounds of the thumb if it is thinner than the track.
    var thumbInset: CGFloat { (dimensions.thickness - resolvedThumbThickness) / 2 }
    
    /// The current `liveContainerDrag` combined with the
    /// `persistedThumbPosition`. Equivalent to the horizontal position of the
    /// thumb's leading edge during a `DragGesture`.
    ///
    /// Like `liveContainerDrag`, can extend beyond the end of the slider.
    var liveContainerThumbDrag: CGFloat { persistedThumbPosition + liveContainerDrag }
    
    /// The clamped horizontal position of the current selected color on the
    /// slider.
    ///
    /// For most of the slider, corresponds with the horizontal position of the
    /// thumb's center. At the start or end of the slider, can extend beyond the
    /// thumb's center to the start or end of the thumb.
    var liveColorPosition: CGFloat {
        min(max(liveContainerThumbDrag + halfThumbThickness, 0), dimensions.length)
    }
    
    /// The clamped horizontal position of the start of the thumb during an active
    /// drag.
    ///
    /// Cannot extend beyond the thumb's leading edge at the end of the slider.
    var liveThumbPosition: CGFloat {
        min(max(liveContainerThumbDrag, 0 + thumbInset), dimensions.length - resolvedThumbThickness - thumbInset)
    }

    /// The main axis offset for the floating color preview.
    ///
    /// Except at the ends of the slider, the floating color preview is centered above the
    /// thumb's center.
    var previewMainAxisOffset: CGFloat {
        let halfPreviewSize = dimensions.previewSize / 2
        let leftBound = halfPreviewSize - halfThumbThickness
        let rightBound = dimensions.length - halfPreviewSize - halfThumbThickness
        let clampedValue = min(max(liveThumbPosition, leftBound), rightBound)

        /// The offset that centers the floating color preview above the thumb.
        let halfThumbOffset = thumbOffset + halfThumbThickness

        if previewHidden {
            let startEdgeLimit: CGFloat
            let endEdgeLimit: CGFloat
            let offsetAdjustment: CGFloat = halfThumbThickness

            startEdgeLimit = -halfPreviewSize + halfThumbOffset
            endEdgeLimit = -halfPreviewSize + halfThumbOffset

            if !isDragging && halfThumbOffset < halfPreviewSize {
                return startEdgeLimit
            } else if (!isDragging && halfThumbOffset > dimensions.length - halfPreviewSize) {
                return endEdgeLimit
            } else {
                return clampedValue - halfPreviewSize + offsetAdjustment
            }
        } else {
            if halfThumbOffset < halfPreviewSize {
                // Clamp the color preview to the starting edge of the slider.
                return 0
            } else if halfThumbOffset > dimensions.length - halfPreviewSize {
                return dimensions.length - dimensions.previewSize
            } else {
                // Clamp the color preview to the ending edge of the slider.
                return clampedValue - halfPreviewSize + halfThumbThickness
            }
        }
    }

    /// The offset of the thumb's leading edge.
    var thumbOffset: CGFloat {
        min(max(liveThumbPosition, thumbInset), dimensions.length - resolvedThumbThickness - thumbInset)
    }
    
    // MARK: - Drag Event Handlers
    
    /// Adjusts the slider by a specific percentage step (for VoiceOver).
    func accessibilityAdjust(direction: AccessibilityAdjustmentDirection, progress: inout Double, step: Double) {
        let stepDelta = dimensions.length * (direction == .increment ? CGFloat(step) : -CGFloat(step))
        let newDrag = min(max(liveContainerThumbDrag + stepDelta, 0), dimensions.length)
        persistedThumbPosition = min(max(newDrag, thumbInset), dimensions.length - resolvedThumbThickness - thumbInset)
        liveContainerDrag = .zero
        progress = Double(dimensions.length > 0 ? liveColorPosition / dimensions.length : 0.0)
    }
}
