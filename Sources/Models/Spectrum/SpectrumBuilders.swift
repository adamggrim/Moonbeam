import Foundation
import SwiftUI

/// A result builder used to construct an array of `BendSection` components.
@resultBuilder
public struct BendSectionBuilder {
    public static func buildBlock(_ components: BendSection...) -> [BendSection] { return Array(components) }
    public static func buildOptional(_ component: [BendSection]?) -> [BendSection] { return component ?? [] }
    public static func buildEither(first component: [BendSection]) -> [BendSection] { return component }
    public static func buildEither(second component: [BendSection]) -> [BendSection] { return component }
}
