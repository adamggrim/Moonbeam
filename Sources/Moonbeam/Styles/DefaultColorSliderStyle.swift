import SwiftUI

/// The default style applied to a color slider.
///
/// This style includes a Liquid Glass slider thumb (on supported platforms),
/// rounded geometry and a floating color preview.
public struct DefaultColorSliderStyle: ColorSliderStyle {
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
    /// Determines when to render the draggable thumb with Liquid Glass.
    public var liquidGlassThumb: LiquidGlassThumb?
    /// The shape applied to the floating color preview.
    public var previewShape: AnyShape?
    /// The stroke styling applied to the floating color preview.
    public var previewStroke: ShapeStroke?
    /// The shadow properties applied to the floating color preview.
    public var previewShadow: ShapeShadow

    /// Initializes a default color slider style.
    ///
    /// - Parameters:
    ///   - trackShape: The shape of the slider track.
    ///   - trackStroke: The stroke applied to the slider track.
    ///   - thumbShape: The shape of the draggable thumb.
    ///   - thumbColor: The fill color of the draggable thumb.
    ///   - thumbStroke: The stroke styling applied to the draggable thumb.
    ///   - thumbShadow: The shadow properties applied to the draggable thumb.
    ///   - liquidGlassThumb: Determines when to render the thumb with Liquid
    ///     Glass.
    ///   - previewShape: The shape applied to the floating color preview.
    ///   - previewStroke: The stroke styling applied to the floating color preview.
    ///   - previewShadow: The shadow properties applied to the floating color preview.
    public init(
        trackShape: AnyShape? = nil,
        trackStroke: ShapeStroke? = nil,
        thumbShape: AnyShape? = nil,
        thumbColor: Color = .white,
        thumbStroke: ShapeStroke? = nil,
        thumbShadow: ShapeShadow = ShapeShadow(),
        liquidGlassThumb: LiquidGlassThumb? = nil,
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
        self.liquidGlassThumb = liquidGlassThumb
        self.previewShape = previewShape
        self.previewStroke = previewStroke
        self.previewShadow = previewShadow
    }

    public func makeBody(configuration: Configuration) -> some View {
        DefaultColorSliderStyleView(style: self, configuration: configuration)
    }
}

private struct DefaultColorSliderStyleView: View {
    let style: DefaultColorSliderStyle
    let configuration: ColorSliderStyleConfiguration

    @Environment(\.colorSliderLiquidGlassThumb) private var defaultLiquidGlassThumb
    @Environment(\.colorSliderThumbStyle) private var thumbStyle
    @Environment(\.colorSliderDimensions) private var dimensions
    @Environment(\.controlSize) private var controlSize

    var body: some View {
        ZStack(alignment: configuration.axis == .horizontal ? .leading : .bottom) {

            configuration.track
                .clipShape(resolvedTrackShape)
                .overlay {
                    if let stroke = style.trackStroke {
                        resolvedTrackShape.stroke(stroke.style, lineWidth: stroke.lineWidth)
                    }
                }

            configuration.thumb
                .overlay {
                    let shape = resolvedThumbShape
                    let dynamicScale: CGFloat = configuration.isDragging ? dimensions.thumbDragScale : 1.0

                    Group {
                        switch thumbStyle {
                        case .colorOutline(let lineWidth, _):
                            shape.stroke(style.thumbColor, lineWidth: lineWidth)

                        case .standard:
                            let activeLiquidGlassThumb = style.liquidGlassThumb ?? defaultLiquidGlassThumb
                            let isLiquidGlassActive: Bool = {
                                if #available(iOS 26.0, macOS 26.0, *) {
                                    return activeLiquidGlassThumb == .always
                                        || (activeLiquidGlassThumb == .dragging && configuration.isDragging)
                                }
                                return false
                            }()

#if compiler(>=6.2)
                            if #available(iOS 26.0, macOS 26.0, *), activeLiquidGlassThumb != .disabled {
                                Color.clear
                                    .glassEffect(
                                        isLiquidGlassActive ? .regular.interactive(true) : .identity, in: shape
                                    )
                                    .overlay(shape.fill(style.thumbColor).opacity(isLiquidGlassActive ? 0.0 : 1.0))
                            } else {
                                shape.fill(style.thumbColor)
                            }
#else
                            shape.fill(style.thumbColor)
#endif
                        }
                    }
                    .scaleEffect(dynamicScale)
                    .shadow(
                        color: style.thumbShadow.color,
                        radius: style.thumbShadow.radius,
                        x: style.thumbShadow.x,
                        y: style.thumbShadow.y
                    )
                    .overlay {
                        if thumbStyle == .standard, let stroke = style.thumbStroke {
                            shape.stroke(stroke.style, lineWidth: stroke.lineWidth)
                        }
                    }
                    .allowsHitTesting(false)
                }
#if !os(macOS)
                .contentShape(.hoverEffect, resolvedThumbShape)
                .hoverEffect()
#endif
                .offset(configuration.thumbOffset)

