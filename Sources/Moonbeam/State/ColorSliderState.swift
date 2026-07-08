import SwiftUI

/// A state structure that isolates layout mathematics, `DragGesture` processing and state
/// normalization away from the `ColorSlider` view.
internal struct ColorSliderState {

    // MARK: - Injected configuration

    var dimensions: ColorSliderDimensions = ColorSliderDimensions()
    var axis: Axis = .horizontal
    var previewPosition: PreviewPosition? = nil
    var previewSpacing: CGFloat? = nil
    var previewHidden: Bool = true

    /// Updates the state structure with the latest environment properties from the view.
    ///
    /// The `ColorSlider` view must explicitly push these properties to
    /// `ColorSliderState` via this method during `onAppear` and `onChange`
    /// events.
    mutating func update(
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

    ///  The current horizontal drag within the parent container view,
    ///  equivalent to the `value.translation.width` of the `DragGesture`.
    ///
    ///  Can extend beyond the end of the slider.
    var liveContainerDrag: CGFloat = .zero

    /// The persisted horizontal position of the start of the thumb on the
    /// slider.
    ///
    /// Cannot extend beyond the thumb's leading edge at the end of the slider.
    var persistedThumbPosition: CGFloat = .zero

    // MARK: - Layout calculations

    var resolvedThumbThickness: CGFloat { dimensions.thumbThickness ?? dimensions.thickness }
    var resolvedThumbLength: CGFloat { dimensions.thumbLength ?? dimensions.thickness * 2 }

    var resolvedPreviewOffset: CGFloat {
        let fallbackOffset = abs(dimensions.previewOffset ?? ColorSliderDefaults.previewOffset)

        let spacingOffset: CGFloat
        if let spacing = previewSpacing {
            spacingOffset = (dimensions.thickness / 2) + (dimensions.previewSize / 2) + abs(spacing)
        } else {
            spacingOffset = fallbackOffset
        }

        return previewPosition == .bottomTrailing ? spacingOffset : -spacingOffset
    }

    var halfThumbThickness: CGFloat { resolvedThumbThickness / 2 }

    /// Inset to adjust the left and right bounds of the thumb if it is thinner
    /// than the track.
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

    /// The clamped horizontal position of the start of the thumb during an
    /// active drag.
    ///
    /// Cannot extend beyond the thumb's leading edge at the end of the slider.
    var liveThumbPosition: CGFloat {
        min(max(liveContainerThumbDrag, 0 + thumbInset), dimensions.length - resolvedThumbThickness - thumbInset)
    }

    /// The main axis offset for the floating color preview.
    ///
    /// Except at the ends of the slider, the floating color preview is centered
    /// above the thumb's center.
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
                return 0
            } else if halfThumbOffset > dimensions.length - halfPreviewSize {
                return dimensions.length - dimensions.previewSize
            } else {
                return clampedValue - halfPreviewSize + halfThumbThickness
            }
        }
    }

    /// The offset of the thumb's leading edge.
    var thumbOffset: CGFloat {
        min(max(liveThumbPosition, thumbInset), dimensions.length - resolvedThumbThickness - thumbInset)
    }

    // MARK: - Drag event handlers

    mutating func updateDrag(translation: CGFloat) {
        isDragging = true
        liveContainerDrag = translation
    }

    mutating func finalizeDrag() {
        isDragging = false
        persistedThumbPosition = liveThumbPosition
        liveContainerDrag = .zero
    }

    /// Adjusts the slider by a specific percentage step (for VoiceOver).
    mutating func accessibilityAdjust(
        direction: AccessibilityAdjustmentDirection,
        progress: inout Double,
        step: Double
    ) {
        let delta = direction == .increment ? step : -step
        let newProgress = min(max(progress + delta, 0.0), 1.0)
        progress = newProgress

        let newTrackPosition = CGFloat(newProgress) * dimensions.length
        persistedThumbPosition = min(
            max(newTrackPosition - halfThumbThickness, thumbInset),
            dimensions.length - resolvedThumbThickness - thumbInset
        )
        liveContainerDrag = .zero
    }
}
