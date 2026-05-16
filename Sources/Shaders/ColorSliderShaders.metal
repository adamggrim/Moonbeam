#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// MARK: Helper – HSB to RGB
float3 convertHSBtoRGB(float hue, float saturation, float brightness) {
    float4 conversionConstants = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 rgbValues = abs(fract(hue + conversionConstants.xyz) * 6.0 - conversionConstants.www);
    return brightness * mix(conversionConstants.xxx, clamp(rgbValues - conversionConstants.xxx, 0.0, 1.0), saturation);
}

// MARK: Helper – Spectrum bends
float calculateBend(float currentHue, float defaultValue, device const float* bendsData, int totalBends, float minimumHue) {
    // Capped at 20 bends to prevent unroll failures.
    for (int bendIndex = 0; bendIndex < 20; bendIndex++) {
        if (bendIndex >= totalBends) break;
        
        int arrayOffset = bendIndex * 5;
        float bendType = bendsData[arrayOffset];
        float startHue = bendsData[arrayOffset+1];
        float endHue = bendsData[arrayOffset+2];
        float targetValue = bendsData[arrayOffset+3];
        float hueCount = bendsData[arrayOffset+4];

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

// MARK: Gradient shader
[[ stitchable ]]
half4 gradientShader(float2 position, half4 currentColor, float2 size, half4 startColor, half4 endColor, float isVertical) {
    float normalizedPosition = isVertical > 0.5 ? (1.0 - (position.y / size.y)) : (position.x / size.x);
    half4 blendedColor = mix(startColor, endColor, clamp(normalizedPosition, 0.0, 1.0));
    
    // Multiply by `currentColor.a` to preserve capsule shape.
    return half4(blendedColor.rgb * currentColor.a, blendedColor.a * currentColor.a);
}

// MARK: Spectrum shader
[[ stitchable ]]
half4 spectrumShader(float2 position, half4 currentColor, float2 size, float isVertical, device const float* shaderData, int shaderDataLength) {
    float normalizedPosition = isVertical > 0.5 ? (1.0 - (position.y / size.y)) : (position.x / size.x);
    normalizedPosition = clamp(normalizedPosition, 0.0, 1.0);

    float totalWeight = shaderData[0];
    if (totalWeight <= 0.0) return half4(0.0);

    float startSectionBoundary = shaderData[1];
    float hueSectionBoundary = shaderData[2];
    float minimumHue = shaderData[3];
    float maximumHue = shaderData[4];
    float baseSaturation = shaderData[5];
    float baseBrightness = shaderData[6];

    int dataPointer = 7;
    int startSectionsCount = int(shaderData[dataPointer++]);
    device const float* startSectionsData = shaderData + dataPointer;
    dataPointer += startSectionsCount * 2;

    int endSectionsCount = int(shaderData[dataPointer++]);
    device const float* endSectionsData = shaderData + dataPointer;
    dataPointer += endSectionsCount * 2;

    int saturationBendsCount = int(shaderData[dataPointer++]);
    device const float* saturationBendsData = shaderData + dataPointer;
    dataPointer += saturationBendsCount * 5;

    int brightnessBendsCount = int(shaderData[dataPointer++]);
    device const float* brightnessBendsData = shaderData + dataPointer;

    if (normalizedPosition < startSectionBoundary) {
        float cumulativeStartPosition = 0.0;
        
        // Capped at two start sections.
        for (int sectionIndex = 0; sectionIndex < 2; sectionIndex++) {
            if (sectionIndex >= startSectionsCount) break;
            
            float isWhiteSection = startSectionsData[sectionIndex*2];
            float sectionEndPosition = startSectionsData[sectionIndex*2 + 1];
            
            if (normalizedPosition < sectionEndPosition) {
                float relativePositionInSection = (normalizedPosition - cumulativeStartPosition) / (sectionEndPosition - cumulativeStartPosition);
                bool isLastSection = (sectionIndex == startSectionsCount - 1);
                
                if (isLastSection) {
                    float finalBrightness = isWhiteSection == 1.0 ? baseBrightness : relativePositionInSection * baseBrightness;
                    float finalSaturation = isWhiteSection == 1.0 ? relativePositionInSection * baseSaturation : baseSaturation;
                    
                    // Capped at 20 saturation bends.
                    for (int bendIndex = 0; bendIndex < 20; bendIndex++) {
                        if (bendIndex >= saturationBendsCount) break;
                        if (saturationBendsData[bendIndex*5+1] == minimumHue && saturationBendsData[bendIndex*5] == 1.0) {
                            finalSaturation = isWhiteSection == 1.0 ? relativePositionInSection * saturationBendsData[bendIndex*5+3] : finalSaturation;
                        }
                    }
                    
                    // Capped at 20 brightness bends.
                    for (int bendIndex = 0; bendIndex < 20; bendIndex++) {
                        if (bendIndex >= brightnessBendsCount) break;
                        if (brightnessBendsData[bendIndex*5+1] == minimumHue && brightnessBendsData[bendIndex*5] == 1.0) {
                            finalBrightness = isWhiteSection == 1.0 ? finalBrightness : relativePositionInSection * brightnessBendsData[bendIndex*5+3];
                        }
                    }
                    return half4(half3(convertHSBtoRGB(minimumHue, finalSaturation, finalBrightness)) * currentColor.a, currentColor.a);
                } else {
                    float nextSectionIsWhite = startSectionsData[(sectionIndex+1)*2];
                    float startingBrightness = isWhiteSection == 1.0 ? 1.0 : 0.0;
                    float endingBrightness = nextSectionIsWhite == 1.0 ? 1.0 : 0.0;
                    float interpolatedBrightness = startingBrightness + (endingBrightness - startingBrightness) * relativePositionInSection;
                    return half4(half3(convertHSBtoRGB(minimumHue, 0.0, interpolatedBrightness)) * currentColor.a, currentColor.a);
                }
            }
            cumulativeStartPosition = sectionEndPosition;
        }
    } else if (normalizedPosition <= hueSectionBoundary) {
        float relativeHuePosition = (hueSectionBoundary > startSectionBoundary) ? (normalizedPosition - startSectionBoundary) / (hueSectionBoundary - startSectionBoundary) : 0.0;
        float currentHue = minimumHue + relativeHuePosition * (maximumHue - minimumHue);

        float calculatedSaturation = calculateBend(currentHue, baseSaturation, saturationBendsData, saturationBendsCount, minimumHue);
        float calculatedBrightness = calculateBend(currentHue, baseBrightness, brightnessBendsData, brightnessBendsCount, minimumHue);

        return half4(half3(convertHSBtoRGB(currentHue, calculatedSaturation, calculatedBrightness)) * currentColor.a, currentColor.a);
    } else {
        float cumulativeEndPosition = hueSectionBoundary;
        
        // Capped at two end sections.
        for (int sectionIndex = 0; sectionIndex < 2; sectionIndex++) {
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
                    
                    // Capped at 20 saturation bends.
                    for (int bendIndex = 0; bendIndex < 20; bendIndex++) {
                        if (bendIndex >= saturationBendsCount) break;
                        if (saturationBendsData[bendIndex*5+2] == maximumHue && saturationBendsData[bendIndex*5] == 1.0) {
                            finalSaturation = isWhiteSection == 1.0 ? (1.0 - relativePositionInSection) * saturationBendsData[bendIndex*5+3] : finalSaturation;
                        }
                    }
                    
                    // Capped at 20 brightness bends.
                    for (int bendIndex = 0; bendIndex < 20; bendIndex++) {
                        if (bendIndex >= brightnessBendsCount) break;
                        if (brightnessBendsData[bendIndex*5+2] == maximumHue && brightnessBendsData[bendIndex*5] == 1.0) {
                            finalBrightness = isWhiteSection == 1.0 ? finalBrightness : (1.0 - relativePositionInSection) * brightnessBendsData[bendIndex*5+3];
                        }
                    }
                    return half4(half3(convertHSBtoRGB(maximumHue, finalSaturation, finalBrightness)) * currentColor.a, currentColor.a);
                } else {
                    float previousSectionIsWhite = endSectionsData[(sectionIndex-1)*2];
                    float startingBrightness = previousSectionIsWhite == 1.0 ? 1.0 : 0.0;
                    float endingBrightness = isWhiteSection == 1.0 ? 1.0 : 0.0;
                    float interpolatedBrightness = startingBrightness + (endingBrightness - startingBrightness) * relativePositionInSection;
                    return half4(half3(convertHSBtoRGB(maximumHue, 0.0, interpolatedBrightness)) * currentColor.a, currentColor.a);
                }
            }
            cumulativeEndPosition = sectionEndPosition;
        }
    }
    return half4(0.0);
}
