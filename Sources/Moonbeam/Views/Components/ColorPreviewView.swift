import SwiftUI

/// An isolated view responsible for rendering the floating color preview.
public struct ColorPreviewView: View {
    /// The currently color displayed in the preview.
    public let currentColor: Color
    /// The dimensions for the preview's size and position.
    public let dimensions: ColorSliderDimensions
    @Environment(\.controlSize) private var controlSize

    /// Creates a new floating color preview.
    ///
    /// - Parameters:
    ///   - currentColor: The color displayed in the preview.
    ///   - dimensions: The dimensions for the preview's size and position.
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
