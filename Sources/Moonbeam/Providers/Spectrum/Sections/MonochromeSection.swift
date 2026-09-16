import Foundation

// MARK: - Monochrome sections

/// Represents the lightest and darkest endpoints of a spectrum.
public enum MonochromeColor: Sendable {
    case black, white
}

/// Section of the color slider that fades to or from a monochrome color.
public protocol MonochromeSection: Sendable {
    /// The color of a `MonochromeSection`, either `.black` or `.white`.
    var color: MonochromeColor { get }

    /// The number of monochrome steps added to the hue section (each equal in
    /// width to a single hue).
    var weight: Double { get }

    /// The mathematical easing curve applied to the monochrome section.
    var easing: Easing { get }
}

/// Provides shared default values shared across all monochrome sections.
public extension MonochromeSection {
    /// The default proportionate width of a monochrome section (1/6th of the
    /// hue spectrum).
    static var defaultWeight: Double { 1.0 / 6.0 }
}

// MARK: - Monochrome sections

/// A spectrum section that starts or end with black.
public struct BlackSection: MonochromeSection {
    public let color: MonochromeColor = .black
    public let weight: Double
    public let easing: Easing

    /// Initializes a black section.
    ///   - Parameter weight: The proportionate width of the section relative
    ///     to a single hue.
    public init(weight: Double = Self.defaultWeight, easing: Easing = .cubic) {
        self.weight = weight
        self.easing = easing
    }
}

/// A spectrum section that starts or end with white.
public struct WhiteSection: MonochromeSection {
    public let color: MonochromeColor = .white
    public let weight: Double
    public let easing: Easing

    /// Initializes a white section.
    /// - Parameter weight: The proportionate width of the section relative to
    ///   a single hue.
    public init(weight: Double = Self.defaultWeight, easing: Easing = .cubic) {
        self.weight = weight
        self.easing = easing
    }
}
