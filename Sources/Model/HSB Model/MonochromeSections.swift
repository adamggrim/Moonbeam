import Foundation

enum MonochromeColor {
    case black, white
}

enum Position {
    case start, end
}

// Section of the color slider that fades to or from a monochrome color
protocol MonochromeSection {
    var color: MonochromeColor { get }
    
    // Number of monochrome gradations added to the hue section (each equal in width to a single hue)
    var count: CGFloat { get }
    var position: Position { get }
    
    var stepSize: CGFloat { get }
}

extension MonochromeSection {
    var stepSize: CGFloat {
        guard count > 1 else { return 1.0 }
        return 1.0 / (count - 1)
    }
}

struct BlackSection: MonochromeSection {
    let color: MonochromeColor = .black
    let count: CGFloat
    let position: Position
}

struct WhiteSection: MonochromeSection {
    let color: MonochromeColor = .white
    let count: CGFloat
    let position: Position
}
