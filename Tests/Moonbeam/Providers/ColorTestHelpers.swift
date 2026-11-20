import SwiftUI
@testable import Moonbeam

extension Color {
    func exceedsSRGB(in environment: EnvironmentValues = EnvironmentValues()) -> Bool {
        let resolved = resolve(in: environment)
        return [resolved.red, resolved.green, resolved.blue].contains { $0 < 0.0 || $0 > 1.0 }
    }

    func isWithinSRGB(in environment: EnvironmentValues = EnvironmentValues()) -> Bool {
        let resolved = resolve(in: environment)
        return [resolved.red, resolved.green, resolved.blue].allSatisfy { (0.0...1.0).contains($0) }
    }

    func oklabChroma(in environment: EnvironmentValues = EnvironmentValues()) -> CGFloat {
        let lab = ColorSpaceConverter.colorToOklab(self, in: environment)
        return hypot(lab.a, lab.b)
    }
}
