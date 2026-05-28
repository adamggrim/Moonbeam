#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// This value must match `spectrumConstants.maxBends` in `SpectrumSliderModel.swift`.
constant int MAX_BENDS = 20;
// This value must match `spectrumConstants.maxMonochromeSections` in `SpectrumSliderModel.swift`.
constant int MAX_MONOCHROME_SECTIONS = 2;

// MARK: - Struct Definitions

struct ShaderBend {
    float4 data0; // x: type, y: startHue, z: endHue, w: targetValue
    float4 data1; // x: hueCount, y: 0, z: 0, w: 0
};

/// Represents the structured data passed to the Metal shader for rendering the spectrum.
///
///  The property sequence, layout and alignment of this struct must exactly mirror the `SpectrumShaderData`
///   struct in `SpectrumSliderModel.swift`.
struct SpectrumShaderData {
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

    float4 startSectionsData;
    float4 endSectionsData;

    ShaderBend saturationBendsData[20];
    ShaderBend brightnessBendsData[20];
};

// MARK: – HSB to RGB

float3 convertHSBtoRGB(float hue, float saturation, float brightness) {
    float4 conversionConstants = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 rgbValues = abs(fract(hue + conversionConstants.xyz) * 6.0 - conversionConstants.www);
    return brightness * mix(conversionConstants.xxx, clamp(rgbValues - conversionConstants.xxx, 0.0, 1.0), saturation);
}

// MARK: - OKLAB and OKLCH to RGB

float3 convertOKLABtoRGB(float L, float a, float b) {
    float l_ = L + 0.3963377774 * a + 0.2158037573 * b;
    float m_ = L - 0.1055613458 * a - 0.0638541728 * b;
    float s_ = L - 0.0894841775 * a - 1.2914855480 * b;

    float l = sign(l_) * pow(abs(l_), 3.0);
    float m = sign(m_) * pow(abs(m_), 3.0);
    float s = sign(s_) * pow(abs(s_), 3.0);

    // Display P3 Matrix
    float3 lin = float3(
        2.7015367 * l - 1.6373796 * m - 0.0641571 * s,
        -0.3150531 * l + 1.3415174 * m - 0.0264643 * s,
         0.0384799 * l - 0.0635483 * m + 1.0250684 * s
    );

    float3 sRGB = float3(
        lin.r <= 0.0031308 ? 12.92 * lin.r : 1.055 * pow(lin.r, 1.0/2.4) - 0.055,
        lin.g <= 0.0031308 ? 12.92 * lin.g : 1.055 * pow(lin.g, 1.0/2.4) - 0.055,
        lin.b <= 0.0031308 ? 12.92 * lin.b : 1.055 * pow(lin.b, 1.0/2.4) - 0.055
    );
    return clamp(sRGB, 0.0, 1.0);
}

float3 convertOKLCHtoRGB(float L, float C, float h) {
    float hueAngle = h * 2.0 * M_PI_F;
    float a = C * cos(hueAngle);
    float b = C * sin(hueAngle);
    return convertOKLABtoRGB(L, a, b);
}

float3 resolveColor(float space, float h, float s_c, float b_l) {
    return space == 1.0 ? convertOKLCHtoRGB(b_l, s_c, h) : convertHSBtoRGB(h, s_c, b_l);
}

float3 convertRGBtoOKLAB(float3 c) {
    float l = 0.4122214708 * c.r + 0.5363325363 * c.g + 0.0514459929 * c.b;
    float m = 0.2119034982 * c.r + 0.6806995451 * c.g + 0.1073969566 * c.b;
    float s = 0.0883024619 * c.r + 0.2817188376 * c.g + 0.6299787005 * c.b;
    l = sign(l) * pow(abs(l), 1.0/3.0);
    m = sign(m) * pow(abs(m), 1.0/3.0);
    s = sign(s) * pow(abs(s), 1.0/3.0);
    return float3(
        0.2104542553*l + 0.7936177850*m - 0.0040720468*s,
        1.9779984951*l - 2.4285922050*m + 0.4505937099*s,
        0.0259040371*l + 0.7827717662*m - 0.8086757660*s
    );
}

// MARK: – Spectrum Bends

