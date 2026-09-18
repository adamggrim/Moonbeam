import Testing
@testable import Moonbeam
import SwiftUI

@Suite struct HardEdgeColorsTests {
    @Test("Hard-edge modifier bounds validation")
    func boundsValidation() {
        let gradient = ColorGradient(startColor: .black, endColor: .white)

        let edgeZero = gradient.hardEdge(into: 0)
        let edgeOne = gradient.hardEdge(into: 1)

        #expect(edgeZero.colors.isEmpty)
        #expect(edgeOne.colors.isEmpty)
    }

    @Test("Hard-edge modifier array conversion")
    func modifierConversion() {
        let gradient = ColorGradient(startColor: .black, endColor: .white)
        let hardEdgeProvider = gradient.hardEdge(into: 4)

        #expect(hardEdgeProvider.colors.count == 4)

        guard case .array(let sourceColors) = hardEdgeProvider.colorSource else {
            Issue.record("Expected converted color source to be a discrete array.")
            return
        }

        #expect(sourceColors.count == 4)
    }

    @Test("Hard-edge bypass for existing arrays")
    func arrayBypass() {
        let initialColors: [Color] = [.red, .blue, .green]
        let originalProvider = HardEdgeColors(colors: initialColors)

        let modifiedProvider = originalProvider.hardEdge(into: 10)

        // Rreturn the original array when the source was already hard-edge.
        #expect(modifiedProvider.colors.count == 3)
    }
}
