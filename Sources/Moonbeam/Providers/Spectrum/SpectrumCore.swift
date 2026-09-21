import Foundation
import SwiftUI
import simd
import os

import MoonbeamShared

// MARK: - Constants and validation

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

/// Drops bend sections that overlap with previously sections.
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

/// Validates monochrome sections  to prevent shader errors.
internal func validateMonochromeSections(
    _ sections: [MonochromeSection], name: String
) -> [MonochromeSection] {
    let maxSections = Int(MAX_MONOCHROME_SECTIONS)

    precondition(
        sections.count <= maxSections,
        "Moonbeam: \(name) monochrome sections exceeds the maximum of \(maxSections). \(sections.count) monochrome " +
        "sections provided."
    )

    return sections
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
        self.data1 = simd_float4(Float(bend.hueCount), bend.easing == .cubic ? 1.0 : 0.0, 0, 0)
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
    let hueWeight = abs(endHue - startHue)
    let startWeight = startSections.reduce(0) { $0 + $1.weight }
    let endWeight = endSections.reduce(0) { $0 + $1.weight }
    let totalWeight = startWeight + hueWeight + endWeight

    let maxSections = Int(MAX_MONOCHROME_SECTIONS)

    /// Packs two monochrome start sections into a single four-part vector.
    ///
    /// For each section `i` (0 or 1), there are two consecutive floats:
    /// - Index `i * 2`: Multiplexed state combining the section color (0.0 or 1.0)
    ///   and the mathematical easing curve (0.0 or 2.0).
    /// - Index `i * 2 + 1`: The cumulative boundary position on the slider.
    var startData = simd_float4(0, 0, 0, 0)
    var cumulativeStart = 0.0
    for (i, section) in startSections.enumerated() {
        if i >= maxSections { break }
        cumulativeStart += section.weight / totalWeight
        let colorVal: Float = section.color == .white
            ? Float(MonochromeSectionTypeWhite.rawValue)
            : Float(MonochromeSectionTypeBlack.rawValue)
        let easingVal: Float = section.easing == .cubic
            ? Float(EasingTypeCubic.rawValue)
            : Float(EasingTypeLinear.rawValue)
        startData[i*2] = colorVal + easingVal
        startData[i*2 + 1] = Float(cumulativeStart)
    }

    /// Packs two monochrome end sections into a single four-part vector.
    ///
    /// For each section `i` (0 or 1), there are two consecutive floats:
    /// - Index `i * 2`: Multiplexed state combining the section color (0.0 or 1.0)
    ///   and the mathematical easing curve (0.0 or 2.0).
    /// - Index `i * 2 + 1`: The cumulative boundary position on the slider.
    var endData = simd_float4(0, 0, 0, 0)
    var cumulativeEnd = (startWeight + hueWeight) / totalWeight
    for (i, section) in endSections.enumerated() {
        if i >= maxSections { break }
        cumulativeEnd += section.weight / totalWeight
        let colorVal: Float = section.color == .white
            ? Float(MonochromeSectionTypeWhite.rawValue)
            : Float(MonochromeSectionTypeBlack.rawValue)
        let easingVal: Float = section.easing == .cubic
            ? Float(EasingTypeCubic.rawValue)
            : Float(EasingTypeLinear.rawValue)
        endData[i*2] = colorVal + easingVal
        endData[i*2 + 1] = Float(cumulativeEnd)
    }

    let shaderFlag = colorSpace == .oklch
        ? ColorSpaceOKLCH.rawValue
        : ColorSpaceHSB.rawValue

    var shaderData = SpectrumShaderData(
        totalWeight: Float(totalWeight),
        startSectionBoundary: Float(startWeight / totalWeight),
        hueSectionBoundary: Float((startWeight + hueWeight) / totalWeight),
        minimumHue: Float(startHue),
        maximumHue: Float(endHue),
        baseSaturation: Float(primaryValue),
        baseBrightness: Float(secondaryValue),
        colorSpaceFlag: shaderFlag,
        startSectionsCount: UInt32(startSections.count),
        endSectionsCount: UInt32(endSections.count),
        saturationBendsCount: UInt32(primaryBendsCount),
        brightnessBendsCount: UInt32(secondaryBendsCount),
        startSectionsData: startData,
        endSectionsData: endData
    )

    return withUnsafeBytes(of: &shaderData) { Data($0) }
}
