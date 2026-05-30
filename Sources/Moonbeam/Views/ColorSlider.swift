import SwiftUI

/// A customizable, interactive view that allows users to select a color
/// from a dynamically generated spectrum or gradient.
public struct ColorSlider: View {
    
    // MARK: - State & Bindings
    
    @Binding public var selection: CGColor
    
    /// The position of the selected color in the slider, normalized to a range
    /// from 0.0 to 1.0.
    @Binding public var progress: Double
    
    @State private var viewModel = ColorSliderViewModel()

    // MARK: - Environment Variables
    
    @Environment(\.colorSliderTrackStroke) private var trackStroke
    
    @Environment(\.colorSliderThumbShape) private var thumbShape
    @Environment(\.colorSliderThumbColor) private var thumbColor
    @Environment(\.colorSliderThumbStroke) private var thumbStroke
    @Environment(\.colorSliderThumbShadow) private var thumbShadow
    
    @Environment(\.colorSliderPreviewShape) private var previewShape
    @Environment(\.colorSliderPreviewStroke) private var previewStroke
    @Environment(\.colorSliderPreviewPosition) private var previewPosition
    @Environment(\.colorSliderPreviewSpacing) private var previewSpacing
    @Environment(\.colorSliderPreviewHidden) private var previewHidden
    @Environment(\.colorSliderPreviewShadow) private var previewShadow
    
    @Environment(\.colorSliderDisableLiquidGlass) private var disableLiquidGlass
    @Environment(\.colorSliderDimensions) private var dimensions
    @Environment(\.colorSliderAnimation) private var animation
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSliderAccessibilityStep) private var accessibilityStep
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.self) private var environment

    // MARK: - Public Properties
    
    public var spectrumIdentifier: AnyHashable?
    public var onSpectrumChanged: ((CGColor) -> Double)?
    public var label: LocalizedStringKey
    public var axis: Axis
    public var isContinuous: Bool

    // MARK: - Private Properties
    
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

    // MARK: - Computed Properties
    
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
        let clampedRatio = max(0.0, min(1.0, viewModel.liveColorPosition / safeLength))
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

    /// Set to `true` to scale the thumb up during a drag gesture. Defaults to `true` if liquid glass is supported and enabled.
    private var enableThumbScale: Bool {
        if #available(iOS 26.0, *) { return !disableLiquidGlass }
        return false
    }

