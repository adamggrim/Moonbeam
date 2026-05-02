import Foundation

public enum MonochromeColor {
    case black, white
}

public protocol SliderComponent {}

/// Section of the color slider that fades to or from a monochrome color.
public protocol MonochromeSection: SliderComponent {
    var color: MonochromeColor { get }

    /// The number of monochrome gradations added to the hue section (each equal in width to a single hue).
    var count: CGFloat { get }
    var stepSize: CGFloat { get }
}

public extension MonochromeSection {
    var stepSize: CGFloat {
        guard count > 1 else { return 1.0 }
        return 1.0 / (count - 1)
    }
}

public struct BlackSection: MonochromeSection {
    public let color: MonochromeColor = .black
    public let count: CGFloat

    public init(count: CGFloat) {
        self.count = count
    }
}

public struct WhiteSection: MonochromeSection {
    public let color: MonochromeColor = .white
    public let count: CGFloat

    public init(count: CGFloat) {
        self.count = count
    }
}
