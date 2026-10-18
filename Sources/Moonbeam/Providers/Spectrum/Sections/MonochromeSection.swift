import Foundation

/// Represents the lightest and darkest endpoints of a spectrum.
public enum MonochromeColor: Sendable {
    case black, white
}

/// Section of the color slider that fades to or from a monochrome color.
public protocol MonochromeSection: Sendable {
    /// The color of a `MonochromeSection`, either `.black` or `.white`.
    var color: MonochromeColor { get }

    /// The proportion of the total slider track this section occupies.
    var fraction: Double { get }
}

/// Provides default values shared across all monochrome sections.
public extension MonochromeSection {
    /// The default proportionate width of a monochrome section (1/6th of the
    /// entire slider).
    static var defaultFraction: Double { 1.0 / 6.0 }
}

/// A spectrum section that starts or ends with black.
public struct BlackSection: MonochromeSection {
    public let color: MonochromeColor = .black
    public let fraction: Double

    /// Initializes a black section.
    ///   - Parameters:
    ///     - fraction: The proportion of the total slider track this section
    ///       occupies (0.0 to 1.0).
    public init(fraction: Double = Self.defaultFraction) {
        self.fraction = fraction
    }
}

/// A spectrum section that starts or ends with white.
public struct WhiteSection: MonochromeSection {
    public let color: MonochromeColor = .white
    public let fraction: Double

    /// Initializes a white section.
    ///   - Parameters:
    ///     - fraction: The proportion of the total slider track this section
    ///       occupies (0.0 to 1.0).
    public init(fraction: Double = Self.defaultFraction) {
        self.fraction = fraction
    }
}
