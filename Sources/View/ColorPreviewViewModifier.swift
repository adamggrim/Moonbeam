import SwiftUI

// Apply modifiers based on whether the color preview is hidden.
struct ColorPreviewViewModifier: ViewModifier {
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
    func modifyColorPreview(isDragging: Bool, scaleRatio: CGFloat, previewHidden: Bool, anchor: UnitPoint) -> some View {
        self.modifier(ColorPreviewViewModifier(isDragging: isDragging, scaleRatio: scaleRatio, previewHidden: previewHidden, anchor: anchor))
    }
}
