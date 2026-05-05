import SwiftUI

public enum ThumbStyle {
    case capsule, circle
}

public struct ColorSliderView: View {
    @State private var viewModel: ColorSliderViewModel

    @Binding var selectedColor: Color
    let axis: Axis
    let dimensions: ColorSliderDimensions
    let thumbColor: Color
    let duration: Double
    let disableLiquidGlass: Bool
    let enableThumbScale: Bool

    public init(
        selectedColor: Binding<Color>,
        axis: Axis = .horizontal,
        length: CGFloat,
        thickness: CGFloat,
        thumbLength: CGFloat? = nil,
        thumbThickness: CGFloat? = nil,
        previewSize: CGFloat,
        previewOffset: CGFloat,
        shadowRadius: CGFloat,
        thumbColor: Color = .white,
        thumbStyle: ThumbStyle = .capsule,
        previewHidden: Bool = true,
        disableLiquidGlass: Bool = false,
        enableThumbScale: Bool? = nil,
        duration: Double = 0.25,
        dataSource: ColorSliderDataSource
    ) {
        let dimensions = ColorSliderDimensions(
            length: length,
            thickness: thickness,
            thumbLength: thumbLength,
            thumbThickness: thumbThickness,
            previewSize: previewSize,
            previewOffset: previewOffset,
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

    public var body: some View {
        ZStack(alignment: axis == .horizontal ? .leading : .bottom) {

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
                            withAnimation(.easeInOut(duration: duration)) {
                                viewModel.isDragging = true
                            }
                        }
                        viewModel.onDragChanged(value)
                    }
                    .onEnded { _ in
                        withAnimation(.easeInOut(duration: duration)) {
                            viewModel.isDragging = false
                            viewModel.onDragEnded()
                        }
                    }
            )

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
        .frame(
            width: axis == .horizontal ? dimensions.length : dimensions.thumbLength,
            height: axis == .horizontal ? dimensions.thumbLength : dimensions.length
        )
        .onChange(of: viewModel.calculatedColor, initial: true) { _, newValue in selectedColor = newValue
        }
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
            Color.black.ignoresSafeArea()

            ColorSliderView(
                selectedColor: $selectedColor,
                axis: axis,
                length: 300,
                thickness: 25,
                previewSize: 100,
                previewOffset: -95,
                shadowRadius: 5,
                thumbStyle: thumbStyle,
                disableLiquidGlass: disableLiquidGlass,
                dataSource: dataSource
            )
        }
    }
}
