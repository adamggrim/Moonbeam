import Foundation
import SwiftUI
import simd
import os

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

fileprivate let logger = Logger(subsystem: "com.moonbeam", category: "SpectrumModel")

fileprivate func validateBendSections(bendSections: [BendSection]) -> Bool {
    guard bendSections.count > 1 else { return true }
    let sortedBendSections = bendSections.sorted { min($0.startHue, $0.endHue) < min($1.startHue, $1.endHue) }
    for (currentSection, nextSection) in zip(sortedBendSections, sortedBendSections.dropFirst()) {
        if max(currentSection.startHue, currentSection.endHue) > min(nextSection.startHue, nextSection.endHue) {
            return false
        }
    }
    return true
}

/// Validates bend sections, silently truncating any that exceed `spectrumConstants.maxBends` to prevent crashes in Metal.
///
/// - Parameters:
///   - bends: The user-provided array of `BendSection` objects.
///   - name: A descriptive identifier for the `BendSection` objects.
///
/// - Returns: A validated array of bend sections.
fileprivate func validateAndTruncateBends(_ bends: [BendSection], name: String) -> [BendSection] {
    let truncated = Array(bends.prefix(spectrumConstants.maxBends))
    
    #if DEBUG
    if bends.count > spectrumConstants.maxBends {
        logger.warning("Moonbeam: \(name) exceeds maximum limit of \(spectrumConstants.maxBends). Truncated to first \(spectrumConstants.maxBends) bends.")
    }
    if !validateBendSections(bendSections: truncated) {
        logger.warning("Moonbeam: \(name) bend sections overlap.")
    }
    #endif // DEBUG
    
    return truncated
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
    
    // 16 Bytes
    var startSectionsCount: Int32
    var endSectionsCount: Int32
    var saturationBendsCount: Int32
    var brightnessBendsCount: Int32
    
    // 32 Bytes
    var startSectionsData: simd_float4
    var endSectionsData: simd_float4
    
    // 20 bend elements to match `MAX_BENDS`
    typealias BendBuffer = (
        ShaderBend, ShaderBend, ShaderBend, ShaderBend, ShaderBend,
        ShaderBend, ShaderBend, ShaderBend, ShaderBend, ShaderBend,
        ShaderBend, ShaderBend, ShaderBend, ShaderBend, ShaderBend,
        ShaderBend, ShaderBend, ShaderBend, ShaderBend, ShaderBend
    )
    
    var saturationBendsData: BendBuffer
    var brightnessBendsData: BendBuffer
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

    var endData = simd_float4(0, 0, 0, 0)
    var cumulativeEnd = (startWeight + hueWeight) / totalWeight
    for (i, sec) in endSections.enumerated() {
        if i >= spectrumConstants.maxMonochromeSections { break }
        cumulativeEnd += sec.weight / totalWeight
        endData[i*2] = sec.color == .white ? 1.0 : 0.0
        endData[i*2 + 1] = Float(cumulativeEnd)
    }

    // Type-safe tuple packing.
    func packBends(_ bends: [BendSection]) -> SpectrumShaderData.BendBuffer {
        var buffer = [ShaderBend](repeating: ShaderBend(bend: nil), count: 20)
        for i in 0..<min(bends.count, 20) {
            buffer[i] = ShaderBend(bend: bends[i])
        }
        return buffer.withUnsafeBytes { $0.load(as: SpectrumShaderData.BendBuffer.self) }
    }

    var shaderData = SpectrumShaderData(
        totalWeight: Float(totalWeight),
        startSectionBoundary: Float(startWeight / totalWeight),
        hueSectionBoundary: Float((startWeight + hueWeight) / totalWeight),
        minimumHue: Float(startHue),
        maximumHue: Float(endHue),
        baseSaturation: Float(primaryValue),
        baseBrightness: Float(secondaryValue),
        /// A numerical flag passed to the Metal shader to indicate the color space.
        colorSpaceFlag: colorSpace == .oklch ? 1.0 : 0.0,
        startSectionsCount: Int32(startSections.count),
        endSectionsCount: Int32(endSections.count),
        saturationBendsCount: Int32(primaryBends.count),
        brightnessBendsCount: Int32(secondaryBends.count),
        startSectionsData: startData,
        endSectionsData: endData,
        saturationBendsData: packBends(primaryBends),
        brightnessBendsData: packBends(secondaryBends)
    )

    return withUnsafeBytes(of: &shaderData) { Data($0) }
}

// MARK: - Public Models

/// Model for calculating standard HSB spectrum colors dynamically.
public struct HSBSpectrumModel: ColorSliderDataSource {
    public let startSections: [MonochromeSection]
    public let endSections: [MonochromeSection]
    public let startHue: Double
    public let endHue: Double
    public let saturation: Double
    public let brightness: Double
    public let saturationBends: [BendSection]
    public let brightnessBends: [BendSection]
    
    /// Creates a dynamically generated spectrum based on the HSB (Hue, Saturation, Brightness) color space.
    ///
    /// - Parameters:
    ///   - startSections: Monochrome sections that fade into the beginning of the hue spectrum. Capped at `spectrumConstants.maxMonochromeSections`.
    ///   - endSections: Monochrome sections that fade out of the end of the hue spectrum.
    ///   - startHue: The starting hue value in degrees normalized to 0.0 to 1.0 (e.g., 180° = 0.5).
    ///   - endHue: The ending hue value in degrees normalized to 0.0 - 1.0.
    ///   - saturation: The baseline saturation applied to the entire hue range (0.0 to 1.0).
    ///   - brightness: The baseline brightness applied to the entire hue range (0.0 to 1.0).
    ///   - saturationBends: A result builder providing sections where the baseline saturation increases or decreases to a `targetValue`.
    ///   - brightnessBends: A result builder providing sections where the baseline brightness increases or decreases to a `targetValue`.
    public init(
        startSections: [MonochromeSection] = [],
        endSections: [MonochromeSection] = [],
        startHue: Double = 0.0,
        endHue: Double = 1.0,
        saturation: Double = 1.0,
        brightness: Double = 1.0,
        @BendSectionBuilder saturationBends: () -> [BendSection] = { [] },
        @BendSectionBuilder brightnessBends: () -> [BendSection] = { [] }
    ) {
        self.startSections = Array(startSections.prefix(spectrumConstants.maxMonochromeSections))
        self.endSections = Array(endSections.prefix(spectrumConstants.maxMonochromeSections))
        self.startHue = startHue
        self.endHue = endHue
        self.saturation = saturation
        self.brightness = brightness
        self.saturationBends = validateAndTruncateBends(saturationBends(), name: "HSB Saturation")
        self.brightnessBends = validateAndTruncateBends(brightnessBends(), name: "HSB Brightness")
    }

    public var colorSource: ColorSourceProvider {
        let fallback: (Double) -> Color = { position in
            SpectrumGenerator.color(at: position, startSections: startSections, endSections: endSections, startHue: startHue, endHue: endHue, primaryValue: saturation, secondaryValue: brightness, colorSpace: .hsb, primaryBends: saturationBends, secondaryBends: brightnessBends)
        }
        let shaderData = encodeSpectrumData(startSections: startSections, endSections: endSections, startHue: startHue, endHue: endHue, primaryValue: saturation, secondaryValue: brightness, colorSpace: .hsb, primaryBends: saturationBends, secondaryBends: brightnessBends)
        return .shader(generator: { size, isVertical in
            ShaderLibrary.bundle(.module).spectrumShader(.float2(size.width, size.height), .float(isVertical ? 1.0 : 0.0), .data(shaderData))
        }, fallback: fallback)
    }
}

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
