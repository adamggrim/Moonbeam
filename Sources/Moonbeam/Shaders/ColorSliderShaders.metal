#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
#include "../../MoonbeamShared/include/MoonbeamShared.h"
using namespace metal;

// MARK: – HSB to RGB

constant float4 hsbConversionConstants = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);

float3 convertHSBtoRGB(float hue, float saturation, float brightness) {
    float3 rgbValues = abs(fract(hue + hsbConversionConstants.xyz) * 6.0 - hsbConversionConstants.www);
    return brightness * mix(hsbConversionConstants.xxx,
        clamp(rgbValues - hsbConversionConstants.xxx, 0.0, 1.0), saturation);
}

// MARK: - Gamma transfer functions

float3 linearToSRGB(float3 c) {
    float3 linear_low = 12.92 * c;
    float3 linear_high = 1.055 * pow(c, 1.0 / 2.4) - 0.055;
    return select(linear_high, linear_low, c <= 0.0031308);
}

float3 sRGBToLinear(float3 c) {
    float3 srgb_low = c / 12.92;
    float3 srgb_high = pow((c + 0.055) / 1.055, 2.4);
    return select(srgb_high, srgb_low, c <= 0.04045);
}

constant float3x3 oklabLMSMatrix = float3x3(
    float3(1.0, 1.0, 1.0),
    float3(0.3963377774, -0.1055613458, -0.0894841775),
    float3(0.2158037573, -0.0638541728, -1.2914855480)
);

constant float3x3 oklabRGBMatrix = float3x3(
    float3(4.0767416621, -1.2684380046, -0.0041960863),
    float3(-3.3077115913, 2.6097574011, -0.7034186147),
    float3(0.2309699292, -0.3413193965, 1.7076147010)
);

// MARK: - OKLAB and OKLCH to RGB

// Matrix to convert OKLAB constants to RGB.
//
// Taken from  "A perceptual color space for image processing" by Björn Ottosson
// (2020):
// https://bottosson.github.io/posts/oklab/
float3 convertOKLABtoRGB(float L, float a, float b) {
    float3 lms_ = oklabLMSMatrix * float3(L, a, b);

    float l = sign(lms_.x) * pow(abs(lms_.x), 3.0);
    float m = sign(lms_.y) * pow(abs(lms_.y), 3.0);
    float s = sign(lms_.z) * pow(abs(lms_.z), 3.0);

    float3 lin = oklabRGBMatrix * float3(l, m, s);

    return linearToSRGB(clamp(lin, 0.0, 1.0));
}

// Matrix to convert OKLCH constants to RGB.
//
// Taken from  "A perceptual color space for image processing" by Björn Ottosson
// (2020):
// https://bottosson.github.io/posts/oklab/
float3 convertOKLCHtoRGB(float L, float C, float h) {
    float hueAngle = h * 2.0 * M_PI_F;
    float a = C * cos(hueAngle);
    float b = C * sin(hueAngle);
    return convertOKLABtoRGB(L, a, b);
}

float3 resolveColor(uint space, float h, float s_c, float b_l) {
    return space == MoonbeamColorSpaceOKLCH ? convertOKLCHtoRGB(b_l, s_c, h) : convertHSBtoRGB(h, s_c, b_l);
}

constant float3x3 rgbToLMSMatrix = float3x3(
    float3(0.4122214708, 0.2119034982, 0.0883024619),
    float3(0.5363325363, 0.6806995451, 0.2817188376),
    float3(0.0514459929, 0.1073969566, 0.6299787005)
);

constant float3x3 lmsToOKLABMatrix = float3x3(
    float3(0.2104542553, 1.9779984951, 0.0259040371),
    float3(0.7936177850, -2.4285922050, 0.7827717662),
    float3(-0.0040720468, 0.4505937099, -0.8086757660)
);

// MARK: - RGB to OKLAB

