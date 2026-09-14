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
public struct ColorSlider<Source: ColorSliderDataSource>: View {

    // MARK: - State and bindings

    /// The position of the slider, normalized to a range from 0.0 to 1.0.
    /// This is the slider's single source of truth.
    @Binding public var value: Double

    /// The data source driving the slider's colors.
    public var dataSource: Source

    /// An optional closure that emits the computed color.
    public var onColorChange: ((Color) -> Void)?

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
    @Environment(\.colorSliderPreviewHidden) private var previewHidden

    // MARK: - Public properties

    /// A localized string key used for VoiceOver accessibility.
    public var label: LocalizedStringKey

    /// The layout orientation of the slider (`.horizontal` or `.vertical`).
    public var axis: Axis

    /// Determines whether the bound `color` output updates continuously during a
    /// drag gesture (`true`), or only when the drag ends (`false`).
    public var isContinuous: Bool

    /// Initializes a customizable color slider.
    ///
    /// Created by providing a data source such as `HSBSpectrumModel`,
    /// `OKLCHSpectrumModel`, `GradientSliderModel`, or `HardEdgeSliderModel`.
    ///
    /// - Parameters:
    ///   - value: A binding to the slider's normalized position (0.0 to 1.0).
    ///   - dataSource: The source defining the color calculations and rendering.
    ///   - onColorChange: An optional closure to receive the generated color.
    ///   - label: A localized string key used for VoiceOver accessibility.
    ///     Defaults to "Color Slider".
    ///   - axis: The layout orientation of the slider. Defaults to
    ///     `.horizontal`.
    ///   - isContinuous: Whether the output color updates continuously during
    ///     a drag gesture. Defaults to `true`.
    public init(
        value: Binding<Double>,
        dataSource: Source,
        onColorChange: ((Color) -> Void)? = nil,
        label: LocalizedStringKey = "Color Slider",
        axis: Axis = .horizontal,
        isContinuous: Bool = true
    ) {
        self._value = value
        self.dataSource = dataSource
        self.onColorChange = onColorChange
        self.label = label
        self.axis = axis
        self.isContinuous = isContinuous
    }

