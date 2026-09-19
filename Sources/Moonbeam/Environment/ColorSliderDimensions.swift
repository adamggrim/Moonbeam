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
    public var previewScale: CGFloat = ColorSliderDefaults.previewScale

    /// The scale applied to the thumb during an active drag interaction.
    public var thumbDragScale: CGFloat = ColorSliderDefaults.thumbDragScale

    /// Calculates the effective track thickness, falling back to the control
    /// size default if there is no provided thickness.
    ///
    /// - Parameter controlSize: The active control size from the environment.
    /// - Returns: The resolved track thickness in points.
    internal func resolvedTrackThickness(for controlSize: ControlSize) -> CGFloat {
        thickness ?? ColorSliderDefaults.trackThickness(for: controlSize)
    }

    /// Calculates the effective thumb length, falling back to twice the
    /// resolved track thickness if there is no provided length.
    ///
    /// - Parameter controlSize: The active control size from the environment.
    /// - Returns: The resolved thumb length in points.
    internal func resolvedThumbLength(for controlSize: ControlSize) -> CGFloat {
        thumbLength ?? (resolvedTrackThickness(for: controlSize) * 2)
    }
}
