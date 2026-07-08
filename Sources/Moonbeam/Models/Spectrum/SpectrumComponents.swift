import Foundation

// MARK: - Core protocols

/// Represents the lightest and darkest endpoints of a spectrum.
public enum MonochromeColor {
    case black, white
}

/// Section of the color slider that fades to or from a monochrome color.
public protocol MonochromeSection {
    /// The color of a `MonochromeSection`, either `.black` or `.white`.
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
    /// The starting hue of the bend section, normalized from 0.0 to 1.0.
    var startHue: CGFloat { get }

    /// The ending hue of the bend section, normalized from 0.0 to 1.0.
    var endHue: CGFloat { get }

    /// The saturation, brightness, lightness or chroma value where the bend peaks.
    var targetValue: CGFloat { get }

    /// The difference between the start and end hues.
    var hueCount: CGFloat { get }
}

public extension BendSection {
    /// Helper to calculate the shortest distance between two hues in a wraparound (circular) hue range.
    static func calculateHueCount(start: CGFloat, end: CGFloat) -> CGFloat {
        let diff = abs(end - start)
        return diff > 0.5 ? 1.0 - diff : diff
    }
}

// MARK: - Monochrome sections

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

// MARK: - Bend sections

/// A bend section that fades into the start or end of a color slider.
public struct OneWayBend: BendSection {
    /// The starting hue of the bend section, normalized from 0.0 to 1.0.
    public let startHue: CGFloat

    /// The ending hue of the bend section, normalized from 0.0 to 1.0.
    public let endHue: CGFloat

    /// The saturation, brightness, lightness or chroma value where the bend peaks.
    public let targetValue: CGFloat

    /// The difference between the start and end hues.
    public let hueCount: CGFloat

    public init(startHue: CGFloat, endHue: CGFloat, target: CGFloat) {
        self.startHue = startHue
        self.endHue = endHue
        self.targetValue = target
        self.hueCount = Self.calculateHueCount(start: startHue, end: endHue)
    }
}

/// A bend section that occurs in the middle of a color slider.
public struct TwoWayBend: BendSection {
    /// The starting hue of the bend section, normalized from 0.0 to 1.0.
    public let startHue: CGFloat

    /// The ending hue of the bend section, normalized from 0.0 to 1.0.
    public let endHue: CGFloat

    /// The saturation, brightness, lightness or chroma value where the bend peaks.
    public let targetValue: CGFloat

    /// The difference between the start and end hues.
    public let hueCount: CGFloat

    /// The hue that reaches `targetValue`.
    public let middleHue: CGFloat

    public init(startHue: CGFloat, endHue: CGFloat, target: CGFloat) {
        self.startHue = startHue
        self.endHue = endHue
        self.targetValue = target
        self.hueCount = Self.calculateHueCount(start: startHue, end: endHue)
        self.middleHue = (self.startHue + self.endHue) / 2
    }
}
