import SwiftUI

public extension View {
    func spectrum(space: SpectrumColorSpace, range: ClosedRange<Double>) -> some View {
        transformEnvironment(\.colorSliderConfiguration) { config in
            config = config.applyingSpectrum(space: space, range: range)
        }
    }

    func baseSaturation(_ value: Double) -> some View {
        transformEnvironment(\.colorSliderConfiguration) { config in
            config = config.applyingBaseSaturation(value)
        }
    }

    func baseBrightness(_ value: Double) -> some View {
        transformEnvironment(\.colorSliderConfiguration) { config in
            config = config.applyingBaseBrightness(value)
        }
    }

    func baseLightness(_ value: Double) -> some View {
        transformEnvironment(\.colorSliderConfiguration) { config in
            config = config.applyingBaseLightness(value)
        }
    }

    func baseChroma(_ value: Double) -> some View {
        transformEnvironment(\.colorSliderConfiguration) { config in
            config = config.applyingBaseChroma(value)
        }
    }

    func startingWith(_ sections: MonochromeSection...) -> some View {
        transformEnvironment(\.colorSliderConfiguration) { config in
            config = config.applyingStartSections(sections)
        }
    }

    func endingWith(_ sections: MonochromeSection...) -> some View {
        transformEnvironment(\.colorSliderConfiguration) { config in
            config = config.applyingEndSections(sections)
        }
    }

    func saturationBends(@BendSectionBuilder _ bends: () -> [BendSection]) -> some View {
        let resolvedBends = bends()
        return transformEnvironment(\.colorSliderConfiguration) { config in
            config = config.applyingSaturationBends(resolvedBends)
        }
    }

    func brightnessBends(@BendSectionBuilder _ bends: () -> [BendSection]) -> some View {
        let resolvedBends = bends()
        return transformEnvironment(\.colorSliderConfiguration) { config in
            config = config.applyingBrightnessBends(resolvedBends)
        }
    }

    func lightnessBends(@BendSectionBuilder _ bends: () -> [BendSection]) -> some View {
        let resolvedBends = bends()
        return transformEnvironment(\.colorSliderConfiguration) { config in
            config = config.applyingLightnessBends(resolvedBends)
        }
    }

    func chromaBends(@BendSectionBuilder _ bends: () -> [BendSection]) -> some View {
        let resolvedBends = bends()
        return transformEnvironment(\.colorSliderConfiguration) { config in
            config = config.applyingChromaBends(resolvedBends)
        }
    }

    func gradient(from startColor: Color, to endColor: Color, space: GradientColorSpace = .rgb) -> some View {
        transformEnvironment(\.colorSliderConfiguration) { config in
            config = config.applyingGradient(from: startColor, to: endColor, space: space)
        }
    }

    func colors(_ colors: [Color]) -> some View {
        transformEnvironment(\.colorSliderConfiguration) { config in
            config = config.applyingColors(colors)
        }
    }

    func hardEdge(into steps: Int) -> some View {
        transformEnvironment(\.colorSliderConfiguration) { config in
            config = config.applyingHardEdge(into: steps)
        }
    }
}
