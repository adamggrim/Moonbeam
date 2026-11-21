import Testing
@testable import Moonbeam
import SwiftUI

@Suite struct ColorSliderLayoutTests {
    @Test("Preview centers over the thumb in the middle of the track")
    func previewCentered() {
        let state = ColorSliderState()
        let layout = ColorSliderLayout(
            state: state,
            value: 0.5,
            axis: .horizontal,
            controlSize: .regular,
            dimensions: ColorSliderDimensions(length: 100.0, thickness: 10.0, previewSize: 30.0),
            previewPosition: nil,
            previewSpacing: nil
        )

        #expect(layout.previewMainAxisOffset == 35.0)
        #expect(layout.previewScaleAnchor.x == 0.5)
    }

    @Test("Preview clamps at the minimum edge of the track")
    func previewClampsToMinEdge() {
        var state = ColorSliderState()
        state.updateDrag(translation: -500.0, currentValue: 0.1)

        let layout = ColorSliderLayout(
            state: state,
            value: 0.0,
            axis: .horizontal,
            controlSize: .regular,
            dimensions: ColorSliderDimensions(length: 100.0, thickness: 10.0, previewSize: 30.0),
            previewPosition: nil,
            previewSpacing: nil
        )

        #expect(layout.previewMainAxisOffset == 0.0)
        #expect(abs(layout.previewScaleAnchor.x - 0.166) < 0.01)
    }

    @Test("Preview clamps at the maximum edge of the track")
    func previewClampsToMaxEdge() {
        var state = ColorSliderState()
        state.updateDrag(translation: 500.0, currentValue: 0.9)

        let layout = ColorSliderLayout(
            state: state,
            value: 1.0,
            axis: .horizontal,
            controlSize: .regular,
            dimensions: ColorSliderDimensions(length: 100.0, thickness: 10.0, previewSize: 30.0),
            previewPosition: nil,
            previewSpacing: nil
        )

        #expect(layout.previewMainAxisOffset == 70.0)
        #expect(abs(layout.previewScaleAnchor.x - 0.833) < 0.01)
    }

    @Test("Press at 0.0 and 1.0 does not jump the normalized value")
    func zeroTranslationPressAtEndpoints() {
        for endpoint in [0.0, 1.0] {
            var state = ColorSliderState()
            state.updateDrag(translation: 0.0, currentValue: endpoint)

            let layout = ColorSliderLayout(
                state: state,
                value: endpoint,
                axis: .horizontal,
                controlSize: .regular,
                dimensions: ColorSliderDimensions(length: 200.0, thickness: 24.0),
                previewPosition: nil,
                previewSpacing: nil
            )

            #expect(layout.normalizedValue(for: state) == endpoint)
        }
    }
}
