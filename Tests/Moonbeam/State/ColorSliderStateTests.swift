import Testing
@testable import Moonbeam
import Foundation

@Suite struct ColorSliderStateTests {
    @Test("Thumb drag to the minimum track bounds")
    func thumbClampsToMinimumBounds() {
        var state = ColorSliderState()
        state.dimensions.length = 300.0

        state.persistedThumbPosition = -50.0

        #expect(state.liveColorPosition == 0.0)
    }

    @Test("Thumb drag to the maximum track bounds")
    func thumbClampsToMaximumBounds() {
        var state = ColorSliderState()
        state.dimensions.length = 300.0

        state.persistedThumbPosition = 400.0

        #expect(state.liveColorPosition == 300.0)
    }

    @Test("Accessibility adjustment increments")
    func accessibilityAdjustIncrements() {
        var state = ColorSliderState()
        state.dimensions.length = 100.0
        var progress = 0.5

        state.accessibilityAdjust(direction: .increment, progress: &progress, step: 0.1)

        #expect(progress == 0.6)
    }

    @Test("Accessibility adjustment clamping")
    func accessibilityAdjustClampsAtMax() {
        var state = ColorSliderState()
        state.dimensions.length = 100.0
        var progress = 0.95

        state.accessibilityAdjust(direction: .increment, progress: &progress, step: 0.1)

        #expect(progress == 1.0)
    }

    @Test("Drag live translation and color position clamping")
    func dragTranslationAndClamping() {
        var state = ColorSliderState()
        state.dimensions.length = 100.0
        state.dimensions.thickness = 10.0
        state.persistedThumbPosition = 50.0

        state.updateDrag(translation: 20.0)

        #expect(state.isDragging == true)
        #expect(state.liveContainerDrag == 20.0)
        #expect(state.liveContainerThumbDrag == 70.0)
        #expect(state.liveColorPosition == 75.0)

        state.finalizeDrag()

        #expect(state.isDragging == false)
        #expect(state.persistedThumbPosition == 70.0)
    }

    @Test("Zero-length layout bounds")
    func zeroLengthLayoutBounds() {
        var state = ColorSliderState()
        state.dimensions.length = 0.0
        state.dimensions.thickness = 10.0
        state.persistedThumbPosition = 0.0

        state.updateDrag(translation: 100.0)

        #expect(state.isDragging == true)
        #expect(state.liveContainerDrag == 100.0)

        // The color position clamps to the track length, which is 0.0.
        #expect(state.liveColorPosition == 0.0)

        // The thumb position clamps to the track length (0.0) minus the thumb thickness (10.0).
        #expect(state.liveThumbPosition == -10.0)

        state.finalizeDrag()

        #expect(state.isDragging == false)
        #expect(state.persistedThumbPosition == -10.0)
    }
}
