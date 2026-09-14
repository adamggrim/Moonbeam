import Testing
@testable import Moonbeam
import Foundation

@Suite struct SpectrumValidationTests {
    @Test("Non-overlapping bend sections validation")
    func validBends() {
        let bends = [
            OneWayBend(startHue: 0.0, endHue: 0.2, target: 0.5),
            OneWayBend(startHue: 0.3, endHue: 0.5, target: 0.8)
        ]

        let validated = validateBends(bends, name: "Test")

        #expect(validated.count == 2)
    }

    @Test("Overlapping bend sections validation")
    func overlappingBendsDropped() {
        let bends = [
            OneWayBend(startHue: 0.0, endHue: 0.5, target: 0.5),
            OneWayBend(startHue: 0.4, endHue: 0.8, target: 0.8)
        ]

        let validated = validateBends(bends, name: "Test")

        #expect(validated.count == 1)
        #expect(validated.first?.targetValue == 0.5)
    }

    @Test("Valid monochrome sections preservation")
    func validMonochromeSections() {
        let sections: [MonochromeSection] = [BlackSection(weight: 0.1), WhiteSection(weight: 0.2)]

        let validated = validateMonochromeSections(sections, name: "Test")

        #expect(validated.count == 2)
        #expect(validated.first?.weight == 0.1)
    }
}
