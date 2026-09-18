import SwiftUI

public extension ColorSlider where Preview == ColorPreviewView {
    /// Initializes a customizable color slider with the default floating color
    /// preview.
    ///
    /// - Parameters:
    ///   - value: A binding to the slider's normalized position (0.0 to 1.0).
    ///   - color: A binding to the slider's color output.
    ///   - colorProvider: The source defining the color calculations and
    ///     rendering.
    ///   - label: A localized string key used for VoiceOver accessibility.
    ///     Defaults to "Color Slider".
    ///   - axis: The layout orientation of the slider (`.horizontal` or
    ///     `.vertical`). Defaults to `.horizontal`.
    ///   - isContinuous: Whether the output color updates continuously during
    ///     a drag gesture. Defaults to `true`.
    init(
        value: Binding<Double>,
        color: Binding<Color>,
        colorProvider: Source,
        label: LocalizedStringKey = "Color Slider",
        axis: Axis = .horizontal,
        isContinuous: Bool = true
    ) {
        self.init(
            value: value,
            color: color,
            colorProvider: colorProvider,
            label: label,
            axis: axis,
            isContinuous: isContinuous,
            previewView: nil
        )
    }
}

public extension ColorSlider where Preview == EmptyView {
    /// Initializes a customizable color slider without a floating color preview.
    ///
    /// - Parameters:
    ///   - value: A binding to the slider's normalized position (0.0 to 1.0).
    ///   - color: A binding to the slider's color output.
    ///   - colorProvider: The source defining the color calculations and
    ///     rendering.
    ///   - label: A localized string key used for VoiceOver accessibility.
    ///     Defaults to "Color Slider".
    ///   - axis: The layout orientation of the slider (`.horizontal` or
    ///     `.vertical`). Defaults to `.horizontal`.
    ///   - isContinuous: Whether the output color updates continuously during
    ///     a drag gesture. Defaults to `true`.
    ///   - preview: Explicitly pass `nil` or `EmptyView()` to hide the preview.
    init(
        value: Binding<Double>,
        color: Binding<Color>,
        colorProvider: Source,
        label: LocalizedStringKey = "Color Slider",
        axis: Axis = .horizontal,
        isContinuous: Bool = true,
        preview: Preview?
    ) {
        self.init(
            value: value,
            color: color,
            colorProvider: colorProvider,
            label: label,
            axis: axis,
            isContinuous: isContinuous,
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
    ///   - color: A binding to the slider's color output.
    ///   - label: A localized string key used for VoiceOver accessibility.
    ///     Defaults to "Color Slider".
    ///   - axis: The layout orientation of the slider (`.horizontal` or
    ///     `.vertical`). Defaults to `.horizontal`.
    ///   - isContinuous: Whether the output color updates continuously during
    ///     a drag gesture. Defaults to `true`.
    ///   - preview: A view builder that creates the custom floating color
    ///     preview.
    init(
        value: Binding<Double>,
        color: Binding<Color>,
        label: LocalizedStringKey = "Color Slider",
        axis: Axis = .horizontal,
        isContinuous: Bool = true,
        @ViewBuilder preview: () -> Preview
    ) {
        self.init(
            value: value,
            color: color,
            colorProvider: Spectrum<HSB>(),
            label: label,
            axis: axis,
            isContinuous: isContinuous,
            preview: preview
        )
    }
}

public extension ColorSlider where Source == Spectrum<HSB>, Preview == ColorPreviewView {
    /// Initializes a customizable color slider with a default HSB spectrum.
    ///
    /// - Parameters:
    ///   - value: A binding to the slider's normalized position (0.0 to 1.0).
    ///   - color: A binding to the slider's color output.
    ///   - label: A localized string key used for VoiceOver accessibility.
    ///     Defaults to "Color Slider".
    ///   - axis: The layout orientation of the slider (`.horizontal` or
    ///     `.vertical`). Defaults to `.horizontal`.
    ///   - isContinuous: Whether the output color updates continuously during
    ///     a drag gesture. Defaults to `true`.
    init(
        value: Binding<Double>,
        color: Binding<Color>,
        label: LocalizedStringKey = "Color Slider",
        axis: Axis = .horizontal,
        isContinuous: Bool = true
    ) {
        self.init(
            value: value,
            color: color,
            colorProvider: Spectrum<HSB>(),
            label: label,
            axis: axis,
            isContinuous: isContinuous,
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
    ///   - color: A binding to the slider's color output.
    ///   - label: A localized string key used for VoiceOver accessibility.
    ///     Defaults to "Color Slider".
    ///   - axis: The layout orientation of the slider (`.horizontal` or
    ///     `.vertical`). Defaults to `.horizontal`.
    ///   - isContinuous: Whether the output color updates continuously during
    ///     a drag gesture. Defaults to `true`.
    ///   - preview: Explicitly pass `nil` or `EmptyView()` to hide the preview.
    init(
        value: Binding<Double>,
        color: Binding<Color>,
        label: LocalizedStringKey = "Color Slider",
        axis: Axis = .horizontal,
        isContinuous: Bool = true,
        preview: Preview?
    ) {
        self.init(
            value: value,
            color: color,
            colorProvider: Spectrum<HSB>(),
            label: label,
            axis: axis,
            isContinuous: isContinuous,
            previewView: preview
        )
    }
}
