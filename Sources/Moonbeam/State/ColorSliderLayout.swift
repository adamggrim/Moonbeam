import SwiftUI

/// A structure that isolates layout mathematics and state normalization away
/// from the `ColorSlider` view.
internal struct ColorSliderLayout {
    var state: ColorSliderState
    let value: Double
    let axis: Axis
    let controlSize: ControlSize
    let dimensions: ColorSliderDimensions
    let previewPosition: PreviewPosition?
    let previewSpacing: CGFloat?

    var layoutDirection: LayoutDirection = .leftToRight
    var thumbStyle: ColorSliderThumbStyle = .standard
    var colorCount: Int = 0

    var resolvedLength: CGFloat { dimensions.length ?? 0 }
    var resolvedTrackThickness: CGFloat { dimensions.resolvedTrackThickness(for: controlSize) }
    var resolvedPreviewSize: CGFloat { dimensions.previewSize ?? ColorSliderDefaults.previewSize(for: controlSize) }

    /// The thumb thickness along the slider's main axis.
    ///
    /// For `.colorOutline`, matches one discrete color block plus both sides'
    /// outline padding and stroke width.
    var resolvedThumbThickness: CGFloat {
        switch thumbStyle {
        case .colorOutline(let lineWidth, let padding):
            let blockWidth = colorCount > 0
                ? (resolvedLength / CGFloat(colorCount))
                : (dimensions.thumbThickness ?? resolvedTrackThickness)
            return blockWidth + (padding * 2) + lineWidth
        case .standard:
            return dimensions.thumbThickness ?? resolvedTrackThickness
        }
    }

    /// The thumb length along the slider's cross axis.
    ///
    /// For `.colorOutline`, matches the track thickness plus both sides'
    /// outline padding and stroke width.
    var resolvedThumbLength: CGFloat {
        dimensions.resolvedThumbLength(for: controlSize, thumbStyle: thumbStyle)
    }

    /// The signed cross-axis offset from the track center to the floating color
    /// preview.
    ///
    /// Negative values place the preview on the `.topLeading` (default) side;
    /// positive values place it on the `.bottomTrailing` side.
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

    /// Inset to adjust the leading and trailing bounds of the draggable thumb
    /// on the main axis.
    var mainAxisThumbInset: CGFloat {
        switch thumbStyle {
        case .colorOutline(let lineWidth, let padding):
            return -(padding + (lineWidth / 2))
        case .standard:
            return (resolvedTrackThickness - resolvedThumbThickness) / 2
        }
    }

    /// Calculates the resting leading-edge thumb position for a normalized
    /// slider value.
    func thumbPosition(for normalizedValue: Double) -> CGFloat {
        let clampedValue = min(max(normalizedValue, 0.0), 1.0)
        let trackPosition = CGFloat(clampedValue) * resolvedLength
        return min(
            max(trackPosition - halfThumbThickness, mainAxisThumbInset),
            resolvedLength - resolvedThumbThickness - mainAxisThumbInset
        )
    }

    /// The unclamped main-axis position of the thumb's leading edge during an
    /// active drag, or its resting position when idle.
    var liveContainerThumbDrag: CGFloat {
        let baseValue = min(max(state.isDragging ? (state.dragStartValue ?? value) : value, 0.0), 1.0)
        let unclampedBasePosition = (CGFloat(baseValue) * resolvedLength) - halfThumbThickness
        return state.isDragging ? unclampedBasePosition + state.liveContainerDrag : unclampedBasePosition
    }

    /// The clamped main-axis position of the current selected color on the
    /// slider.
    ///
    /// For most of the slider, corresponds with the main-axis position of the
    /// draggable thumb's center. At the start or end of the slider, can extend
    /// beyond the thumb's center to the start or end of the thumb.
    var liveColorPosition: CGFloat {
        min(max(liveContainerThumbDrag + halfThumbThickness, 0), resolvedLength)
    }

