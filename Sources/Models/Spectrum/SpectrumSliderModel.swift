import Foundation
import SwiftUI

/// Model for calculating spectrum colors dynamically.
public struct SpectrumSliderModel: ColorSliderDataSource {
    /// The maximum number of monochrome sections allowed at either end of the spectrum.
    ///
    /// This value must match `MAX_MONOCHROME_SECTIONS` in ColorSliderShaders.metal.
    public static let maxMonochromeSections = 2
    
    private static func validateBendSections(bendSections: [BendSection]) -> Bool {
        guard bendSections.count > 1 else { return true }

        let sortedBendSections = bendSections.sorted { $0.startHue < $1.startHue }
        for (currentSection, nextSection) in zip(sortedBendSections, sortedBendSections.dropFirst()) {
            if currentSection.endHue > nextSection.startHue {
                return false
            }
        }
        return true
    }

    private let startSections: [MonochromeSection]
    private let endSections: [MonochromeSection]
    private let hueSection: HueSection

    public var colorSource: ColorSourceProvider {
        let fallback: (Double) -> Color = { position in
            SpectrumGenerator.color(
                at: position,
                startSections: startSections,
                endSections: endSections,
                hueSection: hueSection
            )
        }

        let shaderData = encodeToFloatArray()
        return .shader(generator: { size, isVertical in
            ShaderLibrary.bundle(.module).spectrumShader(
                .float2(size.width, size.height),
                .float(isVertical ? 1.0 : 0.0),
                .floatArray(shaderData)
            )
        }, fallback: fallback)
    }
    
    public init(@SpectrumComponentBuilder components: () -> [SliderComponent]) {
        let evaluatedComponents = components()

        guard let hueIndex = evaluatedComponents.firstIndex(where: { $0 is HueSection }),
              let mainHueSection = evaluatedComponents[hueIndex] as? HueSection,
              evaluatedComponents.filter({ $0 is HueSection }).count == 1 else {
            assertionFailure("Slider must contain exactly one HueSection.")
            self.hueSection = HueSection(minHue: 0, maxHue: 1)
            self.startSections = []
            self.endSections = []
            return
        }

        if let saturationBends = mainHueSection.saturationBends, !Self.validateBendSections(bendSections: saturationBends) {
            assertionFailure("Saturation bend sections are overlapping.")
        }
        if let brightnessBends = mainHueSection.brightnessBends, !Self.validateBendSections(bendSections: brightnessBends) {
            assertionFailure("Brightness bend sections are overlapping.")
        }

        let beforeHue = evaluatedComponents.prefix(upTo: hueIndex).compactMap { $0 as? MonochromeSection }
        let afterHue = evaluatedComponents.suffix(from: hueIndex + 1).compactMap { $0 as? MonochromeSection }

        let saturationBends = mainHueSection.saturationBends ?? []
        let brightnessBends = mainHueSection.brightnessBends ?? []
        
        // Truncate arrays at the Metal shader's hardcoded limits.
        if saturationBends.count > HueSection.maxBends { assertionFailure("No more than \(HueSection.maxBends) saturation bends allowed. Please remove any additional bends.") }
        if brightnessBends.count > HueSection.maxBends { assertionFailure("No more than \(HueSection.maxBends) brightness bends allowed. Please remove any additional bends.") }
        if beforeHue.count > SpectrumSliderModel.maxMonochromeSections { assertionFailure("No more than \(SpectrumSliderModel.maxMonochromeSections) start sections allowed. Please remove any additional sections.") }
        if afterHue.count > SpectrumSliderModel.maxMonochromeSections { assertionFailure("No more than \(SpectrumSliderModel.maxMonochromeSections) end sections allowed. Please remove any additional sections.") }

        let saturationClosure: () -> [BendSection] = { Array(saturationBends.prefix(HueSection.maxBends)) }
        let brightnessClosure: () -> [BendSection] = { Array(brightnessBends.prefix(HueSection.maxBends)) }

        self.hueSection = HueSection(
            minHue: mainHueSection.minHue,
            maxHue: mainHueSection.maxHue,
            baseSaturation: mainHueSection.baseSaturation,
            baseBrightness: mainHueSection.baseBrightness,
            saturationBends: saturationClosure,
            brightnessBends: brightnessClosure
        )
        self.startSections = Array(beforeHue.prefix(SpectrumSliderModel.maxMonochromeSections))
        self.endSections = Array(afterHue.prefix(SpectrumSliderModel.maxMonochromeSections))
    }

    // MARK: - Shader Serialization
    
    /// Flattens the color spectrum into a single `Float` array for Metal shaders.
    private func encodeToFloatArray() -> [Float] {
        var data: [Float] = []
        let startWeight = startSections.reduce(0) { $0 + $1.weight }
        let hueWeight = hueSection.weight
        let endWeight = endSections.reduce(0) { $0 + $1.weight }
        let totalWeight = startWeight + hueWeight + endWeight

        data.append(Float(totalWeight))
        data.append(Float(startWeight / totalWeight))
        data.append(Float((startWeight + hueWeight) / totalWeight))
        data.append(Float(hueSection.minHue))
        data.append(Float(hueSection.maxHue))
        data.append(Float(hueSection.baseSaturation))
        data.append(Float(hueSection.baseBrightness))

        data.append(Float(startSections.count))
        var cumulativeStart = 0.0
        for sec in startSections {
            cumulativeStart += sec.weight / totalWeight
            data.append(sec.color == .white ? 1.0 : 0.0)
            data.append(Float(cumulativeStart))
        }

        data.append(Float(endSections.count))
        var cumulativeEnd = (startWeight + hueWeight) / totalWeight
        for sec in endSections {
            cumulativeEnd += sec.weight / totalWeight
            data.append(sec.color == .white ? 1.0 : 0.0)
            data.append(Float(cumulativeEnd))
        }

        let sBends = hueSection.saturationBends ?? []
        data.append(Float(sBends.count))
        for b in sBends {
            data.append(b is OneWayBend ? 1.0 : 2.0)
            data.append(Float(b.startHue))
            data.append(Float(b.endHue))
            data.append(Float(b.targetValue))
            data.append(Float(b.hueCount))
        }

        let bBends = hueSection.brightnessBends ?? []
        data.append(Float(bBends.count))
        for b in bBends {
            data.append(b is OneWayBend ? 1.0 : 2.0)
            data.append(Float(b.startHue))
            data.append(Float(b.endHue))
            data.append(Float(b.targetValue))
            data.append(Float(b.hueCount))
        }
        
        let remainder = data.count % 4
        if remainder != 0 {
            data.append(contentsOf: repeatElement(0.0, count: 4 - remainder))
        }
        
        return data
    }
}
