import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
class ColorSliderViewModel {
    /// Indicates whether a drag gesture is currently active.
    var isDragging: Bool = false

    ///  The current horizontal drag within the parent container view, equivalent
    ///  to the `value.translation.width` of the `DragGesture`.
    ///
    ///  Can extend beyond the end of the slider.
    private var liveContainerDrag: CGFloat = .zero

    /// The persisted horizontal position of the start of the thumb on the slider.
    ///
    /// Cannot extend beyond the thumb's leading edge at the end of the slider.
    private var persistedThumbPosition: CGFloat = .zero

    /// The current `liveContainerDrag` combined with the
    /// `persistedThumbPosition`. Equivalent to the horizontal position of the
    /// thumb's leading edge during a `DragGesture`.
    ///
    /// This is an intermediate value calculated during an active drag.
    ///
    /// Like `liveContainerDrag`, can extend beyond the end of the slider.
    private var liveContainerThumbDrag: CGFloat = .zero

    /// The clamped horizontal position of the current selected color on the
    ///     slider.
    ///
    ///     For most of the slider, corresponds with the horizontal position of the
    ///     thumb's center. At the start or end of the slider, can extend beyond the
    ///     thumb's center to the start or end of the thumb.
    private var liveColorPosition: CGFloat = .zero


    /// The clamped horizontal position of the start of the thumb during an active
    /// drag.
    ///
    /// Cannot extend beyond the thumb's leading edge at the end of the slider.
    private var liveThumbPosition: CGFloat = .zero


    /// The position of the selected color in the slider, normalized to a range
    /// from 0.0 to 1.0.
    var positionRatio: CGFloat

    let axis: Axis
    let previewHidden: Bool

    /// Stores various layout dimensions for the color slider, as defined by
    /// `ColorSliderDimensions`.
    private let dimensions: ColorSliderDimensions
    private let halfThumbThickness: CGFloat

    /// Inset to adjust the left and right bounds of the thumb.
    ///
    /// Used when `thumbStyle` is `.circle`.
    private let thumbInset: CGFloat

    /// Whether the thumb is a `.capsule` or `.circle`.
    let thumbStyle: ThumbStyle

    /// The dynamically calculated gradient mapped to the slider's pixel width.
    let trackGradient: Gradient
    /// The source providing color data (either an array or a function).
    let dataSource: ColorSliderDataSource

    init(
        axis: Axis,
        positionRatio: CGFloat,
        thumbStyle: ThumbStyle,
        previewHidden: Bool,
        dimensions: ColorSliderDimensions,
        dataSource: ColorSliderDataSource
    ) {
        self.axis = axis
        self.positionRatio = positionRatio
        self.thumbStyle = thumbStyle
        if thumbStyle == .capsule {
            self.thumbInset = 0.0
        } else {
            self.thumbInset = (dimensions.thickness - dimensions.thumbThickness) / 2
        }
        self.previewHidden = previewHidden
        self.dimensions = dimensions
        self.dataSource = dataSource

        switch dataSource.colorSource {
        case .array(let colors):
            self.trackGradient = Gradient(colors: colors)

        case .function(let colorGenerator):
            let exactPixelLength = max(1, Int(dimensions.length))
            let stops = (0...exactPixelLength).map { i -> Gradient.Stop in
                let ratio = Double(i) / Double(exactPixelLength)
                return Gradient.Stop(color: colorGenerator(ratio), location: CGFloat(ratio))
            }
            self.trackGradient = Gradient(stops: stops)
        }

        self.halfThumbThickness = dimensions.thumbThickness / 2
        let position = positionRatio * dimensions.length

        self.liveContainerDrag = position
        self.persistedThumbPosition = position
        self.liveContainerThumbDrag = position
        self.liveThumbPosition = position
    }

    /// The color calculated from the current `liveColorPosition` on the slider.
    ///
    /// Determines which color from `sliderColors` corresponds with the thumb's
    /// current position.
    var calculatedColor: Color {
        let clampedRatio = max(0.0, min(1.0, liveColorPosition / dimensions.length))
        switch dataSource.colorSource {
        case .array(let colors):
            let calculatedIndex = Int(CGFloat(colors.count) * clampedRatio)
            let clampedIndex = max(0, min(colors.count - 1, calculatedIndex))
            return colors[clampedIndex]
        case .function(let colorGenerator):
            return colorGenerator(clampedRatio)
        }
    }

