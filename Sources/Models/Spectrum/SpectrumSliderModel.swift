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

/// A strictly aligned sub-structure to represent a single bend.
/// Uses 32 bytes (two 16-byte `simd_float4s`) to guarantee Metal alignment.
fileprivate struct ShaderBend {
    var data0: simd_float4 // x: type, y: startHue, z: endHue, w: targetValue
    var data1: simd_float4 // x: hueCount, y: 0, z: 0, w: 0 (padding)
    
    init(bend: BendSection?) {
        guard let b = bend else {
            self.data0 = .zero
            self.data1 = .zero
            return
        }
        self.data0 = simd_float4(
            b is OneWayBend ? 1.0 : 2.0,
            Float(b.startHue),
            Float(b.endHue),
            Float(b.targetValue)
        )
        self.data1 = simd_float4(Float(b.hueCount), 0, 0, 0)
    }
}

/// A C-compatible memory layout that bridges directly to the `SpectrumShaderData` struct in Metal.
///
/// The property sequence, layout and alignment of this struct must exactly mirror
/// `SpectrumShaderData` in Metal.
///
/// 1. Do **not** use dynamically sized arrays (e.g., `Array` or `[Float]`).
/// 2. Do **not** use nested objects or classes.
/// 3. Rely strictly on fixed-size tuples and primitive types (`Float`, `Int32`, `simd_float4`).
fileprivate struct SpectrumShaderData {
    // 32 Bytes
    var totalWeight: Float
    var startSectionBoundary: Float
    var hueSectionBoundary: Float
    var minimumHue: Float
    var maximumHue: Float
    var baseSaturation: Float
    var baseBrightness: Float
    var colorSpaceFlag: Float
    
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
/// Model for calculating perceptually uniform OKLCH spectrum colors dynamically.
public struct OKLCHSpectrumModel: ColorSliderDataSource {
    public let startSections: [MonochromeSection]
    public let endSections: [MonochromeSection]
    public let lightness: Double
    public let chroma: Double
    public let startHue: Double
    public let endHue: Double
    public let lightnessBends: [BendSection]
    public let chromaBends: [BendSection]

    /// Creates a dynamically generated spectrum based on the perceptually uniform OKLCH color space.
    ///
    /// - Parameters:
    ///   - startSections: Monochrome sections that fade into the beginning of the hue spectrum. Capped at `spectrumConstants.maxMonochromeSections`.
    ///   - endSections: Monochrome sections that fade out of the end of the hue spectrum.
    ///   - lightness: The perceived brightness of the color (L). Standard range is 0.0 to 1.0. Defaults to 0.75.
    ///   - chroma: The intensity/purity of the color (C). Range depends on device gamut, typically 0.0 to 0.4. Defaults to 0.15.
    ///   - startHue: The starting hue angle (h) normalized to 0.0 - 1.0.
    ///   - endHue: The ending hue angle (h) normalized to 0.0 - 1.0.
    ///   - lightnessBends: Sections where the baseline lightness bends toward a target value.
    ///   - chromaBends: Sections where the baseline chroma bends toward a target value.
    public init(
        startSections: [MonochromeSection] = [],
        endSections: [MonochromeSection] = [],
        lightness: Double = 0.75,
        chroma: Double = 0.15,
        startHue: Double = 0.0,
        endHue: Double = 1.0,
        @BendSectionBuilder lightnessBends: () -> [BendSection] = { [] },
        @BendSectionBuilder chromaBends: () -> [BendSection] = { [] }
    ) {
        self.startSections = Array(startSections.prefix(spectrumConstants.maxMonochromeSections))
        self.endSections = Array(endSections.prefix(spectrumConstants.maxMonochromeSections))
        self.lightness = lightness
        self.chroma = chroma
        self.startHue = startHue
        self.endHue = endHue
        self.lightnessBends = validateAndTruncateBends(lightnessBends(), name: "OKLCH Lightness")
        self.chromaBends = validateAndTruncateBends(chromaBends(), name: "OKLCH Chroma")
    }

    public var colorSource: ColorSourceProvider {
        let fallback: (Double) -> Color = { position in
            SpectrumGenerator.color(at: position, startSections: startSections, endSections: endSections, startHue: startHue, endHue: endHue, primaryValue: chroma, secondaryValue: lightness, colorSpace: .oklch, primaryBends: chromaBends, secondaryBends: lightnessBends)
        }
        let shaderData = encodeSpectrumData(startSections: startSections, endSections: endSections, startHue: startHue, endHue: endHue, primaryValue: chroma, secondaryValue: lightness, colorSpace: .oklch, primaryBends: chromaBends, secondaryBends: lightnessBends)
        return .shader(generator: { size, isVertical in
            ShaderLibrary.bundle(.module).spectrumShader(.float2(size.width, size.height), .float(isVertical ? 1.0 : 0.0), .data(shaderData))
        }, fallback: fallback)
    }
}
