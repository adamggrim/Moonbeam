import SwiftUI
import MoonbeamShared

// MARK: - Enums and protocols

/// The color space used to generate the spectrum.
public enum SpectrumColorSpace: Sendable {
    case hsb, oklch
}

/// A protocol defining a color space profile for a spectrum slider.
public protocol SpectrumColorSpaceProfile: Sendable {
    /// The color space identifier.
    static var colorSpace: SpectrumColorSpace { get }
    /// The descriptive name of the color space used for telemetry and
    /// validation.
    static var name: String { get }
}

/// The HSB (Hue, Saturation, Brightness) color space profile.
public enum HSB: SpectrumColorSpaceProfile {
    public static let colorSpace: SpectrumColorSpace = .hsb
    public static let name = "HSB"
}

/// The OKLCH (Lightness, Chroma, Hue) color space profile.
public enum OKLCH: SpectrumColorSpaceProfile {
    public static let colorSpace: SpectrumColorSpace = .oklch
    public static let name = "OKLCH"
}

// MARK: - Generic base struct

/// A unified color provider for dynamically calculating spectrum colors.
public struct Spectrum<ColorSpace: SpectrumColorSpaceProfile>: ColorProvider {
    let startSections: [MonochromeSection]
    let endSections: [MonochromeSection]
    let startHue: Double
    let endHue: Double
    let primaryValue: Double
    let secondaryValue: Double
    let primaryBends: [BendSection]
    let secondaryBends: [BendSection]
    public let colorSource: ColorSource

    public func accessibilityColorName(for value: Double) -> String? {
        let configuration = SpectrumConfiguration(
            colorSpace: ColorSpace.colorSpace,
            startSections: startSections,
            endSections: endSections,
            startHue: startHue,
            endHue: endHue,
            primaryValue: primaryValue,
            secondaryValue: secondaryValue,
            primaryBends: primaryBends,
            secondaryBends: secondaryBends
        )

        guard let comps = SpectrumGenerator.components(
            at: value,
            configuration: configuration
        ) else { return nil }

        return SpectrumNameResolver.name(
            hue: comps.hue,
            primary: comps.primary,
            secondary: comps.secondary,
            colorSpace: ColorSpace.colorSpace,
            strings: SpectrumAccessibilityStrings()
        )
    }

    internal init(
        startSections: [MonochromeSection],
        endSections: [MonochromeSection],
        startHue: Double,
        endHue: Double,
        primaryValue: Double,
        secondaryValue: Double,
        primaryBends: [BendSection],
        secondaryBends: [BendSection],
        primaryName: String,
        secondaryName: String
    ) {
        let validStart = validateMonochromeSections(startSections, name: "\(ColorSpace.name) Start")
        let validEnd = validateMonochromeSections(endSections, name: "\(ColorSpace.name) End")
        let validPrimaryBends = validateBends(primaryBends, name: "\(ColorSpace.name) \(primaryName)")
        let validSecondaryBends = validateBends(secondaryBends, name: "\(ColorSpace.name) \(secondaryName)")

        self.startSections = validStart
        self.endSections = validEnd
        self.startHue = startHue
        self.endHue = endHue
        self.primaryValue = primaryValue
        self.secondaryValue = secondaryValue
        self.primaryBends = validPrimaryBends
        self.secondaryBends = validSecondaryBends

        let configuration = SpectrumConfiguration(
            colorSpace: ColorSpace.colorSpace,
            startSections: validStart,
            endSections: validEnd,
            startHue: startHue,
            endHue: endHue,
            primaryValue: primaryValue,
            secondaryValue: secondaryValue,
            primaryBends: validPrimaryBends,
            secondaryBends: validSecondaryBends
        )

        let fallback: @Sendable (Double) -> Color = { position in
            SpectrumGenerator.color(
                at: position,
                configuration: configuration
            )
        }

        let shaderData = encodeSpectrumData(
            colorSpace: ColorSpace.colorSpace,
            startSections: validStart,
            endSections: validEnd,
            startHue: startHue,
            endHue: endHue,
            primaryValue: primaryValue,
            secondaryValue: secondaryValue,
            primaryBendsCount: validPrimaryBends.count,
            secondaryBendsCount: validSecondaryBends.count
        )

        let primaryBendsMapped = validPrimaryBends.map { ShaderBend(bend: $0) }
        let nonEmptyPrimaryBends = primaryBendsMapped.isEmpty ? [ShaderBend.empty] : primaryBendsMapped
        let primaryBendsData = nonEmptyPrimaryBends.withUnsafeBufferPointer { Data(buffer: $0) }

        let secondaryBendsMapped = validSecondaryBends.map { ShaderBend(bend: $0) }
        let nonEmptySecondaryBends = secondaryBendsMapped.isEmpty ? [ShaderBend.empty] : secondaryBendsMapped
        let secondaryBendsData = nonEmptySecondaryBends.withUnsafeBufferPointer { Data(buffer: $0) }

        self.colorSource = .shader(generator: { size, isVertical in
            ShaderLibrary.bundle(.module)
                .spectrumShader(
                    .float2(size.width, size.height),
                    .float(isVertical ? 1.0 : 0.0),
                    .data(shaderData),
                    .data(primaryBendsData),
                    .data(secondaryBendsData)
                )
        }, fallback: fallback)
    }
}

