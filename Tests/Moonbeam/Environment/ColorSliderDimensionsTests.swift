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
}
