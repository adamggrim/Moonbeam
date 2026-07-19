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

- **For spectrum sliders:** Create dynamic spectrums using either HSB or OKLCH color spaces. To improve the legibility of certain colors, bend saturation and brightness (HSB) or lightness and chroma (OKLCH) in specific sections using view modifiers. `Moonbeam` also supports black or white fade-ins and fade-outs (e.g., starting the spectrum with white).
- **For gradient sliders**: Create a precise gradient between any two colors using RGB, OKLAB or OKLCH color spaces.
- **For hard-edge sliders**: Create a slider with discrete color blocks by providing an explicit array of colors or adding the `.hardEdge(into:)` modifier to an existing spectrum or gradient.

`Moonbeam` also offers layout and thumb style customization:

- **Orientation:** Render sliders either horizontally or vertically.
- **Thumb styles:** Choose any shape (`Capsule` by default) and an optional stroke.
- **Preview styles:** Choose any shape (`RoundedRectangle` by default) and an optional stroke.

## Example (spectrum)

This example demonstrates how to create an HSB spectrum slider using `Moonbeam`.

1. **Initialize the state variables**
    ```swift
    @State private var selectedColor: Color = .white
    @State private var progress: Double = 0.5
    ```

2. **Create the slider and add modifiers:**

    Use the `.spectrum()` modifier to define the color space and hue range. Add `.startingWith()`, `.endingWith()` . Bend saturation, brightness, lightness or chroma with the `.saturationBends()`, `.brightnessBends()`, `.lightnessBends()` and `.chromaBends()` modifiers.

    HSB spectrum:

    ```swift
    ColorSlider(
        selection: $selectedColor,
        progress: $progress,
        axis: .horizontal
    )
    .spectrum(space: .hsb, range: 0.0...1.0)
    .startingWith(BlackSection()) // Fade from black
    .endingWith(WhiteSection())   // Fade to white
    .saturationBends {
        OneWayBend(startHue: 0.0, endHue: 40.0 / 360, target: 0.5)
    }
    .colorSliderThumbShape(Circle())
    .colorSliderThumbColor(.white)
    ```

    OKLCH spectrum:

    ```swift
    ColorSlider(
        selection: $selectedColor,
        progress: $progress,
        axis: .horizontal
    )
    .spectrum(space: .oklch, range: 0.0...1.0)
    .baseLightness(0.75)
    .baseChroma(0.15)
    .lightnessBends {
        OneWayBend(startHue: 0.0, endHue: 0.2, target: 0.9)
    }
    ```

## Example (gradient)

This example demonstrates how to create a gradient slider using `Moonbeam`.

1. **Initialize the state variables**

    ```swift
    @State private var selectedColor: Color = .cyan
    @State private var progress: Double = 0.5
    ```

2. **Create the slider and add modifiers **

    `Moonbeam` gradient sliders also support OKLCH and OKLAB color spaces.

    ```swift
    ColorSlider(
        selection: $selectedColor,
        progress: $progress,
        axis: .vertical
    )
    .gradient(from: .orange, to: .blue, space: .rgb)
    .colorSliderThumbShape(Circle())
    ```

## Example (hard-edge)

This example demonstrates how to create a hard-edge slider with discrete color blocks. `Moonbeam` supports two types of hard-edge sliders—explicit and implicit. Explicit sliders use a custom array of `Color` objects. Implicit sliders convert a `SpectrumSliderModel` or `GradientSliderModel` into discrete color blocks.

### Explicit

1. **Create the data source**

    ```swift
    let customStops = HardEdgeSliderModel(colors: [
        .green, .yellow, .orange, .red, .purple, .blue
    ])
    ```

2. **Create the slider**

    Pass an array of colors to the `.colors()` modifier.

    ```swift
    @State private var selectedColor: Color = .green

    var body: some View {
        ColorSlider(
            selection: $selectedColor,
            progress: $progress,
            dataSource: customStops,
            axis: .horizontal
        )
    }
    ```

### Implicit

1. **Initialize the state variables**

    ```swift
    @State private var selectedColor: Color = .cyan
    @State private var progress: Double = 0.5
    ```

2. **Create the slider and add modifiers**

    Add the `.hardEdge(into:)` modifier to a gradient or spectrum slider to automatically sample the track.

    ```swift
    ColorSlider(
        selection: $selectedColor,
        progress: $progress,
        axis: .horizontal
    )
    .gradient(from: .red, to: .blue, space: .rgb)
    .hardEdge(into: 6)
    ```

## Customization

`Moonbeam` uses SwiftUI environment values for slider styling. Apply these to a single `ColorSlider` or parent view.

### Data modifiers
* `.spectrum(space:range:)`
* `.baseSaturation(_:) / .baseBrightness(_:)`
* `.baseLightness(_:) / .baseChroma(_:)`
* `.gradient(from:to:space:)`
* `.colors(_:)`
* `.hardEdge(into:)`
* `.startingWith(_:) / .endingWith(_:)`
* `.saturationBends { ... } / .brightnessBends { ... }`
* `.lightnessBends { ... } / .chromaBends { ... }`

### Slider
* `.colorSliderTrackStroke(_:lineWidth:)`
* `.colorSliderCornerRadius(_:)`
* `.colorSliderThumbShape(_:)` *(Accepts any `Shape`.)*
* `.colorSliderThumbColor(_:)`
* `.colorSliderThumbStroke(_:lineWidth:)`
* `.colorSliderDisableLiquidGlass(_:)` *(Defaults to `false`.)*

### Floating color preview
* `.colorSliderPreviewShape(_:)` *(Accepts any `Shape`.)*
* `.colorSliderPreviewStroke(_:lineWidth:)`
* `.colorSliderPreviewPosition(_:spacing:)`
* `.colorSliderPreviewHidden(_:)` *(Defaults to `true`.)*

### Layout and animation
* `.colorSliderDimensions(length:thickness:thumbThickness:thumbLength:previewSize:previewOffset:)`
* `.colorSliderAnimation(_:)`

### Thumb and preview shadows
* `.colorSliderThumbShadow(color:radius:x:y:)`
* `.colorSliderPreviewShadow(color:radius:x:y:)`

## Structure

<details>
<summary>(Click to expand)</summary>

```
Moonbeam/
└── Sources/
  └── Moonbeam/
    ├── Environment/
    │ └── ColorSliderViewModifiers.swift: SwiftUI environment keys and view modifiers for customization
    ├── Models/
    │ ├── Gradient/
    │ │ └── GradientSliderModel.swift: Model for calculating linear gradient colors
    │ ├── HardEdge/
    │ │ └── HardEdgeSliderModel.swift: Model for a slider with discrete color blocks
    │ ├── Spectrum/
    │ │ ├── SpectrumBuilders.swift: Result builders for building spectrum components
    │ │ ├── SpectrumComponents.swift: Definitions for hue, monochrome and bend sections
    │ │ ├── SpectrumGenerator.swift: Core logic for generating spectrums
    │ │ └── SpectrumSliderModel.swift: Model for calculating spectrums
    │ └── ColorSliderDataSource.swift: Protocols and enumerations defining color data sources
    ├── Shaders/
    │   └── ColorSliderShaders.metal: Metal shaders for gradient and spectrum rendering
    └── Views/
        ├── ColorSliderView.swift: The interactive SwiftUI color slider
        └── ColorSliderViewPreviews.swift: SwiftUI previews and test containers
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
