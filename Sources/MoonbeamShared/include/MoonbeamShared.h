#ifndef MoonbeamShared_h
#define MoonbeamShared_h

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

typedef struct {
    float totalWeight;
    float startSectionBoundary;
    float hueSectionBoundary;
    float minimumHue;
    float maximumHue;
    float baseSaturation;
    float baseBrightness;
    float colorSpaceFlag;

    int startSectionsCount;
    int endSectionsCount;
    int saturationBendsCount;
    int brightnessBendsCount;

    mb_float4 startSectionsData;
    mb_float4 endSectionsData;
} SpectrumShaderData;

#endif /* MoonbeamShared_h */
