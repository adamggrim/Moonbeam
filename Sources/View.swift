import SwiftUI

struct ColorSliderView: View {
    
    var model: ColorSliderModel
    var viewModel: ColorSliderViewModel
    let dimensions: ColorSliderDimensions
    let duration: Double
    
    init(sliderWidth: CGFloat, sliderHeight: CGFloat, thumbWidth: CGFloat? = nil, thumbHeight: CGFloat? = nil, previewWidth: CGFloat, previewOffset: CGFloat, shadowRadius: CGFloat, startingColor: Color, thumbColor: Color = .white, thumbStyle: ThumbStyle = .capsule, previewHidden: Bool = true, duration: Double = 0.25) {
        
        let dimensions = ColorSliderDimensions(sliderWidth: sliderWidth, sliderHeight: sliderHeight, thumbWidth: thumbWidth, thumbHeight: thumbHeight, previewWidth: previewWidth, previewOffset: previewOffset, shadowRadius: shadowRadius)
                
        self.model = ColorSliderModel(maxWhite: <#T##Int#>, maxHue: <#T##Int#>, defaultSaturation: <#T##CGFloat#>)
        self.viewModel = ColorSliderViewModel(
            startingColor: startingColor,
            thumbColor: thumbColor,
            thumbStyle: thumbStyle,
            previewHidden: previewHidden,
            dimensions: dimensions)
        self.dimensions = dimensions
        self.duration = duration
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            
            // Color gradient capsule
            Capsule().fill(
                LinearGradient(
                    gradient: Gradient(colors: model.sliderColors),
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
    let thumbHeight: CGFloat?
    let previewWidth: CGFloat
    let previewCornerRadius: CGFloat
    let previewOffset: CGFloat
    let shadowRadius: CGFloat
    let scaleRatio: CGFloat = 0.25
    
    init(sliderWidth: CGFloat, sliderHeight: CGFloat, thumbWidth: CGFloat? = nil, thumbHeight: CGFloat? = nil, previewWidth: CGFloat, previewOffset: CGFloat, shadowRadius: CGFloat) {
        self.sliderWidth = sliderWidth
        self.sliderHeight = sliderHeight
        self.thumbWidth = thumbWidth ?? sliderHeight
        self.thumbHeight = thumbHeight ?? sliderHeight * 2 // Ignored when thumbStyle is .circle
        self.previewWidth = previewWidth
        self.previewOffset = previewOffset
        self.shadowRadius = shadowRadius
        self.previewCornerRadius = previewWidth * 0.225
    }
}

enum ThumbStyle {
    case capsule, circle
}

enum Orientation {
    case horizontal, vertical
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        ColorSliderView(sliderWidth: 300, sliderHeight: 25, previewWidth: 100, previewOffset: -95, shadowRadius: 5, startingColor: Color.white)
            .colorScheme(.dark)
    }
}
