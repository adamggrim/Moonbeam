import SwiftUI

/// A customizable, interactive view that allows users to select a color
/// from a dynamically generated spectrum or gradient.
public struct ColorSliderView: View {
    @Binding public var selectedColor: Color
    public let dataSource: ColorSliderDataSource
    public let label: LocalizedStringKey
    public let axis: Axis

    @Environment(\.colorSliderThumbStyle) private var thumbStyle
    @Environment(\.colorSliderThumbColor) private var thumbColor
    @Environment(\.colorSliderPreviewHidden) private var previewHidden
    @Environment(\.colorSliderDisableLiquidGlass) private var disableLiquidGlass
    @Environment(\.colorSliderDimensions) private var dimensionsEnv
    @Environment(\.colorSliderHardEdgeInnerShadow) private var enableInnerShadow
    @Environment(\.colorSliderPreviewPosition) private var previewPosition
    @Environment(\.colorSliderPreviewSpacing) private var previewSpacing
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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

    /// The duration of the state-change animations. Defaults to 0.25.
    private let duration: Double = 0.25

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

    private var resolvedThumbThickness: CGFloat { dimensionsEnv.thumbThickness ?? dimensionsEnv.thickness }
    private var resolvedThumbLength: CGFloat { thumbStyle == .circle ? resolvedThumbThickness : (dimensionsEnv.thumbLength ?? dimensionsEnv.thickness * 2) } // Prevent a rectangular bounding box.
    private var resolvedPreviewOffset: CGFloat {
        if let rawOffset = dimensionsEnv.previewOffset, previewPosition == nil {
            return rawOffset
        }
        
        let baseDistance: CGFloat = 66 + (previewSpacing ?? 0)
        
        if axis == .horizontal {
            let placement = previewPosition ?? .top
            switch placement {
            case .top: return -baseDistance
            case .bottom: return baseDistance
            case .leading, .trailing: return -baseDistance
            }
        } else {
            let placement = previewPosition ?? .trailing
            switch placement {
            case .trailing: return baseDistance
            case .leading: return -baseDistance
            case .top, .bottom: return baseDistance
            }
        }
    }
    private var halfThumbThickness: CGFloat { resolvedThumbThickness / 2 }
    
