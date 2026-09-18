import SwiftUI

/// The default style applied to a color slider.
///
/// This style includes a Liquid Glass slider thumb (on supported platforms),
/// rounded geometry and a floating color preview.
public struct DefaultColorSliderStyle: ColorSliderStyle {

    // MARK: - Properties

    /// The shape of the slider track.
    public var trackShape: AnyShape?
    /// The stroke applied to the slider track.
    public var trackStroke: ShapeStroke?
    /// The shape of the draggable thumb.
    public var thumbShape: AnyShape?
    /// The fill color of the draggable thumb.
    public var thumbColor: Color
    /// The stroke styling applied to the draggable thumb.
    public var thumbStroke: ShapeStroke?
    /// The shadow properties applied to the draggable thumb.
    public var thumbShadow: ShapeShadow
    /// Disables the Liquid Glass effect on the draggable thumb.
    public var disableLiquidGlass: Bool
    /// The shape applied to the floating color preview.
    public var previewShape: AnyShape?
    /// The stroke styling applied to the floating color preview.
    public var previewStroke: ShapeStroke?
    /// The shadow properties applied to the floating color preview.
    public var previewShadow: ShapeShadow

    @Environment(\.colorSliderDimensions) private var dimensions
    @Environment(\.controlSize) private var controlSize

    // MARK: - Initialization

    public init(
        trackShape: AnyShape? = nil,
        trackStroke: ShapeStroke? = nil,
        thumbShape: AnyShape? = nil,
        thumbColor: Color = .white,
        thumbStroke: ShapeStroke? = nil,
        thumbShadow: ShapeShadow = ShapeShadow(),
        disableLiquidGlass: Bool = false,
        previewShape: AnyShape? = nil,
        previewStroke: ShapeStroke? = nil,
        previewShadow: ShapeShadow = ShapeShadow()
    ) {
        self.trackShape = trackShape
        self.trackStroke = trackStroke
        self.thumbShape = thumbShape
        self.thumbColor = thumbColor
        self.thumbStroke = thumbStroke
        self.thumbShadow = thumbShadow
        self.disableLiquidGlass = disableLiquidGlass
        self.previewShape = previewShape
        self.previewStroke = previewStroke
        self.previewShadow = previewShadow
    }

    // MARK: - Body

    public func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: configuration.axis == .horizontal ? .leading : .bottom) {

            configuration.track
                .clipShape(resolvedTrackShape)
                .overlay {
                    if let stroke = trackStroke {
                        resolvedTrackShape.stroke(stroke.style, lineWidth: stroke.lineWidth)
                    }
                }

            configuration.thumb
                .overlay {
                    let shape = thumbShape ?? AnyShape(Capsule(style: .continuous))
                    let enableThumbScale = {
                        if #available(iOS 26.0, macOS 26.0, *) { return !disableLiquidGlass }
                        return false
                    }()
                    let dynamicScale: CGFloat = (configuration.isDragging && enableThumbScale)
                        ? ColorSliderDefaults.dragScaleMultiplier
                        : 1.0

                    Group {
#if compiler(>=6.2)
                        if #available(iOS 26.0, macOS 26.0, *), !disableLiquidGlass {
                            Color.clear
                                .glassEffect(
                                    configuration.isDragging ? .regular.interactive(true) : .identity, in: shape
                                )
                                .overlay(shape.fill(thumbColor).opacity(configuration.isDragging ? 0.0 : 1.0))
                        } else {
                            shape.fill(thumbColor)
                        }
#else
                        shape.fill(thumbColor)
#endif
                    }
                    .scaleEffect(dynamicScale)
                    .shadow(color: thumbShadow.color, radius: thumbShadow.radius, x: thumbShadow.x, y: thumbShadow.y)
                    .overlay {
                        if let stroke = thumbStroke {
                            shape.stroke(stroke.style, lineWidth: stroke.lineWidth)
                        }
                    }
                }
                .offset(configuration.thumbOffset)
#if !os(macOS)
                .hoverEffect()
#endif

            configuration.preview
                .clipShape(resolvedPreviewShape)
                .overlay {
                    if let stroke = previewStroke {
                        resolvedPreviewShape.stroke(stroke.style, lineWidth: stroke.lineWidth)
                    }
                }
                .shadow(
                    color: previewShadow.color,
                    radius: previewShadow.radius,
                    x: previewShadow.x,
                    y: previewShadow.y
                )
                .scaleEffect(
                    (!configuration.isDragging) ? dimensions.scaleRatio : 1.0,
                    anchor: configuration.previewScaleAnchor
                )
                .opacity((!configuration.isDragging) ? 0.0 : 1.0)
                .offset(configuration.previewOffset)
                .allowsHitTesting(false)
        }
    }

    // MARK: - Geometry resolution

    private var resolvedTrackShape: AnyShape {
        if let shape = trackShape { return shape }
        if let radius = dimensions.cornerRadius {
            return AnyShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        } else {
            return AnyShape(Capsule(style: .continuous))
        }
    }

    private var resolvedPreviewShape: AnyShape {
        if let shape = previewShape { return shape }
        let size = dimensions.previewSize ?? ColorSliderDefaults.previewSize(for: controlSize)
        return AnyShape(
            RoundedRectangle(cornerRadius: size * ColorSliderDefaults.cornerRadiusMultiplier, style: .continuous)
        )
    }
}

// MARK: - Dot syntax extension

public extension ColorSliderStyle where Self == DefaultColorSliderStyle {
    static var automatic: DefaultColorSliderStyle { DefaultColorSliderStyle() }
}
