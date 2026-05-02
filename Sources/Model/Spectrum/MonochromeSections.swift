import Foundation

public enum MonochromeColor {
    case black, white
}

public enum PositionOnSlider {
    case start, end
}

/// Section of the color slider that fades to or from a monochrome color
public protocol MonochromeSection {
    var color: MonochromeColor { get }

    /// Number of monochrome gradations added to the hue section (each equal in width to a single hue)
    var count: CGFloat { get }
    var positionOnSlider: PositionOnSlider { get }

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
    public let positionOnSlider: PositionOnSlider
    
    public init(count: CGFloat, positionOnSlider: PositionOnSlider) {
        self.count = count
        self.positionOnSlider = positionOnSlider
    }
}

public struct WhiteSection: MonochromeSection {
    public let color: MonochromeColor = .white
    public let count: CGFloat
    public let positionOnSlider: PositionOnSlider
    
    public init(count: CGFloat, positionOnSlider: PositionOnSlider) {
        self.count = count
        self.positionOnSlider = positionOnSlider
    }
}