    /// Inset to adjust the left and right bounds of the thumb.
    ///
    /// Used when `thumbStyle` is `.circle`.
    private var thumbInset: CGFloat { thumbStyle == .capsule ? 0.0 : (dimensionsEnv.thickness - resolvedThumbThickness) / 2 }
    
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
        min(max(liveContainerThumbDrag + halfThumbThickness, 0), dimensionsEnv.length)
    }
    
    /// The clamped horizontal position of the start of the thumb during an active
    /// drag.
    ///
    /// Cannot extend beyond the thumb's leading edge at the end of the slider.
    private var liveThumbPosition: CGFloat {
        min(max(liveContainerThumbDrag, 0 + thumbInset), dimensionsEnv.length - resolvedThumbThickness - thumbInset)
    }

    /// The color calculated from the current `liveColorPosition` on the slider.
    private var calculatedColor: Color {
        let safeLength = dimensionsEnv.length > 0 ? dimensionsEnv.length : 0.001
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

    /// The main axis offset for the color preview.
    ///
    /// Except at the ends of the slider, the color preview is centered above the
    /// thumb's center.
    private var previewMainAxisOffset: CGFloat {
        let halfPreviewSize = dimensionsEnv.previewSize / 2
        let quarterThumbThickness = halfThumbThickness / 2
        let leftBound = halfPreviewSize - halfThumbThickness
        let rightBound = dimensionsEnv.length - halfPreviewSize - halfThumbThickness
        let clampedValue = min(max(liveThumbPosition, leftBound), rightBound)

        /// The offset that centers the floating color preview above the thumb.
        let halfThumbOffset = thumbOffset + halfThumbThickness

        /// The offset that positions the floating color preview at one quarter
        /// the length of the thumb.
        ///
        /// Used when `thumbStyle` is `.circle`.
        let quarterThumbOffset = thumbOffset + quarterThumbThickness

        if previewHidden {
            let startEdgeLimit: CGFloat
            let endEdgeLimit: CGFloat
            let offsetAdjustment: CGFloat = halfThumbThickness

            if thumbStyle == .capsule {
                startEdgeLimit = -halfPreviewSize + halfThumbOffset
                endEdgeLimit = -halfPreviewSize + halfThumbOffset
            } else {
                startEdgeLimit = -halfPreviewSize + quarterThumbOffset
                let threeQuarterThumbOffset = thumbOffset + resolvedThumbThickness - quarterThumbThickness
                endEdgeLimit = -halfPreviewSize + threeQuarterThumbOffset
            }

            if !isDragging && halfThumbOffset < halfPreviewSize {
                return startEdgeLimit
            } else if (!isDragging && halfThumbOffset > dimensionsEnv.length - halfPreviewSize) {
                return endEdgeLimit
            } else {
                return clampedValue - halfPreviewSize + offsetAdjustment
            }
        } else {
            if halfThumbOffset < halfPreviewSize {
                // Clamp the color preview to the starting edge of the slider.
                return 0
            } else if halfThumbOffset > dimensionsEnv.length - halfPreviewSize {
                return dimensionsEnv.length - dimensionsEnv.previewSize
            } else {
                // Clamp the color preview to the ending edge of the slider.
                return clampedValue - halfPreviewSize + halfThumbThickness
            }
        }
    }

    /// The offset of the thumb's leading edge.
    private var thumbOffset: CGFloat {
        min(max(liveThumbPosition, thumbInset), dimensionsEnv.length - resolvedThumbThickness - thumbInset)
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
            previewView
        }
        .frame(
            width: axis == .horizontal ? dimensionsEnv.length : resolvedThumbLength,
            height: axis == .horizontal ? resolvedThumbLength : dimensionsEnv.length
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
            width: axis == .horizontal ? dimensionsEnv.length : dimensionsEnv.thickness,
            height: axis == .horizontal ? dimensionsEnv.thickness : dimensionsEnv.length
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
        let thumbShape = thumbStyle == .capsule ? AnyShape(Capsule()) : AnyShape(Circle())

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
        .scaleEffect(isDragging && enableThumbScale ? 1.1 : 1.0)
        .shadow(radius: dimensionsEnv.shadowRadius)
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

    private var previewView: some View {
        // Color preview
        RoundedRectangle(cornerRadius: dimensionsEnv.previewCornerRadius)
            .foregroundColor(calculatedColor)
            .frame(width: dimensionsEnv.previewSize, height: dimensionsEnv.previewSize)
            .modifyColorPreview(
                isDragging: isDragging,
                scaleRatio: dimensionsEnv.scaleRatio,
                previewHidden: previewHidden,
                anchor: axis == .horizontal
                    ? (resolvedPreviewOffset < 0 ? .bottom : .top)
                    : (resolvedPreviewOffset < 0 ? .trailing : .leading)
            )
            .shadow(radius: dimensionsEnv.shadowRadius)
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
            withAnimation(reduceMotion ? nil : .easeInOut(duration: duration)) { isDragging = true }
        }
        liveContainerDrag = axis == .horizontal ? value.translation.width : -value.translation.height
        // Update the ratio so VoiceOver knows where the gesture finished.
        positionRatio = dimensionsEnv.length > 0 ? liveColorPosition / dimensionsEnv.length : 0.0
    }

    /// Finalizes the view's state when the drag gesture ends, updating
    /// `persistedThumbPosition` with the thumb's last valid clamped position
    /// and resetting `liveContainerDrag` to zero.
    private func onDragEnded(_ value: DragGesture.Value) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: duration)) {
            isDragging = false
            persistedThumbPosition = liveThumbPosition
            liveContainerDrag = .zero
        }
    }

    /// Adjusts the slider by a specific percentage step (for VoiceOver).
    private func accessibilityAdjust(direction: AccessibilityAdjustmentDirection) {
        let stepDelta = dimensionsEnv.length * (direction == .increment ? 0.05 : -0.05)
        let newDrag = min(max(liveContainerThumbDrag + stepDelta, 0), dimensionsEnv.length)
        persistedThumbPosition = min(max(newDrag, thumbInset), dimensionsEnv.length - resolvedThumbThickness - thumbInset)
        liveContainerDrag = .zero
        positionRatio = dimensionsEnv.length > 0 ? liveColorPosition / dimensionsEnv.length : 0.0
    }
}