/// Calculates the discrete index of the slider (used to trigger haptics on hard-edge sliders).
    private var discreteIndex: Int? {
        if case .array(let colors) = resolvedDataSource.colorSource, !colors.isEmpty {
            let safeLength = dimensions.length > 0 ? dimensions.length : 0.001
            let clampedRatio = max(0.0, min(1.0, viewModel.liveColorPosition / safeLength))
            let calculatedIndex = Int(CGFloat(colors.count) * clampedRatio)
            return max(0, min(colors.count - 1, calculatedIndex))
        }
        return nil
    }
    
    private var trackShape: AnyShape {
        if let radius = dimensions.cornerRadius {
            return AnyShape(RoundedRectangle(cornerRadius: radius))
        } else {
            return AnyShape(Capsule())
        }
    }
    
    // MARK: - Views
    
    public var body: some View {
        ZStack(alignment: axis == .horizontal ? .leading : .bottom) {
            trackView
            thumbView
            colorPreviewView
        }
        .opacity(isEnabled ? 1.0 : 0.5)
        .grayscale(isEnabled ? 0.0 : 0.99)
        .sensoryFeedback(.selection, trigger: discreteIndex)
        .frame(
            width: axis == .horizontal ? dimensions.length : viewModel.resolvedThumbLength,
            height: axis == .horizontal ? viewModel.resolvedThumbLength : dimensions.length
        )
        .onAppear {
            viewModel.update(
                dimensions: dimensions,
                axis: axis,
                previewPosition: previewPosition,
                previewSpacing: previewSpacing,
                previewHidden: previewHidden
            )
            
            let initialTrackPosition = CGFloat(progress) * dimensions.length
            viewModel.persistedThumbPosition = min(max(initialTrackPosition - viewModel.halfThumbThickness, viewModel.thumbInset), dimensions.length - viewModel.resolvedThumbThickness - viewModel.thumbInset)
        }
        .onChange(of: dimensions) { _, new in viewModel.dimensions = new }
        .onChange(of: axis) { _, new in viewModel.axis = new }
        .onChange(of: previewPosition) { _, new in viewModel.previewPosition = new }
        .onChange(of: previewSpacing) { _, new in viewModel.previewSpacing = new }
        .onChange(of: previewHidden) { _, new in viewModel.previewHidden = new }
        .onChange(of: spectrumIdentifier) { _, _ in
            if let onSpectrumChanged = onSpectrumChanged {
                progress = onSpectrumChanged(selection)
            }
            let newTrackPosition = CGFloat(progress) * dimensions.length
            withAnimation(reduceMotion ? nil : animation) {
                viewModel.persistedThumbPosition = min(max(newTrackPosition - viewModel.halfThumbThickness, viewModel.thumbInset), dimensions.length - viewModel.resolvedThumbThickness - viewModel.thumbInset)
            }
        }
        .onChange(of: progress) { _, newValue in
            if !viewModel.isDragging {
                let newTrackPosition = CGFloat(newValue) * dimensions.length
                withAnimation(reduceMotion ? nil : animation) {
                    viewModel.persistedThumbPosition = min(max(newTrackPosition - viewModel.halfThumbThickness, viewModel.thumbInset), dimensions.length - viewModel.resolvedThumbThickness - viewModel.thumbInset)
                }
            }
        }
        .accessibilityElement(children: .ignore) // Hides individual shapes from VoiceOver.
        .accessibilityValue(Double(progress).formatted(.percent))
        .accessibilityAdjustableAction(accessibilityAdjust)
        .accessibilityLabel(label)
    }

    @ViewBuilder
    private var trackView: some View {
        let size = CGSize(
            width: axis == .horizontal ? dimensions.length : dimensions.thickness,
            height: axis == .horizontal ? dimensions.thickness : dimensions.length
        )

        Group {
            switch resolvedDataSource.colorSource {
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
        let isHorizontal = axis == .horizontal
        let orderedIndices = isHorizontal ? Array(colors.indices) : Array(colors.indices.reversed())

        if isHorizontal {
            HStack(spacing: 0) {
                ForEach(orderedIndices, id: \.self) { index in
                    innerShadowBlock(for: colors[index])
                }
            }
        } else {
            VStack(spacing: 0) {
                ForEach(orderedIndices, id: \.self) { index in
                    innerShadowBlock(for: colors[index])
                }
            }
        }
    }

    @ViewBuilder
    private func innerShadowBlock(for color: Color) -> some View {
        Rectangle()
            .fill(color)
    }

    @ViewBuilder
    private var thumbView: some View {
        Group {
            if #available(iOS 26.0, *), !disableLiquidGlass {
                Color.clear
                    .glassEffect(viewModel.isDragging ? .regular.interactive(true) : .identity, in: thumbShape)
                    .overlay(thumbShape.fill(thumbColor).opacity(viewModel.isDragging ? 0.0 : 1.0))
            } else {
                thumbShape.fill(thumbColor)
            }
        }
        .foregroundColor(thumbColor)
        .frame(
            width: axis == .horizontal ? viewModel.resolvedThumbThickness : viewModel.resolvedThumbLength,
            height: axis == .horizontal ? viewModel.resolvedThumbLength : viewModel.resolvedThumbThickness
        )
        .scaleEffect(viewModel.isDragging && enableThumbScale ? Metrics.dragScaleMultiplier : 1.0)
        .shadow(color: thumbShadow.color, radius: thumbShadow.radius, x: thumbShadow.x, y: thumbShadow.y)
        .overlay {
            if let stroke = thumbStroke {
                thumbShape.stroke(stroke.style, lineWidth: stroke.lineWidth)
            }
        }
        .offset(
            x: axis == .horizontal ? viewModel.thumbOffset : 0,
            y: axis == .horizontal ? 0 : -viewModel.thumbOffset
        )
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged(onDragChanged)
                .onEnded(onDragEnded)
        )
    }

    private var colorPreviewView: some View {
        let resolvedShape = previewShape ?? AnyShape(RoundedRectangle(cornerRadius: dimensions.previewCornerRadius))

        return resolvedShape
            .foregroundColor(viewModel.isDragging ? calculatedColor : Color(selection))
            .frame(width: dimensions.previewSize, height: dimensions.previewSize)
            .scaleEffect(
                previewHidden && !viewModel.isDragging ? dimensions.scaleRatio : 1.0,
                // Dynamically flip the anchor based on offset.
                anchor: axis == .horizontal ? (viewModel.resolvedPreviewOffset > 0 ? .top : .bottom) : (viewModel.resolvedPreviewOffset > 0 ? .leading : .trailing)
            )
            .opacity(previewHidden && !viewModel.isDragging ? 0 : 1.0)
            .shadow(color: previewShadow.color, radius: previewShadow.radius, x: previewShadow.x, y: previewShadow.y)
            .overlay {
                if let stroke = previewStroke {
                    resolvedShape.stroke(stroke.style, lineWidth: stroke.lineWidth)
                }
            }
            .offset(
                x: axis == .horizontal ? viewModel.previewMainAxisOffset : viewModel.resolvedPreviewOffset,
                y: axis == .horizontal ? viewModel.resolvedPreviewOffset : -viewModel.previewMainAxisOffset
            )
    }
    
    // MARK: - Drag Event Handlers

    /// Updates the view's state when the position of the `DragGesture`
    /// changes.
    ///
    /// Called continuously while the user is dragging the thumb. Calculates
    /// `liveContainerThumbDrag`, `liveColorPosition` and`liveThumbPosition`.
    ///
    /// - Parameter value: The current value of the `DragGesture`.
    private func onDragChanged(_ value: DragGesture.Value) {
        if !viewModel.isDragging {
            withAnimation(reduceMotion ? nil : animation) { viewModel.isDragging = true }
        }
        viewModel.liveContainerDrag = axis == .horizontal ? value.translation.width : -value.translation.height
        progress = Double(dimensions.length > 0 ? viewModel.liveColorPosition / dimensions.length : 0.0)
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
            viewModel.isDragging = false
            viewModel.persistedThumbPosition = viewModel.liveThumbPosition
            viewModel.liveContainerDrag = .zero
        }
    }

    /// Adjusts the slider by a specific percentage step (for VoiceOver).
    private func accessibilityAdjust(direction: AccessibilityAdjustmentDirection) {
        viewModel.accessibilityAdjust(direction: direction, progress: &progress, step: accessibilityStep)
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
