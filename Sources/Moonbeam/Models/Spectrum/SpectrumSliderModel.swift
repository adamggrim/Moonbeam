import Foundation
import SwiftUI
import simd
import os

import MoonbeamShared

/// The color space used to generate the spectrum.
public enum SpectrumColorSpace: Sendable {
    case hsb, oklch
}

// MARK: - Constants and validation

fileprivate let logger = Logger(subsystem: "com.moonbeam", category: "SpectrumModel")

/// A lightweight wrapper for telemetry and non-fatal production logging.
internal enum MoonbeamTelemetry {
    static func reportNonFatalIssue(_ message: String) {
        logger.error("Moonbeam configuration error: \(message, privacy: .public)")
    }
}

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

/// Validates bend sections.
///
/// - Parameters:
///   - bends: The user-provided array of `BendSection` objects.
///   - name: A descriptive identifier for the `BendSection` objects.
///
/// - Returns: A validated array of bend sections.
fileprivate func validateBends(_ bends: [BendSection], name: String) -> [BendSection] {
    var validBends: [BendSection] = []

    for bend in bends {
        let minBend = min(bend.startHue, bend.endHue)
        let maxBend = max(bend.startHue, bend.endHue)

        let hasOverlap = validBends.contains { existing in
            max(existing.startHue, existing.endHue) > minBend && min(existing.startHue, existing.endHue) < maxBend
        }

        if !hasOverlap {
            validBends.append(bend)
        } else {
            MoonbeamTelemetry.reportNonFatalIssue(
                "Moonbeam: \(name) contains overlapping bend sections. Bend sections after the first will not appear."
            )
        }
    }
    return validBends
}

/// Validates monochrome sections  to prevent shader errors.
fileprivate func validateMonochromeSections(
    _ sections: [MonochromeSection], name: String
) -> [MonochromeSection] {
    let maxSections = Int(MAX_MONOCHROME_SECTIONS)

    precondition(
        sections.count <= maxSections,
        "Moonbeam: \(name) monochrome sections exceed the maximum of \(maxSections). You provided \(sections.count)."
    )

    return sections
}

// MARK: - Metal data structures

/// Adds an initializer to the C-bridged `ShaderBend` struct to map Swift `BendSection` properties.
extension ShaderBend {
    init(bend: BendSection) {
        self.init()
        self.data0 = simd_float4(
            bend is OneWayBend ? Float(MoonbeamBendTypeOneWay.rawValue) : Float(MoonbeamBendTypeTwoWay.rawValue),
            Float(bend.startHue),
            Float(bend.endHue),
            Float(bend.targetValue)
        )
        self.data1 = simd_float4(Float(bend.hueCount), 0, 0, 0)
    }

    static let empty = ShaderBend(data0: .zero, data1: .zero)
}

fileprivate func encodeSpectrumData(
    startSections: [MonochromeSection], endSections: [MonochromeSection],
    startHue: Double, endHue: Double, primaryValue: Double, secondaryValue: Double,
    colorSpace: SpectrumColorSpace, primaryBendsCount: Int, secondaryBendsCount: Int
) -> Data {
    let hueWeight = abs(endHue - startHue)
    let startWeight = startSections.reduce(0) { $0 + $1.weight }
    let endWeight = endSections.reduce(0) { $0 + $1.weight }
    let totalWeight = startWeight + hueWeight + endWeight

    let maxSections = Int(MAX_MONOCHROME_SECTIONS)

    var startData = simd_float4(0, 0, 0, 0)
    var cumulativeStart = 0.0
    for (i, section) in startSections.enumerated() {
        if i >= maxSections { break }
        cumulativeStart += section.weight / totalWeight
        startData[i*2] = section.color == .white ? 1.0 : 0.0
        startData[i*2 + 1] = Float(cumulativeStart)
    }

    var endData = simd_float4(0, 0, 0, 0)
    var cumulativeEnd = (startWeight + hueWeight) / totalWeight
    for (i, section) in endSections.enumerated() {
        if i >= maxSections { break }
        cumulativeEnd += section.weight / totalWeight
        endData[i*2] = section.color == .white ? 1.0 : 0.0
        endData[i*2 + 1] = Float(cumulativeEnd)
    }

    var shaderData = SpectrumShaderData(
        totalWeight: Float(totalWeight),
        startSectionBoundary: Float(startWeight / totalWeight),
        hueSectionBoundary: Float((startWeight + hueWeight) / totalWeight),
        minimumHue: Float(startHue),
        maximumHue: Float(endHue),
        baseSaturation: Float(primaryValue),
        baseBrightness: Float(secondaryValue),
        colorSpaceFlag: colorSpace == .oklch ? MoonbeamColorSpaceOKLCH.rawValue : MoonbeamColorSpaceHSB.rawValue,
        startSectionsCount: UInt32(startSections.count),
        endSectionsCount: UInt32(endSections.count),
        saturationBendsCount: UInt32(primaryBendsCount),
        brightnessBendsCount: UInt32(secondaryBendsCount),
        startSectionsData: startData,
        endSectionsData: endData
    )

    return withUnsafeBytes(of: &shaderData) { Data($0) }
}

