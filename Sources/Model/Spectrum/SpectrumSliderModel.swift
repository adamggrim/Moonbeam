import Foundation
import SwiftUI

/// Represents the HSB components on the color slider that can bend.
public enum BendableComponent {
    case saturation, brightness
}

/// A declarative builder for assembling bend sections.
@resultBuilder
public struct BendSectionBuilder {
    public static func buildBlock(_ components: BendSection...) -> [BendSection] {
        return Array(components)
    }
    public static func buildOptional(_ component: [BendSection]?) -> [BendSection] {
        return component ?? []
    }
    public static func buildEither(first component: [BendSection]) -> [BendSection] {
        return component
    }
    public static func buildEither(second component: [BendSection]) -> [BendSection] {
        return component
    }
}

/// Model for calculating spectrum colors dynamically.
public struct SpectrumSliderModel: ColorSliderDataSource {
    private struct InvalidBendSectionError: Error {
        let message: String
        init(message: String = "Invalid bend section") {
            self.message = message
        }
    }

    private static func validateBendSections(bendSections: [BendSection]) -> Bool {
        guard bendSections.count > 0 else { return false }
        guard bendSections.count > 1 else { return true }

        let sortedBendSections = bendSections.sorted { $0.startHue < $1.startHue }
        for (currentSection, nextSection) in zip(sortedBendSections, sortedBendSections.dropFirst()) {
            if currentSection.endHue > nextSection.startHue {
                return false
            }
        }
        return true
    }

    private let minHue: CGFloat
    private let maxHue: CGFloat
    private let baseSaturation: CGFloat
    private let baseBrightness: CGFloat
    private let blackSection: BlackSection?
    private let whiteSection: WhiteSection?
    private let bendSections: [BendSection]?
    private let priorityColor: MonochromeColor?

    public var colorSource: ColorSourceProvider {
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

    public init(
        minHue: CGFloat,
        maxHue: CGFloat,
        baseSaturation: CGFloat = 1.0,
        baseBrightness: CGFloat = 1.0,
        blackSection: BlackSection? = nil,
        whiteSection: WhiteSection? = nil,
        priorityColor: MonochromeColor? = nil,
        @BendSectionBuilder bendSections: () -> [BendSection] = { [] }
    ) throws {
        let evaluatedBends = bendSections()
        
        if !evaluatedBends.isEmpty, !Self.validateBendSections(bendSections: evaluatedBends) {
            throw InvalidBendSectionError()
        }

        self.minHue = minHue
        self.maxHue = maxHue
        self.baseSaturation = baseSaturation
        self.baseBrightness = baseBrightness
        self.blackSection = blackSection
        self.whiteSection = whiteSection
        self.bendSections = evaluatedBends.isEmpty ? nil : evaluatedBends
        self.priorityColor = priorityColor
    }
}
