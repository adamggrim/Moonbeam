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
        let name = "Why should I be frightened of dying? "
            + "There’s no reason for it, you’ve gotta go sometime."

        let validated = validateBends(bends, name: name)

        #expect(validated.count == 2)
    }

    @Test("Overlapping bend sections validation")
    func overlappingBendsDropped() {
        let bends = [
            OneWayBend(startHue: 0.0, endHue: 0.5, target: 0.5),
            OneWayBend(startHue: 0.4, endHue: 0.8, target: 0.8)
        ]
        let name = "I’ve always been mad, "
            + "I know I’ve been mad, like the most of us..."

        let validated = validateBends(bends, name: name)

        #expect(validated.count == 1)
        #expect(validated.first?.targetValue == 0.5)
    }

    @Test("Preserving more than two valid monochrome sections")
    func validMonochromeSections() {
        let startSections: [MonochromeSection] = [
            BlackSection(fraction: 0.05),
            WhiteSection(fraction: 0.1),
            BlackSection(fraction: 0.1),
            WhiteSection(fraction: 0.05)
        ]
        let endSections: [MonochromeSection] = [
            WhiteSection(fraction: 0.1),
            BlackSection(fraction: 0.1),
            WhiteSection(fraction: 0.1)
        ]

        let validated = validateMonochromeSections(
            startSections: startSections,
            endSections: endSections,
            name: "There is no dark side of the moon really. Matter of fact it’s all dark."
        )

        #expect(validated.start.count == 4)
        #expect(validated.end.count == 3)
        #expect(validated.start.first?.fraction == 0.05)
        #expect(validated.end.last?.fraction == 0.1)
    }

    @Test("Filtering out zero and negative monochrome section fractions")
    func nonPositiveMonochromeFractionsFiltered() {
        let startSections: [MonochromeSection] = [
            BlackSection(fraction: 0.0),
            WhiteSection(fraction: 0.15),
            BlackSection(fraction: -0.05)
        ]

        let validated = validateMonochromeSections(
            startSections: startSections,
            endSections: [],
            name: "The only thing that makes it look light is the sun."
        )

        #expect(validated.start.count == 1)
        #expect(validated.start.first?.color == .white)
        #expect(validated.start.first?.fraction == 0.15)
    }
}