    /// The horizontal offset for the color preview.
    ///
    /// Except at the ends of the slider, the color preview is centered above the
    /// thumb's center.
    var previewMainAxisOffset: CGFloat {
        let halfPreviewSize = dimensions.previewSize / 2
        let quarterThumbThickness = halfThumbThickness / 2
        let leftBound = halfPreviewSize - halfThumbThickness
        let rightBound = dimensions.length - halfPreviewSize - halfThumbThickness
        let clampedValue = min(max(liveThumbPosition, leftBound), rightBound)

        /// The offset that centers the floating color preview above the thumb.
        let halfThumbOffset = thumbOffset + halfThumbThickness


        /// The offset that positions the floating color preview at one quarter
        /// the length of the thumb.
        ///
        /// Used when `thumbStyle` is `.circle`.
        let quarterThumbOffset = thumbOffset + quarterThumbThickness

        let startEdgeLimit: CGFloat
        let endEdgeLimit: CGFloat
        let offsetAdjustment: CGFloat

        if previewHidden {
            switch thumbStyle {
            case .capsule:
                startEdgeLimit = -halfPreviewSize + halfThumbOffset
                endEdgeLimit = -halfPreviewSize + halfThumbOffset
                offsetAdjustment = halfThumbThickness
            case .circle:
                startEdgeLimit = -halfPreviewSize + quarterThumbOffset
                let threeQuarterThumbOffset = thumbOffset + dimensions.thumbThickness - quarterThumbThickness
                endEdgeLimit = -halfPreviewSize + threeQuarterThumbOffset
                offsetAdjustment = halfThumbThickness
            }

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
        let leftBound = thumbInset
        let rightBound = dimensions.length - dimensions.thumbThickness - thumbInset
        return min(max(liveThumbPosition, leftBound), rightBound)
    }


    /// Updates the ViewModel's state when the position of the `DragGesture`
    /// changes.
    ///
    /// Called continuously while the user is dragging the thumb. Calculates
    /// `liveContainerThumbDrag`, `liveColorPosition` and`liveThumbPosition`.
    ///
    /// - Parameter value: The current value of the `DragGesture`.
    func onDragChanged(_ value: DragGesture.Value) {
        let translation = axis == .horizontal ? value.translation.width : -value.translation.height

        liveContainerDrag = translation
        liveContainerThumbDrag = persistedThumbPosition + liveContainerDrag

        /// Clamped value to prevent the drag gesture from displacing the thumb on rebound
        /// from the left and right edges of the slider.
        liveColorPosition = min(
            max(liveContainerThumbDrag + halfThumbThickness, 0), dimensions.length
        )
        liveThumbPosition = min(
            max(liveContainerThumbDrag, 0 + thumbInset),
            dimensions.length - dimensions.thumbThickness - thumbInset
        )
        
        // Update the ratio so VoiceOver knows where the gesture finished.
        positionRatio = liveColorPosition / dimensions.length
    }

    /// Finalizes the ViewModel's state when the drag gesture ends, updating
    /// `persistedThumbPosition` with the thumb's last valid clamped position
    /// and resetting `liveContainerDrag` to zero.
    func onDragEnded() {
        persistedThumbPosition = liveThumbPosition
        liveContainerDrag = .zero
    }

    /// Adjusts the slider by a specific percentage step (for VoiceOver).
    func accessibilityAdjust(by percentageStep: CGFloat) {
            let stepDelta = dimensions.length * percentageStep
            liveContainerThumbDrag = min(max(liveContainerThumbDrag + stepDelta, 0), dimensions.length)
            
            liveColorPosition = min(max(liveContainerThumbDrag + halfThumbThickness, 0), dimensions.length)
            liveThumbPosition = min(
                max(liveContainerThumbDrag, thumbInset),
                dimensions.length - dimensions.thumbThickness - thumbInset
            )
            
            persistedThumbPosition = liveThumbPosition
            positionRatio = liveColorPosition / dimensions.length
        }
}
