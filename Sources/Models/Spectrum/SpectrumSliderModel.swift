import Foundation
import SwiftUI

/// Model for calculating spectrum colors dynamically.
public struct SpectrumSliderModel: ColorSliderDataSource {
    private struct InvalidArchitectureError: Error {
        let message: String
        init(message: String = "Slider architecture is invalid.") {
            self.message = message
        }
    }

    private static func validateBendSections(bendSections: [BendSection]) -> Bool {
        guard bendSections.count > 1 else { return true }

        let sortedBendSections = bendSections.sorted { $0.startHue < $1.startHue }
        for (currentSection, nextSection) in zip(sortedBendSections, sortedBendSections.dropFirst()) {
            if currentSection.endHue > nextSection.startHue {
                return false
            }
        }
        return true
    }

    private let startSections: [MonochromeSection]
    private let endSections: [MonochromeSection]
    private let hueSection: HueSection

    public var colorSource: ColorSourceProvider {
        return .function { position in
            SpectrumGenerator.color(
                at: position,
                startSections: startSections,
                endSections: endSections,
                hueSection: hueSection
            )
        }
    }

    public init(@SpectrumComponentBuilder components: () -> [SliderComponent]) throws {
        let evaluatedComponents = components()

        let hueSections = evaluatedComponents.compactMap { $0 as? HueSection }
        guard let mainHueSection = hueSections.first, hueSections.count == 1 else {
            throw InvalidArchitectureError(message: "Slider must contain exactly one HueSection.")
        }

        if let saturationBends = mainHueSection.saturationBends, !Self.validateBendSections(bendSections: saturationBends) {
            throw InvalidArchitectureError(message: "Saturation bend sections are overlapping.")
        }
        if let brightnessBends = mainHueSection.brightnessBends, !Self.validateBendSections(bendSections: brightnessBends) {
            throw InvalidArchitectureError(message: "Brightness bend sections are overlapping.")
        }

        let hueIndex = evaluatedComponents.firstIndex { $0 is HueSection }!
        let beforeHue = evaluatedComponents.prefix(upTo: hueIndex).compactMap { $0 as? MonochromeSection }
        let afterHue = evaluatedComponents.suffix(from: hueIndex + 1).compactMap { $0 as? MonochromeSection }

        self.hueSection = mainHueSection
        self.startSections = beforeHue
        self.endSections = afterHue
    }
}
