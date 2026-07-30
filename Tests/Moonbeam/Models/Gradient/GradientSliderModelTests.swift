import Testing
@testable import Moonbeam
import SwiftUI

@Suite struct GradientSliderModelTests {
    @Test("Gradient interpolation resolving to a valid color")
    func gradientInterpolation() {
        let model = GradientSliderModel(startColor: .black, endColor: .white, colorSpace: .rgb)

        guard case .shader(_, let fallback) = model.colorSource else {
            Issue.record("Expected shader color source with a pure-Swift fallback.")
            return
        }

        let midColor = fallback(0.5)
        let expectedColor = Color.black.mix(with: .white, by: 0.5)

        #expect(midColor == expectedColor)
    }

    @Test("Property-based gradient interpolation across random bounds")
    func gradientInterpolationProperties() {
        let model = GradientSliderModel(startColor: .black, endColor: .white, colorSpace: .rgb)

        guard case .shader(_, let fallback) = model.colorSource else {
            Issue.record("Expected shader color source with a pure-Swift fallback.")
            return
        }

        for _ in 0..<100 {
            let position = Double.random(in: 0.0...1.0)
            let calculatedColor = fallback(position)
            let expectedColor = Color.black.mix(with: .white, by: position)

            #expect(calculatedColor == expectedColor)
        }
    }
}