// MARK: - Internal models

/// Model for calculating standard HSB spectrum colors dynamically.
internal struct HSBSpectrumModel: ColorSliderDataSource, Sendable {
    let startSections: [MonochromeSection]
    let endSections: [MonochromeSection]
    let startHue: Double
    let endHue: Double
    let saturation: Double
    let brightness: Double
    let saturationBends: [BendSection]
    let brightnessBends: [BendSection]
    let colorSource: ColorSourceProvider

    /// Creates a dynamically generated spectrum based on the HSB (Hue,
    /// Saturation, Brightness) color space.
    ///
    /// - Parameters:
    ///   - startSections: Monochrome sections that fade into the
    ///     beginning of the hue spectrum. Capped at `MAX_MONOCHROME_SECTIONS`.
    ///   - endSections: Monochrome sections that fade out of the end of the hue
    ///     spectrum.
    ///   - startHue: The starting hue value in degrees normalized to 0.0 to 1.0
    ///     (e.g., 180° = 0.5).
    ///   - endHue: The ending hue value in degrees normalized to 0.0 - 1.0.
    ///   - saturation: The baseline saturation applied to the entire hue range
    ///     (0.0 to 1.0).
    ///   - brightness: The baseline brightness applied to the entire hue range
    ///     (0.0 to 1.0).
    ///   - saturationBends: A result builder providing sections where the
    ///     baseline saturation increases or decreases to a `targetValue`.
    ///   - brightnessBends: A result builder providing sections where the
    ///     baseline brightness increases or decreases to a `targetValue`.
    init(
        startSections: [MonochromeSection] = [],
        endSections: [MonochromeSection] = [],
        startHue: Double = 0.0,
        endHue: Double = 1.0,
        saturation: Double = 1.0,
        brightness: Double = 1.0,
        @BendSectionBuilder saturationBends: () -> [BendSection] = { [] },
        @BendSectionBuilder brightnessBends: () -> [BendSection] = { [] }
    ) {
        let validStart = validateMonochromeSections(startSections, name: "HSB Start")
        let validEnd = validateMonochromeSections(endSections, name: "HSB End")
        let validSaturationBends = validateBends(saturationBends(), name: "HSB Saturation")
        let validBrightnessBends = validateBends(brightnessBends(), name: "HSB Brightness")

        self.startSections = validStart
        self.endSections = validEnd
        self.startHue = startHue
        self.endHue = endHue
        self.saturation = saturation
        self.brightness = brightness
        self.saturationBends = validSaturationBends
        self.brightnessBends = validBrightnessBends

        let fallback: @Sendable (Double) -> Color = { position in
            SpectrumGenerator.color(
                at: position,
                startSections: validStart,
                endSections: validEnd,
                startHue: startHue,
                endHue: endHue,
                primaryValue: saturation,
                secondaryValue: brightness,
                colorSpace: .hsb,
                primaryBends: validSaturationBends,
                secondaryBends: validBrightnessBends
            )
        }
        let shaderData = encodeSpectrumData(
            startSections: validStart,
            endSections: validEnd,
            startHue: startHue,
            endHue: endHue,
            primaryValue: saturation,
            secondaryValue: brightness,
            colorSpace: .hsb,
            primaryBendsCount: validSaturationBends.count,
            secondaryBendsCount: validBrightnessBends.count
        )

        let saturationBendsMapped = validSaturationBends.map { ShaderBend(bend: $0) }
        let nonEmptySaturationBends = saturationBendsMapped.isEmpty ? [ShaderBend.empty] : saturationBendsMapped
        let saturationBendsData = nonEmptySaturationBends.withUnsafeBufferPointer { Data(buffer: $0) }

        let brightnessBendsMapped = validBrightnessBends.map { ShaderBend(bend: $0) }
        let nonEmptyBrightnessBends = brightnessBendsMapped.isEmpty ? [ShaderBend.empty] : brightnessBendsMapped
        let brightnessBendsData = nonEmptyBrightnessBends.withUnsafeBufferPointer { Data(buffer: $0) }

        self.colorSource = .shader(generator: { size, isVertical in
            ShaderLibrary.bundle(.module)
                .spectrumShader(
                    .float2(size.width, size.height),
                    .float(isVertical ? 1.0 : 0.0),
                    .data(shaderData),
                    .data(saturationBendsData),
                    .data(brightnessBendsData)
                )
        }, fallback: fallback)
    }
}

