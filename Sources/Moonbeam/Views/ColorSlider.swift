import SwiftUI

#if canImport(UIKit)
import UIKit
typealias PlatformColor = UIColor
#elseif canImport(AppKit)
import AppKit
typealias PlatformColor = NSColor
#endif

/// A customizable, interactive view that allows users to select a color
/// from a dynamically generated spectrum or gradient.
@MainActor
public struct ColorSlider<Source: ColorProvider, Preview: View>: View {

    // MARK: - State and bindings

    /// The position of the slider, normalized to a range from 0.0 to 1.0.
    /// This is the slider's single source of truth.
    @Binding public var value: Double

    /// The color output of the slider.
    @Binding public var color: Color

    /// The data source driving the slider's colors.
    public var colorProvider: Source

    @State private var sliderState = ColorSliderState()

    // MARK: - Environment variables

    @Environment(\.colorSliderStyle) private var style
    @Environment(\.colorSliderDimensions) private var dimensions
    @Environment(\.controlSize) private var controlSize
    @Environment(\.colorSliderDragMinimumDistance) private var minimumDragDistance
    @Environment(\.colorSliderAnimation) private var animation
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSliderAccessibilityStep) private var accessibilityStep
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorSliderPreviewPosition) private var previewPosition
    @Environment(\.colorSliderPreviewSpacing) private var previewSpacing

    // MARK: - Public properties

    /// A localized string key used for VoiceOver accessibility.
    public var label: LocalizedStringKey

    /// The layout orientation of the slider (`.horizontal` or `.vertical`).
    public var axis: Axis

    /// Determines whether the bound `color` output updates continuously during a
    /// drag gesture (`true`), or only when the drag ends (`false`).
    public var isContinuous: Bool

    public var preview: Preview?

    /// Initializes a customizable color slider.
    ///
    /// Created by providing a data source such as `Spectrum<ColorSpace>`,
    /// `ColorGradient`, or `HardEdgeColors`.
    ///
    /// - Parameters:
    ///   - value: A binding to the slider's normalized position (0.0 to 1.0).
    ///   - colorProvider: The source defining the color calculations and
    ///     rendering.
    ///   - onColorChange: An optional closure to receive the generated color.
    ///   - label: A localized string key used for VoiceOver accessibility.
    ///     Defaults to "Color Slider".
    ///   - axis: The layout orientation of the slider (`.horizontal` or
    ///     `.vertical`). Defaults to `.horizontal`.
    ///   - isContinuous: Whether the output color updates continuously during
    ///     a drag gesture. Defaults to `true`.
    public init(
        value: Binding<Double>,
        color: Binding<Color>,
        colorProvider: Source,
        label: LocalizedStringKey = "Color Slider",
        axis: Axis = .horizontal,
        isContinuous: Bool = true,
        @ViewBuilder preview: () -> Preview
    ) {
        self._value = value
        self._color = color
        self.colorProvider = colorProvider
        self.label = label
        self.axis = axis
        self.isContinuous = isContinuous
        self.preview = preview()
    }

    /// The color calculated from the current `liveColorPosition` on the slider.
        private func calculatedColor(layout: ColorSliderLayout) -> Color {
        let nonZeroLength = layout.resolvedLength > 0 ? layout.resolvedLength : 0.001
        let clampedRatio = max(0.0, min(1.0, layout.liveColorPosition / nonZeroLength))
        switch colorProvider.colorSource {
        case .array(let colors):
            guard !colors.isEmpty else { return .clear }
            let calculatedIndex = Int(CGFloat(colors.count) * clampedRatio)
            let clampedIndex = max(0, min(colors.count - 1, calculatedIndex))
            return colors[clampedIndex]
        case .function(let colorGenerator):
            return colorGenerator(clampedRatio)
        case .shader(_, let fallback):
            return fallback(clampedRatio)
        }
    }

    /// Calculates the discrete index of the slider (used to trigger haptics on
    /// hard-edge sliders).
    private func discreteIndex(layout: ColorSliderLayout) -> Int? {
        let source = colorProvider.colorSource

        switch source {
        case .array(let colors) where !colors.isEmpty:
            let length: CGFloat = layout.resolvedLength
            let nonZeroLength: CGFloat = length > 0 ? length : 0.001

            let position: CGFloat = layout.liveColorPosition
            let rawRatio: CGFloat = position / nonZeroLength
            let clampedRatio: CGFloat = max(0.0, min(1.0, rawRatio))

            let colorCount: CGFloat = CGFloat(colors.count)
            let calculatedIndex: Int = Int(colorCount * clampedRatio)

            let maxIndex: Int = colors.count - 1
            return max(0, min(maxIndex, calculatedIndex))

        default:
            return nil
        }
    }

    // MARK: - Views

    public var body: some View {
        GeometryReader { proxy in
            let dynamicLength = axis == .horizontal ? proxy.size.width : proxy.size.height
            let resolvedDimensions: ColorSliderDimensions = {
                var d = dimensions
                d.length = d.length ?? dynamicLength
                return d
            }()

            let layout = ColorSliderLayout(
                state: sliderState,
                value: value,
                dimensions: resolvedDimensions,
                axis: axis,
                controlSize: controlSize,
                previewPosition: previewPosition,
                previewSpacing: previewSpacing
            )

            let thumbXOffset: CGFloat = axis == .horizontal ? layout.thumbOffset : 0
            let thumbYOffset: CGFloat = axis == .horizontal ? 0 : -layout.thumbOffset

            let previewXOffset: CGFloat = axis == .horizontal
                ? layout.previewMainAxisOffset
                : layout.resolvedPreviewOffset

            let previewYOffset: CGFloat = axis == .horizontal
                ? layout.resolvedPreviewOffset
                : -layout.previewMainAxisOffset

            let configuration = ColorSliderStyleConfiguration(
                value: value,
                isDragging: sliderState.isDragging,
                axis: axis,
                thumbOffset: CGSize(width: thumbXOffset, height: thumbYOffset),
                previewOffset: CGSize(width: previewXOffset, height: previewYOffset),
                previewScaleAnchor: layout.previewScaleAnchor,
                track: ColorSliderStyleConfiguration.Track(
                    TrackView(
                        colorProvider: colorProvider,
                        dimensions: resolvedDimensions,
                        axis: axis
                    )
                ),
                thumb: ColorSliderStyleConfiguration.Thumb(
                    ThumbView(
                        axis: axis,
                        resolvedThumbThickness: layout.resolvedThumbThickness,
                        resolvedThumbLength: layout.resolvedThumbLength
                    )
                ),
                preview: ColorSliderStyleConfiguration.Preview(
                    Group {
                        if let preview {
                            preview
                        } else if Preview.self == ColorPreviewView.self {
                            ColorPreviewView(
                                currentColor: calculatedColor(layout: layout),
                                dimensions: resolvedDimensions
                            )
                        }
                    }
                )
            )

            style(configuration)
                .animation(sliderState.isDragging || reduceMotion ? nil : animation, value: value)
                .gesture(
                    DragGesture(minimumDistance: minimumDragDistance)
                        .onChanged { onDragChanged($0, layout: layout) }
                        .onEnded { onDragEnded($0, layout: layout) }
                )
                .opacity(isEnabled ? 1.0 : 0.5)
                .grayscale(isEnabled ? 0.0 : 0.99)
                .sensoryFeedback(.selection, trigger: discreteIndex(layout: layout))
                .onAppear {
                    self.color = calculatedColor(layout: layout)
                }
                .onChange(of: value) { _, newValue in
                    if !sliderState.isDragging {
                        let newLayout = ColorSliderLayout(
                            state: sliderState,
                            value: newValue,
                            dimensions: resolvedDimensions,
                            axis: axis,
                            controlSize: controlSize,
                            previewPosition: previewPosition,
                            previewSpacing: previewSpacing
                        )
                        self.color = calculatedColor(layout: newLayout)
                    }
                }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityValue({
            let percentage = value.formatted(.percent)
            if let colorName = colorProvider.accessibilityColorName(for: value) {
                let format = String(localized: "color_slider_value_format", defaultValue: "%1$@ at %2$@")
                return Text(String(format: format, colorName, percentage))
            }
            return Text(percentage)
        }())
        .accessibilityAdjustableAction(accessibilityAdjust)
        .accessibilityLabel(label)
        .frame(
            width: axis == .vertical ? dimensions.resolvedThumbLength(for: controlSize) : dimensions.length,
            height: axis == .horizontal ? dimensions.resolvedThumbLength(for: controlSize) : dimensions.length
        )
        .frame(
            maxWidth: axis == .horizontal && dimensions.length == nil ? .infinity : nil,
            maxHeight: axis == .vertical && dimensions.length == nil ? .infinity : nil
        )
    }

    // MARK: - Drag event handlers

    /// Updates the view's state when the position of the `DragGesture`
    /// changes.
    ///
    /// Called continuously while the user is dragging the thumb. Calculates
    /// `liveContainerThumbDrag`, `liveColorPosition` and `liveThumbPosition`.
    ///
    /// - Parameters:
    ///   - dragValue: The current value of the `DragGesture`.
    ///   - layout: The layout context describing the dimensions of the active render pass.
    private func onDragChanged(_ dragValue: DragGesture.Value, layout: ColorSliderLayout) {
        let translation = axis == .horizontal ? dragValue.translation.width : -dragValue.translation.height

        if !sliderState.isDragging {
            withAnimation(reduceMotion ? nil : animation) { sliderState.isDragging = true }
        }

        sliderState.updateDrag(translation: translation, currentValue: value)

        let newLayout = ColorSliderLayout(
            state: sliderState,
            value: value,
            dimensions: layout.dimensions,
            axis: layout.axis,
            controlSize: layout.controlSize,
            previewPosition: layout.previewPosition,
            previewSpacing: layout.previewSpacing
        )

        let newProgress = Double(
            newLayout.resolvedLength > 0
            ? newLayout.liveColorPosition / newLayout.resolvedLength
            : 0.0
        )

        self.value = newProgress

        if isContinuous {
            self.color = calculatedColor(layout: newLayout)
        }
    }

    private func onDragEnded(_: DragGesture.Value, layout: ColorSliderLayout) {
        if !isContinuous {
            self.color = calculatedColor(layout: layout)
        }
        withAnimation(reduceMotion ? nil : animation) {
            sliderState.finalizeDrag()
        }
    }

    private func accessibilityAdjust(direction: AccessibilityAdjustmentDirection) {
        let delta = direction == .increment ? accessibilityStep : -accessibilityStep
        self.value = min(max(value + delta, 0.0), 1.0)
    }
}

public extension ColorSlider where Preview == ColorPreviewView {
    /// Initializes a customizable color slider with the default floating color preview.
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
        self._value = value
        self._color = color
        self.colorProvider = colorProvider
        self.label = label
        self.axis = axis
        self.isContinuous = isContinuous
        self.preview = nil
    }
}

public extension ColorSlider where Preview == EmptyView {
    /// Initializes a customizable color slider without a floating color preview.
    ///
    /// - Parameters:
    ///   - value: A binding to the slider's normalized position (0.0 to 1.0).
    ///   - color: A binding to the slider's color output.
    ///   - colorProvider: The source defining the color calculations and rendering.
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
        self._value = value
        self._color = color
        self.colorProvider = colorProvider
        self.label = label
        self.axis = axis
        self.isContinuous = isContinuous
        self.preview = nil
    }
}

public extension ColorSlider where Source == Spectrum<HSB> {
    /// Initializes a customizable color slider with a default HSB spectrum and a custom preview view.
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
            isContinuous: isContinuous
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
            preview: preview
        )
    }
}
