import SwiftUI

/// A customizable, interactive view that allows users to select a color
/// from a dynamically generated spectrum or gradient.
public struct ColorSliderView: View {
    @Binding public var selectedColor: Color
    public let dataSource: ColorSliderDataSource
    public let label: LocalizedStringKey
    public let axis: Axis

    @Environment(\.colorSliderTrackStroke) private var trackStroke
    
    @Environment(\.colorSliderThumbShape) private var thumbShape
    @Environment(\.colorSliderThumbColor) private var thumbColor
    @Environment(\.colorSliderThumbStroke) private var thumbStroke
    
    @Environment(\.colorSliderPreviewShape) private var previewShape
    @Environment(\.colorSliderPreviewStroke) private var previewStroke
    @Environment(\.colorSliderPreviewPosition) private var previewPosition
    @Environment(\.colorSliderPreviewSpacing) private var previewSpacing
    @Environment(\.colorSliderPreviewHidden) private var previewHidden
    
    @Environment(\.colorSliderDisableLiquidGlass) private var disableLiquidGlass
    @Environment(\.colorSliderDimensions) private var dimensions
    @Environment(\.colorSliderHardEdgeInnerShadow) private var enableInnerShadow
    @Environment(\.colorSliderAnimation) private var animation
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Constants
    private enum Metrics {
        static let defaultPreviewOffset: CGFloat = 70.0
        static let dragScaleMultiplier: CGFloat = 1.1
        static let accessibilityStepPercentage: CGFloat = 0.05
    }
    
    // MARK: - State
    
    /// Indicates whether a drag gesture is currently active.
    @State private var isDragging: Bool = false
    
    ///  The current horizontal drag within the parent container view, equivalent
    ///  to the `value.translation.width` of the `DragGesture`.
    ///
    ///  Can extend beyond the end of the slider.
    @State private var liveContainerDrag: CGFloat = .zero
    
    /// The persisted horizontal position of the start of the thumb on the slider.
    ///
    /// Cannot extend beyond the thumb's leading edge at the end of the slider.
    @State private var persistedThumbPosition: CGFloat = .zero
    
    /// The position of the selected color in the slider, normalized to a range
    /// from 0.0 to 1.0.
    @State private var positionRatio: CGFloat = 0.0

    /// Initializes a customizable color slider.
    ///
    /// - Parameters:
    ///   - selectedColor: A binding to the currently selected color.
    ///   - dataSource: The model providing the gradient or spectrum data.
    ///   - label: A localized string key used for VoiceOver accessibility. Defaults to "Color Slider".
    ///   - axis: The layout orientation of the slider. Defaults to `.horizontal`.
    public init(
        selectedColor: Binding<Color>,
        dataSource: ColorSliderDataSource,
        label: LocalizedStringKey = "Color Slider",
        axis: Axis = .horizontal
    ) {
        self._selectedColor = selectedColor
        self.dataSource = dataSource
        self.label = label
        self.axis = axis
    }
    
    // MARK: - Layout Calculations

    private var resolvedThumbThickness: CGFloat { dimensions.thumbThickness ?? dimensions.thickness }
    private var resolvedThumbLength: CGFloat { dimensions.thumbLength ?? dimensions.thickness * 2 }
    private var resolvedPreviewOffset: CGFloat { dimensions.previewOffset ?? (axis == .horizontal ? -Metrics.defaultPreviewOffset : Metrics.defaultPreviewOffset) }
    private var halfThumbThickness: CGFloat { resolvedThumbThickness / 2 }
        
    /// Inset to adjust the left and right bounds of the thumb if it is thinner than the track.
    private var thumbInset: CGFloat { (dimensions.thickness - resolvedThumbThickness) / 2 }
    
    /// The current `liveContainerDrag` combined with the
    /// `persistedThumbPosition`. Equivalent to the horizontal position of the
    /// thumb's leading edge during a `DragGesture`.
    ///
    /// This is an intermediate value calculated during an active drag.
    ///
    /// Like `liveContainerDrag`, can extend beyond the end of the slider.
    private var liveContainerThumbDrag: CGFloat { persistedThumbPosition + liveContainerDrag }
    
