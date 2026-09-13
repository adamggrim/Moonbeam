import SwiftUI

/// The properties of a styled color slider instance.
public struct ColorSliderStyleConfiguration {

    /// The current value of the color slider, normalized between `0.0` and
    /// `1.0`.
    public let value: Double

    /// A boolean value indicating whether the user is currently dragging the
    /// slider thumb.
    public let isDragging: Bool

    /// The layout orientation of the slider (horizontal or vertical).
    public let axis: Axis

    /// The calculated spatial offset for the thumb along the slider track.
    public let thumbOffset: CGSize

    /// The calculated spatial offset for the floating color preview.
    public let previewOffset: CGSize

    /// The anchor point used to animate the floating preview out of the thumb.
    public let previewScaleAnchor: UnitPoint

    /// The pre-configured background track view.
    public let track: Track

    /// The pre-configured draggable thumb view.
    public let thumb: Thumb

    /// The pre-configured floating color preview view.
    public let preview: Preview

    /// A view representing the track of the color slider.
    public struct Track: View {
        private let content: AnyView
        internal init<V: View>(_ content: V) { self.content = AnyView(content) }
        public var body: some View { content }
    }

    /// A view representing the draggable thumb for the color slider.
    public struct Thumb: View {
        private let content: AnyView
        internal init<V: View>(_ content: V) { self.content = AnyView(content) }
        public var body: some View { content }
    }

    /// A view representing the floating color preview for the color slider.
    public struct Preview: View {
        private let content: AnyView
        internal init<V: View>(_ content: V) { self.content = AnyView(content) }
        public var body: some View { content }
    }
}
