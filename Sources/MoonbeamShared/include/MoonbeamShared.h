#ifndef MoonbeamShared_h
#define MoonbeamShared_h

#define MAX_MONOCHROME_SECTIONS 2

#ifdef __METAL_VERSION__
#include <metal_stdlib>
using namespace metal;
typedef float4 mb_float4;
#else
#include <simd/simd.h>
typedef simd_float4 mb_float4;
#endif

typedef struct {
    mb_float4 data0;
    mb_float4 data1;
} ShaderBend;

typedef enum {
    MoonbeamColorSpaceRGB = 0,
    MoonbeamColorSpaceHSB = 1,
    MoonbeamColorSpaceOKLAB = 2,
    MoonbeamColorSpaceOKLCH = 3
} MoonbeamColorSpaceFlag;

typedef struct {
    float totalWeight;
    float startSectionBoundary;
    float hueSectionBoundary;
    float minimumHue;
    float maximumHue;
    float baseSaturation;
    float baseBrightness;
    uint32_t colorSpaceFlag;

    int startSectionsCount;
    int endSectionsCount;
    int saturationBendsCount;
    int brightnessBendsCount;

    mb_float4 startSectionsData;
    mb_float4 endSectionsData;
} SpectrumShaderData;

#endif /* MoonbeamShared_h */
