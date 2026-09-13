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

/// A type-erased wrapper for `ColorSliderStyle`.
///
/// SwiftUI environment values require a concrete type. This wrapper abstracts
/// the underlying generic style so it can be safely stored and retrieved.
internal struct AnyColorSliderStyle: ColorSliderStyle, @unchecked Sendable {
    private let _makeBody: @MainActor (Configuration) -> AnyView

    /// Initializes a type-erased style from any concrete `ColorSliderStyle`.
    ///
    /// - Parameter style: The underlying custom style to erase.
    init<S: ColorSliderStyle>(_ style: S) {
        self._makeBody = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }

    /// Renders the type-erased body using the stored style closure.
    @MainActor
    func makeBody(configuration: Configuration) -> some View {
        _makeBody(configuration)
    }
}

// MARK: - Environment

private struct ColorSliderStyleKey: EnvironmentKey {
    static let defaultValue = AnyColorSliderStyle(DefaultColorSliderStyle())
}

extension EnvironmentValues {
    /// The active color slider style applied to the view hierarchy.
    var colorSliderStyle: AnyColorSliderStyle {
        get { self[ColorSliderStyleKey.self] }
        set { self[ColorSliderStyleKey.self] = newValue }
    }
}

// MARK: - View Modifier

public extension View {
    /// Sets the style for color sliders within this view.
    ///
    /// Use this modifier to replace the default slider appearance with a custom
    /// implementation conforming to `ColorSliderStyle`.
    ///
    /// - Parameter style: The custom style to apply.
    /// - Returns: A view that utilizes the specified style for child sliders.
    func colorSliderStyle<S: ColorSliderStyle>(_ style: S) -> some View {
        environment(\.colorSliderStyle, AnyColorSliderStyle(style))
    }
}
