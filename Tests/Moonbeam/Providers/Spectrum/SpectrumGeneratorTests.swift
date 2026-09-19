import Testing
@testable import Moonbeam
import SwiftUI

@Suite struct SpectrumGeneratorTests {
    @Test("Generator output for a monochrome start section")
    func monochromeStartSection() {
        let startSections = [BlackSection(weight: 1.0)]
        let configuration = SpectrumConfiguration(
            colorSpace: .hsb,
            startSections: startSections,
            endSections: [],
            startHue: 0.0,
            endHue: 1.0,
            primaryValue: 1.0,
            secondaryValue: 1.0,
            primaryBends: nil,
            secondaryBends: nil
        )
        let color = SpectrumGenerator.color(
            at: 0.0,
            configuration: configuration
        )
        #expect(color == Color(hue: 0.0, saturation: 1.0, brightness: 0.0))
    }

    @Test("Generator output for the middle of a spectrum slider without bends")
    func middleOfSpectrum() {
        let configuration = SpectrumConfiguration(
            colorSpace: .hsb,
            startSections: [],
            endSections: [],
            startHue: 0.0,
            endHue: 1.0,
            primaryValue: 1.0,
            secondaryValue: 1.0,
            primaryBends: nil,
            secondaryBends: nil
        )
        let color = SpectrumGenerator.color(
            at: 0.5,
            configuration: configuration
        )
        #expect(color == Color(hue: 0.5, saturation: 1.0, brightness: 1.0))
    }

    @Test("Generator application of the correct bend target to primary values")
    func appliedSpectrumBend() {
        let bends = [OneWayBend(startHue: 0.0, endHue: 0.5, target: 0.2)]
        let configuration = SpectrumConfiguration(
            colorSpace: .hsb,
            startSections: [],
            endSections: [],
            startHue: 0.0,
            endHue: 1.0,
            primaryValue: 1.0,
            secondaryValue: 1.0,
            primaryBends: bends,
            secondaryBends: nil
        )
        let color = SpectrumGenerator.color(
            at: 0.25,
            configuration: configuration
        )
        #expect(color == Color(hue: 0.25, saturation: 0.6, brightness: 1.0))
    }
}
