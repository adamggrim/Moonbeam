import Testing
@testable import Moonbeam
import SwiftUI

@Suite struct SpectrumGeneratorTests {
    @Test("Generator output for a monochrome start section")
    func monochromeStartSection() {
        let startSections = [BlackSection(weight: 1.0)]
        let color = SpectrumGenerator.color(
            at: 0.0,
            startSections: startSections,
            endSections: [],
            startHue: 0.0,
            endHue: 1.0,
            primaryValue: 1.0,
            secondaryValue: 1.0,
            colorSpace: .hsb,
            primaryBends: nil,
            secondaryBends: nil
        )
        #expect(color != .clear)
    }

    @Test("Generator hue in the middle of a spectrum")
    func middleOfSpectrum() {
        let color = SpectrumGenerator.color(
            at: 0.5,
            startSections: [],
            endSections: [],
            startHue: 0.0,
            endHue: 1.0,
            primaryValue: 1.0,
            secondaryValue: 1.0,
            colorSpace: .hsb,
            primaryBends: nil,
            secondaryBends: nil
        )
        #expect(color != .clear)
    }
}