    /// The clamped horizontal position of the current selected color on the
    ///     slider.
    ///
    ///     For most of the slider, corresponds with the horizontal position of the
    ///     thumb's center. At the start or end of the slider, can extend beyond the
    ///     thumb's center to the start or end of the thumb.
    private var liveColorPosition: CGFloat {
        min(max(liveContainerThumbDrag + halfThumbThickness, 0), dimensions.length)
    }
    
    /// The clamped horizontal position of the start of the thumb during an active
    /// drag.
    ///
    /// Cannot extend beyond the thumb's leading edge at the end of the slider.
    private var liveThumbPosition: CGFloat {
        min(max(liveContainerThumbDrag, 0 + thumbInset), dimensions.length - resolvedThumbThickness - thumbInset)
    }

    /// The color calculated from the current `liveColorPosition` on the slider.
    private var calculatedColor: Color {
        let safeLength = dimensions.length > 0 ? dimensions.length : 0.001
        let clampedRatio = max(0.0, min(1.0, liveColorPosition / safeLength))
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

    /// The main axis offset for the floating color preview.
    ///
    /// Except at the ends of the slider, the floating color preview is centered above the
    /// thumb's center.
    private var previewMainAxisOffset: CGFloat {
        let halfPreviewSize = dimensions.previewSize / 2
        let leftBound = halfPreviewSize - halfThumbThickness
        let rightBound = dimensions.length - halfPreviewSize - halfThumbThickness
        let clampedValue = min(max(liveThumbPosition, leftBound), rightBound)

        /// The offset that centers the floating color preview above the thumb.
        let halfThumbOffset = thumbOffset + halfThumbThickness

        if previewHidden {
            let startEdgeLimit: CGFloat
            let endEdgeLimit: CGFloat
            let offsetAdjustment: CGFloat = halfThumbThickness

            startEdgeLimit = -halfPreviewSize + halfThumbOffset
            endEdgeLimit = -halfPreviewSize + halfThumbOffset

            if !isDragging && halfThumbOffset < halfPreviewSize {
                return startEdgeLimit
            } else if (!isDragging && halfThumbOffset > dimensions.length - halfPreviewSize) {
                return endEdgeLimit
            } else {
                return clampedValue - halfPreviewSize + offsetAdjustment
            }
        } else {
            if halfThumbOffset < halfPreviewSize {
                // Clamp the color preview to the starting edge of the slider.
                return 0
            } else if halfThumbOffset > dimensions.length - halfPreviewSize {
                return dimensions.length - dimensions.previewSize
            } else {
                // Clamp the color preview to the ending edge of the slider.
                return clampedValue - halfPreviewSize + halfThumbThickness
            }
        }
    }

    /// The offset of the thumb's leading edge.
    private var thumbOffset: CGFloat {
        min(max(liveThumbPosition, thumbInset), dimensions.length - resolvedThumbThickness - thumbInset)
    }

    /// Set to `true` to scale the thumb up during a drag gesture. Defaults to `true` if liquid glass is supported and enabled.
    private var enableThumbScale: Bool {
        if #available(iOS 26.0, *) { return !disableLiquidGlass }
        return false
    }

    // MARK: - Views
    public var body: some View {
        ZStack(alignment: axis == .horizontal ? .leading : .bottom) {
            trackView
            thumbView
            colorPreviewView
        }
        .frame(
            width: axis == .horizontal ? dimensions.length : resolvedThumbLength,
            height: axis == .horizontal ? resolvedThumbLength : dimensions.length
        )
        .onChange(of: calculatedColor, initial: true) { _, newValue in
            selectedColor = newValue
        }
        .accessibilityElement(children: .ignore) // Hides individual shapes from VoiceOver.
        .accessibilityValue(Double(positionRatio).formatted(.percent))
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
            switch dataSource.colorSource {
            case .array(let colors):
                hardEdgeTrackView(colors: colors)
                    .clipShape(Capsule())
            case .function(let colorGenerator):
                Capsule().fill(colorGenerator(0.5))
            case .shader(let shaderGenerator, _):
                Capsule()
                    .fill(Color.white) // Pixels for Metal to paint on.
                    .colorEffect(shaderGenerator(size, axis == .vertical))
            }
        }
        .frame(width: size.width, height: size.height)
        .overlay {
            if let stroke = trackStroke {
                Capsule().stroke(stroke.style, lineWidth: stroke.lineWidth)
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
        if enableInnerShadow {
            Rectangle()
                .fill(
                    color.shadow(.inner(color: .black.opacity(0.3), radius: 3, x: 0, y: 0))
                )
        } else {
            Rectangle()
                .fill(color)
        }
    }

    @ViewBuilder
    private var thumbView: some View {
        Group {
            if #available(iOS 26.0, *), !disableLiquidGlass {
                Color.clear
                    .glassEffect(isDragging ? .regular.interactive(true) : .identity, in: thumbShape)
                    .overlay(thumbShape.fill(thumbColor).opacity(isDragging ? 0.0 : 1.0))
            } else {
                thumbShape.fill(thumbColor)
            }
        }
        .foregroundColor(thumbColor)
        .frame(
            width: axis == .horizontal ? resolvedThumbThickness : resolvedThumbLength,
            height: axis == .horizontal ? resolvedThumbLength : resolvedThumbThickness
        )
        .scaleEffect(isDragging && enableThumbScale ? Metrics.dragScaleMultiplier : 1.0)
        .shadow(radius: dimensions.shadowRadius)
        .overlay {
            if let stroke = thumbStroke {
                thumbShape.stroke(stroke.style, lineWidth: stroke.lineWidth)
            }
        }
        .offset(
            x: axis == .horizontal ? thumbOffset : 0,
            y: axis == .horizontal ? 0 : -thumbOffset
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
            .foregroundColor(calculatedColor)
            .frame(width: dimensions.previewSize, height: dimensions.previewSize)
            .scaleEffect(
                previewHidden && !isDragging ? dimensions.scaleRatio : 1.0,
                anchor: axis == .horizontal ? .bottom : (resolvedPreviewOffset < 0 ? .trailing : .leading)
            )
            .opacity(previewHidden && !isDragging ? 0 : 1.0)
            .shadow(radius: dimensions.shadowRadius)
            .overlay {
                if let stroke = previewStroke {
                    resolvedShape.stroke(stroke.style, lineWidth: stroke.lineWidth)
                }
            }
            .offset(
                x: axis == .horizontal ? previewMainAxisOffset : resolvedPreviewOffset,
                y: axis == .horizontal ? resolvedPreviewOffset : -previewMainAxisOffset
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
        if !isDragging {
            withAnimation(reduceMotion ? nil : animation) { isDragging = true }
        }
        liveContainerDrag = axis == .horizontal ? value.translation.width : -value.translation.height
        // Update the ratio so VoiceOver knows where the gesture finished.
        positionRatio = dimensions.length > 0 ? liveColorPosition / dimensions.length : 0.0
    }

    /// Finalizes the view's state when the drag gesture ends, updating
    /// `persistedThumbPosition` with the thumb's last valid clamped position
    /// and resetting `liveContainerDrag` to zero.
    private func onDragEnded(_ value: DragGesture.Value) {
            withAnimation(reduceMotion ? nil : animation) {
            isDragging = false
            persistedThumbPosition = liveThumbPosition
            liveContainerDrag = .zero
        }
    }

    /// Adjusts the slider by a specific percentage step (for VoiceOver).
    private func accessibilityAdjust(direction: AccessibilityAdjustmentDirection) {
        let stepDelta = dimensions.length * (direction == .increment ? Metrics.accessibilityStepPercentage : -Metrics.accessibilityStepPercentage)
        let newDrag = min(max(liveContainerThumbDrag + stepDelta, 0), dimensions.length)
        persistedThumbPosition = min(max(newDrag, thumbInset), dimensions.length - resolvedThumbThickness - thumbInset)
        liveContainerDrag = .zero
        positionRatio = dimensions.length > 0 ? liveColorPosition / dimensions.length : 0.0
    }
}
