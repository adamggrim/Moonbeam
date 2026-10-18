import Foundation
import SwiftUI
import simd

import MoonbeamShared

// MARK: - Validation

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
    var validStart = startSections.filter { $0.fraction > 0.0 }
    var validEnd = endSections.filter { $0.fraction > 0.0 }

    let startSum = validStart.reduce(0) { $0 + $1.fraction }
    let endSum = validEnd.reduce(0) { $0 + $1.fraction }
    let totalFraction = startSum + endSum

    if totalFraction > 1.0 {
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

extension ShaderMonochromeSection {
    static let empty = ShaderMonochromeSection(isWhite: 0, endPosition: 0)
}

internal func encodeMonochromeSections(
    _ sections: [MonochromeSection],
    startingAt initialPosition: Double
) -> Data {
    guard !sections.isEmpty else {
        return [ShaderMonochromeSection.empty].withUnsafeBufferPointer { Data(buffer: $0) }
    }

    var cumulativePosition = initialPosition
    let mapped = sections.map { section -> ShaderMonochromeSection in
        cumulativePosition += section.fraction
        let colorVal: Float = section.color == .white
            ? Float(MonochromeSectionTypeWhite.rawValue)
            : Float(MonochromeSectionTypeBlack.rawValue)
        return ShaderMonochromeSection(
            isWhite: colorVal,
            endPosition: Float(cumulativePosition)
        )
    }
    return mapped.withUnsafeBufferPointer { Data(buffer: $0) }
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

    let shaderFlag = colorSpace == .oklch
        ? ColorSpaceOklch.rawValue
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
        brightnessBendsCount: UInt32(secondaryBendsCount)
    )

    return withUnsafeBytes(of: &shaderData) { Data($0) }
}
