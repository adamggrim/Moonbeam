import Testing
@testable import Moonbeam
import Foundation

@Suite struct BendSectionTests {
    @Test("Standard hue distance calculation")
    func standardHueDistance() {
        let distance = OneWayBend.calculateHueCount(start: 0.2, end: 0.5)
        #expect(distance == 0.3)
    }

    @Test("Wide hue distance calculation across more than half the spectrum")
    func wideHueDistance() {
        let distance = OneWayBend.calculateHueCount(start: 0.9, end: 0.1)
        #expect(abs(distance - 0.8) < 0.0001)
    }
}
