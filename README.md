# Moonbeam

`Moonbeam` is a Swift package for color sliders with floating color previews.

For a given hue range, `Moonbeam` lets you bend saturation or brightness in specific sections. It also supports custom gradients and thumb styles.

## Requirements

- Swift 6.0
- iOS 18.0
- iPadOS 18.0
- macOS 15.0

## Dependencies

`Moonbeam` requires the following Swift framework:

- `SwiftUI`: For building color sliders and running animations

## Variations

`Moonbeam` supports two color slider modes—spectrum (HSB- and OKLCH-based) and gradient (color mixing-based).

- **For spectrum sliders:** Use either the HSB or OKLCH color space. To improve the legibility of certain colors, you can bend saturation and brightness (HSB) or lightness and chroma (OKLCH) in specific sections using the `saturationBends`, `brightnessBends`, `lightnessBends`, and `chromaBends` parameters. `Moonbeam` also supports starting or ending spectrum sliders with black or white `monochromeSections`.
- **For gradient sliders**: Create a precise gradient between any two colors using the RGB, OKLAB or OKLCH color space.
- **For hard-edge sliders**: Create a slider with discrete color blocks by providing an explicit array of colors or adding the `.hardEdge(into:)` modifier to an existing slider.

`Moonbeam` also offers layout and thumb style customization:

- **Orientation:** Render sliders either horizontally or vertically.
- **Thumb styles:** Choose any shape (`Capsule` by default) and an optional stroke.
- **Preview styles:** Choose any shape (`RoundedRectangle` by default) and an optional stroke.

## Example (spectrum)

This example demonstrates how to create an HSB spectrum slider using `Moonbeam`.

1. **Initialize the state variables**
    ```swift
    @State private var progress: Double = 0.5
    @State private var selectedColor: Color = .white
    ```

2. **Create the slider and add modifiers:**

    Use the `Spectrum` data source to define the color space and hue range. Add optional black or white `startSections` or `endSections`. Bend saturation, brightness, lightness or chroma using the `saturationBends`, `brightnessBends`, `lightnessBends`, and `chromaBends` parameters.

    HSB spectrum:

    ```swift
    ColorSlider(
        value: $progress,
        colorProvider: Spectrum<HSB>(
            startSections: [BlackSection()], // Fade from black
            endSections: [WhiteSection()],   // Fade to white
            startHue: 0.0,
            endHue: 1.0,
            saturationBends: {
                OneWayBend(startHue: 0.0, endHue: 40.0 / 360, target: 0.5)
            }
        ),
        axis: .horizontal
    )
    .colorSliderStyle(
        DefaultColorSliderStyle(
            thumbShape: AnyShape(Circle()),
            thumbColor: .white
        )
    )
    ```

    OKLCH spectrum:

    ```swift
    ColorSlider(
        value: $progress,
        colorProvider: Spectrum<OKLCH>(
            lightness: 0.75,
            chroma: 0.15,
            startHue: 0.0,
            endHue: 1.0,
            lightnessBends: {
                OneWayBend(startHue: 0.0, endHue: 0.2, target: 0.9)
            }
        ),
        axis: .horizontal
    )
    ```

## Example (gradient)

This example demonstrates how to create a gradient slider using `Moonbeam`.

1. **Initialize the state variables**

    ```swift
    @State private var progress: Double = 0.0
    @State private var selectedColor: Color = .cyan
    ```

2. **Create the slider and add modifiers **

    `Moonbeam` gradient sliders also support OKLCH and OKLAB color spaces.

    ```swift
    ColorSlider(
        value: $progress,
        colorProvider: ColorGradient(startColor: .orange, endColor: .blue, colorSpace: .rgb),
        axis: .vertical
    )
    .colorSliderStyle(DefaultColorSliderStyle(
        thumbShape: AnyShape(Circle())
    ))
    ```

## Example (hard-edge)

This example demonstrates how to create a hard-edge slider. `Moonbeam` supports two types of hard-edge sliders—explicit and implicit. Explicit sliders use a custom array of `Color` objects. Implicit sliders convert a `Spectrum` or `ColorGradient` into discrete color blocks.

