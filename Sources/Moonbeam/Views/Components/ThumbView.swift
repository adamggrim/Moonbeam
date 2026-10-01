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
        let hitWidth: CGFloat = max(thumbWidth, ColorSliderDefaults.minimumTouchTarget)
        let hitHeight: CGFloat = max(thumbHeight, ColorSliderDefaults.minimumTouchTarget)

        Color.clear
            .frame(width: thumbWidth, height: thumbHeight)
            .overlay {
                Color.clear
                    .frame(width: hitWidth, height: hitHeight)
                    .contentShape(Rectangle())
            }
    }
}
