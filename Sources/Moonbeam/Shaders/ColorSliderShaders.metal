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

constant float sRGBGammaThreshold = 0.0031308;
constant float sRGBLinearThreshold = 0.04045;
constant float sRGBGammaScale = 12.92;
constant float sRGBGammaOffset = 0.055;
constant float sRGBGammaPower = 2.4;
constant float sRGBGammaHighScale = 1.055;

float3 linearToSRGB(float3 c) {
    float3 linear_low = sRGBGammaScale * c;
    float3 linear_high = sRGBGammaHighScale * pow(c, 1.0 / sRGBGammaPower) - sRGBGammaOffset;
    return select(linear_high, linear_low, c <= sRGBGammaThreshold);
}

float3 sRGBToLinear(float3 c) {
    float3 srgb_low = c / sRGBGammaScale;
    float3 srgb_high = pow((c + sRGBGammaOffset) / sRGBGammaHighScale, sRGBGammaPower);
    return select(srgb_high, srgb_low, c <= sRGBLinearThreshold);
}

// Matrices to convert LMS constants to/from Oklab and RGB.
//
// Taken from "A perceptual color space for image processing" by Björn Ottosson
// (2020):
// https://bottosson.github.io/posts/oklab/
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

// MARK: - Oklab and Oklch to RGB

constant float maxOklchChroma = 0.4;
constant int gamutSearchIterations = 16;

float3 convertOklabToLinearRGB(float L, float a, float b) {
    float3 lms_ = oklabLMSMatrix * float3(L, a, b);

    float l = sign(lms_.x) * pow(abs(lms_.x), 3.0);
    float m = sign(lms_.y) * pow(abs(lms_.y), 3.0);
    float s = sign(lms_.z) * pow(abs(lms_.z), 3.0);

    return oklabRGBMatrix * float3(l, m, s);
}

bool isLinearRGBInGamut(float3 lin) {
    return all(lin >= 0.0) && all(lin <= 1.0);
}

// Matrix to convert Oklab constants to RGB.
//
// Taken from "A perceptual color space for image processing" by Björn Ottosson
// (2020):
// https://bottosson.github.io/posts/oklab/
float3 convertOklabtoRGB(float L, float a, float b) {
    float3 lin = convertOklabToLinearRGB(L, a, b);
    return linearToSRGB(clamp(lin, 0.0, 1.0));
}

// Matrix to convert Oklch constants to RGB.
//
// Taken from "A perceptual color space for image processing" by Björn Ottosson
// (2020):
// https://bottosson.github.io/posts/oklab/
float3 convertOklchtoRGB(float L, float C, float h) {
    if (L <= 0.0) return float3(0.0);
    if (L >= 1.0) return float3(1.0);

    float hueAngle = h * 2.0 * M_PI_F;
    float cosH = cos(hueAngle);
    float sinH = sin(hueAngle);

    float clampedC = max(C, 0.0);
    float3 lin = convertOklabToLinearRGB(L, clampedC * cosH, clampedC * sinH);

    if (!isLinearRGBInGamut(lin)) {
        float low = 0.0;
        float high = min(clampedC, maxOklchChroma);
        lin = float3(pow(L, 3.0));

        for (int i = 0; i < gamutSearchIterations; i++) {
            float mid = 0.5 * (low + high);
            float3 candidate = convertOklabToLinearRGB(L, mid * cosH, mid * sinH);
            if (isLinearRGBInGamut(candidate)) {
                low = mid;
                lin = candidate;
            } else {
                high = mid;
            }
        }
    }

    return linearToSRGB(clamp(lin, 0.0, 1.0));
}

float3 resolveColor(uint colorSpace, float h, float s_c, float b_l) {
    return colorSpace == ColorSpaceOklch ? convertOklchtoRGB(b_l, s_c, h) : convertHSBtoRGB(h, s_c, b_l);
}

// Matrices to convert RGB to LMS and Oklab constants.
//
// Taken from "A perceptual color space for image processing" by Björn Ottosson
// (2020):
// https://bottosson.github.io/posts/oklab/
constant float3x3 rgbToLMSMatrix = float3x3(
    float3(0.4122214708, 0.2119034982, 0.0883024619),
    float3(0.5363325363, 0.6806995451, 0.2817188376),
    float3(0.0514459929, 0.1073969566, 0.6299787005)
);

