import Foundation

public enum MonochromeColor {
    case black, white
}

public protocol SliderComponent {}

/// Section of the color slider that fades to or from a monochrome color.
public protocol MonochromeSection: SliderComponent {
    var color: MonochromeColor { get }

    /// The number of monochrome gradations added to the hue section (each equal in width to a single hue).
    var weight: CGFloat { get }
}

public struct BlackSection: MonochromeSection {
    public let color: MonochromeColor = .black
    public let weight: CGFloat

    public init(weight: CGFloat = 1.0 / 6.0) {
            self.weight = weight
        }
}

public struct WhiteSection: MonochromeSection {
    public let color: MonochromeColor = .white
    public let weight: CGFloat

    public init(weight: CGFloat = 1.0 / 6.0) {
            self.weight = weight
        }
}