// MARK: - HSB initialization

public extension Spectrum where ColorSpace == HSB {
    /// Creates a dynamically generated spectrum based on the HSB (Hue,
    /// Saturation, Brightness) color space.
    ///
    /// - Parameters:
    ///   - startSections: Monochrome sections that fade into the beginning of
    ///     the hue spectrum. Capped at `MAX_MONOCHROME_SECTIONS`.
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
    ///     baseline saturation increases or decreases to `targetValue`.
    ///   - brightnessBends: A result builder providing sections where the
    ///     baseline brightness increases or decreases to `targetValue`.
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
        self.init(
            startSections: startSections,
            endSections: endSections,
            startHue: startHue,
            endHue: endHue,
            primaryValue: saturation,
            secondaryValue: brightness,
            primaryBends: saturationBends(),
            secondaryBends: brightnessBends(),
            primaryName: "Saturation",
            secondaryName: "Brightness"
        )
    }
}

// MARK: - OKLCH initialization

public extension Spectrum where ColorSpace == OKLCH {
    /// Creates a dynamically generated spectrum based on the perceptually
    /// uniform OKLCH color space.
    ///
    /// - Parameters:
    ///   - startSections: Monochrome sections that fade into the beginning of
    ///     the hue spectrum. Capped at `MAX_MONOCHROME_SECTIONS`.
    ///   - endSections: Monochrome sections that fade out of the end of the hue
    ///     spectrum.
    ///   - lightness: The perceived brightness of the color. Standard range is
    ///     0.0 to 1.0. Defaults to 0.75.
    ///   - chroma: The intensity of the color. Range depends on the device
    ///     gamut, typically 0.0 to 0.4. Defaults to 0.15.
    ///   - startHue: The starting hue, normalized to 0.0 through 1.0.
    ///   - endHue: The ending hue, normalized to 0.0 through 1.0.
    ///   - lightnessBends: Sections where the baseline lightness bends toward
    ///     `targetValue`.
    ///   - chromaBends: Sections where the baseline chroma bends toward
    ///     `targetValue`.
    init(
        startSections: [MonochromeSection] = [],
        endSections: [MonochromeSection] = [],
        lightness: Double = 0.75,
        chroma: Double = 0.15,
        startHue: Double = 0.0,
        endHue: Double = 1.0,
        @BendSectionBuilder lightnessBends: () -> [BendSection] = { [] },
        @BendSectionBuilder chromaBends: () -> [BendSection] = { [] }
    ) {
        self.init(
            startSections: startSections,
            endSections: endSections,
            startHue: startHue,
            endHue: endHue,
            primaryValue: chroma,
            secondaryValue: lightness,
            primaryBends: chromaBends(),
            secondaryBends: lightnessBends(),
            primaryName: "Chroma",
            secondaryName: "Lightness"
        )
    }
}
