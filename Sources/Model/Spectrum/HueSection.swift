import Foundation


/// A protocol for a section of the color slider with special conditions for saturation or brightness.
public protocol BendSection {
    var startHue: CGFloat { get }
    var endHue: CGFloat { get }

    var targetValue: CGFloat { get }

    var hueCount: CGFloat { get }
}

/// The core component representing the colorful spectrum of the slider.
public struct HueSection: SliderComponent {
    public let minHue: CGFloat
    public let maxHue: CGFloat
    public let baseSaturation: CGFloat
    public let baseBrightness: CGFloat
    public let saturationBends: [BendSection]?
    public let brightnessBends: [BendSection]?
    public let weight: CGFloat

    public init(
        minHue: CGFloat,
        maxHue: CGFloat,
        baseSaturation: CGFloat = 1.0,
        baseBrightness: CGFloat = 1.0,
        @BendSectionBuilder saturationBends: () -> [BendSection] = { [] },
            @BendSectionBuilder brightnessBends: () -> [BendSection] = { [] }
        ) {
            self.minHue = minHue
            self.maxHue = maxHue
            self.baseSaturation = baseSaturation
            self.baseBrightness = baseBrightness

            let evaluatedSatBends = saturationBends()
            let evaluatedBrightBends = brightnessBends()
            
            self.saturationBends = evaluatedSatBends.isEmpty ? nil : evaluatedSatBends
            self.brightnessBends = evaluatedBrightBends.isEmpty ? nil : evaluatedBrightBends
            self.weight = maxHue - minHue
    }
}

/// A bend section that fades into the start or end of a color slider.
public struct OneWayBend: BendSection {
    public let startHue: CGFloat
    public let endHue: CGFloat
    public let targetValue: CGFloat
    public let hueCount: CGFloat

    public init(hue range: ClosedRange<CGFloat>, target: CGFloat) {
        self.startHue = range.lowerBound
        self.endHue = range.upperBound
        self.targetValue = target
        self.hueCount = range.upperBound - range.lowerBound
    }
}

/// A bend section that occurs in the middle of a color slider.
public struct TwoWayBend: BendSection {
    public let startHue: CGFloat
    public let endHue: CGFloat
    public let targetValue: CGFloat
    public let hueCount: CGFloat
    public let middleHue: CGFloat

    public init(hue range: ClosedRange<CGFloat>, target: CGFloat) {
        self.startHue = range.lowerBound
        self.endHue = range.upperBound
        self.targetValue = target
        self.hueCount = range.upperBound - range.lowerBound
        self.middleHue = (self.startHue + self.hueCount) / 2
    }
}
