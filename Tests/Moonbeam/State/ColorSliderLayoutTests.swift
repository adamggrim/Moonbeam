import Testing
@testable import Moonbeam
import SwiftUI

@Suite struct ColorSliderLayoutTests {
    @Test("Preview alignment centered over thumb in middle of track")
    func previewCentered() {
        let state = ColorSliderState()
        let layout = ColorSliderLayout(
            state: state,
            value: 0.5,
            dimensions: ColorSliderDimensions(length: 100.0, thickness: 10.0, previewSize: 30.0),
            axis: .horizontal, controlSize: .regular, previewPosition: nil, previewSpacing: nil
        )

        #expect(layout.previewMainAxisOffset == 35.0)
        #expect(layout.previewScaleAnchor.x == 0.5)
    }

    @Test("Preview clamping at the minimum edge of the track")
    func previewClampsToMinEdge() {
        var state = ColorSliderState()
        state.updateDrag(translation: -500.0, currentValue: 0.1)

        let layout = ColorSliderLayout(
            state: state,
            value: 0.0,
            dimensions: ColorSliderDimensions(length: 100.0, thickness: 10.0, previewSize: 30.0),
            axis: .horizontal, controlSize: .regular, previewPosition: nil, previewSpacing: nil
        )

        #expect(layout.previewMainAxisOffset == 0.0)
        #expect(abs(layout.previewScaleAnchor.x - 0.166) < 0.01)
    }

    @Test("Preview clamping at the maximum edge of the track")
    func previewClampsToMaxEdge() {
        var state = ColorSliderState()
        state.updateDrag(translation: 500.0, currentValue: 0.9)

        let layout = ColorSliderLayout(
            state: state,
            value: 1.0,
            dimensions: ColorSliderDimensions(length: 100.0, thickness: 10.0, previewSize: 30.0),
            axis: .horizontal, controlSize: .regular, previewPosition: nil, previewSpacing: nil
        )

        #expect(layout.previewMainAxisOffset == 70.0)
        #expect(abs(layout.previewScaleAnchor.x - 0.833) < 0.01)
    }
}