            configuration.preview
                .clipShape(resolvedPreviewShape)
                .overlay {
                    if let stroke = style.previewStroke {
                        resolvedPreviewShape.stroke(stroke.style, lineWidth: stroke.lineWidth)
                    }
                }
                .shadow(
                    color: style.previewShadow.color,
                    radius: style.previewShadow.radius,
                    x: style.previewShadow.x,
                    y: style.previewShadow.y
                )
                .scaleEffect(
                    (!configuration.isDragging) ? dimensions.previewScale : 1.0,
                    anchor: configuration.previewScaleAnchor
                )
                .opacity((!configuration.isDragging) ? 0.0 : 1.0)
                .offset(configuration.previewOffset)
                .allowsHitTesting(false)
        }
    }

    private var resolvedTrackShape: AnyShape {
        if let shape = style.trackShape { return shape }
        if let radius = dimensions.cornerRadius {
            return AnyShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        } else {
            return AnyShape(Capsule(style: .continuous))
        }
    }

    private var resolvedThumbShape: AnyShape {
        if let shape = style.thumbShape { return shape }
        switch thumbStyle {
        case .colorOutline(_, let padding):
            let colorCount = configuration.colorCount

            let baseRadius = dimensions.cornerRadius ?? (dimensions.resolvedTrackThickness(for: controlSize) / 2)
            let radius = baseRadius + padding

            if colorCount <= 1 {
                return AnyShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            }

            // Morph the outer corners from rounded to sharp.
            let firstBlockMultiplier = max(0.0, min(1.0, 2.0 * (1.0 - (configuration.value * Double(colorCount)))))
            let lastBlockMultiplier = max(
                0.0, min(1.0, 2.0 * ((configuration.value * Double(colorCount)) - Double(colorCount - 1)))
            )

            let firstRadius = radius * firstBlockMultiplier
            let lastRadius = radius * lastBlockMultiplier

            if configuration.axis == .horizontal {
                return AnyShape(UnevenRoundedRectangle(
                    topLeadingRadius: firstRadius,
                    bottomLeadingRadius: firstRadius,
                    bottomTrailingRadius: lastRadius,
                    topTrailingRadius: lastRadius,
                    style: .continuous
                ))
            } else {
                return AnyShape(UnevenRoundedRectangle(
                    topLeadingRadius: lastRadius,
                    bottomLeadingRadius: firstRadius,
                    bottomTrailingRadius: firstRadius,
                    topTrailingRadius: lastRadius,
                    style: .continuous
                ))
            }

        case .standard:
            return AnyShape(Capsule(style: .continuous))
        }
    }

    private var resolvedPreviewShape: AnyShape {
        if let shape = style.previewShape { return shape }
        let size = dimensions.previewSize ?? ColorSliderDefaults.previewSize(for: controlSize)
        return AnyShape(
            RoundedRectangle(cornerRadius: size * ColorSliderDefaults.cornerRadiusMultiplier, style: .continuous)
        )
    }
}

public extension ColorSliderStyle where Self == DefaultColorSliderStyle {
    static var automatic: DefaultColorSliderStyle { DefaultColorSliderStyle() }
}
