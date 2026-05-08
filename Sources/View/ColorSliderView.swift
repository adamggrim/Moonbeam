import SwiftUI

public enum ThumbStyle {
    case capsule, circle
}

public struct ColorSliderView: View {
    @State private var viewModel: ColorSliderViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding var selectedColor: Color
    let label: LocalizedStringKey
    let axis: Axis
    let dimensions: ColorSliderDimensions
    let thumbColor: Color
    let duration: Double
    let disableLiquidGlass: Bool
    let enableThumbScale: Bool

    public init(
        selectedColor: Binding<Color>,
        dataSource: ColorSliderDataSource,
        label: LocalizedStringKey = "Color Slider",
        axis: Axis = .horizontal,
        thickness: CGFloat = 25,
        length: CGFloat = 300,
        thumbThickness: CGFloat? = nil,
        thumbLength: CGFloat? = nil,
        previewSize: CGFloat = 60,
        previewOffset: CGFloat? = nil,
        shadowRadius: CGFloat = 5,
        thumbColor: Color = .white,
        thumbStyle: ThumbStyle = .capsule,
        previewHidden: Bool = true,
        disableLiquidGlass: Bool = false,
        enableThumbScale: Bool? = nil,
        duration: Double = 0.25
    ) {
        let resolvedThumbThickness = thumbThickness ?? thickness
        let resolvedThumbLength = thumbStyle == .circle ? resolvedThumbThickness : (thumbLength ?? thickness * 2) // Prevent a rectangular bounding box.
        
        let resolvedPreviewOffset = previewOffset ?? (axis == .horizontal ? -70 : 70)
        
        let dimensions = ColorSliderDimensions(
            thickness: thickness,
            length: length,
            thumbThickness: resolvedThumbThickness,
            thumbLength: resolvedThumbLength,
            previewSize: previewSize,
            previewOffset: resolvedPreviewOffset,
            shadowRadius: shadowRadius
        )

        self._viewModel = State(initialValue: ColorSliderViewModel(
            axis: axis,
            positionRatio: 0.0,
            thumbStyle: thumbStyle,
            previewHidden: previewHidden,
            dimensions: dimensions,
            dataSource: dataSource
        ))
        self._selectedColor = selectedColor
        self.label = label
        self.axis = axis
        self.dimensions = dimensions
        self.duration = duration
        self.thumbColor = thumbColor
        self.disableLiquidGlass = disableLiquidGlass
        
        if let explicitScale = enableThumbScale {
            self.enableThumbScale = explicitScale
        } else {
            if #available(iOS 26.0, *) {
                self.enableThumbScale = !disableLiquidGlass
            } else {
                self.enableThumbScale = false
            }
        }
    }

    private var trackView: some View {
            Capsule().fill(
                LinearGradient(
                    gradient: viewModel.trackGradient,
                    startPoint: axis == .horizontal ? .leading : .bottom,
                    endPoint: axis == .horizontal ? .trailing : .top
                )
            )
            .frame(
                width: axis == .horizontal ? dimensions.length : dimensions.thickness,
                height: axis == .horizontal ? dimensions.thickness : dimensions.length
            )
        }
        
        @ViewBuilder
        private var thumbView: some View {
            let thumbShape = viewModel.thumbStyle == .capsule ? AnyShape(Capsule()) : AnyShape(Circle())

            Group {
                if #available(iOS 26.0, *), !disableLiquidGlass {
                    Color.clear
                        .glassEffect(
                            viewModel.isDragging ? .regular.interactive(true) : .identity,
                            in: thumbShape
                        )
                        .overlay(
                            thumbShape
                                .fill(thumbColor)
                                .opacity(viewModel.isDragging ? 0.0 : 1.0)
                        )
                } else {
                    thumbShape
                        .fill(thumbColor)
                }
            }
            .foregroundColor(thumbColor)
            .frame(
                width: axis == .horizontal ? dimensions.thumbThickness : dimensions.thumbLength,
                height: axis == .horizontal ? dimensions.thumbLength : dimensions.thumbThickness
            )
            .scaleEffect(viewModel.isDragging && enableThumbScale ? 1.25 : 1.0)
            .shadow(radius: dimensions.shadowRadius)
            .offset(
                x: axis == .horizontal ? viewModel.thumbOffset : 0,
                y: axis == .horizontal ? 0 : -viewModel.thumbOffset
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !viewModel.isDragging {
                            withAnimation(reduceMotion ? nil : .easeInOut(duration: duration)) {
                                viewModel.isDragging = true
                            }
                        }
                        viewModel.onDragChanged(value)
                    }
                    .onEnded { _ in
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: duration)) {
                            viewModel.isDragging = false
                            viewModel.onDragEnded()
                        }
                    }
            )
        }
        
        private var previewView: some View {
            // Color preview
            RoundedRectangle(cornerRadius: dimensions.previewCornerRadius)
                .foregroundColor(viewModel.calculatedColor)
                .frame(width: dimensions.previewSize, height: dimensions.previewSize)
                .modifyPreview(
                    isDragging: viewModel.isDragging,
                    scaleRatio: dimensions.scaleRatio,
                    previewHidden: viewModel.previewHidden,
                    anchor: axis == .horizontal ? .bottom : (dimensions.previewOffset < 0 ? .trailing : .leading)
                )
                .shadow(radius: dimensions.shadowRadius)
                .offset(
                    x: axis == .horizontal ? viewModel.previewMainAxisOffset : dimensions.previewOffset,
                    y: axis == .horizontal ? dimensions.previewOffset : -viewModel.previewMainAxisOffset
                )
        }

        // MARK: - Main Body

        public var body: some View {
            ZStack(alignment: axis == .horizontal ? .leading : .bottom) {
                trackView
                thumbView
                previewView
            }
            .frame(
                width: axis == .horizontal ? dimensions.length : dimensions.thumbLength,
                height: axis == .horizontal ? dimensions.thumbLength : dimensions.length
            )
            .onChange(of: viewModel.calculatedColor, initial: true) { _, newValue in
                selectedColor = newValue
            }
            .accessibilityElement(children: .ignore) // Hides individual shapes from VoiceOver.
            .accessibilityValue(Double(viewModel.positionRatio).formatted(.percent))
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    viewModel.accessibilityAdjust(by: 0.05)
                case .decrement:
                    viewModel.accessibilityAdjust(by: -0.05)
                @unknown default:
                    break
                }
            }
            .accessibilityLabel(label)
        }
}

