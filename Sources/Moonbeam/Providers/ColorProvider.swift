import SwiftUI

/// Represents whether the colors are defined by an array, a function or a Metal
/// shader.
public enum ColorSource: Sendable {
    /// Provides colors as a precomputed array.
    ///
    /// Designed for hard-edge sliders.
    case array([Color])

    /// Dynamically calculates a color based on normalized position (i.e., 0.0
    /// to 1.0).
    ///
    /// Designed for spectrum and gradient color sliders.
    case function(@Sendable (_ position: Double) -> Color)

    /// Renders the background using a Metal shader.
    case shader(generator: @Sendable (
        _ size: CGSize, _ isVertical: Bool
    ) -> Shader, fallback: @Sendable (_ position: Double) -> Color)
}

/// Protocol shared by `Spectrum`, `ColorGradient` and `HardEdgeColors`.
public protocol ColorProvider: Sendable {

    /// Determines how the slider track is drawn on screen.
    var colorSource: ColorSource { get }

    /// Resolves a descriptive color name for VoiceOver.
    func accessibilityColorName(for value: Double) -> String?
}

public extension ColorProvider {
    /// A default that returns `nil` to indicate the data source does not
    /// provide color names.
    func accessibilityColorName(for value: Double) -> String? { return nil }

    /// Resolves the calculated color at a normalized position (0.0 to 1.0).
    func color(at position: Double) -> Color {
        let clampedRatio = max(0.0, min(1.0, position))
        switch colorSource {
        case .array(let colors):
            guard !colors.isEmpty else { return .clear }
            let calculatedIndex = Int(Double(colors.count) * clampedRatio)
            let clampedIndex = max(0, min(colors.count - 1, calculatedIndex))
            return colors[clampedIndex]
        case .function(let colorGenerator):
            return colorGenerator(clampedRatio)
        case .shader(_, let fallback):
            return fallback(clampedRatio)
        }
    }
}
