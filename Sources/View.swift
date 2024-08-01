import SwiftUI

// The color slider, with a draggable thumb and color preview
struct ColorSliderView: View {
    
    var viewModel: ColorSliderViewModel
    
    let dimensions: ColorSliderDimensions
    let duration = 0.25
    
    init(width: CGFloat, height: CGFloat, color: Color, thumbColor: Color = .white, previewHidden: Bool = true) {
        let dimensions = ColorSliderDimensions(width: width, height: height)
        self.dimensions = dimensions
        self.viewModel = ColorSliderViewModel(color: color, thumbColor: thumbColor, previewHidden: previewHidden, dimensions: dimensions)
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
            
            // Thumb capsule
            Capsule()
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
                            viewModel.color = viewModel.calculatedColor
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
            RoundedRectangle(cornerRadius: dimensions.colorPreviewCornerRadius)
                .foregroundColor(viewModel.color)
                .frame(width: dimensions.colorPreviewWidth, height: dimensions.colorPreviewWidth)
                .modifyColorPreview(isDragging: viewModel.isDragging, scaleRatio: dimensions.scaleRatio, previewHidden: viewModel.previewHidden)
                .shadow(radius: dimensions.shadowRadius)
                .offset(x: viewModel.colorPreviewHorizontalOffset, y: viewModel.colorPreviewVerticalOffset)
        }
        .frame(width: dimensions.sliderWidth, height: dimensions.thumbHeight)
    }
}

// Apply modifiers based on whether the color preview is hidden.
struct ColorPreviewViewModifier: ViewModifier {
    
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
    
    func modifyColorPreview(isDragging: Bool, scaleRatio: CGFloat, previewHidden: Bool) -> some View {
        self.modifier(ColorPreviewViewModifier(isDragging: isDragging, scaleRatio: scaleRatio, previewHidden: previewHidden))
    }
}

struct ColorSliderDimensions {
    
    let sliderWidth: CGFloat
    let sliderHeight: CGFloat
    let thumbWidth: CGFloat
    let thumbHeight: CGFloat
    let colorPreviewWidth: CGFloat
    let colorPreviewCornerRadius: CGFloat
    let shadowRadius: CGFloat
    let scaleRatio: CGFloat = 0.25
    
    init(width: CGFloat, height: CGFloat) {
        self.sliderWidth = width
        self.sliderHeight = height
        self.thumbWidth = height
        self.thumbHeight = height * 2.3333
        self.colorPreviewWidth = height * 3.3333
        self.colorPreviewCornerRadius = height * 0.6666
        self.shadowRadius = height / 2
    }
}
