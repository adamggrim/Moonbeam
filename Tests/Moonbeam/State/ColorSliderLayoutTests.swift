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

    @Test("Color outline thumb frames discrete blocks with symmetric padding and stroke width")
    func colorOutlineGeometryAndOffsets() {
        let thumbStyle = ColorSliderThumbStyle.colorOutline(lineWidth: 2.0, padding: 4.0)
        let dimensions = ColorSliderDimensions(length: 240.0, thickness: 20.0)

        let firstBlockLayout = ColorSliderLayout(
            state: ColorSliderState(),
            value: 0.5 / 6.0,
            axis: .horizontal,
            controlSize: .regular,
            dimensions: dimensions,
            previewPosition: nil,
            previewSpacing: nil,
            thumbStyle: thumbStyle,
            colorCount: 6
        )

        #expect(firstBlockLayout.resolvedThumbThickness == 50.0)
        #expect(firstBlockLayout.resolvedThumbLength == 30.0)
        #expect(firstBlockLayout.mainAxisThumbInset == -5.0)
        #expect(firstBlockLayout.thumbOffsetSize == CGSize(width: -5.0, height: 0.0))

        let lastBlockLayout = ColorSliderLayout(
            state: ColorSliderState(),
            value: 5.5 / 6.0,
            axis: .horizontal,
            controlSize: .regular,
            dimensions: dimensions,
            previewPosition: nil,
            previewSpacing: nil,
            thumbStyle: thumbStyle,
            colorCount: 6
        )

        #expect(lastBlockLayout.thumbOffsetSize == CGSize(width: 195.0, height: 0.0))
    }

    @Test("Tap-to-seek clamps track locations across orientations and directions")
    func tapToSeekNormalizedValues() {
        let dimensions = ColorSliderDimensions(length: 200.0, thickness: 20.0)

        let ltrHorizontal = ColorSliderLayout(
            state: ColorSliderState(),
            value: 0.0,
            axis: .horizontal,
            controlSize: .regular,
            dimensions: dimensions,
            previewPosition: nil,
            previewSpacing: nil,
            layoutDirection: .leftToRight
        )
        #expect(ltrHorizontal.normalizedValue(forTrackLocation: CGPoint(x: 50.0, y: 10.0)) == 0.25)
        #expect(ltrHorizontal.normalizedValue(forTrackLocation: CGPoint(x: -10.0, y: 10.0)) == 0.0)
        #expect(ltrHorizontal.normalizedValue(forTrackLocation: CGPoint(x: 250.0, y: 10.0)) == 1.0)

        let rtlHorizontal = ColorSliderLayout(
            state: ColorSliderState(),
            value: 0.0,
            axis: .horizontal,
            controlSize: .regular,
            dimensions: dimensions,
            previewPosition: nil,
            previewSpacing: nil,
            layoutDirection: .rightToLeft
        )
        #expect(rtlHorizontal.normalizedValue(forTrackLocation: CGPoint(x: 50.0, y: 10.0)) == 0.75)

        let vertical = ColorSliderLayout(
            state: ColorSliderState(),
            value: 0.0,
            axis: .vertical,
            controlSize: .regular,
            dimensions: dimensions,
            previewPosition: nil,
            previewSpacing: nil
        )
        #expect(vertical.normalizedValue(forTrackLocation: CGPoint(x: 10.0, y: 50.0)) == 0.75)
        #expect(vertical.normalizedValue(forTrackLocation: CGPoint(x: 10.0, y: 200.0)) == 0.0)
        #expect(vertical.normalizedValue(forTrackLocation: CGPoint(x: 10.0, y: 0.0)) == 1.0)
    }

    @Test("Snapping aligns values to discrete block centers when enabled")
    func snapsToDiscreteColorCenters() {
        let layout = ColorSliderLayout(
            state: ColorSliderState(),
            value: 0.0,
            axis: .horizontal,
            controlSize: .regular,
            dimensions: ColorSliderDimensions(length: 200.0),
            previewPosition: nil,
            previewSpacing: nil,
            colorCount: 4
        )

        #expect(layout.snappedValue(for: 0.0, snapsToColor: true) == 0.125)
        #expect(layout.snappedValue(for: 0.24, snapsToColor: true) == 0.125)
        #expect(layout.snappedValue(for: 0.26, snapsToColor: true) == 0.375)
        #expect(layout.snappedValue(for: 1.0, snapsToColor: true) == 0.875)
        #expect(layout.snappedValue(for: 0.24, snapsToColor: false) == 0.24)
        #expect(layout.snappedValue(for: 1.5, snapsToColor: false) == 1.0)
    }

    @Test("RTL layout mirrors horizontal offsets, vertical preview cross-axis and scale anchors")
    func rtlOffsetsAndScaleAnchors() {
        let dimensions = ColorSliderDimensions(
            length: 100.0,
            thickness: 10.0,
            previewSize: 30.0,
            previewOffset: 50.0
        )

        let horizontalMid = ColorSliderLayout(
            state: ColorSliderState(),
            value: 0.2,
            axis: .horizontal,
            controlSize: .regular,
            dimensions: dimensions,
            previewPosition: .topLeading,
            previewSpacing: nil,
            layoutDirection: .rightToLeft
        )
        #expect(horizontalMid.thumbOffsetSize == CGSize(width: -15.0, height: 0.0))
        #expect(horizontalMid.previewOffsetSize == CGSize(width: -5.0, height: -50.0))

        let horizontalMin = ColorSliderLayout(
            state: ColorSliderState(),
            value: 0.0,
            axis: .horizontal,
            controlSize: .regular,
            dimensions: dimensions,
            previewPosition: .topLeading,
            previewSpacing: nil,
            layoutDirection: .rightToLeft
        )
        #expect(abs(horizontalMin.previewScaleAnchor.x - (5.0 / 6.0)) < 0.001)
        #expect(horizontalMin.previewScaleAnchor.y == 1.0)

        let vertical = ColorSliderLayout(
            state: ColorSliderState(),
            value: 0.2,
            axis: .vertical,
            controlSize: .regular,
            dimensions: dimensions,
            previewPosition: .topLeading,
            previewSpacing: nil,
            layoutDirection: .rightToLeft
        )
        #expect(vertical.thumbOffsetSize == CGSize(width: 0.0, height: -15.0))
        #expect(vertical.previewOffsetSize == CGSize(width: 50.0, height: -5.0))
        #expect(vertical.previewScaleAnchor == UnitPoint(x: 0.0, y: 0.5))
    }
}
