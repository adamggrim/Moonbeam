import SwiftUI

/// An isolated view responsible for rendering the floating color preview.
public struct ColorPreviewView: View {
    public let currentColor: Color
    public let dimensions: ColorSliderDimensions
    @Environment(\.controlSize) private var controlSize

    public init(currentColor: Color, dimensions: ColorSliderDimensions) {
        self.currentColor = currentColor
        self.dimensions = dimensions
    }

    public var body: some View {
        let size = dimensions.previewSize ?? ColorSliderDefaults.previewSize(for: controlSize)
        Rectangle()
            .foregroundColor(currentColor)
            .frame(width: size, height: size)
    }
}
