import SwiftUI

enum ThumbStyle {
    case capsule, circle
}

struct ColorSliderView: View {
    @State private var viewModel: ColorSliderViewModel

    let axis: Axis
    let dimensions: ColorSliderDimensions
    let thumbColor: Color
    let duration: Double

    init(
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
        self.axis = axis
        self.dimensions = dimensions
        self.duration = duration
        self.thumbColor = thumbColor
    }

    var body: some View {
        ZStack(alignment: axis == .horizontal ? .leading : .bottom) {

            // Track Gradient
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

            Group {
                switch viewModel.thumbStyle {
                case .capsule: Capsule()
                case .circle: Circle()
                }
            }
            .foregroundColor(thumbColor)
            .frame(
                width: axis == .horizontal ? dimensions.thumbThickness : dimensions.thumbLength,
                height: axis == .horizontal ? dimensions.thumbLength : dimensions.thumbThickness
            )
            .shadow(radius: dimensions.shadowRadius)
            .offset(
                x: axis == .horizontal ? viewModel.thumbOffset : 0,
                y: axis == .horizontal ? 0 : -viewModel.thumbOffset
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !viewModel.isDragging {
                            withAnimation(.easeInOut(duration: duration)) { viewModel.isDragging = true }
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

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ColorSliderView(
                axis: axis,
                length: 300,
                thickness: 25,
                previewSize: 100,
                previewOffset: -95,
                shadowRadius: 5,
                dataSource: dataSource
            )
        }
    }
}
