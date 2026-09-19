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

typedef struct {
    mb_float4 data0;
    mb_float4 data1;
} ShaderBend;

typedef enum {
    ColorSpaceRGB = 0,
    ColorSpaceHSB = 1,
    ColorSpaceOKLAB = 2,
    ColorSpaceOKLCH = 3
} ColorSpaceFlag;

typedef enum {
    BendTypeOneWay = 1,
    MoonbeamBendTypeTwoWay = 2
} MoonbeamBendType;

typedef enum {
    MonochromeSectionTypeBlack = 0,
    MonochromeSectionTypeWhite = 1
} MonochromeSectionType;

typedef enum {
    EasingTypeLinear = 0,
    EasingTypeCubic = 2
} EasingTypeFlag;

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
