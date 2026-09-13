import SwiftUI

/// An isolated view responsible for calculating the dimensions of the draggable
/// slider thumb.
internal struct ThumbView: View {
    let axis: Axis
    let resolvedThumbThickness: CGFloat
    let resolvedThumbLength: CGFloat

    var body: some View {
        let thumbWidth: CGFloat = axis == .horizontal ? resolvedThumbThickness : resolvedThumbLength
        let thumbHeight: CGFloat = axis == .horizontal ? resolvedThumbLength : resolvedThumbThickness

        Color.clear
            .frame(width: thumbWidth, height: thumbHeight)
    }
}
