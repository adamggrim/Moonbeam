import Foundation
import SwiftUI

public enum SpectrumColorSpace {
    case hsb, oklch
}

// MARK: - Constants & Validation

/// Global bounds for shader data structures.
internal enum spectrumConstants {
    /// The maximum number of monochrome sections allowed at either end of the spectrum.
    ///
    /// This value must match `MAX_MONOCHROME_SECTIONS` in `ColorSliderShaders.metal`.
    static let maxMonochromeSections = 2
 
    /// The maximum number of bends sections allowed in the spectrum.
    ///
    /// This value must match `MAX_BENDS` in `ColorSliderShaders.metal`.
    static let maxBends = 20
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

        if let primaryBends = mainHueSection.primaryBends, !Self.validateBendSections(bendSections: primaryBends) {
            assertionFailure("Primary bend sections are overlapping.")
        }
        if let secondaryBends = mainHueSection.secondaryBends, !Self.validateBendSections(bendSections: secondaryBends) {
            assertionFailure("Secondary bend sections are overlapping.")
        }
// MARK: - Metal Data Structures

        let beforeHue = evaluatedComponents.prefix(upTo: hueIndex).compactMap { $0 as? MonochromeSection }
        let afterHue = evaluatedComponents.suffix(from: hueIndex + 1).compactMap { $0 as? MonochromeSection }

        let primaryBends = mainHueSection.primaryBends ?? []
        let secondaryBends = mainHueSection.secondaryBends ?? []

        // Truncate arrays at the Metal shader's hardcoded limits.
        if primaryBends.count > HueSection.maxBends { assertionFailure("No more than \(HueSection.maxBends) primary bends allowed. Please remove any additional bends.") }
        if secondaryBends.count > HueSection.maxBends { assertionFailure("No more than \(HueSection.maxBends) secondary bends allowed. Please remove any additional bends.") }
        if beforeHue.count > SpectrumSliderModel.maxMonochromeSections { assertionFailure("No more than \(SpectrumSliderModel.maxMonochromeSections) start sections allowed. Please remove any additional sections.") }
        if afterHue.count > SpectrumSliderModel.maxMonochromeSections { assertionFailure("No more than \(SpectrumSliderModel.maxMonochromeSections) end sections allowed. Please remove any additional sections.") }

        self.hueSection = HueSection(
            minHue: mainHueSection.minHue,
            maxHue: mainHueSection.maxHue,
            colorSpace: mainHueSection.colorSpace,
            primaryValue: mainHueSection.primaryValue,
            secondaryValue: mainHueSection.secondaryValue,
            primaryBends: Array(primaryBends.prefix(HueSection.maxBends)),
            secondaryBends: Array(secondaryBends.prefix(HueSection.maxBends))
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
        data.append(Float(hueSection.primaryValue))
        data.append(Float(hueSection.secondaryValue))
        data.append(hueSection.colorSpace == .oklch ? 1.0 : 0.0)

        data.append(Float(startSections.count))
        var cumulativeStart = 0.0
        for sec in startSections {
            cumulativeStart += sec.weight / totalWeight
            data.append(sec.color == .white ? 1.0 : 0.0)
            data.append(Float(cumulativeStart))
        }

fileprivate func encodeSpectrumData(
    startSections: [MonochromeSection], endSections: [MonochromeSection],
    startHue: Double, endHue: Double, primaryValue: Double, secondaryValue: Double,
    colorSpace: SpectrumColorSpace, primaryBends: [BendSection], secondaryBends: [BendSection]
) -> Data {
    let hueWeight = abs(endHue - startHue)
    let startWeight = startSections.reduce(0) { $0 + $1.weight }
    let endWeight = endSections.reduce(0) { $0 + $1.weight }
    let totalWeight = startWeight + hueWeight + endWeight

    var startData = simd_float4(0, 0, 0, 0)
    var cumulativeStart = 0.0
    for (i, sec) in startSections.enumerated() {
        if i >= spectrumConstants.maxMonochromeSections { break }
        cumulativeStart += sec.weight / totalWeight
        startData[i*2] = sec.color == .white ? 1.0 : 0.0
        startData[i*2 + 1] = Float(cumulativeStart)
    }

        let sBends = hueSection.primaryBends ?? []
        data.append(Float(sBends.count))
        for b in sBends {
            data.append(b is OneWayBend ? 1.0 : 2.0)
            data.append(Float(b.startHue))
            data.append(Float(b.endHue))
            data.append(Float(b.targetValue))
            data.append(Float(b.hueCount))
        }

        let bBends = hueSection.secondaryBends ?? []
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
