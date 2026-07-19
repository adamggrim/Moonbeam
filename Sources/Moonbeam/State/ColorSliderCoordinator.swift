import SwiftUI

/// An coordinator that isolates gesture processing and state mutations away
/// from the view.
internal struct ColorSliderCoordinator {
    static func updateDrag(state: inout ColorSliderState, translation: CGFloat) {
        state.isDragging = true
        state.liveContainerDrag = translation
    }

    static func finalizeDrag(state: inout ColorSliderState) {
        state.isDragging = false
        state.persistedThumbPosition = state.liveThumbPosition
        state.liveContainerDrag = .zero
    }

    /// Adjusts the slider by a specific percentage step (for VoiceOver).
    static func accessibilityAdjust(
        state: inout ColorSliderState,
        direction: AccessibilityAdjustmentDirection,
        progress: inout Double,
        step: Double
    ) {
        let delta = direction == .increment ? step : -step
        let newProgress = min(max(progress + delta, 0.0), 1.0)
        progress = newProgress

        let newTrackPosition = CGFloat(newProgress) * state.dimensions.length
        state.persistedThumbPosition = min(
            max(newTrackPosition - state.halfThumbThickness, state.thumbInset),
            state.dimensions.length - state.resolvedThumbThickness - state.thumbInset
        )
        state.liveContainerDrag = .zero
    }
}
