#ifndef MoonbeamShared_h
#define MoonbeamShared_h

#define MAX_MONOCHROME_SECTIONS 2

#ifdef __METAL_VERSION__
#include <metal_stdlib>
typedef metal::float4 mb_float4;
#else
#include <simd/simd.h>
typedef simd_float4 mb_float4;
#endif

/// Represents a bend section.
///
/// Packed into 128-bit SIMD vectors to ensure memory alignment between Swift
/// and Metal.
///
/// Mapping for `data0`:
/// - x: Bend Type (1.0 = OneWay, 2.0 = TwoWay) mapped to `MoonbeamBendType`
/// - y: Start Hue (normalized 0.0 - 1.0)
/// - z: End Hue (normalized 0.0 - 1.0)
/// - w: Target Value (saturation, brightness, chroma, or lightness)
///
/// Mapping for `data1`:
/// - x: Hue Count (difference between start and end hues)
/// - y: Easing curve type (1.0 = Cubic, 0.0 = Linear)
/// - z: Unused padding to force 16-byte GPU memory alignment
/// - w: Unused padding to force 16-byte GPU memory alignment
typedef struct {
    mb_float4 data0;
    mb_float4 data1;
} ShaderBend;

/// Determines the color space for interpolation and spectrum rendering
/// calculations.
typedef enum {
    ColorSpaceRGB = 0,
    ColorSpaceHSB = 1,
    ColorSpaceOKLAB = 2,
    ColorSpaceOKLCH = 3
} ColorSpaceFlag;

/// Defines the bend type of a bend section.
/// - `BendTypeOneWay`: Transitions from a default value to a target.
/// - `MoonbeamBendTypeTwoWay`: Transitions from a default value to a target
///   and smoothly returns to the default.
typedef enum {
    BendTypeOneWay = 1,
    MoonbeamBendTypeTwoWay = 2
} MoonbeamBendType;

/// Represents whether a monochrome section shifts to or from black or white.
typedef enum {
    MonochromeSectionTypeBlack = 0,
    MonochromeSectionTypeWhite = 1
} MonochromeSectionType;

/// Determines the mathematical smoothing curve applied to a bend.
/// Values are spaced by two to allow for multiplexed bit-packing with
/// `MonochromeSectionType`.
typedef enum {
    EasingTypeLinear = 0,
    EasingTypeCubic = 2
} EasingTypeFlag;

/// The shared memory layout bridging a spectrum's state from Swift to Metal
/// shaders.
///
/// Vector mapping for `startSectionsData` / `endSectionsData`:
/// - x: Section 0 config (`MonochromeSectionType` + `EasingTypeFlag`)
/// - y: Section 0 cumulative boundary (normalized coordinate)
/// - z: Section 1 config (`MonochromeSectionType` + `EasingTypeFlag`)
/// - w: Section 1 cumulative boundary (normalized coordinate)
typedef struct {
    float totalWeight;
    float startSectionBoundary;
    float hueSectionBoundary;
    float minimumHue;
    float maximumHue;
    float baseSaturation;
    float baseBrightness;
    uint32_t colorSpaceFlag;

    uint32_t startSectionsCount;
    uint32_t endSectionsCount;
    uint32_t saturationBendsCount;
    uint32_t brightnessBendsCount;

    mb_float4 startSectionsData;
    mb_float4 endSectionsData;
} SpectrumShaderData;

#endif /* MoonbeamShared_h */
