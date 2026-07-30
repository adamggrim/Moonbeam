import Testing
@testable import Moonbeam
import Foundation
import MoonbeamShared

@Suite struct SpectrumSliderModelTests {
    @Test("Shader data encoding mapping to C-struct")
    func shaderDataEncoding() {
        let startSections: [MonochromeSection] = [BlackSection(weight: 0.2)]
        let endSections: [MonochromeSection] = [WhiteSection(weight: 0.3)]

        let data = encodeSpectrumData(
            startSections: startSections,
            endSections: endSections,
            startHue: 0.1,
            endHue: 0.9,
            primaryValue: 0.8,
            secondaryValue: 0.9,
            colorSpace: .hsb,
            primaryBendsCount: 1,
            secondaryBendsCount: 2
        )

        data.withUnsafeBytes { rawBuffer in
            let shaderData = rawBuffer.load(as: SpectrumShaderData.self)

            #expect(abs(shaderData.totalWeight - 1.3) < 0.0001)
            #expect(shaderData.minimumHue == 0.1)
            #expect(shaderData.maximumHue == 0.9)
            #expect(shaderData.baseSaturation == 0.8)
            #expect(shaderData.baseBrightness == 0.9)
            #expect(shaderData.startSectionsCount == 1)
            #expect(shaderData.endSectionsCount == 1)
            #expect(shaderData.saturationBendsCount == 1)
            #expect(shaderData.brightnessBendsCount == 2)
            #expect(shaderData.colorSpaceFlag == MoonbeamColorSpaceHSB.rawValue)
        }
    }
}
