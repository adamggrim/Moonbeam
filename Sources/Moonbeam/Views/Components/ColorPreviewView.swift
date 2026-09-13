import SwiftUI

/// An isolated view responsible for rendering the floating color preview.
internal struct ColorPreviewView: View {
    let currentColor: Color
    let dimensions: ColorSliderDimensions

    var body: some View {
        Rectangle()
            .foregroundColor(currentColor)
            .frame(width: dimensions.previewSize, height: dimensions.previewSize)
    }
}