// Matrix to convert RGB to OKLAB.
//
// Taken from  "A perceptual color space for image processing" by Björn Ottosson
// (2020):
// https://bottosson.github.io/posts/oklab/
float3 convertRGBtoOKLAB(float3 c) {
    float3 lin = sRGBToLinear(c);

    float3 lms = rgbToLMSMatrix * lin;
    lms = sign(lms) * pow(abs(lms), 1.0/3.0);

    return lmsToOKLABMatrix * lms;
}

// MARK: – Spectrum bends

float calculateBend(
    float currentHue,
    float defaultValue,
    device const ShaderBend* bendsData,
    uint totalBends,
    float minimumHue
) {
    for (uint bendIndex = 0; bendIndex < totalBends; bendIndex++) {
        float bendType = bendsData[bendIndex].data0.x;
        float startHue = bendsData[bendIndex].data0.y;
        float endHue = bendsData[bendIndex].data0.z;
        float targetValue = bendsData[bendIndex].data0.w;
        float hueCount = bendsData[bendIndex].data1.x;

        if (currentHue >= startHue && currentHue <= endHue) {
            float valueDifference = defaultValue - targetValue;
            float hueOffset = currentHue - startHue;

            if (bendType == float(MoonbeamBendTypeOneWay)) { // One-way bend
                float valueIncrement = (hueCount != 0.0) ? (valueDifference / hueCount) : 0.0;
                if (startHue == minimumHue) {
                    return targetValue + (valueIncrement * hueOffset);
                } else {
                    return defaultValue - (valueIncrement * hueOffset);
                }
            } else { // Two-way bend
                float normalizedPosition = (hueCount != 0.0) ? (hueOffset / hueCount) : 0.0;
                float curveProgress = sin(normalizedPosition * M_PI_F);
                return defaultValue - (valueDifference * curveProgress);
            }
        }
    }
    return defaultValue;
}

// MARK: - Coordinate helper

inline float calculateNormalizedPosition(float2 position, float2 size, float isVertical) {
    float normalized = isVertical > 0.5 ? (1.0 - (position.y / size.y)) : (position.x / size.x);
    return clamp(normalized, 0.0, 1.0);
}

// MARK: - Gradient shader

[[ stitchable ]]
half4 gradientShader(
    float2 position,
    half4 currentColor,
    float2 size,
    half4 startColor,
    half4 endColor,
    float isVertical,
    float colorSpaceFlag
) {
    float normalizedPosition = calculateNormalizedPosition(position, size, isVertical);

    uint space = uint(colorSpaceFlag);

    if (space == MoonbeamColorSpaceRGB) {
        half4 blendedColor = mix(startColor, endColor, half(normalizedPosition));
        return half4(blendedColor.rgb * currentColor.a, blendedColor.a * currentColor.a);
    }

    float3 labStart = convertRGBtoOKLAB(float3(startColor.rgb));
    float3 labEnd = convertRGBtoOKLAB(float3(endColor.rgb));

    if (space == MoonbeamColorSpaceOKLAB) {
        float3 mixedLab = mix(labStart, labEnd, normalizedPosition);
        float3 rgbOut = convertOKLABtoRGB(mixedLab.x, mixedLab.y, mixedLab.z);
        return half4(half3(rgbOut) * currentColor.a, currentColor.a);
    } else {
        float cStart = sqrt(labStart.y*labStart.y + labStart.z*labStart.z);
        float hStart = atan2(labStart.z, labStart.y);
        if (hStart < 0.0) hStart += 2.0 * M_PI_F;

        float cEnd = sqrt(labEnd.y*labEnd.y + labEnd.z*labEnd.z);
        float hEnd = atan2(labEnd.z, labEnd.y);
        if (hEnd < 0.0) hEnd += 2.0 * M_PI_F;

        float hDelta = (hEnd - hStart) / (2.0 * M_PI_F);
        if (hDelta > 0.5) hStart += 2.0 * M_PI_F;
        else if (hDelta < -0.5) hStart -= 2.0 * M_PI_F;

        float L = mix(labStart.x, labEnd.x, normalizedPosition);
        float C = mix(cStart, cEnd, normalizedPosition);
        float h = mix(hStart, hEnd, normalizedPosition) / (2.0 * M_PI_F);

        float3 rgbOut = convertOKLCHtoRGB(L, C, h);
        return half4(half3(rgbOut) * currentColor.a, currentColor.a);
    }
}

