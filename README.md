# Moonbeam

`Moonbeam` is a Swift package for color sliders with floating color previews.

For a given hue range on a color spectrum, `Moonbeam` lets you bend saturation or brightness in specific sections. It also supports gradients and customizable sizing and presentation options.

## Requirements

- Swift 6.0
- iOS 18.0
- iPadOS 18.0

## Dependencies

`Moonbeam` requires the following Swift framework:

- `SwiftUI`: For building color sliders and running animations

## Variations

`Moonbeam` supports two color slider modes—spectrum (HSB-based) and gradient (color mixing-based).

- For spectrum sliders, you can bend saturation or brightness in specific sections to improve legibility:

- With gradient sliders, you can create a precise mix between any two colors:

`Moonbeam` also offers two slider thumb styles—capsule and circle.

- For capsules, you can customize by width and height:

- With circles, you can customize by width:

## Example (Spectrum)

This example demonstrates how to create a spectrum slider using `Moonbeam`.

1. **Create the slider**


2. **Choose the slider thumb style and hues**


3. **Bend the saturation or brightness**


4. **Use the slider**

To improve legibility of certain colors against a light or dark background, you can bend the saturation or brightness in specific sections.

## Example (Gradient)

This example demonstrates how to create a gradient slider using `Moonbeam`.

1. **Create the slider**


2. **Choose the slider thumb style and hues**


3. **Use the slider**


## Usage

Follow these steps to run `Moonbeam`:

1. **Install Xcode**: 

3. **Install the package**:

4. **Use the package in your program**: 

## License

This project is licensed under the MIT License.

## Contributors

- Adam Grim (@adamggrim)