float calculateBend(float currentHue, float defaultValue, device const ShaderBend* bendsData, int totalBends, float minimumHue) {
    // Capped at `MAX_BENDS` to prevent unroll failures.
    for (int bendIndex = 0; bendIndex < MAX_BENDS; bendIndex++) {
        if (bendIndex >= totalBends) break;
        
        float bendType = bendsData[bendIndex].data0.x;
        float startHue = bendsData[bendIndex].data0.y;
        float endHue = bendsData[bendIndex].data0.z;
        float targetValue = bendsData[bendIndex].data0.w;
        float hueCount = bendsData[bendIndex].data1.x;

        if (currentHue >= startHue && currentHue <= endHue) {
            float valueDifference = defaultValue - targetValue;
            float hueOffset = currentHue - startHue;

            if (bendType == 1.0) { // One-way bend
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

// MARK: - Gradient Shader

[[ stitchable ]]
half4 gradientShader(float2 position, half4 currentColor, float2 size, half4 startColor, half4 endColor, float isVertical, float colorSpaceFlag) {
    float normalizedPosition = isVertical > 0.5 ? (1.0 - (position.y / size.y)) : (position.x / size.x);
    normalizedPosition = clamp(normalizedPosition, 0.0, 1.0);

    if (colorSpaceFlag == 0.0) {
        half4 blendedColor = mix(startColor, endColor, normalizedPosition);
        return half4(blendedColor.rgb * currentColor.a, blendedColor.a * currentColor.a);
    }

    float3 labStart = convertRGBtoOKLAB(float3(startColor.rgb));
    float3 labEnd = convertRGBtoOKLAB(float3(endColor.rgb));

    if (colorSpaceFlag == 1.0) {
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

// MARK: - Spectrum Shader

[[ stitchable ]]
half4 spectrumShader(float2 position, half4 currentColor, float2 size, float isVertical, device const SpectrumShaderData* data, int dataLength) {
    float normalizedPosition = isVertical > 0.5 ? (1.0 - (position.y / size.y)) : (position.x / size.x);
    normalizedPosition = clamp(normalizedPosition, 0.0, 1.0);

    float totalWeight = data->totalWeight;
    if (totalWeight <= 0.0) return half4(0.0);

    float startSectionBoundary = data->startSectionBoundary;
    float hueSectionBoundary = data->hueSectionBoundary;
    float minimumHue = data->minimumHue;
    float maximumHue = data->maximumHue;
    float baseSaturation = data->baseSaturation;
    float baseBrightness = data->baseBrightness;
    float colorSpaceFlag = data->colorSpaceFlag;

    int startSectionsCount = data->startSectionsCount;
    int endSectionsCount = data->endSectionsCount;
    int saturationBendsCount = data->saturationBendsCount;
    int brightnessBendsCount = data->brightnessBendsCount;

    float4 startSectionsData = data->startSectionsData;
    float4 endSectionsData = data->endSectionsData;

    if (normalizedPosition < startSectionBoundary) {
        float cumulativeStartPosition = 0.0;
        
        // Capped at `MAX_MONOCHROME_SECTIONS` start sections.
        for (int sectionIndex = 0; sectionIndex < MAX_MONOCHROME_SECTIONS; sectionIndex++) {
            if (sectionIndex >= startSectionsCount) break;
            
            float isWhiteSection = startSectionsData[sectionIndex*2];
            float sectionEndPosition = startSectionsData[sectionIndex*2 + 1];
            
            if (normalizedPosition < sectionEndPosition) {
                float relativePositionInSection = (normalizedPosition - cumulativeStartPosition) / (sectionEndPosition - cumulativeStartPosition);
                bool isLastSection = (sectionIndex == startSectionsCount - 1);
                
                if (isLastSection) {
                    float finalBrightness = isWhiteSection == 1.0 ? baseBrightness : relativePositionInSection * baseBrightness;
                    float finalSaturation = isWhiteSection == 1.0 ? relativePositionInSection * baseSaturation : baseSaturation;
                    
                    // Capped at `MAX_BENDS` saturation bends.
                    for (int bendIndex = 0; bendIndex < MAX_BENDS; bendIndex++) {
                        if (bendIndex >= saturationBendsCount) break;
                        if (data->saturationBendsData[bendIndex].data0.y == minimumHue && data->saturationBendsData[bendIndex].data0.x == 1.0) {
                            finalSaturation = isWhiteSection == 1.0 ? relativePositionInSection * data->saturationBendsData[bendIndex].data0.w : finalSaturation;
                        }
                    }
                    
                    // Capped at `MAX_BENDS` brightness bends.
                    for (int bendIndex = 0; bendIndex < MAX_BENDS; bendIndex++) {
                        if (bendIndex >= brightnessBendsCount) break;
                        if (data->brightnessBendsData[bendIndex].data0.y == minimumHue && data->brightnessBendsData[bendIndex].data0.x == 1.0) {
                            finalBrightness = isWhiteSection == 1.0 ? finalBrightness : relativePositionInSection * data->brightnessBendsData[bendIndex].data0.w;
                        }
                    }
                    
                    if (isWhiteSection == 1.0 && colorSpaceFlag == 1.0) finalBrightness = 1.0 - (relativePositionInSection * (1.0 - baseBrightness));
                    return half4(half3(resolveColor(colorSpaceFlag, minimumHue, finalSaturation, finalBrightness)) * currentColor.a, currentColor.a);
                } else {
                    float nextSectionIsWhite = startSectionsData[(sectionIndex+1)*2];
                    float startingBrightness = isWhiteSection == 1.0 ? 1.0 : 0.0;
                    float endingBrightness = nextSectionIsWhite == 1.0 ? 1.0 : 0.0;
                    float interpolatedBrightness = startingBrightness + (endingBrightness - startingBrightness) * relativePositionInSection;
                    return half4(half3(resolveColor(colorSpaceFlag, minimumHue, 0.0, interpolatedBrightness)) * currentColor.a, currentColor.a);
                }
            }
            cumulativeStartPosition = sectionEndPosition;
        }
    } else if (normalizedPosition <= hueSectionBoundary) {
        float relativeHuePosition = (hueSectionBoundary > startSectionBoundary) ? (normalizedPosition - startSectionBoundary) / (hueSectionBoundary - startSectionBoundary) : 0.0;
        float currentHue = minimumHue + relativeHuePosition * (maximumHue - minimumHue);

        float calculatedSaturation = calculateBend(currentHue, baseSaturation, data->saturationBendsData, saturationBendsCount, minimumHue);
        float calculatedBrightness = calculateBend(currentHue, baseBrightness, data->brightnessBendsData, brightnessBendsCount, minimumHue);

        return half4(half3(resolveColor(colorSpaceFlag, currentHue, calculatedSaturation, calculatedBrightness)) * currentColor.a, currentColor.a);
    } else {
        float cumulativeEndPosition = hueSectionBoundary;
        
        // Capped at `MAX_MONOCHROME_SECTIONS` end sections.
        for (int sectionIndex = 0; sectionIndex < MAX_MONOCHROME_SECTIONS; sectionIndex++) {
            if (sectionIndex >= endSectionsCount) break;
            
            float isWhiteSection = endSectionsData[sectionIndex*2];
            float sectionEndPosition = endSectionsData[sectionIndex*2 + 1];
            bool isLastSection = (sectionIndex == endSectionsCount - 1);

            if (normalizedPosition <= sectionEndPosition || isLastSection) {
                float relativePositionInSection = clamp((normalizedPosition - cumulativeEndPosition) / (sectionEndPosition - cumulativeEndPosition), 0.0, 1.0);
                bool isFirstEndSection = (sectionIndex == 0);

                if (isFirstEndSection) {
                    float finalBrightness = isWhiteSection == 1.0 ? baseBrightness : (1.0 - relativePositionInSection) * baseBrightness;
                    float finalSaturation = isWhiteSection == 1.0 ? (1.0 - relativePositionInSection) * baseSaturation : baseSaturation;
                    
                    // Capped at `MAX_BENDS` saturation bends.
                    for (int bendIndex = 0; bendIndex < MAX_BENDS; bendIndex++) {
                        if (bendIndex >= saturationBendsCount) break;
                        if (data->saturationBendsData[bendIndex].data0.z == maximumHue && data->saturationBendsData[bendIndex].data0.x == 1.0) {
                            finalSaturation = isWhiteSection == 1.0 ? (1.0 - relativePositionInSection) * data->saturationBendsData[bendIndex].data0.w : finalSaturation;
                        }
                    }
                    
                    // Capped at `MAX_BENDS` brightness bends.
                    for (int bendIndex = 0; bendIndex < MAX_BENDS; bendIndex++) {
                        if (bendIndex >= brightnessBendsCount) break;
                        if (data->brightnessBendsData[bendIndex].data0.z == maximumHue && data->brightnessBendsData[bendIndex].data0.x == 1.0) {
                            finalBrightness = isWhiteSection == 1.0 ? finalBrightness : (1.0 - relativePositionInSection) * data->brightnessBendsData[bendIndex].data0.w;
                        }
                    }
                    if (isWhiteSection == 1.0 && colorSpaceFlag == 1.0) finalBrightness = 1.0 - ((1.0 - relativePositionInSection) * (1.0 - baseBrightness));
                    return half4(half3(resolveColor(colorSpaceFlag, maximumHue, finalSaturation, finalBrightness)) * currentColor.a, currentColor.a);
                } else {
                    float previousSectionIsWhite = endSectionsData[(sectionIndex-1)*2];
                    float startingBrightness = previousSectionIsWhite == 1.0 ? 1.0 : 0.0;
                    float endingBrightness = isWhiteSection == 1.0 ? 1.0 : 0.0;
                    float interpolatedBrightness = startingBrightness + (endingBrightness - startingBrightness) * relativePositionInSection;
                    return half4(half3(resolveColor(colorSpaceFlag, maximumHue, 0.0, interpolatedBrightness)) * currentColor.a, currentColor.a);
                }
            }
            cumulativeEndPosition = sectionEndPosition;
        }
    }
    return half4(0.0);
}
