import SwiftUI

public extension ColorSlider where Preview == ColorPreviewView {
    /// Initializes a customizable color slider with the default floating color
    /// preview.
    ///
    /// - Parameters:
    ///   - value: A binding to the slider's normalized position (0.0 to 1.0).
    ///   - colorProvider: The source defining the color calculations and
    ///     rendering.
    ///   - label: A localized string key used for VoiceOver accessibility.
    ///     Defaults to "Color Slider".
    ///   - axis: The layout orientation of the slider (`.horizontal` or
    ///     `.vertical`). Defaults to `.horizontal`.
    init(
        value: Binding<Double>,
        colorProvider: Source,
        label: LocalizedStringKey = "Color Slider",
        axis: Axis = .horizontal
    ) {
        self.init(
            value: value,
            colorProvider: colorProvider,
            label: label,
            axis: axis,
            previewView: nil
        )
    }
}

public extension ColorSlider where Preview == EmptyView {
    /// Initializes a customizable color slider without a floating color preview.
    ///
    /// - Parameters:
    ///   - value: A binding to the slider's normalized position (0.0 to 1.0).
    ///   - colorProvider: The source defining the color calculations and
    ///     rendering.
    ///   - label: A localized string key used for VoiceOver accessibility.
    ///     Defaults to "Color Slider".
    ///   - axis: The layout orientation of the slider (`.horizontal` or
    ///     `.vertical`). Defaults to `.horizontal`.
    ///   - preview: Explicitly pass `nil` or `EmptyView()` to hide the preview.
    init(
        value: Binding<Double>,
        colorProvider: Source,
        label: LocalizedStringKey = "Color Slider",
        axis: Axis = .horizontal,
        preview: Preview?
    ) {
        self.init(
            value: value,
            colorProvider: colorProvider,
            label: label,
            axis: axis,
            previewView: preview
        )
    }
}

public extension ColorSlider where Source == Spectrum<HSB> {
    /// Initializes a customizable color slider with a default HSB spectrum and
    /// custom preview view.
    ///
    /// - Parameters:
    ///   - value: A binding to the slider's normalized position (0.0 to 1.0).
    ///   - label: A localized string key used for VoiceOver accessibility.
    ///     Defaults to "Color Slider".
    ///   - axis: The layout orientation of the slider (`.horizontal` or
    ///     `.vertical`). Defaults to `.horizontal`.
    ///   - preview: A view builder that creates the custom floating color
    ///     preview.
    init(
        value: Binding<Double>,
        label: LocalizedStringKey = "Color Slider",
        axis: Axis = .horizontal,
        @ViewBuilder preview: () -> Preview
    ) {
        self.init(
            value: value,
            colorProvider: Spectrum<HSB>(),
            label: label,
            axis: axis,
            preview: preview
        )
    }
}

public extension ColorSlider where Source == Spectrum<HSB>, Preview == ColorPreviewView {
    /// Initializes a customizable color slider with a default HSB spectrum.
    ///
    /// - Parameters:
    ///   - value: A binding to the slider's normalized position (0.0 to 1.0).
    ///   - label: A localized string key used for VoiceOver accessibility.
    ///     Defaults to "Color Slider".
    ///   - axis: The layout orientation of the slider (`.horizontal` or
    ///     `.vertical`). Defaults to `.horizontal`.
    init(
        value: Binding<Double>,
        label: LocalizedStringKey = "Color Slider",
        axis: Axis = .horizontal
    ) {
        self.init(
            value: value,
            colorProvider: Spectrum<HSB>(),
            label: label,
            axis: axis,
            previewView: nil
        )
    }
}

public extension ColorSlider where Source == Spectrum<HSB>, Preview == EmptyView {
    /// Initializes a customizable color slider with a default HSB spectrum and
    /// no floating color preview.
    ///
    /// - Parameters:
    ///   - value: A binding to the slider's normalized position (0.0 to 1.0).
    ///   - label: A localized string key used for VoiceOver accessibility.
    ///     Defaults to "Color Slider".
    ///   - axis: The layout orientation of the slider (`.horizontal` or
    ///     `.vertical`). Defaults to `.horizontal`.
    ///   - preview: Explicitly pass `nil` or `EmptyView()` to hide the preview.
    init(
        value: Binding<Double>,
        label: LocalizedStringKey = "Color Slider",
        axis: Axis = .horizontal,
        preview: Preview?
    ) {
        self.init(
            value: value,
            colorProvider: Spectrum<HSB>(),
            label: label,
            axis: axis,
            previewView: preview
        )
    }
}