/// Model for calculating perceptually uniform OKLCH spectrum colors dynamically.
public struct OKLCHSpectrumModel: ColorSliderDataSource, Sendable {
    public let startSections: [MonochromeSection]
    public let endSections: [MonochromeSection]
    public let lightness: Double
    public let chroma: Double
    public let startHue: Double
    public let endHue: Double
    public let lightnessBends: [BendSection]
    public let chromaBends: [BendSection]
    let colorSource: ColorSourceProvider

    /// Creates a dynamically generated spectrum based on the perceptually
    /// uniform OKLCH color space.
    ///
    /// - Parameters:
    ///   - startSections: Monochrome sections that fade into the beginning of
    ///     the hue spectrum. Capped at
    ///     `MAX_MONOCHROME_SECTIONS`.
    ///   - endSections: Monochrome sections that fade out of the end of the hue
    ///     spectrum.
    ///   - lightness: The perceived brightness of the color. Standard range is
    ///     0.0 to 1.0. Defaults to 0.75.
    ///   - chroma: The intensity of the color. Range depends on the device
    ///     gamut, typically 0.0 to 0.4. Defaults to 0.15.
    ///   - startHue: The starting hue, normalized to 0.0 through 1.0.
    ///   - endHue: The ending hue, normalized to 0.0 through 1.0.
    ///   - lightnessBends: Sections where the baseline lightness bends toward
    ///     a target value.
    ///   - chromaBends: Sections where the baseline chroma bends toward a
    ///     target value.
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
        let validStart = validateMonochromeSections(startSections, name: "OKLCH Start")
        let validEnd = validateMonochromeSections(endSections, name: "OKLCH End")
        let validLightnessBends = validateBends(lightnessBends(), name: "OKLCH Lightness")
        let validChromaBends = validateBends(chromaBends(), name: "OKLCH Chroma")

        self.startSections = validStart
        self.endSections = validEnd
        self.lightness = lightness
        self.chroma = chroma
        self.startHue = startHue
        self.endHue = endHue
        self.lightnessBends = validLightnessBends
        self.chromaBends = validChromaBends

        let fallback: @Sendable (Double) -> Color = { position in
            SpectrumGenerator.color(
                at: position,
                startSections: validStart,
                endSections: validEnd,
                startHue: startHue,
                endHue: endHue,
                primaryValue: chroma,
                secondaryValue: lightness,
                colorSpace: .oklch,
                primaryBends: validChromaBends,
                secondaryBends: validLightnessBends
            )
        }
        let shaderData = encodeSpectrumData(
            startSections: validStart,
            endSections: validEnd,
            startHue: startHue,
            endHue: endHue,
            primaryValue: chroma,
            secondaryValue: lightness,
            colorSpace: .oklch,
            primaryBendsCount: validChromaBends.count,
            secondaryBendsCount: validLightnessBends.count
        )

        let chromaBendsMapped = validChromaBends.map { ShaderBend(bend: $0) }
        let nonEmptyChromaBends = chromaBendsMapped.isEmpty ? [ShaderBend.empty] : chromaBendsMapped
        let chromaBendsData = nonEmptyChromaBends.withUnsafeBufferPointer { Data(buffer: $0) }

        let lightnessBendsMapped = validLightnessBends.map { ShaderBend(bend: $0) }
        let nonEmptyLightnessBends = lightnessBendsMapped.isEmpty ? [ShaderBend.empty] : lightnessBendsMapped
        let lightnessBendsData = nonEmptyLightnessBends.withUnsafeBufferPointer { Data(buffer: $0) }

        self.colorSource = .shader(generator: { size, isVertical in
            ShaderLibrary.bundle(.module)
                .spectrumShader(
                    .float2(size.width, size.height),
                    .float(isVertical ? 1.0 : 0.0),
                    .data(shaderData),
                    .data(chromaBendsData),
                    .data(lightnessBendsData)
                )
        }, fallback: fallback)
    }
}
