import Testing
@testable import Moonbeam
import SwiftUI

@Suite struct ColorSliderDimensionsTests {
    @Test("Dimension resolution falls back to default control size metrics")
    func fallbackToControlSize() {
        let dimensions = ColorSliderDimensions()
        let resolvedThickness = dimensions.resolvedTrackThickness(for: .regular)
        #expect(resolvedThickness == 24.0)
        let resolvedThumbLength = dimensions.resolvedThumbLength(for: .regular)
        #expect(resolvedThumbLength == 48.0)
    }

    @Test("Explicit dimensions successfully override control size fallbacks")
    func explicitDimensions() {
        let dimensions = ColorSliderDimensions(thickness: 10.0, thumbLength: 30.0)
        let resolvedThickness = dimensions.resolvedTrackThickness(for: .regular)
        #expect(resolvedThickness == 10.0)
        let resolvedThumbLength = dimensions.resolvedThumbLength(for: .regular)
        #expect(resolvedThumbLength == 30.0)
    }

    @Test("Color outline thumb length resolves from track thickness, padding and stroke width")
    func colorOutlineThumbLength() {
        let dimensions = ColorSliderDimensions(thickness: 20.0, thumbLength: 50.0)
        let resolvedThumbLength = dimensions.resolvedThumbLength(
            for: .regular,
            thumbStyle: .colorOutline(lineWidth: 3.0, padding: 4.0)
        )
        #expect(resolvedThumbLength == 31.0)
    }
}
