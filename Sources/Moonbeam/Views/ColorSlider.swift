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
public struct ColorSlider: View {

    // MARK: - State & bindings

    @Binding public var selection: CGColor

    /// The position of the selected color in the slider, normalized to a range
    /// from 0.0 to 1.0.
    @Binding public var progress: Double

    @State private var sliderState = ColorSliderState()

    // MARK: - Environment variables

    @Environment(\.colorSliderPreviewPosition) private var previewPosition
    @Environment(\.colorSliderPreviewSpacing) private var previewSpacing
    @Environment(\.colorSliderPreviewHidden) private var previewHidden
    @Environment(\.colorSliderDimensions) private var dimensions
    @Environment(\.colorSliderDragMinimumDistance) private var minimumDragDistance
    @Environment(\.colorSliderAnimation) private var animation
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSliderAccessibilityStep) private var accessibilityStep
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.self) private var environment

    // MARK: - Public properties

    /// An optional identifier that triggers animation and position updates when the spectrum changes.
    public var spectrumIdentifier: AnyHashable?

    /// A closure invoked when the spectrum changes, enabling an updated progress value for the thumb.
    public var onSpectrumChanged: ((CGColor) -> Double)?

    /// A localized string key used for VoiceOver accessibility.
    public var label: LocalizedStringKey

    /// The layout orientation of the slider (`.horizontal` or `.vertical`).
    public var axis: Axis

    /// Determines whether the bound `selection` updates continuously during a drag gesture (`true`), or only when the drag ends (`false`).
    public var isContinuous: Bool

    // MARK: - Private properties

    private var dataSource: ColorSliderDataSource?
    private var colorSpace: SpectrumColorSpace = .hsb
    private var hueRange: ClosedRange<Double> = 0.0...1.0
    private var startSections: [MonochromeSection] = []
    private var endSections: [MonochromeSection] = []
    private var saturationBends: [BendSection] = []
    private var brightnessBends: [BendSection] = []

    // MARK: - Constants

    private enum Metrics {
        static let defaultPreviewOffset: CGFloat = 70.0
        static let dragScaleMultiplier: CGFloat = 1.1
        static let accessibilityStepPercentage: CGFloat = 0.05
    }

    // MARK: - Initializer

    /// Initializes a customizable color slider.
    ///
    /// Created either by injecting a discrete `dataSource` (e.g., a
    /// `GradientSliderModel` or `HardEdgeSliderModel`), or by attaching `.spectrum(...)`
    /// modifiers directly to the view to build a spectrum implicitly.
    ///
    /// - Parameters:
    ///   - selection: A binding to the currently absolute selected color.
    ///   - progress: A binding to the slider's normalized position (0.0 to 1.0).
    ///   - dataSource: An optional model providing custom gradient or hard-edge data. If omitted, use the `.spectrum(...)` modifier chain to build the data source.
    ///   - spectrumIdentifier: An optional identifier to trigger a spectrum change.
    ///   - onSpectrumChanged: An optional callback defining the thumb's behavior when the spectrum changes.
    ///   - label: A localized string key used for VoiceOver accessibility. Defaults to "Color Slider".
    ///   - axis: The layout orientation of the slider. Defaults to `.horizontal`.
    ///   - isContinuous: Whether the selected color updates continuously during a drag gesture. Defaults to `true`.
    public init(
        selection: Binding<CGColor>,
        progress: Binding<Double>,
        dataSource: ColorSliderDataSource? = nil,
        spectrumIdentifier: AnyHashable? = nil,
        onSpectrumChanged: ((CGColor) -> Double)? = nil,
        label: LocalizedStringKey = "Color Slider",
        axis: Axis = .horizontal,
        isContinuous: Bool = true
    ) {
        self._selection = selection
        self._progress = progress
        self.dataSource = dataSource
        self.spectrumIdentifier = spectrumIdentifier
        self.onSpectrumChanged = onSpectrumChanged
        self.label = label
        self.axis = axis
        self.isContinuous = isContinuous
    }

    // MARK: - Computed properties

    private var resolvedDataSource: ColorSliderDataSource {
        if let dataSource = dataSource { return dataSource }

        let currentSaturationBends: () -> [BendSection] = { saturationBends }
        let currentBrightnessBends: () -> [BendSection] = { brightnessBends }

        if colorSpace == .oklch {
            return OKLCHSpectrumModel(
                startSections: startSections,
                endSections: endSections,
                lightness: 0.75,
                chroma: 0.15,
                startHue: hueRange.lowerBound,
                endHue: hueRange.upperBound,
                lightnessBends: currentBrightnessBends,
                chromaBends: currentSaturationBends
            )
        } else {
            return HSBSpectrumModel(
                startSections: startSections,
                endSections: endSections,
                startHue: hueRange.lowerBound,
                endHue: hueRange.upperBound,
                saturation: 1.0,
                brightness: 1.0,
                saturationBends: currentSaturationBends,
                brightnessBends: currentBrightnessBends
            )
        }
    }

    /// The color calculated from the current `liveColorPosition` on the slider.
    private var calculatedColor: Color {
        let safeLength = dimensions.length > 0 ? dimensions.length : 0.001
        let clampedRatio = max(0.0, min(1.0, sliderState.liveColorPosition / safeLength))
        switch resolvedDataSource.colorSource {
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

    /// The geometric shape of the slider track, falling back to `Capsule` if no corner radius is specified in the dimensions configuration.
    private var trackShape: AnyShape {
        if let radius = dimensions.cornerRadius {
            return AnyShape(RoundedRectangle(cornerRadius: radius))
        } else {
            return AnyShape(Capsule())
        }
    }

    /// Calculates the discrete index of the slider (used to trigger haptics on hard-edge sliders).
    private var discreteIndex: Int? {
        let source = resolvedDataSource.colorSource

        switch source {
        case .array(let colors) where !colors.isEmpty:
            let length: CGFloat = dimensions.length
            let safeLength: CGFloat = length > 0 ? length : 0.001

            let position: CGFloat = sliderState.liveColorPosition
            let rawRatio: CGFloat = position / safeLength
            let clampedRatio: CGFloat = max(0.0, min(1.0, rawRatio))

            let countFloat: CGFloat = CGFloat(colors.count)
            let calculatedIndex: Int = Int(countFloat * clampedRatio)

            let maxIndex: Int = colors.count - 1
            return max(0, min(maxIndex, calculatedIndex))

        default:
            return nil
        }
    }

    // MARK: - Views

    public var body: some View {
        ZStack(alignment: axis == .horizontal ? .leading : .bottom) {
            SliderTrackView(
                dataSource: resolvedDataSource,
                dimensions: dimensions,
                axis: axis
            )

            SliderThumbView(
                isDragging: sliderState.isDragging,
                thumbOffset: sliderState.thumbOffset,
                dimensions: dimensions,
                axis: axis,
                resolvedThumbThickness: sliderState.resolvedThumbThickness,
                resolvedThumbLength: sliderState.resolvedThumbLength
            )
            .gesture(
                DragGesture(minimumDistance: minimumDragDistance)
                    .onChanged(onDragChanged)
                    .onEnded(onDragEnded)
            )

            SliderPreviewView(
                isDragging: sliderState.isDragging,
                currentColor: sliderState.isDragging ? calculatedColor : Color(selection),
                previewMainAxisOffset: sliderState.previewMainAxisOffset,
                resolvedPreviewOffset: sliderState.resolvedPreviewOffset,
                dimensions: dimensions,
                axis: axis
            )
        }
        .opacity(isEnabled ? 1.0 : 0.5)
        .grayscale(isEnabled ? 0.0 : 0.99)
        .sensoryFeedback(.selection, trigger: discreteIndex)
        .frame(
            width: axis == .horizontal ? dimensions.length : sliderState.resolvedThumbLength,
            height: axis == .horizontal ? sliderState.resolvedThumbLength : dimensions.length
        )
        .onAppear {
            sliderState.update(
                dimensions: dimensions,
                axis: axis,
                previewPosition: previewPosition,
                previewSpacing: previewSpacing,
                previewHidden: previewHidden
            )

            let initialTrackPosition = CGFloat(progress) * dimensions.length
            sliderState.persistedThumbPosition = min(
                max(initialTrackPosition - sliderState.halfThumbThickness, sliderState.thumbInset),
                dimensions.length - sliderState.resolvedThumbThickness - sliderState.thumbInset
            )
        }
        .onChange(of: dimensions) { _, new in sliderState.dimensions = new }
        .onChange(of: axis) { _, new in sliderState.axis = new }
        .onChange(of: previewPosition) { _, new in sliderState.previewPosition = new }
        .onChange(of: previewSpacing) { _, new in sliderState.previewSpacing = new }
        .onChange(of: previewHidden) { _, new in sliderState.previewHidden = new }
        .onChange(of: spectrumIdentifier) { _, _ in
            if let onSpectrumChanged = onSpectrumChanged {
                progress = onSpectrumChanged(selection)
            }
            let newTrackPosition = CGFloat(progress) * dimensions.length
            withAnimation(reduceMotion ? nil : animation) {
                sliderState.persistedThumbPosition = min(
                    max(newTrackPosition - sliderState.halfThumbThickness, sliderState.thumbInset),
                    dimensions.length - sliderState.resolvedThumbThickness - sliderState.thumbInset
                )            }
        }
        .onChange(of: progress) { _, newValue in
            if !sliderState.isDragging {
                let newTrackPosition = CGFloat(newValue) * dimensions.length
                withAnimation(reduceMotion ? nil : animation) {
                    sliderState.persistedThumbPosition = min(
                        max(newTrackPosition - sliderState.halfThumbThickness, sliderState.thumbInset),
                        dimensions.length - sliderState.resolvedThumbThickness - sliderState.thumbInset
                    )
                }
            }
        }
        .accessibilityElement(children: .ignore) // Hides individual shapes from VoiceOver.
        .accessibilityValue(Double(progress).formatted(.percent))
        .accessibilityAdjustableAction(accessibilityAdjust)
        .accessibilityLabel(label)
    }

    // MARK: - Drag event handlers

    /// Updates the view's state when the position of the `DragGesture`
    /// changes.
    ///
    /// Called continuously while the user is dragging the thumb. Calculates
    /// `liveContainerThumbDrag`, `liveColorPosition` and`liveThumbPosition`.
    ///
    /// - Parameter value: The current value of the `DragGesture`.
    private func onDragChanged(_ value: DragGesture.Value) {
        let translation = axis == .horizontal ? value.translation.width : -value.translation.height

        if !sliderState.isDragging {
            withAnimation(reduceMotion ? nil : animation) { sliderState.isDragging = true }
        }

        sliderState.updateDrag(translation: translation)
        progress = Double(dimensions.length > 0 ? sliderState.liveColorPosition / dimensions.length : 0.0)

        if isContinuous {
            selection = calculatedColor.resolve(in: environment).cgColor
        }
    }

    /// Finalizes the view's state when the drag gesture ends, updating
    /// `persistedThumbPosition` with the thumb's last valid clamped position
    /// and resetting `liveContainerDrag` to zero.
    private func onDragEnded(_ value: DragGesture.Value) {
        if !isContinuous {
            selection = calculatedColor.resolve(in: environment).cgColor
        }
        withAnimation(reduceMotion ? nil : animation) {
            sliderState.finalizeDrag()
        }
    }

    /// Adjusts the slider by a specific percentage step (for VoiceOver).
    private func accessibilityAdjust(direction: AccessibilityAdjustmentDirection) {
        sliderState.accessibilityAdjust(direction: direction, progress: &progress, step: accessibilityStep)
        selection = calculatedColor.resolve(in: environment).cgColor
    }

    // MARK: - Modifiers

    public func spectrum(space: SpectrumColorSpace, range: ClosedRange<Double>) -> Self {
        var copy = self
        copy.colorSpace = space
        copy.hueRange = range
        copy.dataSource = nil
        return copy
    }

    public func startingWith(_ sections: MonochromeSection...) -> Self {
        var copy = self
        copy.startSections = sections
        copy.dataSource = nil
        return copy
    }

    public func endingWith(_ sections: MonochromeSection...) -> Self {
        var copy = self
        copy.endSections = sections
        copy.dataSource = nil
        return copy
    }

    public func saturationBends(@BendSectionBuilder _ bends: () -> [BendSection]) -> Self {
        var copy = self
        copy.saturationBends = bends()
        copy.dataSource = nil
        return copy
    }

    public func brightnessBends(@BendSectionBuilder _ bends: () -> [BendSection]) -> Self {
        var copy = self
        copy.brightnessBends = bends()
        copy.dataSource = nil
        return copy
    }
}

/// An isolated view for rendering the slider background track.
private struct SliderTrackView: View {
    let dataSource: ColorSliderDataSource
    let dimensions: ColorSliderDimensions
    let axis: Axis

    @Environment(\.colorSliderTrackStroke) private var trackStroke

    private var trackShape: AnyShape {
        if let radius = dimensions.cornerRadius {
            return AnyShape(RoundedRectangle(cornerRadius: radius))
        } else {
            return AnyShape(Capsule())
        }
    }

    var body: some View {
        let size = CGSize(
            width: axis == .horizontal ? dimensions.length : dimensions.thickness,
            height: axis == .horizontal ? dimensions.thickness : dimensions.length
        )

        Group {
            switch dataSource.colorSource {
            case .array(let colors):
                hardEdgeTrackView(colors: colors)
                    .clipShape(trackShape)
            case .function(let colorGenerator):
                trackShape.fill(colorGenerator(0.5))
            case .shader(let shaderGenerator, _):
                trackShape
                    .fill(Color.white) // Pixels for Metal to paint on.
                    .colorEffect(shaderGenerator(size, axis == .vertical))
            }
        }
        .frame(width: size.width, height: size.height)
        .overlay {
            if let stroke = trackStroke {
                trackShape.stroke(stroke.style, lineWidth: stroke.lineWidth)
            }
        }
    }

    @ViewBuilder
    private func hardEdgeTrackView(colors: [Color]) -> some View {
        if colors.isEmpty {
            Color.clear
        } else {
            let isHorizontal = axis == .horizontal
            let step = 1.0 / Double(colors.count)

            let stops: [Gradient.Stop] = colors.enumerated().flatMap { index, color in
                [
                    Gradient.Stop(color: color, location: step * Double(index)),
                    Gradient.Stop(color: color, location: step * Double(index + 1))
                ]
            }

            LinearGradient(
                stops: stops,
                startPoint: isHorizontal ? .leading : .bottom,
                endPoint: isHorizontal ? .trailing : .top
            )
        }
    }
}

/// An isolated view responsible for rendering the draggable slider thumb.
private struct SliderThumbView: View {
    let isDragging: Bool
    let thumbOffset: CGFloat
    let dimensions: ColorSliderDimensions
    let axis: Axis
    let resolvedThumbThickness: CGFloat
    let resolvedThumbLength: CGFloat

    @Environment(\.colorSliderThumbShape) private var thumbShape
    @Environment(\.colorSliderThumbColor) private var thumbColor
    @Environment(\.colorSliderThumbStroke) private var thumbStroke
    @Environment(\.colorSliderThumbShadow) private var thumbShadow
    @Environment(\.colorSliderDisableLiquidGlass) private var disableLiquidGlass

    /// Set to `true` to scale the thumb up during a drag gesture if the platform supports Liquid Glass effects and it has not been explicitly disabled.
    private var enableThumbScale: Bool {
        if #available(iOS 26.0, macOS 16.0, *) { return !disableLiquidGlass }
        return false
    }

    var body: some View {
        let thumbWidth: CGFloat = axis == .horizontal ? resolvedThumbThickness : resolvedThumbLength
        let thumbHeight: CGFloat = axis == .horizontal ? resolvedThumbLength : resolvedThumbThickness

        let xOffset: CGFloat = axis == .horizontal ? thumbOffset : 0
        let yOffset: CGFloat = axis == .horizontal ? 0 : -thumbOffset

        let dynamicScale: CGFloat = (isDragging && enableThumbScale) ? 1.1 : 1.0

        Group {
            if #available(iOS 26.0, macOS 16.0, *), !disableLiquidGlass {
                Color.clear
                    .glassEffect(isDragging ? .regular.interactive(true) : .identity, in: thumbShape)
                    .overlay(thumbShape.fill(thumbColor).opacity(isDragging ? 0.0 : 1.0))
            } else {
                thumbShape.fill(thumbColor)
            }
        }
        .foregroundColor(thumbColor)
        .frame(width: thumbWidth, height: thumbHeight)
        .scaleEffect(dynamicScale)
        .shadow(color: thumbShadow.color, radius: thumbShadow.radius, x: thumbShadow.x, y: thumbShadow.y)
        .overlay {
            if let stroke = thumbStroke {
                thumbShape.stroke(stroke.style, lineWidth: stroke.lineWidth)
            }
        }
        .offset(x: xOffset, y: yOffset)
    }
}

