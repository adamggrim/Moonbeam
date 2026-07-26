import Testing
@testable import Moonbeam
import Foundation

@Suite struct DataSourceFactoryTests {
    @Test("Factory resolving OKLCH space")
    func resolvesOKLCH() {
        var config = ColorSliderConfiguration()
        config.colorSpace = .oklch
        let source = DataSourceFactory.resolve(from: config)

        #expect(source is OKLCHSpectrumModel)
    }

    @Test("Factory resolving HSB space")
    func resolvesHSB() {
        var config = ColorSliderConfiguration()
        config.colorSpace = .hsb

        let source = DataSourceFactory.resolve(from: config)

        #expect(source is HSBSpectrumModel)
    }

    @Test("Factory wrapping source in hard-edge model")
    func appliesHardEdgeWrapper() {
        var config = ColorSliderConfiguration()
        config.colorSpace = .hsb
        config.hardEdgeSteps = 5

        let source = DataSourceFactory.resolve(from: config)

        #expect(source is HardEdgeSliderModel)
    }
}
