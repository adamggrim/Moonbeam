import Foundation
import SwiftUI

@resultBuilder
public struct BendSectionBuilder {
    public static func buildBlock(_ components: BendSection...) -> [BendSection] { return Array(components) }
    public static func buildOptional(_ component: [BendSection]?) -> [BendSection] { return component ?? [] }
    public static func buildEither(first component: [BendSection]) -> [BendSection] { return component }
    public static func buildEither(second component: [BendSection]) -> [BendSection] { return component }
}

@resultBuilder
public struct SpectrumComponentBuilder {
    public static func buildBlock(_ components: SliderComponent...) -> [SliderComponent] { return Array(components) }
    public static func buildOptional(_ component: [SliderComponent]?) -> [SliderComponent] { return component ?? [] }
    public static func buildEither(first component: [SliderComponent]) -> [SliderComponent] { return component }
    public static func buildEither(second component: [SliderComponent]) -> [SliderComponent] { return component }
}
