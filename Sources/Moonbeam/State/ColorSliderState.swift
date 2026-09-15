import SwiftUI

/// A structure that isolates layout mathematics and state normalization away
/// from the `ColorSlider` view.
internal struct ColorSliderLayout {
    let state: ColorSliderState
    let value: Double
    let dimensions: ColorSliderDimensions
    let axis: Axis
    let controlSize: ControlSize
    let previewPosition: PreviewPosition?
    let previewSpacing: CGFloat?

    var resolvedLength: CGFloat { dimensions.length ?? 0 }
    var resolvedTrackThickness: CGFloat { dimensions.resolvedTrackThickness(for: controlSize) }
    var resolvedPreviewSize: CGFloat { dimensions.previewSize ?? ColorSliderDefaults.previewSize(for: controlSize) }
    var resolvedThumbThickness: CGFloat { dimensions.thumbThickness ?? resolvedTrackThickness }
    var resolvedThumbLength: CGFloat { dimensions.resolvedThumbLength(for: controlSize) }
    var resolvedPreviewOffset: CGFloat {
        let fallbackOffset = abs(dimensions.previewOffset ?? ColorSliderDefaults.previewOffset(for: controlSize))

        let spacingOffset: CGFloat
        if let spacing = previewSpacing {
            spacingOffset = (resolvedTrackThickness / 2) + (resolvedPreviewSize / 2) + abs(spacing)
        } else {
            spacingOffset = fallbackOffset
        }

        return previewPosition == .bottomTrailing ? spacingOffset : -spacingOffset
    }
    var halfThumbThickness: CGFloat { resolvedThumbThickness / 2 }

    /// Inset to adjust the left and right bounds of the thumb if it is thinner
    /// than the track.
    var thumbInset: CGFloat { (resolvedTrackThickness - resolvedThumbThickness) / 2 }

    var liveContainerThumbDrag: CGFloat {
        let baseValue = state.isDragging ? (state.dragStartValue ?? value) : value
        let trackPosition = CGFloat(baseValue) * resolvedLength
        let baseThumbPosition = min(
            max(trackPosition - halfThumbThickness, thumbInset),
            resolvedLength - resolvedThumbThickness - thumbInset
        )
        return state.isDragging ? baseThumbPosition + state.liveContainerDrag : baseThumbPosition
    }

    /// The clamped main-axis position of the current selected color on the
    /// slider.
    ///
    /// For most of the slider, corresponds with the horizontal position of the
    /// thumb's center. At the start or end of the slider, can extend beyond the
    /// thumb's center to the start or end of the thumb.
    var liveColorPosition: CGFloat {
        min(max(liveContainerThumbDrag + halfThumbThickness, 0), resolvedLength)
    }

    /// The clamped main-axis position of the start of the thumb during an
    /// active drag.
    ///
    /// Cannot extend beyond the thumb's leading edge at the end of the slider.
    var liveThumbPosition: CGFloat {
        min(max(liveContainerThumbDrag, 0 + thumbInset), resolvedLength - resolvedThumbThickness - thumbInset)
    }

    /// The main axis offset for the floating color preview.
    ///
    /// Except at the ends of the slider, the floating color preview is centered
    /// above the thumb's center.
    var previewMainAxisOffset: CGFloat {
        let halfPreviewSize = resolvedPreviewSize / 2
        let leftBound = halfPreviewSize - halfThumbThickness
        let rightBound = resolvedLength - halfPreviewSize - halfThumbThickness
        let clampedValue = min(max(liveThumbPosition, leftBound), rightBound)

        return clampedValue - halfPreviewSize + halfThumbThickness
    }

    /// Calculates the exact relative position of the thumb inside the preview.
    ///
    /// The preview always animates out of and back into the slider thumb.
    var previewScaleAnchor: UnitPoint {
        let halfThumbOffset = thumbOffset + halfThumbThickness
        let relativeMainAxis = (halfThumbOffset - previewMainAxisOffset) / resolvedPreviewSize

        let crossAxisLimit = resolvedPreviewOffset > 0 ? 0.0 : 1.0

        if axis == .horizontal {
            return UnitPoint(x: relativeMainAxis, y: crossAxisLimit)
        } else {
            return UnitPoint(x: crossAxisLimit, y: 1.0 - relativeMainAxis)
        }
    }

    /// The offset of the thumb's leading edge.
    var thumbOffset: CGFloat {
        min(max(liveThumbPosition, thumbInset), resolvedLength - resolvedThumbThickness - thumbInset)
    }
}

/// A state structure that isolates the drag gesture properties.
internal struct ColorSliderState {
    var isDragging: Bool = false
    var dragStartValue: Double? = nil
    var liveContainerDrag: CGFloat = .zero

    mutating func updateDrag(translation: CGFloat, currentValue: Double) {
        if !isDragging {
            isDragging = true
            dragStartValue = currentValue
        }
        liveContainerDrag = translation
    }

    mutating func finalizeDrag() {
        isDragging = false
        dragStartValue = nil
        liveContainerDrag = .zero
    }
}
