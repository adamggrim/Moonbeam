import Foundation

// MARK: - Core Protocols

/// A baseline protocol representing any structural block within a spectrum slider.
public protocol SliderComponent {}

/// Represents the lightest and darkest endpoints of a spectrum.
public enum MonochromeColor {
    case black, white
}

/// Section of the color slider that fades to or from a monochrome color.
public protocol MonochromeSection: SliderComponent {
    var color: MonochromeColor { get }

    /// The number of monochrome steps added to the hue section (each equal in width to a single hue).
    var weight: CGFloat { get }
}

/// Provides shared default values shared across all monochrome sections.
public extension MonochromeSection {
    /// The default proportionate width of a monochrome step (1/6th of a standard hue).
    static var defaultWeight: CGFloat { 1.0 / 6.0 }
}

/// A protocol for a section of the color slider with special conditions for saturation or brightness.
public protocol BendSection {
    var startHue: CGFloat { get }
    var endHue: CGFloat { get }
    var targetValue: CGFloat { get }
    var hueCount: CGFloat { get }
}

// MARK: - Monochrome Sections

/// A spectrum section that resolves to pure black.
public struct BlackSection: MonochromeSection {
    public let color: MonochromeColor = .black
    public let weight: CGFloat

    /// Initializes a black section.
    ///   - Parameter weight: The proportionate width of the section relative to a single hue.
    public init(weight: CGFloat = Self.defaultWeight) {
        self.weight = weight
    }
}

public struct WhiteSection: MonochromeSection {
    public let color: MonochromeColor = .white
    public let weight: CGFloat

    /// Initializes a white section.
    /// - Parameter weight: The proportionate width of the section relative to a single hue.
    public init(weight: CGFloat = Self.defaultWeight) {
        self.weight = weight
    }
}

// MARK: - Hue Section
/// The core component representing the colorful spectrum of the slider.
public struct HueSection: SliderComponent {
    public static let maxBends = 20

    public let minHue: CGFloat
    public let maxHue: CGFloat
    public let colorSpace: SpectrumColorSpace
    public let weight: CGFloat

    let primaryValue: CGFloat   // Holds Saturation (HSB) OR Chroma (OKLCH).
    let secondaryValue: CGFloat // Holds Brightness (HSB) OR Lightness (OKLCH).
    let primaryBends: [BendSection]?
    let secondaryBends: [BendSection]?

    // MARK: HSB Initializer
    public init(
        minHue: CGFloat,
        maxHue: CGFloat,
        baseSaturation: CGFloat = 1.0,
        baseBrightness: CGFloat = 1.0,
        @BendSectionBuilder saturationBends: () -> [BendSection] = { [] },
        @BendSectionBuilder brightnessBends: () -> [BendSection] = { [] }
    ) {
        self.colorSpace = .hsb
        self.minHue = minHue
        self.maxHue = maxHue
        self.primaryValue = baseSaturation
        self.secondaryValue = baseBrightness
        
        let evaluatedSaturationBends = saturationBends()
        let evaluatedBrightnessBends = brightnessBends()
        self.primaryBends = evaluatedSaturationBends.isEmpty ? nil : evaluatedSaturationBends
        self.secondaryBends = evaluatedBrightnessBends.isEmpty ? nil : evaluatedBrightnessBends
        self.weight = maxHue - minHue
    }

    // MARK: OKLCH Initializer
    public init(
        oklchMinHue minHue: CGFloat,
        maxHue: CGFloat,
        chroma: CGFloat = 0.15,
        lightness: CGFloat = 0.70,
        @BendSectionBuilder chromaBends: () -> [BendSection] = { [] },
        @BendSectionBuilder lightnessBends: () -> [BendSection] = { [] }
    ) {
        self.colorSpace = .oklch
        self.minHue = minHue
        self.maxHue = maxHue
        self.primaryValue = chroma
        self.secondaryValue = lightness
        
        let evaluatedChromaBends = chromaBends()
        let evaluatedLightnessBends = lightnessBends()
        self.primaryBends = evaluatedChromaBends.isEmpty ? nil : evaluatedChromaBends
        self.secondaryBends = evaluatedLightnessBends.isEmpty ? nil : evaluatedLightnessBends
        self.weight = maxHue - minHue
    }
    
    // Internal initializer used by the model compiler.
    internal init(minHue: CGFloat, maxHue: CGFloat, colorSpace: SpectrumColorSpace, primaryValue: CGFloat, secondaryValue: CGFloat, primaryBends: [BendSection]?, secondaryBends: [BendSection]?) {
        self.minHue = minHue
        self.maxHue = maxHue
        self.colorSpace = colorSpace
        self.primaryValue = primaryValue
        self.secondaryValue = secondaryValue
        self.primaryBends = primaryBends
        self.secondaryBends = secondaryBends
        self.weight = maxHue - minHue
    }
}

// MARK: - Bend Sections
/// A bend section that fades into the start or end of a color slider.
public struct OneWayBend: BendSection {
    public let startHue: CGFloat
    public let endHue: CGFloat
    public let targetValue: CGFloat
    public let hueCount: CGFloat

    public init(hue range: ClosedRange<CGFloat>, target: CGFloat) {
        self.startHue = range.lowerBound
        self.endHue = range.upperBound
        self.targetValue = target
        self.hueCount = range.upperBound - range.lowerBound
    }
}

/// A bend section that occurs in the middle of a color slider.
public struct TwoWayBend: BendSection {
    public let startHue: CGFloat
    public let endHue: CGFloat
    public let targetValue: CGFloat
    public let hueCount: CGFloat
    public let middleHue: CGFloat

    public init(hue range: ClosedRange<CGFloat>, target: CGFloat) {
        self.startHue = range.lowerBound
        self.endHue = range.upperBound
        self.targetValue = target
        self.hueCount = range.upperBound - range.lowerBound
        self.middleHue = (self.startHue + self.hueCount) / 2
    }
}
