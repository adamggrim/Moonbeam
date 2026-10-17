import Foundation
import SwiftUI
import simd
import os

import MoonbeamShared

// MARK: - Validation

fileprivate let logger = Logger(subsystem: "com.moonbeam", category: "Spectrum")

/// Determines if an array of bend sections contains any overlapping sections.
///
/// - Parameter bendSections: An array of `BendSection` objects.
/// - Returns: `true` if all sections occupy distinct hue ranges, otherwise
///   `false`.
internal func validateBendSections(bendSections: [BendSection]) -> Bool {
    guard bendSections.count > 1 else { return true }
    let sortedBendSections = bendSections.sorted { min($0.startHue, $0.endHue) < min($1.startHue, $1.endHue) }
    for (currentSection, nextSection) in zip(sortedBendSections, sortedBendSections.dropFirst()) {
        if max(currentSection.startHue, currentSection.endHue) > min(nextSection.startHue, nextSection.endHue) {
            return false
        }
    }
    return true
}

/// Drops bend sections that overlap with another bend section.
///
/// - Parameters:
///   - bends: The user-provided array of `BendSection` objects.
///   - name: A descriptive identifier (e.g., "HSB Saturation") used to format
///     the telemetry error message.
///
/// - Returns: The sanitized array of bend sections.
internal func validateBends(_ bends: [BendSection], name: String) -> [BendSection] {
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
            Telemetry.reportNonFatalError(
                "Moonbeam: \(name) contains overlapping bend sections. Bend sections after the first will not appear."
            )
        }
    }
    return validBends
}

/// Validates monochrome sections to prevent shader errors.
internal func validateMonochromeSections(
    startSections: [MonochromeSection],
    endSections: [MonochromeSection],
    name: String
) -> (start: [MonochromeSection], end: [MonochromeSection]) {
    let maxSections = Int(MAX_MONOCHROME_SECTIONS)

    var validStart = Array(startSections.prefix(maxSections))
    var validEnd = Array(endSections.prefix(maxSections))

    let startSum = validStart.reduce(0) { $0 + $1.fraction }
    let endSum = validEnd.reduce(0) { $0 + $1.fraction }
    let totalFraction = startSum + endSum

    if totalFraction >= 1.0 {
        Telemetry.reportNonFatalError(
            "Moonbeam: \(name) monochrome sections total fraction (\(totalFraction)) exceeds 1.0. Sections scaled to "
            + "fit."
        )
        let scale = 1.0 / totalFraction

        validStart = validStart.map { section in
            let newFraction = section.fraction * scale
            return section.color == .black
                ? BlackSection(fraction: newFraction)
                : WhiteSection(fraction: newFraction) as MonochromeSection
        }

        validEnd = validEnd.map { section in
            let newFraction = section.fraction * scale
            return section.color == .black
                ? BlackSection(fraction: newFraction)
                : WhiteSection(fraction: newFraction) as MonochromeSection
        }
    }

    return (validStart, validEnd)
}

// MARK: - Metal data bridging

/// Adds an initializer to the C-bridged `ShaderBend` struct to map Swift
/// `BendSection` properties.
extension ShaderBend {
    init(bend: BendSection) {
        self.init()
        self.data0 = simd_float4(
            bend is OneWayBend ? Float(BendTypeOneWay.rawValue) : Float(MoonbeamBendTypeTwoWay.rawValue),
            Float(bend.startHue),
            Float(bend.endHue),
            Float(bend.targetValue)
        )
        self.data1 = simd_float4(Float(bend.hueCount), 0, 0, 0)
    }

    static let empty = ShaderBend(data0: .zero, data1: .zero)
}

internal func encodeSpectrumData(
    colorSpace: SpectrumColorSpace,
    startSections: [MonochromeSection],
    endSections: [MonochromeSection],
    startHue: Double,
    endHue: Double,
    primaryValue: Double,
    secondaryValue: Double,
    primaryBendsCount: Int,
    secondaryBendsCount: Int
) -> Data {
    let startFraction = startSections.reduce(0) { $0 + $1.fraction }
    let endFraction = endSections.reduce(0) { $0 + $1.fraction }

    let maxSections = Int(MAX_MONOCHROME_SECTIONS)

    /// Packs two monochrome start sections into a single four-part vector.
    ///
    /// For each section `i` (0 or 1), there are two consecutive floats:
    /// - Index `i * 2`: The section color (0.0 for black, 1.0 for white).
    /// - Index `i * 2 + 1`: The cumulative boundary position on the slider.
    var startData = simd_float4(0, 0, 0, 0)
    var cumulativeStart = 0.0
    for (i, section) in startSections.enumerated() {
        if i >= maxSections { break }
        cumulativeStart += section.fraction
        let colorVal: Float = section.color == .white
            ? Float(MonochromeSectionTypeWhite.rawValue)
            : Float(MonochromeSectionTypeBlack.rawValue)
        startData[i*2] = colorVal
        startData[i*2 + 1] = Float(cumulativeStart)
    }

    /// Packs two monochrome end sections into a single four-part vector.
    ///
    /// For each section `i` (0 or 1), there are two consecutive floats:
    /// - Index `i * 2`: The section color (0.0 for black, 1.0 for white).
    /// - Index `i * 2 + 1`: The cumulative boundary position on the slider.
    var endData = simd_float4(0, 0, 0, 0)
    var cumulativeEnd = 1.0 - endFraction
    for (i, section) in endSections.enumerated() {
        if i >= maxSections { break }
        cumulativeEnd += section.fraction
        let colorVal: Float = section.color == .white
            ? Float(MonochromeSectionTypeWhite.rawValue)
            : Float(MonochromeSectionTypeBlack.rawValue)
        endData[i*2] = colorVal
        endData[i*2 + 1] = Float(cumulativeEnd)
    }

    let shaderFlag = colorSpace == .oklch
        ? ColorSpaceOKLCH.rawValue
        : ColorSpaceHSB.rawValue

    var shaderData = SpectrumShaderData(
        startSectionBoundary: Float(startFraction),
        hueSectionBoundary: Float(1.0 - endFraction),
        minimumHue: Float(startHue),
        maximumHue: Float(endHue),
        baseSaturation: Float(primaryValue),
        baseBrightness: Float(secondaryValue),
        colorSpaceFlag: shaderFlag,
        startSectionsCount: UInt32(startSections.count),
        endSectionsCount: UInt32(endSections.count),
        saturationBendsCount: UInt32(primaryBendsCount),
        brightnessBendsCount: UInt32(secondaryBendsCount),
        padding: 0,
        startSectionsData: startData,
        endSectionsData: endData
    )

    return withUnsafeBytes(of: &shaderData) { Data($0) }
}
