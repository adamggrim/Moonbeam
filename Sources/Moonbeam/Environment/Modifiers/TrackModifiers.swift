import SwiftUI

public extension View {
    /// Adds a stroke to the slider track.
    func colorSliderTrackStroke<S: ShapeStyle>(
        _ style: S,
        lineWidth: CGFloat = ColorSliderDefaults.strokeLineWidth
    ) -> some View {
        let stroke = TrackStroke(style: AnyShapeStyle(style), lineWidth: lineWidth)
        return environment(\.colorSliderTrackStroke, stroke)
    }

    /// Changes the corner radius so the slider track appears as a
    /// `RoundedRectangle` instead of a `Capsule`.
    func colorSliderCornerRadius(_ radius: CGFloat) -> some View {
        var newDimensions = ColorSliderDimensions()
        newDimensions.cornerRadius = radius
        return environment(\.colorSliderDimensions, newDimensions)
    }
}
