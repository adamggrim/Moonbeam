import SwiftUI

/// A configuration object for the data and rules required to generate a color
/// slider.
public struct ColorSliderConfiguration: Sendable {
    /// An explicitly provided data source, such as a gradient or hard-edge model.
    /// If nil, the slider will generate an implicit spectrum based on the properties below.
    internal var dataSource: (any ColorSliderDataSource)? = nil

    /// The color space used to generate the spectrum. Defaults to HSB.
    public var colorSpace: SpectrumColorSpace = .hsb

    /// The normalized range of hues to display on the slider.
    public var hueRange: ClosedRange<Double> = 0.0...1.0

    public var startSections: [MonochromeSection] = []
    public var endSections: [MonochromeSection] = []

    public var saturationBends: [BendSection] = []
    public var brightnessBends: [BendSection] = []
    public var lightnessBends: [BendSection] = []
    public var chromaBends: [BendSection] = []

    public var baseSaturation: Double? = nil
    public var baseBrightness: Double? = nil
    public var baseLightness: Double? = nil
    public var baseChroma: Double? = nil

    public var hardEdgeSteps: Int? = nil

    public init() {}

    internal func applyingSpectrum(space: SpectrumColorSpace, range: ClosedRange<Double>) -> Self {
        var copy = self
        copy.colorSpace = space
        copy.hueRange = range
        copy.dataSource = nil
        return copy
    }

    internal func applyingBaseSaturation(_ value: Double) -> Self {
        var copy = self
        copy.baseSaturation = value
        copy.dataSource = nil
        return copy
    }

    internal func applyingBaseBrightness(_ value: Double) -> Self {
        var copy = self
        copy.baseBrightness = value
        copy.dataSource = nil
        return copy
    }

    internal func applyingBaseLightness(_ value: Double) -> Self {
        var copy = self
        copy.baseLightness = value
        copy.dataSource = nil
        return copy
    }

    internal func applyingBaseChroma(_ value: Double) -> Self {
        var copy = self
        copy.baseChroma = value
        copy.dataSource = nil
        return copy
    }

    internal func applyingStartSections(_ sections: [MonochromeSection]) -> Self {
        var copy = self
        copy.startSections = sections
        copy.dataSource = nil
        return copy
    }

    internal func applyingEndSections(_ sections: [MonochromeSection]) -> Self {
        var copy = self
        copy.endSections = sections
        copy.dataSource = nil
        return copy
    }

    internal func applyingSaturationBends(_ bends: [BendSection]) -> Self {
        var copy = self
        copy.saturationBends = bends
        copy.dataSource = nil
        return copy
    }

    internal func applyingBrightnessBends(_ bends: [BendSection]) -> Self {
        var copy = self
        copy.brightnessBends = bends
        copy.dataSource = nil
        return copy
    }

    internal func applyingLightnessBends(_ bends: [BendSection]) -> Self {
        var copy = self
        copy.lightnessBends = bends
        copy.dataSource = nil
        return copy
    }

    internal func applyingChromaBends(_ bends: [BendSection]) -> Self {
        var copy = self
        copy.chromaBends = bends
        copy.dataSource = nil
        return copy
    }

    internal func applyingGradient(from startColor: Color, to endColor: Color, space: GradientColorSpace) -> Self {
        var copy = self
        copy.dataSource = GradientSliderModel(startColor: startColor, endColor: endColor, colorSpace: space)
        return copy
    }

    internal func applyingColors(_ colors: [Color]) -> Self {
        var copy = self
        copy.dataSource = HardEdgeSliderModel(colors: colors)
        return copy
    }

    internal func applyingHardEdge(into steps: Int) -> Self {
        var copy = self
        copy.hardEdgeSteps = steps
        return copy
    }
}
