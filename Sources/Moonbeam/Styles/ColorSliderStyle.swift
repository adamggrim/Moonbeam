import SwiftUI

/// A type that applies a custom appearance to a color slider.
public protocol ColorSliderStyle: Sendable {
    /// A view that represents the body of a color slider.
    associatedtype Body: View

    /// Creates a view that represents the body of a color slider.
    ///
    /// - Parameter configuration: The properties and subviews of the color
    ///   slider.
    /// - Returns: A fully assembled layout view.
    @MainActor @ViewBuilder func makeBody(configuration: Configuration) -> Body

    /// An alias for the configuration properties provided to the style.
    typealias Configuration = ColorSliderStyleConfiguration
}

// MARK: - Environment

private struct ColorSliderStyleKey: EnvironmentKey {
    static let defaultValue: @MainActor @Sendable (ColorSliderStyleConfiguration) -> AnyView = { configuration in
        AnyView(DefaultColorSliderStyle().makeBody(configuration: configuration))
    }
}

extension EnvironmentValues {
    /// A closure returning a type-erased layout view that represents the active color slider style applied to the view hierarchy.
    var colorSliderStyle: @MainActor @Sendable (ColorSliderStyleConfiguration) -> AnyView {
        get { self[ColorSliderStyleKey.self] }
        set { self[ColorSliderStyleKey.self] = newValue }
    }
}

// MARK: - View modifier

public extension View {
    /// Sets the style for color sliders within this view.
    ///
    /// Use this modifier to replace the default slider appearance with a custom
    /// implementation conforming to `ColorSliderStyle`.
    ///
    /// - Parameter style: The custom style to apply.
    /// - Returns: A view that utilizes the specified style for child sliders.
    func colorSliderStyle<S: ColorSliderStyle>(_ style: S) -> some View {
        environment(\.colorSliderStyle, { configuration in
            AnyView(style.makeBody(configuration: configuration))
        })
    }
}