### Explicit

1. **Create the data source**

    ```swift
    let customStops = HardEdgeColors(colors: [
        .green, .yellow, .orange, .red, .purple, .blue
    ])
    ```

2. **Create the slider**

    Pass an array of colors to the `HardEdgeColors` data source.

    ```swift
    @State private var progress: Double = 0.0
    @State private var selectedColor: Color = .green

    var body: some View {
        ColorSlider(
            value: $progress,
            colorProvider: customStops,
            axis: .horizontal
        )
    }
    ```

### Implicit

1. **Initialize the state variables**

    ```swift
    @State private var progress: Double = 0.0
    @State private var selectedColor: Color = .cyan
    ```

2. **Create the slider and add modifiers**

    Add the `.hardEdge(into:)` modifier to a gradient or spectrum slider to automatically sample the track.

    ```swift
    ColorSlider(
        value: $progress,
        colorProvider: ColorGradient(startColor: .red, endColor: .blue, colorSpace: .rgb)
            .hardEdge(into: 6),
        axis: .horizontal
    )
    ```

## Customization

`Moonbeam` uses an idiomatic SwiftUI styling architecture via the `ColorSliderStyle` protocol.

### Styling
Customize the appearance of any color slider by applying the `.colorSliderStyle()` modifier to a slider or its parent view.

    ```swift
    ColorSlider(
        value: $progress,
        colorProvider: colorProvider
    )
    .colorSliderStyle(DefaultColorSliderStyle(
        trackShape: AnyShape(Rectangle()),
        trackStroke: ShapeStroke(style: AnyShapeStyle(.white), lineWidth: 1.0),
        thumbShape: AnyShape(Circle()),
        thumbColor: .white,
        thumbStroke: ShapeStroke(style: AnyShapeStyle(.white), lineWidth: 1.0),
        thumbShadow: ShapeShadow(color: .black, radius: 5, x: 0, y: 0),
        liquidGlassThumb: .disabled,
        previewShape: AnyShape(RoundedRectangle(cornerRadius: 8)),
        previewStroke: ShapeStroke(style: AnyShapeStyle(.white), lineWidth: 1.0),
        previewShadow: ShapeShadow(color: .black, radius: 5, x: 0, y: 0)
    ))
    ```

To build a custom layout, create a struct that conforms to the `ColorSliderStyle` protocol.

### Environment modifiers
Apply these SwiftUI environment modifiers to a single `ColorSlider` or its parent view:

* `.colorSliderDimensions(length:thickness:cornerRadius:thumbThickness:thumbLength:previewSize:previewOffset:previewScale:thumbDragScale:)`
* `.colorSliderDragMinimumDistance(_:)`
* `.colorSliderAccessibilityStep(_:)`
* `.colorSliderAnimation(_:)`
* `.colorSliderPreviewPosition(_:spacing:)`
* `.colorSliderLiquidGlassThumb(_:)` *(Defaults to `.dragging`)*

## Accessibility
Moonbeam features built-in VoiceOver support. Sliders announce their current percentage and, for `Spectrum` providers, a descriptive color name (e.g., "dark blue at 45%").

To support multiple languages, define the following localization keys:
* **Colors:** `"black"`, `"white"`, `"gray"`, `"red"`, `"orange"`, `"yellow"`, `"green"`, `"cyan"`, `"blue"`, `"purple"`, `"pink"`
* **Tone modifiers:** `"light"`, `"dark"`, `"bright"`, `"dull"`
* **Format string:** `"color_name_format"` (Defaults to `"%1$@ %2$@"`, where `%1$@` represents the adjective and `%2$@` represents the base color)

Adjust the VoiceOver increment with the `.colorSliderAccessibilityStep(_:)` modifier.

## Structure

<details>
<summary>(Click to expand)</summary>

