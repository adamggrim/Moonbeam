# Moonbeam

`Moonbeam` is a Swift package for color sliders with floating color previews.

For a given hue range, `Moonbeam` lets you bend saturation or brightness in specific sections. It also supports custom gradients and thumb styles.

## Requirements

- Swift 6.0
- iOS 18.0
- iPadOS 18.0

## Dependencies

`Moonbeam` requires the following Swift framework:

- `SwiftUI`: For building color sliders and running animations

## Variations

`Moonbeam` supports two color slider modes—spectrum (HSB-based) and gradient (color mixing-based).

- **For spectrum sliders:** To improve the legibility of certain colors against a light or dark background, bend the saturation or brightness in specific sections. `Moonbeam` also supports black or white fade-ins and fade-outs (e.g., starting the spectrum with white).
- **For gradient sliders**: Create a precise gradient between any two colors.
- **For hard-edge sliders**: Create a slider with discrete color blocks.

`Moonbeam` also offers layout and thumb style customization:

- **Orientation:** Render sliders either horizontally or vertically.
- **Thumb styles:** Choose any shape (`Capsule` by default) and an optional stroke.
- **Preview styles:** Choose any shape (`RoundedRectangle` by default) and an optional stroke.

## Example (Spectrum)

This example demonstrates how to create a spectrum slider using `Moonbeam`.

1. **Create the slider**
    ```swift
    @State private var selectedColor: Color = .white
    ```

2. **Build the spectrum model:** Use the result builder to add black or white sections and bend saturation or brightness.

    ```swift
    let spectrumModel = SpectrumSliderModel {
        BlackSection() // Fade from black

        HueSection(
            minHue: 0.0,
            maxHue: 1.0,
            saturationBends: {
                OneWayBend(hue: 0.0...(40.0 / 360), target: 0.5)
            }
        )

        WhiteSection() // Fade to white
    }
    ```

3. **Choose slider styles**

    ```swift
    ColorSliderView(
        selectedColor: $selectedColor,
        dataSource: spectrumModel,
        axis: .horizontal
    )
    .colorSliderThumbStyle(.circle)
    .colorSliderThumbColor(.white)
    ```

## Example (Gradient)

This example demonstrates how to create a gradient slider using `Moonbeam`.

1. **Create the slider**
    ```swift
    @State private var selectedColor: Color = .cyan
    ```

2. **Create the gradient model**

    ```swift
    let gradientModel = GradientSliderModel(startColor: .cyan, endColor: .purple)
    ```
3. **Choose slider styles**

    ```swift
    ColorSliderView(
        selectedColor: $selectedColor,
        dataSource: gradientModel,
        axis: .vertical
    )
    .colorSliderThumbStyle(.capsule)
    ```

## Example (Hard-Edge)

This example demonstrates how to create a hard-edge slider with discrete color blocks. `Moonbeam` supports two types of hard-edge sliders—implicit and explicit. Explicit sliders initialize the slider using a custom array of `Color` objects. Implicit sliders convert a `SpectrumSliderModel` or `GradientSliderModel` into discrete color blocks.

### Explicit

1. **Create the data source**
    ```swift
    let customStops = HardEdgeSliderModel(colors: [
        .green, .yellow, .orange, .red, .purple, .blue
    ])
    ```

2. **Create the slider**
    ```swift
    @State private var selectedColor: Color = .green

    var body: some View {
        ColorSliderView(
            selectedColor: $selectedColor,
            dataSource: customStops,
            axis: .horizontal
        )
    }
    ```

### Implicit

1. **Create a smooth model and convert it into discrete blocks**
    ```swift
    let chunkyGradient = GradientSliderModel(
        startColor: .cyan,
        endColor: .purple
    ).hardEdge(into: 6)
    ```

2. **Create the slider**
    ```swift
    @State private var selectedColor: Color = .cyan

    var body: some View {
        ColorSliderView(
            selectedColor: $selectedColor,
            dataSource: chunkyGradient,
            axis: .horizontal
        )
    }
    ```

## Structure

```
Moonbeam/
└── Sources/
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

## Usage

Follow these steps to integrate `Moonbeam` into your project:

1. **Install Xcode:** Ensure you are running Xcode 16 or later to support Swift 6.0 and iOS 18.

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