constant float3x3 lmsToOklabMatrix = float3x3(
    float3(0.2104542553, 1.9779984951, 0.0259040371),
    float3(0.7936177850, -2.4285922050, 0.7827717662),
    float3(-0.0040720468, 0.4505937099, -0.8086757660)
);

// MARK: - RGB to Oklab

// Matrix to convert RGB to Oklab.
//
// Taken from "A perceptual color space for image processing" by Björn Ottosson
// (2020):
// https://bottosson.github.io/posts/oklab/
float3 convertRGBtoOklab(float3 c) {
    float3 lin = sRGBToLinear(c);

    float3 lms = rgbToLMSMatrix * lin;
    lms = sign(lms) * pow(abs(lms), 1.0/3.0);

    return lmsToOklabMatrix * lms;
}

// MARK: – Spectrum bends

constant float hueComparisonTolerance = 0.0001f;

float calculateBend(
    float currentHue,
    float defaultValue,
    device const ShaderBend* bendsData,
    uint totalBends,
    float minimumHue,
    uint colorSpaceFlag
) {
    for (uint bendIndex = 0; bendIndex < totalBends; bendIndex++) {
        float bendType = bendsData[bendIndex].data0.x;
        float startHue = bendsData[bendIndex].data0.y;
        float endHue = bendsData[bendIndex].data0.z;
        float targetValue = bendsData[bendIndex].data0.w;
        float hueCount = bendsData[bendIndex].data1.x;

        float minBendHue = min(startHue, endHue);
        float maxBendHue = max(startHue, endHue);

        if (currentHue >= minBendHue && currentHue <= maxBendHue) {
            float valueDifference = defaultValue - targetValue;
            float hueOffset = abs(currentHue - startHue);
            float normalizedPosition = clamp((hueCount != 0.0f) ? (hueOffset / hueCount) : 0.0f, 0.0f, 1.0f);

            if (bendType == float(BendTypeOneWay)) { // One-way bend
                if (abs(startHue - minimumHue) < hueComparisonTolerance) {
                    float easeOut = normalizedPosition * (1.0f + normalizedPosition * (1.0f - normalizedPosition));
                    return targetValue + (valueDifference * easeOut);
                } else {
                    float easeIn = normalizedPosition * normalizedPosition * (2.0f - normalizedPosition);
                    return defaultValue - (valueDifference * easeIn);
                }
            } else { // Two-way bend
                float u = clamp(1.0f - abs(normalizedPosition * 2.0f - 1.0f), 0.0f, 1.0f);
                float peakSlope = 0.0f;
                if (colorSpaceFlag == ColorSpaceHSB && valueDifference > hueComparisonTolerance) {
                    float idealSlope = (1.5f * hueCount * targetValue) / valueDifference;
                    peakSlope = clamp(idealSlope, 0.0f, 2.0f);
                }
                float hermiteProgress = u * u * ((3.0f - peakSlope) - (2.0f - peakSlope) * u);
                return defaultValue - (valueDifference * hermiteProgress);
            }
        }
    }
    return defaultValue;
}

// MARK: – Monochrome fade helper

inline float2 calculateMonochromeFade(
    float isWhiteSection,
    float fadeFactor,
    float baseSaturation,
    float baseBrightness,
    uint colorSpaceFlag,
    float targetHue,
    device const ShaderBend* saturationBendsData,
    uint saturationBendsCount,
    device const ShaderBend* brightnessBendsData,
    uint brightnessBendsCount,
    bool isStartBend
) {
    float finalSaturation = isWhiteSection == 1.0 ? fadeFactor * baseSaturation : baseSaturation;
    float finalBrightness = isWhiteSection == 1.0 ? baseBrightness : fadeFactor * baseBrightness;

    for (uint bendIndex = 0; bendIndex < saturationBendsCount; bendIndex++) {
        float bendHue = isStartBend ? saturationBendsData[bendIndex].data0.y : saturationBendsData[bendIndex].data0.z;
        if (abs(bendHue - targetHue) < hueComparisonTolerance
            && saturationBendsData[bendIndex].data0.x == float(BendTypeOneWay)) {
            finalSaturation = isWhiteSection == 1.0
                ? fadeFactor * saturationBendsData[bendIndex].data0.w
                : saturationBendsData[bendIndex].data0.w;
        }
    }

    for (uint bendIndex = 0; bendIndex < brightnessBendsCount; bendIndex++) {
        float bendHue = isStartBend ? brightnessBendsData[bendIndex].data0.y : brightnessBendsData[bendIndex].data0.z;
        if (abs(bendHue - targetHue) < hueComparisonTolerance
            && brightnessBendsData[bendIndex].data0.x == float(BendTypeOneWay)) {
            finalBrightness = isWhiteSection == 1.0
                ? brightnessBendsData[bendIndex].data0.w
                : fadeFactor * brightnessBendsData[bendIndex].data0.w;
        }
    }

    if (isWhiteSection == 1.0 && colorSpaceFlag == ColorSpaceOklch) {
        finalBrightness = 1.0 - (fadeFactor * (1.0 - finalBrightness));
    }

    return float2(finalSaturation, finalBrightness);
}

