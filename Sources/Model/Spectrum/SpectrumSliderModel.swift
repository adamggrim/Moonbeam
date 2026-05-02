import Foundation
import SwiftUI

/// Represents the HSB components on the color slider that can bend.
enum BendableComponent {
    case saturation, brightness
}

/// Model for calculating spectrum colors dynamically.
struct SpectrumSliderModel: ColorSliderDataSource {
    /// Error for when `validateBendSections()` returns `false`
    private struct InvalidBendSectionError: Error {
        let message: String
        init(message: String = "Invalid bend section") {
            self.message = message
        }
    }

    private static func validateBendSections(
        bendSections: [BendSection]
    ) -> Bool {
        guard bendSections.count > 0 else { return false }
        guard bendSections.count > 1 else { return true }

        let sortedBendSections = bendSections.sorted {
            $0.startHue < $1.startHue
        }

        for (currentSection, nextSection) in zip(
            sortedBendSections,
            sortedBendSections.dropFirst()
        ) {
            if currentSection.endHue > nextSection.startHue {
                return false
            }
        }
        return true
    }

    private let minHue: CGFloat
    private let maxHue: CGFloat
    private let baseSaturation: CGFloat = 1.0
    private let baseBrightness: CGFloat = 1.0
    private let blackSection: BlackSection?
    private let whiteSection: WhiteSection?
    private let bendSections: [BendSection]?
    private let priorityColor: MonochromeColor?

    var colorSource: ColorSourceProvider {
        return .function { position in
            SpectrumGenerator.color(
                at: position,
                minHue: minHue,
                maxHue: maxHue,
                blackSection: blackSection,
                whiteSection: whiteSection,
                bendSections: bendSections,
                priorityColor: priorityColor,
                baseSaturation: baseSaturation,
                baseBrightness: baseBrightness
            )
        }
    }

    init(
        minHue: CGFloat,
        maxHue: CGFloat,
        blackSection: BlackSection? = nil,
        whiteSection: WhiteSection? = nil,
        bendSections: [BendSection]? = nil,
        priorityColor: MonochromeColor? = nil
    ) throws {
        if let bendSections = bendSections, !Self.validateBendSections(bendSections: bendSections) {
            throw InvalidBendSectionError()
        }
        
        self.minHue = minHue
        self.maxHue = maxHue
        self.blackSection = blackSection
        self.whiteSection = whiteSection
        self.bendSections = bendSections
        self.priorityColor = priorityColor
    }
}
