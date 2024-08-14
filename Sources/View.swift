import SwiftUI

// The color slider, with a draggable thumb and color preview
struct ColorSliderView: View {
    
    var viewModel: ColorSliderViewModel
    let dimensions: ColorSliderDimensions
    
    let duration = 0.25
    
    init(sliderWidth: CGFloat, sliderHeight: CGFloat, thumbWidth: CGFloat, thumbHeight: CGFloat, previewWidth: CGFloat, previewOffset: CGFloat, shadowRadius: CGFloat, startingColor: Color, thumbColor: Color = .white, thumbStyle: ThumbStyle, previewHidden: Bool = true) {
        let dimensions = ColorSliderDimensions(sliderWidth: sliderWidth, sliderHeight: sliderHeight, thumbWidth: thumbWidth, thumbHeight: thumbHeight, previewWidth: previewWidth, previewOffset: previewOffset, shadowRadius: shadowRadius)
        self.dimensions = dimensions
        self.viewModel = ColorSliderViewModel(
            startingColor: startingColor,
            thumbColor: thumbColor,
            thumbStyle: thumbStyle,
            previewHidden: previewHidden,
            dimensions: dimensions)
    }
    
    var body: some View {
        
        ZStack(alignment: .leading) {
            
            // Gradient capsule
            Capsule().fill(
                LinearGradient(
                    gradient: Gradient(colors: sliderColors),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: dimensions.sliderHeight)
            
            // Slider thumb
            Group {
                switch viewModel.thumbStyle {
                case .capsule:
                    Capsule()
                case .circle:
                    Circle()
                }
            }
            .foregroundColor(viewModel.thumbColor)
            .frame(width: dimensions.thumbWidth, height: dimensions.thumbHeight)
            .shadow(radius: dimensions.shadowRadius)
            .offset(x: viewModel.thumbOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        withAnimation(.easeInOut(duration: duration)) {
                            viewModel.isDragging = true
                        }
                        viewModel.startingColor = viewModel.calculatedColor
                        viewModel.onDragChanged(value)
                    }
                    .onEnded { value in
                        withAnimation(.easeInOut(duration: duration)) {
                            viewModel.isDragging = false
                        }
                        viewModel.onDragEnded()
                    }
            )
            
            // Floating color preview
            RoundedRectangle(cornerRadius: dimensions.previewCornerRadius)
                .foregroundColor(viewModel.startingColor)
                .frame(width: dimensions.previewWidth, height: dimensions.previewWidth)
                .modifyPreview(isDragging: viewModel.isDragging, scaleRatio: dimensions.scaleRatio, previewHidden: viewModel.previewHidden)
                .shadow(radius: dimensions.shadowRadius)
                .offset(x: viewModel.previewHorizontalOffset, y: dimensions.previewOffset)
        }
        .frame(width: dimensions.sliderWidth, height: dimensions.thumbHeight)
    }
}

enum ThumbStyle {
    case capsule
    case circle
}

// Apply modifiers based on whether the color preview is hidden.
struct PreviewViewModifier: ViewModifier {
    
    var isDragging: Bool
    let scaleRatio: CGFloat
    let previewHidden: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(previewHidden && !isDragging ? scaleRatio : 1.0, anchor: .bottom)
            .opacity(previewHidden && !isDragging ? 0 : 1.0)
    }
}

extension View {
    
    func modifyPreview(isDragging: Bool, scaleRatio: CGFloat, previewHidden: Bool) -> some View {
        self.modifier(PreviewViewModifier(isDragging: isDragging, scaleRatio: scaleRatio, previewHidden: previewHidden))
    }
}

struct ColorSliderDimensions {
    
    let sliderWidth: CGFloat
    let sliderHeight: CGFloat
    let thumbWidth: CGFloat
    let thumbHeight: CGFloat
    let previewWidth: CGFloat
    let previewCornerRadius: CGFloat
    let previewOffset: CGFloat
    let shadowRadius: CGFloat
    let scaleRatio: CGFloat = 0.25
    
    init(sliderWidth: CGFloat, sliderHeight: CGFloat, thumbWidth: CGFloat, thumbHeight: CGFloat, previewWidth: CGFloat, previewOffset: CGFloat, shadowRadius: CGFloat) {
        self.sliderWidth = sliderWidth
        self.sliderHeight = sliderHeight
        self.thumbWidth = thumbWidth
        self.thumbHeight = thumbHeight
        self.previewWidth = previewWidth
        self.previewOffset = previewOffset
        self.shadowRadius = shadowRadius
        self.previewCornerRadius = previewWidth * 0.225
    }
}
