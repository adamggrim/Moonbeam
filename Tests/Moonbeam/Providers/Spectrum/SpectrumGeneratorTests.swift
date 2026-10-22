import Testing
@testable import Moonbeam
import SwiftUI

@Suite struct SpectrumGeneratorTests {
    @Test("Generator output for a monochrome start section")
    func monochromeStartSection() {
        let startSections = [BlackSection(fraction: 0.999)]
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
        #expect(color == Color(hue: 0.25, saturation: 0.7, brightness: 1.0))
    }

    @Test("Reversed spectrum applies leading OneWayBend ease-out from startHue")
    func reversedSpectrumLeadingOneWayBend() throws {
        let bends = [OneWayBend(startHue: 0.5, endHue: 0.9, target: 0.2)]
        let configuration = SpectrumConfiguration(
            colorSpace: .hsb,
            startSections: [],
            endSections: [],
            startHue: 0.9,
            endHue: 0.1,
            primaryValue: 1.0,
            secondaryValue: 1.0,
            primaryBends: bends,
            secondaryBends: nil
        )

        let startComponents = try #require(
            SpectrumGenerator.components(at: 0.0, configuration: configuration)
        )
        let midBendComponents = try #require(
            SpectrumGenerator.components(at: 0.25, configuration: configuration)
        )
        let endBendComponents = try #require(
            SpectrumGenerator.components(at: 0.5, configuration: configuration)
        )

        #expect(abs(startComponents.hue - 0.9) < 0.0001)
        #expect(abs(startComponents.primary - 0.2) < 0.0001)

        #expect(abs(midBendComponents.hue - 0.7) < 0.0001)
        #expect(abs(midBendComponents.primary - 0.7) < 0.0001)

        #expect(abs(endBendComponents.hue - 0.5) < 0.0001)
        #expect(abs(endBendComponents.primary - 1.0) < 0.0001)
    }

    @Test("Reversed spectrum applies trailing OneWayBend ease-in toward endHue")
    func reversedSpectrumTrailingOneWayBend() throws {
        let bends = [OneWayBend(startHue: 0.5, endHue: 0.1, target: 0.2)]
        let configuration = SpectrumConfiguration(
            colorSpace: .hsb,
            startSections: [],
            endSections: [],
            startHue: 0.9,
            endHue: 0.1,
            primaryValue: 1.0,
            secondaryValue: 1.0,
            primaryBends: bends,
            secondaryBends: nil
        )

        let entryComponents = try #require(
            SpectrumGenerator.components(at: 0.5, configuration: configuration)
        )
        let midBendComponents = try #require(
            SpectrumGenerator.components(at: 0.75, configuration: configuration)
        )
        let endComponents = try #require(
            SpectrumGenerator.components(at: 1.0, configuration: configuration)
        )

        #expect(abs(entryComponents.hue - 0.5) < 0.0001)
        #expect(abs(entryComponents.primary - 1.0) < 0.0001)

        #expect(abs(midBendComponents.hue - 0.3) < 0.0001)
        #expect(abs(midBendComponents.primary - 0.7) < 0.0001)

        #expect(abs(endComponents.hue - 0.1) < 0.0001)
        #expect(abs(endComponents.primary - 0.2) < 0.0001)
    }
}
