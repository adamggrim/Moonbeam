import Testing
@testable import Moonbeam
import Foundation

@Suite struct ColorSliderStateTests {
    @Test("Thumb drag to the minimum track bounds")
    func thumbClampsToMinimumBounds() {
        var state = ColorSliderState()
        state.updateDrag(translation: -500.0, currentValue: 0.1)

        let layout = ColorSliderLayout(
            state: state, value: 0.1, dimensions: ColorSliderDimensions(length: 300.0),
            axis: .horizontal, controlSize: .regular, previewPosition: nil, previewSpacing: nil
        )

        #expect(layout.liveColorPosition == 0.0)
    }

    @Test("Thumb drag to the maximum track bounds")
    func thumbClampsToMaximumBounds() {
        var state = ColorSliderState()
        state.updateDrag(translation: 500.0, currentValue: 0.9)

        let layout = ColorSliderLayout(
            state: state, value: 0.9, dimensions: ColorSliderDimensions(length: 300.0),
            axis: .horizontal, controlSize: .regular, previewPosition: nil, previewSpacing: nil
        )

        #expect(layout.liveColorPosition == 300.0)
    }

    @Test("Drag live translation and color position clamping")
    func dragTranslationAndClamping() {
        var state = ColorSliderState()
        state.updateDrag(translation: 20.0, currentValue: 0.5)

        let layout = ColorSliderLayout(
            state: state, value: 0.5, dimensions: ColorSliderDimensions(length: 100.0, thickness: 10.0),
            axis: .horizontal, controlSize: .regular, previewPosition: nil, previewSpacing: nil
        )

        #expect(state.isDragging == true)
        #expect(state.liveContainerDrag == 20.0)
        #expect(layout.liveContainerThumbDrag == 65.0)
        #expect(layout.liveColorPosition == 70.0)

        state.finalizeDrag()

        #expect(state.isDragging == false)
    }

    @Test("Zero-length layout bounds")
    func zeroLengthLayoutBounds() {
        var state = ColorSliderState()
        state.updateDrag(translation: 100.0, currentValue: 0.0)

        let layout = ColorSliderLayout(
            state: state, value: 0.0, dimensions: ColorSliderDimensions(length: 0.0, thickness: 10.0),
            axis: .horizontal, controlSize: .regular, previewPosition: nil, previewSpacing: nil
        )

        #expect(state.isDragging == true)
        #expect(state.liveContainerDrag == 100.0)

        // The color position clamps to the track length, which is 0.0.
        #expect(layout.liveColorPosition == 0.0)

        // The thumb position clamps to the track length (0.0) minus the thumb
        // thickness (10.0).
        #expect(layout.liveThumbPosition == -10.0)

        state.finalizeDrag()

        #expect(state.isDragging == false)
    }
}