    /// The color calculated from the current `liveColorPosition` on the slider.
    private var calculatedColor: Color {
        let nonZeroLength = sliderState.resolvedLength > 0 ? sliderState.resolvedLength : 0.001
        let clampedRatio = max(0.0, min(1.0, sliderState.liveColorPosition / nonZeroLength))
        switch dataSource.colorSource {
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
    private var discreteIndex: Int? {
        let source = dataSource.colorSource

        switch source {
        case .array(let colors) where !colors.isEmpty:
            let length: CGFloat = sliderState.resolvedLength
            let nonZeroLength: CGFloat = length > 0 ? length : 0.001

            let position: CGFloat = sliderState.liveColorPosition
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

            let thumbXOffset: CGFloat = axis == .horizontal ? sliderState.thumbOffset : 0
            let thumbYOffset: CGFloat = axis == .horizontal ? 0 : -sliderState.thumbOffset

            let previewXOffset: CGFloat = axis == .horizontal
                ? sliderState.previewMainAxisOffset
                : sliderState.resolvedPreviewOffset

            let previewYOffset: CGFloat = axis == .horizontal
                ? sliderState.resolvedPreviewOffset
                : -sliderState.previewMainAxisOffset

            let configuration = ColorSliderStyleConfiguration(
                value: value,
                isDragging: sliderState.isDragging,
                axis: axis,
                thumbOffset: CGSize(width: thumbXOffset, height: thumbYOffset),
                previewOffset: CGSize(width: previewXOffset, height: previewYOffset),
                previewScaleAnchor: sliderState.previewScaleAnchor,
                track: ColorSliderStyleConfiguration.Track(
                    TrackView(
                        dataSource: dataSource,
                        dimensions: resolvedDimensions,
                        axis: axis
                    )
                ),
                thumb: ColorSliderStyleConfiguration.Thumb(
                    ThumbView(
                        axis: axis,
                        resolvedThumbThickness: sliderState.resolvedThumbThickness,
                        resolvedThumbLength: sliderState.resolvedThumbLength
                    )
                ),
                preview: ColorSliderStyleConfiguration.Preview(
                    ColorPreviewView(
                        currentColor: calculatedColor,
                        dimensions: resolvedDimensions
                    )
                )
            )

            style.makeBody(configuration: configuration)
                .gesture(
                    DragGesture(minimumDistance: minimumDragDistance)
                        .onChanged(onDragChanged)
                        .onEnded(onDragEnded)
                )
                .opacity(isEnabled ? 1.0 : 0.5)
                .grayscale(isEnabled ? 0.0 : 0.99)
                .sensoryFeedback(.selection, trigger: discreteIndex)
                .onAppear {
                    sliderState.update(
                        dimensions: resolvedDimensions,
                        axis: axis,
                        controlSize: controlSize,
                        previewPosition: previewPosition,
                        previewSpacing: previewSpacing,
                        previewHidden: previewHidden
                    )

                    let initialTrackPosition = CGFloat(value) * sliderState.resolvedLength
                    sliderState.persistedThumbPosition = min(
                        max(initialTrackPosition - sliderState.halfThumbThickness, sliderState.thumbInset),
                        sliderState.resolvedLength - sliderState.resolvedThumbThickness - sliderState.thumbInset
                    )

                    if let onColorChange {
                        onColorChange(calculatedColor)
                    }
                }
                .onChange(of: dimensions) { _, newDimensions in
                    var updated = newDimensions
                    updated.length = updated.length ?? dynamicLength
                    sliderState.dimensions = updated
                    if !sliderState.isDragging {
                        let newTrackPosition = CGFloat(value) * sliderState.resolvedLength
                        sliderState.persistedThumbPosition = min(
                            max(newTrackPosition - sliderState.halfThumbThickness, sliderState.thumbInset),
                            sliderState.resolvedLength - sliderState.resolvedThumbThickness - sliderState.thumbInset
                        )
                    }
                }
                .onChange(of: proxy.size) { _, newSize in
                    let newLength = axis == .horizontal ? newSize.width : newSize.height
                    var updated = dimensions
                    updated.length = dimensions.length ?? newLength
                    sliderState.dimensions = updated
                    if !sliderState.isDragging {
                        let newTrackPosition = CGFloat(value) * sliderState.resolvedLength
                        sliderState.persistedThumbPosition = min(
                            max(newTrackPosition - sliderState.halfThumbThickness, sliderState.thumbInset),
                            sliderState.resolvedLength - sliderState.resolvedThumbThickness - sliderState.thumbInset
                        )
                    }
                }
                .onChange(of: axis) { _, new in sliderState.axis = new }
                .onChange(of: controlSize) { _, newSize in
                    sliderState.controlSize = newSize
                    if !sliderState.isDragging {
                        let newTrackPosition = CGFloat(value) * sliderState.resolvedLength
                        sliderState.persistedThumbPosition = min(
                            max(newTrackPosition - sliderState.halfThumbThickness, sliderState.thumbInset),
                            sliderState.resolvedLength - sliderState.resolvedThumbThickness - sliderState.thumbInset
                        )
                    }
                }
                .onChange(of: value) { _, newValue in
                    if !sliderState.isDragging {
                        let newTrackPosition = CGFloat(newValue) * sliderState.resolvedLength
                        withAnimation(reduceMotion ? nil : animation) {
                            sliderState.persistedThumbPosition = min(
                                max(newTrackPosition - sliderState.halfThumbThickness, sliderState.thumbInset),
                                sliderState.resolvedLength - sliderState.resolvedThumbThickness - sliderState.thumbInset
                            )
                        }
                        onColorChange?(calculatedColor)
                    }
                }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityValue({
            let percentage = value.formatted(.percent)
            if let colorName = dataSource.accessibilityColorName(for: value) {
                let format = String(localized: "color_slider_value_format", defaultValue: "%1$@ at %2$@")
                return Text(String(format: format, colorName, percentage))
            }
            return Text(percentage)
        }())
        .accessibilityAdjustableAction(accessibilityAdjust)
        .accessibilityLabel(label)
        .frame(
            width: axis == .vertical ? sliderState.resolvedThumbLength : dimensions.length,
            height: axis == .horizontal ? sliderState.resolvedThumbLength : dimensions.length
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
    /// - Parameter dragValue: The current value of the `DragGesture`.
    private func onDragChanged(_ dragValue: DragGesture.Value) {
        let translation = axis == .horizontal ? dragValue.translation.width : -dragValue.translation.height

        if !sliderState.isDragging {
            withAnimation(reduceMotion ? nil : animation) { sliderState.isDragging = true }
        }

        sliderState.updateDrag(translation: translation)

        let newProgress = Double(
            sliderState.resolvedLength > 0
            ? sliderState.liveColorPosition / sliderState.resolvedLength
            : 0.0
        )

        self.value = newProgress

        if isContinuous {
            onColorChange?(calculatedColor)
        }
    }

    private func onDragEnded(_: DragGesture.Value) {
        if !isContinuous {
            onColorChange?(calculatedColor)
        }
        withAnimation(reduceMotion ? nil : animation) {
            sliderState.finalizeDrag()
        }
    }

    private func accessibilityAdjust(direction: AccessibilityAdjustmentDirection) {
        var mutableProgress = value
        sliderState.accessibilityAdjust(
            direction: direction,
            progress: &mutableProgress,
            step: accessibilityStep
        )
        self.value = mutableProgress
        onColorChange?(calculatedColor)
    }
}

public extension ColorSlider where Source == HSBSpectrumModel {
    /// Initializes a customizable color slider with a default HSB spectrum.
    ///
    /// - Parameters:
    ///   - value: A binding to the slider's normalized position (0.0 to 1.0).
    ///   - onColorChange: An optional closure to receive the generated color.
    ///   - label: A localized string key used for VoiceOver accessibility.
    ///     Defaults to "Color Slider".
    ///   - axis: The layout orientation of the slider. Defaults to
    ///     `.horizontal`.
    ///   - isContinuous: Whether the output color updates continuously during
    ///     a drag gesture. Defaults to `true`.
    init(
        value: Binding<Double>,
        onColorChange: ((Color) -> Void)? = nil,
        label: LocalizedStringKey = "Color Slider",
        axis: Axis = .horizontal,
        isContinuous: Bool = true
    ) {
        self.init(
            value: value,
            dataSource: HSBSpectrumModel(),
            onColorChange: onColorChange,
            label: label,
            axis: axis,
            isContinuous: isContinuous
        )
    }
}
