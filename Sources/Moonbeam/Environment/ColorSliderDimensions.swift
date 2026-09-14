import SwiftUI

/// Encapsulates various layout dimensions for the color slider and its
/// components.
public struct ColorSliderDimensions: Sendable, Equatable {
    /// The length of the slider track. If `nil`, the slider takes up the
    /// available space.
    public var length: CGFloat? = nil

    /// The thickness of the slider track. If `nil`, the track falls back to the
    /// native control size.
    public var thickness: CGFloat? = nil

    /// The corner radius of the slider track. If `nil`, the track resolves to
    /// a `Capsule` shape.
    public var cornerRadius: CGFloat? = nil

    /// The thickness of the slider thumb. If `nil`, falls back to the track's
    /// `thickness`.
    public var thumbThickness: CGFloat? = nil

    /// The length of the slider thumb. If `nil`, defaults to twice the track's
    /// `thickness`.
    public var thumbLength: CGFloat? = nil

    /// The width and height of the floating color preview. If `nil`, falls back
    /// to the native control size.
    public var previewSize: CGFloat? = nil

    /// The distance between the floating color preview and the slider thumb.
    public var previewOffset: CGFloat? = nil

    /// The scale of the floating color preview when it is hidden and not
    /// actively being dragged.
    public var scaleRatio: CGFloat = ColorSliderDefaults.scaleRatio
}
