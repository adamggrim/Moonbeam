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

        @Test("Accessibility adjust increments")
        func accessibilityAdjustIncrements() {
            var state = ColorSliderState()
            state.dimensions.length = 100.0
            var progress = 0.5

            state.accessibilityAdjust(direction: .increment, progress: &progress, step: 0.1)

            #expect(progress == 0.6)
        }

        @Test("Accessibility adjust clamping")
        func accessibilityAdjustClampsAtMax() {
            var state = ColorSliderState()
            state.dimensions.length = 100.0
            var progress = 0.95

            state.accessibilityAdjust(direction: .increment, progress: &progress, step: 0.1)

            #expect(progress == 1.0)
        }
    }
