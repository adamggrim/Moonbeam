import SwiftUI

struct ColorSliderView: View {
    
    var viewModel: ColorSliderViewModel
    
    let dimensions: ColorSliderDimensions
    let duration = 0.25
    
    init(width: CGFloat, height: CGFloat, color: Color, thumbColor: Color = .white) {
        let dimensions = ColorSliderDimensions(width: width, height: height)
        self.dimensions = dimensions
        self.viewModel = ColorSliderViewModel(color: color, thumbColor: thumbColor, dimensions: dimensions)
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
                .scaleEffect(viewModel.isDragging ? 1.0 : dimensions.scaleRatio, anchor: .bottom)
                .opacity(viewModel.isDragging ? 1.0 : .zero)
                .shadow(radius: dimensions.shadowRadius)
                .offset(x: viewModel.colorPreviewHorizontalOffset, y: viewModel.colorPreviewVerticalOffset)
        }
        .frame(width: dimensions.sliderWidth, height: dimensions.thumbHeight)
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

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        ColorSliderView(width: 200, height: 15, color: Color.red)
            .colorScheme(.dark)
    }
}