// MARK: - Modifiers & Previews

// Apply modifiers based on whether the color preview is hidden.
struct PreviewViewModifier: ViewModifier {
    var isDragging: Bool
    let scaleRatio: CGFloat
    let previewHidden: Bool
    let anchor: UnitPoint

    func body(content: Content) -> some View {
        content
            .scaleEffect(previewHidden && !isDragging ? scaleRatio : 1.0, anchor: anchor)
            .opacity(previewHidden && !isDragging ? 0 : 1.0)
    }
}

extension View {
    func modifyPreview(isDragging: Bool, scaleRatio: CGFloat, previewHidden: Bool, anchor: UnitPoint) -> some View {
        self.modifier(PreviewViewModifier(isDragging: isDragging, scaleRatio: scaleRatio, previewHidden: previewHidden, anchor: anchor))
    }
}

private struct PreviewContainer: View {
    let dataSource: ColorSliderDataSource
    var axis: Axis = .horizontal
    var thumbStyle: ThumbStyle = .capsule
    var disableLiquidGlass: Bool = false
    
    @State private var selectedColor: Color = .clear

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            ColorSliderView(
                selectedColor: $selectedColor,
                dataSource: dataSource,
                axis: axis,
                length: 300,
                thickness: 25,
                previewSize: 100,
                previewOffset: -95,
                shadowRadius: 5,
                thumbStyle: thumbStyle,
                disableLiquidGlass: disableLiquidGlass
            )
        }
    }
}

#Preview("Horizontal Slider") {
    let spectrumModel = try! SpectrumSliderModel {
        BlackSection()
        HueSection(minHue: 0.0, maxHue: 1.0)
        WhiteSection()
    }
    return PreviewContainer(dataSource: spectrumModel)
}

#Preview("Vertical Slider") {
    let spectrumModel = try! SpectrumSliderModel {
        BlackSection()
        HueSection(minHue: 0.0, maxHue: 1.0)
        WhiteSection()
    }
    return PreviewContainer(dataSource: spectrumModel, axis: .vertical)
}


#Preview("Spectrum with BendSections") {
    let spectrumModel = try! SpectrumSliderModel {
        HueSection(minHue: 0.0, maxHue: 1.0) {
            OneWayBend(hue: 0.0...(40.0 / 360), saturation: 0.5)
            TwoWayBend(hue: (200.0 / 360)...(280.0 / 360), saturation: 0.3)
        }
    }

    return PreviewContainer(dataSource: spectrumModel)
}

#Preview("Spectrum with MonochromeSections") {
    let spectrumModel = try! SpectrumSliderModel {
        BlackSection()
        WhiteSection()

        HueSection(minHue: 0.0, maxHue: 1.0)

        BlackSection()
        WhiteSection()

    }

    return PreviewContainer(dataSource: spectrumModel)
}

#Preview("Gradient") {
    let gradientModel = GradientSliderModel(
        startColor: .cyan,
        endColor: .purple
    )

    return PreviewContainer(dataSource: gradientModel)
}

#Preview("Circle Thumb (Horizontal)") {
    let spectrumModel = try! SpectrumSliderModel {
        BlackSection()
        HueSection(minHue: 0.0, maxHue: 1.0)
        WhiteSection()
    }
    return PreviewContainer(dataSource: spectrumModel, axis: .horizontal, thumbStyle: .circle)
}

#Preview("Circle Thumb (Vertical)") {
    let spectrumModel = try! SpectrumSliderModel {
        BlackSection()
        HueSection(minHue: 0.0, maxHue: 1.0)
        WhiteSection()
    }
    return PreviewContainer(dataSource: spectrumModel, axis: .vertical, thumbStyle: .circle)
}

#Preview("BendSections (Glass Disabled)") {
    let spectrumModel = try! SpectrumSliderModel {
        HueSection(minHue: 0.0, maxHue: 1.0) {
            OneWayBend(hue: 0.0...(40.0 / 360), saturation: 0.5)
            TwoWayBend(hue: (200.0 / 360)...(280.0 / 360), saturation: 0.3)
        }
    }

    return PreviewContainer(
        dataSource: spectrumModel,
        disableLiquidGlass: true
    )
}
