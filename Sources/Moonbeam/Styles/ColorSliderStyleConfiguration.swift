import SwiftUI

/// The properties of a styled color slider instance.
public struct ColorSliderStyleConfiguration {

    /// The current progress value of the color slider, normalized between
    /// `0.0` and `1.0`.
    public let value: Double

    /// A boolean value indicating whether the user is currently dragging the
    /// slider thumb.
    public let isDragging: Bool

    /// The layout orientation of the slider (`.horizontal` or `.vertical`).
    public let axis: Axis

    /// The calculated spatial offset for the leading edge of the draggable
    /// thumb.
    public let thumbOffset: CGSize

    /// The calculated spatial offset for the floating color preview.
    public let previewOffset: CGSize

    /// The anchor point used to animate the floating color preview out of the thumb.
    public let previewScaleAnchor: UnitPoint

    /// The slider track.
    public let track: Track

    /// The draggable thumb.
    public let thumb: Thumb

    /// The floating color preview.
    public let preview: Preview

    /// A view representing the color slider track.
    public struct Track: View {
        public let body: AnyView
        internal init<V: View>(_ content: V) { self.body = AnyView(content) }
    }

    /// A view representing the draggable thumb.
    public struct Thumb: View {
        public let body: AnyView
        internal init<V: View>(_ content: V) { self.body = AnyView(content) }
    }

    /// A view representing the floating color preview for the color slider.
    public struct Preview: View {
        public let body: AnyView
        internal init<V: View>(_ content: V) { self.body = AnyView(content) }
    }
}