```
Moonbeam/
└── Sources/
  ├── Moonbeam/
  │ ├── Environment/
  │ │ ├── ColorSliderDefaults.swift: Global default metrics and constants
  │ │ ├── ColorSliderDimensions.swift: Layout and geometry dimensions for sliders
  │ │ ├── ColorSliderViewModifiers.swift: Layout-oriented environment keys
  │ │ ├── ShapeModifiers.swift: Shadow and stroke modifiers for component shapes
  │ │ └── Telemetry.swift: Lightweight wrapper for telemetry and non-fatal production logging
  │ ├── Providers/
  │ │ ├── Gradient/
  │ │ │ └── ColorGradient.swift: Data source model for linear color gradient calculations
  │ │ ├── HardEdge/
  │ │ │ └── HardEdgeColors.swift: Data source model for sliders with discrete color blocks
  │ │ ├── Spectrum/
  │ │ │ ├── Sections/
  │ │ │ │ ├── BendSection.swift: Bend section definitions
  │ │ │ │ ├── Easing.swift: Mathematical easing curves for color transitions
  │ │ │ │ └── MonochromeSection.swift: Black and white secion definitions
  │ │ │ ├── SpectrumColorSpace.swift: Dynamic generator for spectrum colors
  │ │ │ ├── SpectrumCore.swift: Utilities and Metal encoders for spectrums
  │ │ │ ├── SpectrumGenerator.swift: Pure-Swift fallback logic for spectrums
  │ │ │ └── SpectrumNameResolver.swift: Mapping utility that returns color names based on hue and intensity values
  │ │ ├── ColorProvider.swift: Protocols and enums defining data sources and rendering methods
  │ │ └── ColorSpaceConverter.swift: Mathematical conversions between OKLCH, OKLAB and RGB
  │ ├── Shaders/
  │ │ └── ColorSliderShaders.metal: Metal shaders for hardware-accelerated gradient and spectrum rendering
  │ ├── State/
  │ │ ├── ColorSliderLayout.swift: Layout mathematics and state normalization
  │ │ └── ColorSliderState.swift: State manager handling layout math, gestures and value clamping
  │ ├── Styles/
  │ │ ├── ColorSliderStyle.swift: Core protocol and type-erased wrapper for styling
  │ │ ├── ColorSliderStyleConfiguration.swift: Exposes styles to slider state and internal views
  │ │ └── DefaultColorSliderStyle.swift: Customizable ZStack layout implementation
  │ └── Views/
  │   ├── Components/
  │   │ ├── ColorPreviewView.swift: Floating color preview of the currently selected color
  │   │ ├── ThumbView.swift: Draggable thumb view
  │   │ └── TrackView.swift: Slider track view
  │   ├── Previews/
  │   │ ├── GradientSliders.swift: Previews for gradient sliders
  │   │ ├── HardEdgeSliders.swift: Previews for hard-edge block sliders
  │   │ ├── HSBSliders.swift: Previews for HSB sliders
  │   │ ├── OKLCHSliders.swift: Previews for OKLCH sliders
  │   │ └── PreviewContainer.swift: Helper container view for standardized previews
  │   ├── ColorSlider.swift: Main color slider view
  │   └── ColorSlider+Initializers.swift: Color slider convenience initializers
  └── MoonbeamShared/
  ├── include/
  │ ├── MoonbeamShared.h: Shared C/Metal headers and data structures
  │ └── module.modulemap: Clang module map for bridging MoonbeamShared
  └── MoonbeamShared.c: Blank C file to satisfy Swift Pacakge Manager (SPM) requirements
```
</details>

## Usage

Follow these steps to integrate `Moonbeam` into your project:

1. **Install Xcode:** Ensure you are running Xcode 16 or later to support Swift 6.0, iOS 18 and macOS 15.

2. **Install the package:** Add `Moonbeam` to your `Package.swift` dependencies:

    ```swift
    dependencies: [
        .package(url: "https://github.com/adamggrim/Moonbeam.git", from: "1.0.0")
    ]
    ```

3. Use the package in your project:

    ```swift
    import Moonbeam
    ```

## License

This project is licensed under the MIT License.

## Contributors

- Adam Grim (@adamggrim)