    /// The clamped main-axis position of the leading edge of the draggable
    /// thumb.
    var liveThumbPosition: CGFloat {
        let minPosition = mainAxisThumbInset
        let maxPosition = resolvedLength - resolvedThumbThickness - mainAxisThumbInset
        return min(max(liveContainerThumbDrag, minPosition), maxPosition)
    }

    /// The main axis offset for the floating color preview.
    ///
    /// Except at the ends of the slider, the floating color preview is centered
    /// above the draggable thumb's center.
    var previewMainAxisOffset: CGFloat {
        let halfPreviewSize = resolvedPreviewSize / 2
        let leftBound = halfPreviewSize - halfThumbThickness
        let rightBound = resolvedLength - halfPreviewSize - halfThumbThickness
        let clampedValue = min(max(liveThumbPosition, leftBound), rightBound)

        return clampedValue - halfPreviewSize + halfThumbThickness
    }

    /// Calculates the exact relative position of the draggable thumb inside the
    /// preview.
    ///
    /// The preview always animates out of and back into the slider thumb.
    var previewScaleAnchor: UnitPoint {
        let halfThumbOffset = thumbOffset + halfThumbThickness
        let relativeMainAxis = (halfThumbOffset - previewMainAxisOffset) / resolvedPreviewSize

        let isRightToLeft = layoutDirection == .rightToLeft

        if axis == .horizontal {
            let anchorX = isRightToLeft ? (1.0 - relativeMainAxis) : relativeMainAxis
            let crossAxisLimit = resolvedPreviewOffset > 0 ? 0.0 : 1.0
            return UnitPoint(x: anchorX, y: crossAxisLimit)
        } else {
            let crossOffset = isRightToLeft ? -resolvedPreviewOffset : resolvedPreviewOffset
            let crossAxisLimit = crossOffset > 0 ? 0.0 : 1.0
            return UnitPoint(x: crossAxisLimit, y: 1.0 - relativeMainAxis)
        }
    }

    /// The offset of the thumb's leading edge.
    var thumbOffset: CGFloat {
        liveThumbPosition
    }

    /// The 2D spatial offset for the draggable thumb.
    var thumbOffsetSize: CGSize {
        let isRightToLeft = layoutDirection == .rightToLeft
        let xOffset = axis == .horizontal ? (isRightToLeft ? -thumbOffset : thumbOffset) : 0

        return CGSize(
            width: xOffset,
            height: axis == .horizontal ? 0 : -thumbOffset
        )
    }

    /// The 2D spatial offset for the floating color preview.
    var previewOffsetSize: CGSize {
        let isRightToLeft = layoutDirection == .rightToLeft

        let horizontalMain = isRightToLeft ? -previewMainAxisOffset : previewMainAxisOffset
        let verticalCross = isRightToLeft ? -resolvedPreviewOffset : resolvedPreviewOffset

        return CGSize(
            width: axis == .horizontal ? horizontalMain : verticalCross,
            height: axis == .horizontal ? resolvedPreviewOffset : -previewMainAxisOffset
        )
    }

    /// Calculates the normalized slider value (0.0 to 1.0) for a given drag state.
    func normalizedValue(for updatedState: ColorSliderState) -> Double {
        guard resolvedLength > 0 else { return 0.0 }
        var updatedLayout = self
        updatedLayout.state = updatedState
        return Double(updatedLayout.liveColorPosition / resolvedLength)
    }

    /// Calculates the normalized slider value (0.0 to 1.0) for a tap location
    /// on the track.
    func normalizedValue(forTrackLocation location: CGPoint) -> Double {
        guard resolvedLength > 0 else { return 0.0 }

        let rawPosition: CGFloat
        if axis == .horizontal {
            rawPosition = layoutDirection == .rightToLeft
                ? (resolvedLength - location.x)
                : location.x
        } else {
            rawPosition = resolvedLength - location.y
        }

        return min(max(Double(rawPosition / resolvedLength), 0.0), 1.0)
    }
}
