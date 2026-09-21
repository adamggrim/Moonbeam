import Foundation

/// A protocol for a section of the color slider with special conditions for
/// saturation, brightness, lightness or chroma.
public protocol BendSection: Sendable {
    /// The starting hue of the bend section, normalized from 0.0 to 1.0.
    var startHue: Double { get }

    /// The ending hue of the bend section, normalized from 0.0 to 1.0.
    var endHue: Double { get }

    /// The saturation, brightness, lightness or chroma value where the bend
    /// peaks.
    var targetValue: Double { get }

    /// The difference between the start and end hues.
    var hueCount: Double { get }

    /// The mathematical easing curve applied to the bend section.
    var easing: Easing { get }
}

public extension BendSection {
    /// Helper to calculate the shortest distance between two hues in a
    /// wraparound (circular) hue range.
    static func calculateHueCount(start: Double, end: Double) -> Double {
        let diff = abs(end - start)
        return diff > 0.5 ? 1.0 - diff : diff
    }
}

/// A result builder used to construct an array of `BendSection` components.
@resultBuilder
public struct BendSectionBuilder {
    public static func buildBlock(_ components: BendSection...) -> [BendSection] { return Array(components) }
    public static func buildOptional(_ component: [BendSection]?) -> [BendSection] { return component ?? [] }
    public static func buildEither(first component: [BendSection]) -> [BendSection] { return component }
    public static func buildEither(second component: [BendSection]) -> [BendSection] { return component }
}

/// A bend section that fades into the start or end of a color slider.
public struct OneWayBend: BendSection {
    /// The starting hue of the bend section, normalized from 0.0 to 1.0.
    public let startHue: Double

    /// The ending hue of the bend section, normalized from 0.0 to 1.0.
    public let endHue: Double

    /// The saturation, brightness, lightness or chroma value where the
    /// bend peaks.
    public let targetValue: Double

    /// The difference between the start and end hues.
    public let hueCount: Double

    /// The mathematical easing curve applied to the bend section.
    public let easing: Easing

    public init(startHue: Double, endHue: Double, target: Double, easing: Easing = .cubic) {
        self.startHue = startHue
        self.endHue = endHue
        self.targetValue = target
        self.easing = easing
        self.hueCount = Self.calculateHueCount(start: startHue, end: endHue)
    }
}

/// A bend section that occurs in the middle of a color slider.
public struct TwoWayBend: BendSection {
    /// The starting hue of the bend section, normalized from 0.0 to 1.0.
    public let startHue: Double

    /// The ending hue of the bend section, normalized from 0.0 to 1.0.
    public let endHue: Double

    /// The saturation, brightness, lightness or chroma value where the bend
    /// peaks.
    public let targetValue: Double

    /// The difference between the start and end hues.
    public let hueCount: Double

    /// The mathematical easing curve applied to the bend section.
    public let easing: Easing

    public init(startHue: Double, endHue: Double, target: Double, easing: Easing = .cubic) {
        self.startHue = startHue
        self.endHue = endHue
        self.targetValue = target
        self.easing = easing
        self.hueCount = Self.calculateHueCount(start: startHue, end: endHue)
    }
}