// MARK: - Coordinate helper

inline float calculateNormalizedPosition(float2 position, float2 size, float isVertical) {
    float normalized = isVertical > 0.5 ? (1.0 - (position.y / size.y)) : (position.x / size.x);
    return clamp(normalized, 0.0, 1.0);
}

// MARK: - Gradient shader

constant float achromaticChromaThreshold = 0.0001;

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

    uint colorSpace = uint(colorSpaceFlag);

    if (colorSpace == ColorSpaceRGB) {
        half4 blendedColor = mix(startColor, endColor, half(normalizedPosition));
        return half4(blendedColor.rgb * currentColor.a, blendedColor.a * currentColor.a);
    }

    float3 labStart = convertRGBtoOklab(float3(startColor.rgb));
    float3 labEnd = convertRGBtoOklab(float3(endColor.rgb));

    if (colorSpace == ColorSpaceOklab) {
        float3 mixedLab = mix(labStart, labEnd, normalizedPosition);
        float3 rgbOut = convertOklabtoRGB(mixedLab.x, mixedLab.y, mixedLab.z);
        return half4(half3(rgbOut) * currentColor.a, currentColor.a);
    } else {
        float cStart = sqrt(labStart.y * labStart.y + labStart.z * labStart.z);
        float hStart = atan2(labStart.z, labStart.y);
        if (hStart < 0.0) hStart += 2.0 * M_PI_F;

        float cEnd = sqrt(labEnd.y * labEnd.y + labEnd.z * labEnd.z);
        float hEnd = atan2(labEnd.z, labEnd.y);
        if (hEnd < 0.0) hEnd += 2.0 * M_PI_F;

        bool startIsAchromatic = cStart < achromaticChromaThreshold;
        bool endIsAchromatic = cEnd < achromaticChromaThreshold;

        if (startIsAchromatic && endIsAchromatic) {
            hStart = 0.0;
            hEnd = 0.0;
        } else if (startIsAchromatic) {
            hStart = hEnd;
        } else if (endIsAchromatic) {
            hEnd = hStart;
        } else {
            float hDelta = (hEnd - hStart) / (2.0 * M_PI_F);
            if (hDelta > 0.5) hStart += 2.0 * M_PI_F;
            else if (hDelta < -0.5) hStart -= 2.0 * M_PI_F;
        }

        float L = mix(labStart.x, labEnd.x, normalizedPosition);
        float C = mix(cStart, cEnd, normalizedPosition);
        float h = mix(hStart, hEnd, normalizedPosition) / (2.0 * M_PI_F);

        float3 rgbOut = convertOklchtoRGB(L, C, h);
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
    device const ShaderMonochromeSection* startSectionsData,
    int startSectionsDataLength,
    device const ShaderMonochromeSection* endSectionsData,
    int endSectionsDataLength,
    device const ShaderBend* saturationBendsData,
    int saturationBendsDataLength,
    device const ShaderBend* brightnessBendsData,
    int brightnessBendsDataLength
) {
    float normalizedPosition = calculateNormalizedPosition(position, size, isVertical);

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

    if (normalizedPosition < startSectionBoundary) {
        float cumulativeStartPosition = 0.0;

        for (uint sectionIndex = 0; sectionIndex < startSectionsCount; sectionIndex++) {
            float isWhiteSection = startSectionsData[sectionIndex].isWhite;
            float sectionEndPosition = startSectionsData[sectionIndex].endPosition;
            bool isLastSection = (sectionIndex == startSectionsCount - 1);

            if (normalizedPosition < sectionEndPosition || isLastSection) {
                float distanceMoved = normalizedPosition - cumulativeStartPosition;
                float sectionWidth = sectionEndPosition - cumulativeStartPosition;
                float relativePositionInSection = clamp(distanceMoved / sectionWidth, 0.0, 1.0);

                if (isLastSection) {
                    float rawFade = relativePositionInSection;
                    float easedFade = (startSectionsCount > 1)
                        ? smoothstep(0.0f, 1.0f, rawFade)
                        : rawFade * (1.0f + rawFade * (1.0f - rawFade));
                    float2 fade = calculateMonochromeFade(
                        isWhiteSection, easedFade, baseSaturation, baseBrightness,
                        colorSpaceFlag, minimumHue, saturationBendsData, saturationBendsCount,
                        brightnessBendsData, brightnessBendsCount, true
                    );
                    return half4(
                        half3(resolveColor(colorSpaceFlag, minimumHue, fade.x, fade.y))
                            * currentColor.a,
                        currentColor.a
                    );
                } else {
                    float nextSectionIsWhite = startSectionsData[sectionIndex + 1].isWhite;
                    half startingBrightness = select(0.0h, 1.0h, isWhiteSection == 1.0f);
                    half endingBrightness = select(0.0h, 1.0h, nextSectionIsWhite == 1.0f);
                    float brightnessDelta = endingBrightness - startingBrightness;
                    float smoothRel = smoothstep(0.0f, 1.0f, relativePositionInSection);
                    float interpolatedBrightness = startingBrightness + brightnessDelta * smoothRel;
                    return half4(
                        half3(resolveColor(colorSpaceFlag, minimumHue, 0.0, interpolatedBrightness))
                            * currentColor.a,
                        currentColor.a
                    );
                }
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
            minimumHue,
            colorSpaceFlag
        );
        float calculatedBrightness = calculateBend(
            currentHue,
            baseBrightness,
            brightnessBendsData,
            brightnessBendsCount,
            minimumHue,
            colorSpaceFlag
        );

        return half4(
            half3(resolveColor(colorSpaceFlag, currentHue, calculatedSaturation, calculatedBrightness))
                * currentColor.a,
            currentColor.a
        );
    } else {
        float cumulativeEndPosition = hueSectionBoundary;

        for (uint sectionIndex = 0; sectionIndex < endSectionsCount; sectionIndex++) {
            float isWhiteSection = endSectionsData[sectionIndex].isWhite;
            float sectionEndPosition = endSectionsData[sectionIndex].endPosition;
            bool isLastSection = (sectionIndex == endSectionsCount - 1);

            if (normalizedPosition <= sectionEndPosition || isLastSection) {
                float distanceFromEnd = normalizedPosition - cumulativeEndPosition;
                float sectionWidth = sectionEndPosition - cumulativeEndPosition;
                float relativePositionInSection = clamp(distanceFromEnd / sectionWidth, 0.0, 1.0);

                if (sectionIndex == 0) {
                    float rawFade = 1.0f - relativePositionInSection;
                    float easedFade = (endSectionsCount > 1)
                        ? smoothstep(0.0f, 1.0f, rawFade)
                        : rawFade * (1.0f + rawFade * (1.0f - rawFade));
                    float2 fade = calculateMonochromeFade(
                        isWhiteSection, easedFade, baseSaturation, baseBrightness,
                        colorSpaceFlag, maximumHue, saturationBendsData, saturationBendsCount,
                        brightnessBendsData, brightnessBendsCount, false
                    );
                    return half4(
                        half3(resolveColor(colorSpaceFlag, maximumHue, fade.x, fade.y))
                            * currentColor.a,
                        currentColor.a
                    );
                } else {
                    float previousSectionIsWhite = endSectionsData[sectionIndex - 1].isWhite;
                    half startingBrightness = select(0.0h, 1.0h, previousSectionIsWhite == 1.0f);
                    half endingBrightness = select(0.0h, 1.0h, isWhiteSection == 1.0f);
                    float brightnessDelta = endingBrightness - startingBrightness;
                    float smoothRel = smoothstep(0.0f, 1.0f, relativePositionInSection);
                    float interpolatedBrightness = startingBrightness + brightnessDelta * smoothRel;
                    return half4(
                        half3(resolveColor(colorSpaceFlag, maximumHue, 0.0, interpolatedBrightness))
                            * currentColor.a,
                        currentColor.a
                    );
                }
            }
            cumulativeEndPosition = sectionEndPosition;
        }
    }
    return half4(0.0);
}
