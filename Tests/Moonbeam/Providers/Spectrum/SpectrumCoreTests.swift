import Testing
@testable import Moonbeam
import Foundation
import MoonbeamShared

@Suite struct SpectrumCoreTests {
    @Test("Shader data encoding mapping to C-struct")
    func shaderDataEncoding() {
        let startSections: [MonochromeSection] = [BlackSection(fraction: 0.2)]
        let endSections: [MonochromeSection] = [WhiteSection(fraction: 0.3)]

        let data = encodeSpectrumData(
            colorSpace: .hsb,
            startSections: startSections,
            endSections: endSections,
            startHue: 0.1,
            endHue: 0.9,
            primaryValue: 0.8,
            secondaryValue: 0.9,
            primaryBendsCount: 1,
            secondaryBendsCount: 2
        )

        data.withUnsafeBytes { rawBuffer in
            let shaderData = rawBuffer.load(as: SpectrumShaderData.self)

            #expect(shaderData.minimumHue == 0.1)
            #expect(shaderData.maximumHue == 0.9)
            #expect(shaderData.baseSaturation == 0.8)
            #expect(shaderData.baseBrightness == 0.9)
            #expect(shaderData.startSectionsCount == 1)
            #expect(shaderData.endSectionsCount == 1)
            #expect(shaderData.saturationBendsCount == 1)
            #expect(shaderData.brightnessBendsCount == 2)
            #expect(shaderData.colorSpaceFlag == ColorSpaceHSB.rawValue)
        }
    }

    @Test("Monochrome section encoding more than two sections")
    func multiSectionMonochromeEncoding() {
        let sections: [MonochromeSection] = [
            BlackSection(fraction: 0.1),
            WhiteSection(fraction: 0.15),
            BlackSection(fraction: 0.05),
            WhiteSection(fraction: 0.2)
        ]

        let data = encodeMonochromeSections(sections, startingAt: 0.2)

        data.withUnsafeBytes { rawBuffer in
            let encoded = rawBuffer.bindMemory(to: ShaderMonochromeSection.self)

            #expect(encoded.count == 4)

            #expect(encoded[0].isWhite == Float(MonochromeSectionTypeBlack.rawValue))
            #expect(abs(encoded[0].endPosition - 0.3) < 0.0001)

            #expect(encoded[1].isWhite == Float(MonochromeSectionTypeWhite.rawValue))
            #expect(abs(encoded[1].endPosition - 0.45) < 0.0001)

            #expect(encoded[2].isWhite == Float(MonochromeSectionTypeBlack.rawValue))
            #expect(abs(encoded[2].endPosition - 0.5) < 0.0001)

            #expect(encoded[3].isWhite == Float(MonochromeSectionTypeWhite.rawValue))
            #expect(abs(encoded[3].endPosition - 0.7) < 0.0001)
        }
    }

    @Test("Empty monochrome section array encoding a placeholder")
    func emptyMonochromeEncoding() {
        let data = encodeMonochromeSections([], startingAt: 0.0)

        data.withUnsafeBytes { rawBuffer in
            let encoded = rawBuffer.bindMemory(to: ShaderMonochromeSection.self)

            #expect(encoded.count == 1)
            #expect(encoded[0].isWhite == 0.0)
            #expect(encoded[0].endPosition == 0.0)
        }
    }
}
