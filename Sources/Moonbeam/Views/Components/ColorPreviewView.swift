import SwiftUI

/// An isolated view responsible for rendering the floating color preview.
internal struct ColorPreviewView: View {
    let currentColor: Color
    let dimensions: ColorSliderDimensions
    @Environment(\.controlSize) private var controlSize

    var body: some View {
        let size = dimensions.previewSize ?? ColorSliderDefaults.previewSize(for: controlSize)
        Rectangle()
            .foregroundColor(currentColor)
            .frame(width: size, height: size)
    }
}
