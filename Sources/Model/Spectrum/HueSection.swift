import Foundation

/**
 A protocol for a section of the color slider with special conditions for
 saturation or brightness.
 */
public protocol BendSection {
    var startHue: CGFloat { get }
    var endHue: CGFloat { get }

    var targetSaturation: CGFloat { get }
    var targetBrightness: CGFloat { get }

    var hueCount: CGFloat { get }
}

/**
 The color section of the color slider, for showing the full spectrum of color
 options.
 */
public struct HueSection {
    let minHue: CGFloat
    let maxHue: CGFloat
    let count: CGFloat
    let stepSize: CGFloat

    public init(minHue: CGFloat, maxHue: CGFloat) {
        self.minHue = minHue
        self.maxHue = maxHue

        let calculatedCount = maxHue - minHue
        self.count = calculatedCount

        if calculatedCount - 1 > 0 {
            self.stepSize = 1.0 / (calculatedCount - 1)
        } else {
            self.stepSize = 0.0
        }
    }
}

/// A bend section that fades into the start or end of a color slider.
public struct OneWayBend: BendSection {
    public let startHue: CGFloat
    public let endHue: CGFloat
    public let targetSaturation: CGFloat
    public let targetBrightness: CGFloat
    public let hueCount: CGFloat

    public init(hue range: ClosedRange<CGFloat>, saturation: CGFloat = 1.0, brightness: CGFloat = 1.0) {
        self.startHue = range.lowerBound
        self.endHue = range.upperBound
        self.targetSaturation = saturation
        self.targetBrightness = brightness
        self.hueCount = range.upperBound - range.lowerBound
    }
}

/// A bend section that occurs in the middle of a color slider.
public struct TwoWayBend: BendSection {
    public let startHue: CGFloat
    public let endHue: CGFloat
    public let targetSaturation: CGFloat
    public let targetBrightness: CGFloat
    public let hueCount: CGFloat
    public let middleHue: CGFloat

    public init(hue range: ClosedRange<CGFloat>, saturation: CGFloat = 1.0, brightness: CGFloat = 1.0) {
        self.startHue = range.lowerBound
        self.endHue = range.upperBound
        self.targetSaturation = saturation
        self.targetBrightness = brightness
        self.hueCount = range.upperBound - range.lowerBound
        self.middleHue = (self.startHue + self.hueCount) / 2
    }
}
