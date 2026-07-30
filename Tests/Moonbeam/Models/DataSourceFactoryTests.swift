import Testing
@testable import Moonbeam
import Foundation

@Suite struct DataSourceFactoryTests {
    @Test("Factory resolving OKLCH space")
    func resolvesOKLCH() {
        var config = ColorSliderConfiguration()
        config.colorSpace = .oklch
        config.baseLightness = 0.8
        config.baseChroma = 0.2
        config.hueRange = 0.2...0.8

        let source = DataSourceFactory.resolve(from: config) as? OKLCHSpectrumModel

        #expect(source != nil)
        #expect(source?.lightness == 0.8)
        #expect(source?.chroma == 0.2)
        #expect(source?.startHue == 0.2)
        #expect(source?.endHue == 0.8)
    }

    @Test("Factory resolving HSB space")
    func resolvesHSB() {
        var config = ColorSliderConfiguration()
        config.colorSpace = .hsb
        config.baseSaturation = 0.5

        let source = DataSourceFactory.resolve(from: config) as? HSBSpectrumModel

        #expect(source != nil)
        #expect(source?.saturation == 0.5)
    }

    @Test("Factory wrapping source in hard-edge model")
    func appliesHardEdgeWrapper() {
        var config = ColorSliderConfiguration()
        config.colorSpace = .hsb
        config.hardEdgeSteps = 5

        let source = DataSourceFactory.resolve(from: config) as? HardEdgeSliderModel

        #expect(source != nil)
        #expect(source?.colors.count == 5)
    }
}
