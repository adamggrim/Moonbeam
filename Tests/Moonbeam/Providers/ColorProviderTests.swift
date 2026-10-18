import Testing
@testable import Moonbeam
import SwiftUI

private struct CustomFunctionProvider: ColorProvider {
    let colorSource: ColorSource = .shader(
        generator: { _, _ in
            Shader(function: .init(library: .bundle(.module), name: "gradientShader"), arguments: [])
        },
        fallback: { position in
            Color(red: position, green: 1.0 - position, blue: 0.5)
        }
    )
}

@Suite struct ColorProviderTests {
    @Test("Evaluating colors across normalized positions")
    func functionProviderEvaluation() {
        let provider = CustomFunctionProvider()

        #expect(provider.color(at: 0.0) == Color(red: 0.0, green: 1.0, blue: 0.5))
        #expect(provider.color(at: 0.25) == Color(red: 0.25, green: 0.75, blue: 0.5))
        #expect(provider.color(at: 0.5) == Color(red: 0.5, green: 0.5, blue: 0.5))
        #expect(provider.color(at: 1.0) == Color(red: 1.0, green: 0.0, blue: 0.5))
    }

    @Test("Clamping out-of-bounds positions")
    func functionProviderClamping() {
        let provider = CustomFunctionProvider()

        #expect(provider.color(at: -0.5) == Color(red: 0.0, green: 1.0, blue: 0.5))
        #expect(provider.color(at: 1.5) == Color(red: 1.0, green: 0.0, blue: 0.5))
    }

    @Test("Converting into center-sampled hard-edge stops")
    func functionProviderHardEdgeConversion() {
        let provider = CustomFunctionProvider()
        let hardEdge = provider.hardEdge(into: 4)

        #expect(hardEdge.colors.count == 4)
        #expect(hardEdge.colors[0] == Color(red: 0.125, green: 0.875, blue: 0.5))
        #expect(hardEdge.colors[1] == Color(red: 0.375, green: 0.625, blue: 0.5))
        #expect(hardEdge.colors[2] == Color(red: 0.625, green: 0.375, blue: 0.5))
        #expect(hardEdge.colors[3] == Color(red: 0.875, green: 0.125, blue: 0.5))
    }
}