// MARK: - Spectrum shader

[[ stitchable ]]
half4 spectrumShader(
    float2 position,
    half4 currentColor,
    float2 size,
    float isVertical,
    device const SpectrumShaderData* data,
    int dataLength,
    device const ShaderBend* saturationBendsData,
    int saturationBendsDataLength,
    device const ShaderBend* brightnessBendsData,
    int brightnessBendsDataLength
) {
    float normalizedPosition = calculateNormalizedPosition(position, size, isVertical);

    float totalWeight = data->totalWeight;
    if (totalWeight <= 0.0) return half4(0.0);

    float startSectionBoundary = data->startSectionBoundary;
    float hueSectionBoundary = data->hueSectionBoundary;
    float minimumHue = data->minimumHue;
    float maximumHue = data->maximumHue;
    float baseSaturation = data->baseSaturation;
    float baseBrightness = data->baseBrightness;
    uint colorSpaceFlag = data->colorSpaceFlag;

    uint startSectionsCount = data->startSectionsCount;
    uint endSectionsCount = data->endSectionsCount;
    uint saturationBendsCount = data->saturationBendsCount;
    uint brightnessBendsCount = data->brightnessBendsCount;

    float4 startSectionsData = data->startSectionsData;
    float4 endSectionsData = data->endSectionsData;

    if (normalizedPosition < startSectionBoundary) {
        float cumulativeStartPosition = 0.0;

        // Capped at `MAX_MONOCHROME_SECTIONS` start sections.
        uint sectionIndex = 0;
        if (sectionIndex < startSectionsCount) {
            float isWhiteSection = startSectionsData[0];
            float sectionEndPosition = startSectionsData[1];

            if (normalizedPosition < sectionEndPosition) {
                float distanceMoved = normalizedPosition - cumulativeStartPosition;
                float sectionWidth = sectionEndPosition - cumulativeStartPosition;
                float relativePositionInSection = distanceMoved / sectionWidth;
                bool isLastSection = (0 == startSectionsCount - 1);

                if (isLastSection) {
                    float finalBrightness;
                    if (isWhiteSection == 1.0) {
                        finalBrightness = baseBrightness;
                    } else {
                        finalBrightness = relativePositionInSection * baseBrightness;
                    }
                    float finalSaturation;
                    if (isWhiteSection == 1.0) {
                        finalSaturation = relativePositionInSection * baseSaturation;
                    } else {
                        finalSaturation = baseSaturation;
                    }

                    for (uint bendIndex = 0; bendIndex < saturationBendsCount; bendIndex++) {
                        if (saturationBendsData[bendIndex].data0.y == minimumHue &&
                            saturationBendsData[bendIndex].data0.x == 1.0) {

                            finalSaturation = isWhiteSection == 1.0
                                ? relativePositionInSection * saturationBendsData[bendIndex].data0.w
                                : finalSaturation;
                        }
                    }

                    for (uint bendIndex = 0; bendIndex < brightnessBendsCount; bendIndex++) {
                        if (brightnessBendsData[bendIndex].data0.y == minimumHue &&
                            brightnessBendsData[bendIndex].data0.x == 1.0) {

                            finalBrightness = isWhiteSection == 1.0
                                ? finalBrightness
                                : relativePositionInSection * brightnessBendsData[bendIndex].data0.w;
                        }
                    }

                    if (isWhiteSection == 1.0 && colorSpaceFlag == MoonbeamColorSpaceOKLCH) {
                        finalBrightness = 1.0 - (relativePositionInSection * (1.0 - baseBrightness));
                    }
                    return half4(
                        half3(resolveColor(colorSpaceFlag, minimumHue, finalSaturation, finalBrightness))
                            * currentColor.a,
                        currentColor.a
                    );
                } else {
                    float nextSectionIsWhite = startSectionsData[2];
                    half startingBrightness = select(0.0h, 1.0h, isWhiteSection == 1.0f);
                    half endingBrightness = select(0.0h, 1.0h, nextSectionIsWhite == 1.0f);
                    float brightnessDelta = endingBrightness - startingBrightness;
                    float interpolatedBrightness = startingBrightness + brightnessDelta * relativePositionInSection;
                    return half4(
                        half3(resolveColor(colorSpaceFlag, minimumHue, 0.0, interpolatedBrightness))
                            * currentColor.a,
                        currentColor.a
                    );
                }
            }
            cumulativeStartPosition = sectionEndPosition;
        }

        sectionIndex = 1;
        if (sectionIndex < startSectionsCount) {
            float isWhiteSection = startSectionsData[2];
            float sectionEndPosition = startSectionsData[3];

            if (normalizedPosition < sectionEndPosition) {
                float distanceMoved = normalizedPosition - cumulativeStartPosition;
                float sectionWidth = sectionEndPosition - cumulativeStartPosition;
                float relativePositionInSection = distanceMoved / sectionWidth;

                float finalBrightness;
                if (isWhiteSection == 1.0) {
                    finalBrightness = baseBrightness;
                } else {
                    finalBrightness = relativePositionInSection * baseBrightness;
                }
                float finalSaturation;
                if (isWhiteSection == 1.0) {
                    finalSaturation = relativePositionInSection * baseSaturation;
                } else {
                    finalSaturation = baseSaturation;
                }

                for (uint bendIndex = 0; bendIndex < saturationBendsCount; bendIndex++) {
                    if (saturationBendsData[bendIndex].data0.y == minimumHue &&
                        saturationBendsData[bendIndex].data0.x == 1.0) {

                        finalSaturation = isWhiteSection == 1.0
                            ? relativePositionInSection * saturationBendsData[bendIndex].data0.w
                            : finalSaturation;
                    }
                }

                for (uint bendIndex = 0; bendIndex < brightnessBendsCount; bendIndex++) {
                    if (brightnessBendsData[bendIndex].data0.y == minimumHue &&
                        brightnessBendsData[bendIndex].data0.x == 1.0) {

                        finalBrightness = isWhiteSection == 1.0
                            ? finalBrightness
                            : relativePositionInSection * brightnessBendsData[bendIndex].data0.w;
                    }
                }

                if (isWhiteSection == 1.0 && colorSpaceFlag == MoonbeamColorSpaceOKLCH) {
                    finalBrightness = 1.0 - (relativePositionInSection * (1.0 - baseBrightness));
                }
                return half4(
                    half3(resolveColor(colorSpaceFlag, minimumHue, finalSaturation, finalBrightness))
                        * currentColor.a,
                    currentColor.a
                );
            }
            cumulativeStartPosition = sectionEndPosition;
        }
    } else if (normalizedPosition <= hueSectionBoundary) {
        float hueSectionWidth = hueSectionBoundary - startSectionBoundary;
        float distanceFromStart = normalizedPosition - startSectionBoundary;

        float relativeHuePosition = (hueSectionBoundary > startSectionBoundary)
            ? (distanceFromStart / hueSectionWidth)
            : 0.0;
        float currentHue = minimumHue + relativeHuePosition * (maximumHue - minimumHue);

        float calculatedSaturation = calculateBend(
            currentHue,
            baseSaturation,
            saturationBendsData,
            saturationBendsCount,
            minimumHue
        );
        float calculatedBrightness = calculateBend(
            currentHue,
            baseBrightness,
            brightnessBendsData,
            brightnessBendsCount,
            minimumHue
        );

        return half4(
            half3(resolveColor(colorSpaceFlag, currentHue, calculatedSaturation, calculatedBrightness))
                * currentColor.a,
            currentColor.a
        );
    } else {
        float cumulativeEndPosition = hueSectionBoundary;

        // Capped at `MAX_MONOCHROME_SECTIONS` end sections.
        uint sectionIndex = 0;
        if (sectionIndex < endSectionsCount) {
            float isWhiteSection = endSectionsData[0];
            float sectionEndPosition = endSectionsData[1];
            bool isLastSection = (0 == endSectionsCount - 1);

            if (normalizedPosition <= sectionEndPosition || isLastSection) {
                float distanceFromEnd = normalizedPosition - cumulativeEndPosition;
                float sectionWidth = sectionEndPosition - cumulativeEndPosition;

                float relativePositionInSection = clamp(distanceFromEnd / sectionWidth, 0.0, 1.0);

                float finalBrightness;
                if (isWhiteSection == 1.0) {
                    finalBrightness = baseBrightness;
                } else {
                    finalBrightness = (1.0 - relativePositionInSection) * baseBrightness;
                }
                float finalSaturation;
                if (isWhiteSection == 1.0) {
                    finalSaturation = (1.0 - relativePositionInSection) * baseSaturation;
                } else {
                    finalSaturation = baseSaturation;
                }

                for (uint bendIndex = 0; bendIndex < saturationBendsCount; bendIndex++) {
                    if (saturationBendsData[bendIndex].data0.z == maximumHue &&
                        saturationBendsData[bendIndex].data0.x == 1.0) {

                        finalSaturation = isWhiteSection == 1.0
                            ? (1.0 - relativePositionInSection) * saturationBendsData[bendIndex].data0.w
                            : finalSaturation;
                    }
                }

                for (uint bendIndex = 0; bendIndex < brightnessBendsCount; bendIndex++) {
                    if (brightnessBendsData[bendIndex].data0.z == maximumHue &&
                        brightnessBendsData[bendIndex].data0.x == 1.0) {

                        finalBrightness = isWhiteSection == 1.0
                            ? finalBrightness
                            : (1.0 - relativePositionInSection) * brightnessBendsData[bendIndex].data0.w;
                    }
                }
                if (isWhiteSection == 1.0 && colorSpaceFlag == MoonbeamColorSpaceOKLCH) {
                    finalBrightness = 1.0 - ((1.0 - relativePositionInSection) * (1.0 - baseBrightness));
                }
                return half4(
                    half3(resolveColor(colorSpaceFlag, maximumHue, finalSaturation, finalBrightness))
                        * currentColor.a,
                    currentColor.a
                );
            }
            cumulativeEndPosition = sectionEndPosition;
        }

        sectionIndex = 1;
        if (sectionIndex < endSectionsCount) {
            float isWhiteSection = endSectionsData[2];
            float sectionEndPosition = endSectionsData[3];
            bool isLastSection = true;

            if (normalizedPosition <= sectionEndPosition || isLastSection) {
                float distanceFromEnd = normalizedPosition - cumulativeEndPosition;
                float sectionWidth = sectionEndPosition - cumulativeEndPosition;

                float relativePositionInSection = clamp(distanceFromEnd / sectionWidth, 0.0, 1.0);

                float previousSectionIsWhite = endSectionsData[0];
                half startingBrightness = select(0.0h, 1.0h, previousSectionIsWhite == 1.0f);
                half endingBrightness = select(0.0h, 1.0h, isWhiteSection == 1.0f);
                float brightnessDelta = endingBrightness - startingBrightness;
                float interpolatedBrightness = startingBrightness + brightnessDelta * relativePositionInSection;
                return half4(
                    half3(resolveColor(colorSpaceFlag, maximumHue, 0.0, interpolatedBrightness))
                        * currentColor.a,
                    currentColor.a
                );
            }
            cumulativeEndPosition = sectionEndPosition;
        }
    }
    return half4(0.0);
}
