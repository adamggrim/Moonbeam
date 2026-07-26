import Testing
@testable import Moonbeam
import SwiftUI

@Suite struct ColorSliderConfigurationTests {
    @Test("Gradient modifier")
    func gradientModifier() {
        let baseConfig = ColorSliderConfiguration()

        let updated = baseConfig.applyingGradient(from: .red, to: .blue, space: .oklab)

        #expect(updated.dataSource != nil)
    }

    @Test("Spectrum modifier")
    func spectrumModifier() {
        let baseConfig = ColorSliderConfiguration()
            .applyingColors([.red, .blue])

        let updated = baseConfig.applyingSpectrum(space: .oklch, range: 0.2...0.8)

        #expect(updated.dataSource == nil)
        #expect(updated.colorSpace == .oklch)
        #expect(updated.hueRange == 0.2...0.8)
    }

    @Test("Hard-edge modifier")
    func hardEdgeModifier() {
        let baseConfig = ColorSliderConfiguration()

        let updated = baseConfig.applyingHardEdge(into: 8)

        #expect(updated.hardEdgeSteps == 8)
    }
}