/// An isolated view responsible for rendering the floating color preview.
private struct SliderPreviewView: View {
    let isDragging: Bool
    let currentColor: Color
    let previewMainAxisOffset: CGFloat
    let resolvedPreviewOffset: CGFloat
    let dimensions: ColorSliderDimensions
    let axis: Axis

    @Environment(\.colorSliderPreviewShape) private var previewShape
    @Environment(\.colorSliderPreviewStroke) private var previewStroke
    @Environment(\.colorSliderPreviewHidden) private var previewHidden
    @Environment(\.colorSliderPreviewShadow) private var previewShadow

    var body: some View {
        let resolvedShape = previewShape ?? AnyShape(RoundedRectangle(cornerRadius: dimensions.previewCornerRadius))

        let dynamicAnchor: UnitPoint = axis == .horizontal
            ? (resolvedPreviewOffset > 0 ? .top : .bottom)
            : (resolvedPreviewOffset > 0 ? .leading : .trailing)

        let dynamicScale: CGFloat = (previewHidden && !isDragging) ? dimensions.scaleRatio : 1.0
        let dynamicOpacity: Double = (previewHidden && !isDragging) ? 0.0 : 1.0

        let xOffset: CGFloat = axis == .horizontal ? previewMainAxisOffset : resolvedPreviewOffset
        let yOffset: CGFloat = axis == .horizontal ? resolvedPreviewOffset : -previewMainAxisOffset

        resolvedShape
            .foregroundColor(currentColor)
            .frame(width: dimensions.previewSize, height: dimensions.previewSize)
            .scaleEffect(dynamicScale, anchor: dynamicAnchor)
            .opacity(dynamicOpacity)
            .shadow(color: previewShadow.color, radius: previewShadow.radius, x: previewShadow.x, y: previewShadow.y)
            .overlay {
                if let stroke = previewStroke {
                    resolvedShape.stroke(stroke.style, lineWidth: stroke.lineWidth)
                }
            }
            .offset(x: xOffset, y: yOffset)
    }
}

public extension ColorSlider {
    /// Convenience initializer to accept SwiftUI's `Color` instead of `CGColor`.
    init(
        selection: Binding<Color>,
        progress: Binding<Double>,
        dataSource: ColorSliderDataSource? = nil,
        spectrumIdentifier: AnyHashable? = nil,
        onSpectrumChanged: ((Color) -> Double)? = nil,
        label: LocalizedStringKey = "Color Slider",
        axis: Axis = .horizontal,
        isContinuous: Bool = true
    ) {
        let cgSelection = Binding<CGColor>(
            get: {
                PlatformColor(selection.wrappedValue).cgColor
            },
            set: { selection.wrappedValue = Color($0) }
        )

        let cgOnChanged: ((CGColor) -> Double)? = onSpectrumChanged.map { callback in
            return { cgColor in callback(Color(cgColor)) }
        }

        self.init(
            selection: cgSelection,
            progress: progress,
            dataSource: dataSource,
            spectrumIdentifier: spectrumIdentifier,
            onSpectrumChanged: cgOnChanged,
            label: label,
            axis: axis,
            isContinuous: isContinuous
        )
    }
}
