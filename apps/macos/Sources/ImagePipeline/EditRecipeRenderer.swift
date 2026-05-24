import CoreImage
import Foundation

enum EditRecipeRenderer {
    static func apply(
        _ recipe: EditRecipe,
        to image: CIImage,
        toneTuning: ToneTuning = .defaultV1,
        behaviorTuning: BehaviorTuning? = nil,
        overlay: ToneRangeOverlay = .off
    ) throws -> CIImage {
        let kernelParameters: [Float]
        if let behaviorTuning {
            kernelParameters = recipe.light.kernelParameters(behaviorTuning: behaviorTuning)
        } else {
            kernelParameters = recipe.light.kernelParameters(toneTuning: toneTuning)
        }
        let hasCustomBehavior = behaviorTuning.map { $0 != .defaultV2 } ?? false

        guard !recipe.isNeutral || toneTuning != .defaultV1 || hasCustomBehavior || overlay != .off else {
            return image
        }

        guard let kernel = lightKernel else {
            throw ImagePipelineRenderError.unableToCreateEditKernel
        }

        let arguments: [Any] = [image]
            + kernelParameters.map { Double($0) }
            + [overlay.kernelMode]

        guard let editedImage = kernel.apply(extent: image.extent, arguments: arguments) else {
            throw ImagePipelineRenderError.unableToApplyEditRecipe
        }

        return editedImage
    }

    private static let lightKernel = CIColorKernel(source:
        """
        float darkroomInfluence(
            float positionEV,
            float startEV,
            float fullEV,
            float falloff,
            float midtoneProtection,
            float endpointProtection,
            float falloffShape,
            float bodyBias,
            float peakDamping
        ) {
            float width = max(abs(fullEV - startEV), 0.001);
            float direction = fullEV >= startEV ? 1.0 : -1.0;
            float progress = ((positionEV - startEV) * direction) / width;
            float linear = clamp(progress, 0.0, 1.0);
            float smoothProgress = smoothstep(0.0, 1.0, linear);
            float base = smoothProgress;
            if (falloffShape >= 2.5) {
                base = pow(smoothProgress, 1.75);
            } else if (falloffShape >= 1.5) {
                base = pow(smoothProgress, 0.65);
            } else if (falloffShape >= 0.5) {
                base = linear;
            }
            float bodyBase = pow(base, 0.45);
            float peakBase = pow(base, 2.2);
            float biasAmount = clamp(abs(bodyBias), 0.0, 1.0);
            float biasedBase = bodyBias >= 0.0
                ? mix(base, bodyBase, biasAmount)
                : mix(base, peakBase, biasAmount);
            float shaped = pow(biasedBase, 1.0 / clamp(falloff, 0.1, 4.0));
            float grayDistance = abs(positionEV / 1.5);
            float midtoneGuard = 1.0 - clamp(midtoneProtection, 0.0, 0.95)
                * exp(-grayDistance * grayDistance);
            float endpointGuard = 1.0 - clamp(endpointProtection, 0.0, 0.95)
                * smoothstep(1.0, 1.75, progress);
            float peakGuard = 1.0 - clamp(peakDamping, 0.0, 0.98)
                * smoothstep(0.55, 1.0, progress);

            return shaped * clamp(midtoneGuard, 0.0, 1.0) * clamp(endpointGuard, 0.0, 1.0) * clamp(peakGuard, 0.0, 1.0);
        }

        float darkroomSoftClipZ(float z, float amount) {
            float clippedAmount = clamp(amount, 0.0, 2.0);
            if (clippedAmount <= 0.0) {
                return z;
            }

            float limit = 16.0 / max(clippedAmount, 0.001);
            float scaled = clamp(z / limit, -20.0, 20.0);
            return limit * ((2.0 / (1.0 + exp(-2.0 * scaled))) - 1.0);
        }

        float darkroomContrastZoneWeight(float z, float zone) {
            if (zone < 0.5) {
                return smoothstep(0.0, 4.0, -z);
            } else if (zone < 1.5) {
                return 1.0 - smoothstep(0.5, 3.0, abs(z));
            } else if (zone < 2.5) {
                return smoothstep(0.0, 4.0, z);
            }

            return 1.0;
        }

        float darkroomChromaPreservationScale(float value) {
            return clamp(1.0 + (value - 0.9) * 1.5, 0.0, 1.5);
        }

        float darkroomToneChromaModeScale(float mode, float targetZ) {
            float highlightWeight = smoothstep(0.0, 4.0, max(targetZ, 0.0));
            float shadowWeight = smoothstep(0.0, 4.0, max(-targetZ, 0.0));

            if (mode < 0.5) {
                return 1.0;
            } else if (mode < 1.5) {
                return clamp(1.0 - 0.3 * highlightWeight, 0.45, 1.35);
            } else if (mode < 2.5) {
                return clamp(1.0 + 0.24 * max(highlightWeight, shadowWeight), 0.45, 1.35);
            }

            return clamp(1.0 - 0.16 * highlightWeight + 0.08 * shadowWeight, 0.45, 1.35);
        }

        float darkroomRegionalPullDesaturationScale(float mode) {
            if (mode < 0.5) {
                return 1.0;
            } else if (mode < 1.5) {
                return 1.65;
            } else if (mode < 2.5) {
                return 0.35;
            }

            return 1.15;
        }

        float darkroomRegionalLiftDesaturationScale(float mode) {
            if (mode < 0.5) {
                return 0.0;
            } else if (mode < 1.5) {
                return 0.2;
            } else if (mode < 2.5) {
                return 0.55;
            }

            return 1.0;
        }

        float darkroomRegionalLiftDesaturationFloor(float mode) {
            if (mode < 0.5) {
                return 0.0;
            } else if (mode < 1.5) {
                return 0.015;
            } else if (mode < 2.5) {
                return 0.04;
            }

            return 0.07;
        }

        float darkroomSkinLikeMask(vec3 color, float luma) {
            float chroma = length(color - vec3(luma));
            float warmOrder = smoothstep(0.0, 0.18, color.r - color.g)
                * smoothstep(-0.02, 0.16, color.g - color.b);
            float notExtremeRed = 1.0 - smoothstep(0.4, 0.85, color.r - color.g);
            float brightness = smoothstep(0.04, 0.35, luma) * (1.0 - smoothstep(1.2, 2.4, luma));
            float colorfulness = smoothstep(0.015, 0.22, chroma);

            return clamp(warmOrder * notExtremeRed * brightness * colorfulness, 0.0, 1.0);
        }

        float darkroomGamutRisk(vec3 color) {
            return clamp(smoothstep(0.92, 1.25, max(color.r, max(color.g, color.b))), 0.0, 1.0);
        }

        float darkroomCenteredControl(float value, float center) {
            float clippedValue = clamp(value, 0.0, 1.0);
            float clippedCenter = clamp(center, 0.001, 0.999);

            if (clippedValue >= clippedCenter) {
                return clamp((clippedValue - clippedCenter) / max(1.0 - clippedCenter, 0.001), 0.0, 1.0);
            }

            return -clamp((clippedCenter - clippedValue) / max(clippedCenter, 0.001), 0.0, 1.0);
        }

        float darkroomColorChangeScale(
            float skinProtectionAmount,
            float skinFreedom,
            float hueProtectionAmount,
            float hueFreedom
        ) {
            float positive = clamp(max(skinProtectionAmount, hueProtectionAmount), 0.0, 0.95);
            float negative = clamp(max(skinFreedom, hueFreedom), 0.0, 1.0);

            return clamp(1.0 - positive + negative * 0.35, 0.0, 1.5);
        }

        kernel vec4 darkroom_light(
            __sample pixel,
            float exposureGain,
            float contrastStrength,
            float pivotEV,
            float highlightsEV,
            float shadowsEV,
            float whitesEV,
            float blacksEV,
            float middleGray,
            float toneEpsilon,
            float lumaRed,
            float lumaGreen,
            float lumaBlue,
            float contrastMaxEV,
            float contrastRolloffEV,
            float shadowZoneStartEV,
            float shadowZoneFullEV,
            float highlightZoneStartEV,
            float highlightZoneFullEV,
            float blackZoneStartEV,
            float blackZoneFullEV,
            float whiteZoneStartEV,
            float whiteZoneFullEV,
            float endpointMaxEV,
            float baseContrast,
            float toeStrength,
            float toeLengthEV,
            float shoulderStrength,
            float shoulderLengthEV,
            float outputSoftClip,
            float shadowFalloff,
            float shadowMidtoneProtection,
            float shadowEndpointProtection,
            float highlightFalloff,
            float highlightMidtoneProtection,
            float highlightEndpointProtection,
            float blackSoftness,
            float blackProtection,
            float whiteSoftness,
            float whiteProtection,
            float exposureEV,
            float exposureShadowLiftEV,
            float exposureToeFollowAmount,
            float exposureHighlightProtectionPerEV,
            float exposureChromaResponse,
            float exposureSaturationMin,
            float exposureSaturationMax,
            float exposureShadowStartEV,
            float exposureShadowFullEV,
            float exposureShadowFalloff,
            float exposureShadowMidtoneProtection,
            float exposureShadowEndpointProtection,
            float exposureShadowBodyBias,
            float exposureShadowPeakDamping,
            float contrastMode,
            float contrastAffectsSaturation,
            float contrastSaturationAmount,
            float contrastSaturationZone,
            float contrastHueProtection,
            float contrastNeutralProtection,
            float highlightFalloffShape,
            float highlightPullDesaturation,
            float highlightNearWhiteDesaturation,
            float highlightSaturationClamp,
            float highlightHueProtection,
            float highlightBodyBias,
            float highlightPeakDamping,
            float shadowFalloffShape,
            float shadowLiftDesaturation,
            float shadowNoiseChromaProtection,
            float shadowHueProtection,
            float shadowBodyBias,
            float shadowPeakDamping,
            float whiteFalloffShape,
            float whiteShoulderCoupling,
            float whiteChromaProtection,
            float whiteDesaturationNearClip,
            float whiteBodyBias,
            float whitePeakDamping,
            float blackFalloffShape,
            float blackToeCoupling,
            float blackChromaProtection,
            float blackDensitySaturationCoupling,
            float blackBodyBias,
            float blackPeakDamping,
            float toneChromaMode,
            float globalChromaPreservation,
            float saturationMin,
            float saturationMax,
            float neutralProtection,
            float skinProtection,
            float hueStability,
            float gamutCompressionAmount,
            float colorContrastSaturationAmount,
            float contrastSaturationMidtoneBias,
            float colorHighlightPullDesaturation,
            float colorHighlightNearWhiteDesaturation,
            float colorShadowLiftDesaturation,
            float colorShadowNoiseChromaProtection,
            float colorBlackDensitySaturation,
            float colorBlackChromaProtection,
            float colorWhiteClipDesaturation,
            float colorWhiteChromaProtection,
            float overlayInfluenceOpacity,
            float overlaySaturationScale,
            float overlayNeutralDriftThreshold,
            float highlightLiftDesaturation,
            float highlightChromaMode,
            float shadowChromaMode,
            float overlayMode
        ) {
            vec3 color = max(pixel.rgb * exposureGain, vec3(0.0));
            float luma = dot(color, vec3(lumaRed, lumaGreen, lumaBlue));
            float safeLuma = max(luma, toneEpsilon);
            float z = log2(safeLuma / max(middleGray, toneEpsilon)) * max(baseContrast, 0.001);

            float effectiveToeStrength = max(
                toeStrength - max(exposureEV, 0.0) * max(exposureToeFollowAmount, 0.0),
                0.0
            );
            z -= effectiveToeStrength * darkroomInfluence(-z, 0.0, toeLengthEV, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0);
            z += max(exposureShadowLiftEV, 0.0) * darkroomInfluence(
                z,
                exposureShadowStartEV,
                exposureShadowFullEV,
                exposureShadowFalloff,
                exposureShadowMidtoneProtection,
                exposureShadowEndpointProtection,
                0.0,
                exposureShadowBodyBias,
                exposureShadowPeakDamping
            );
            float effectiveShoulderStrength = max(shoulderStrength, 0.0)
                + max(exposureEV, 0.0) * max(exposureHighlightProtectionPerEV, 0.0)
                + max(whiteShoulderCoupling, 0.0) * max(whitesEV, 0.0);
            z -= effectiveShoulderStrength * darkroomInfluence(z, 0.0, shoulderLengthEV, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0);

            float shadowInfluence = darkroomInfluence(
                z,
                shadowZoneStartEV,
                shadowZoneFullEV,
                shadowFalloff,
                shadowMidtoneProtection,
                shadowEndpointProtection,
                shadowFalloffShape,
                shadowBodyBias,
                shadowPeakDamping
            );
            z += shadowsEV * shadowInfluence;

            float highlightInfluence = darkroomInfluence(
                z,
                highlightZoneStartEV,
                highlightZoneFullEV,
                highlightFalloff,
                highlightMidtoneProtection,
                highlightEndpointProtection,
                highlightFalloffShape,
                highlightBodyBias,
                highlightPeakDamping
            );
            z += highlightsEV * highlightInfluence;

            float blackInfluence = darkroomInfluence(
                z,
                blackZoneStartEV,
                blackZoneFullEV,
                blackSoftness,
                0.0,
                blackProtection,
                blackFalloffShape,
                blackBodyBias,
                blackPeakDamping
            );
            z += blacksEV * blackInfluence;

            float whiteInfluence = darkroomInfluence(
                z,
                whiteZoneStartEV,
                whiteZoneFullEV,
                whiteSoftness,
                0.0,
                whiteProtection,
                whiteFalloffShape,
                whiteBodyBias,
                whitePeakDamping
            );
            z += whitesEV * whiteInfluence;

            float centered = z - pivotEV;
            float scaledCenter = centered / max(contrastRolloffEV, 0.001);
            float contrastCurve = scaledCenter / (1.0 + abs(scaledCenter));
            z += contrastStrength * contrastMaxEV * contrastCurve;
            z = darkroomSoftClipZ(z, outputSoftClip);

            float targetLuma = max(middleGray, toneEpsilon) * pow(2.0, z);
            float ratio = targetLuma / safeLuma;
            color *= max(0.0, ratio);

            float finalLuma = max(dot(color, vec3(lumaRed, lumaGreen, lumaBlue)), toneEpsilon);
            float skinMask = darkroomSkinLikeMask(color, finalLuma);
            float gamutRisk = darkroomGamutRisk(color);
            float skinControl = darkroomCenteredControl(skinProtection, 0.25);
            float hueControl = darkroomCenteredControl(hueStability, 0.85);
            float toneChromaScale = 1.0
                + (darkroomToneChromaModeScale(toneChromaMode, z) - 1.0)
                    * darkroomColorChangeScale(
                        skinMask * max(skinControl, 0.0),
                        skinMask * max(-skinControl, 0.0),
                        gamutRisk * max(hueControl, 0.0),
                        gamutRisk * max(-hueControl, 0.0)
                    );
            color = max(vec3(0.0), vec3(finalLuma) + (color - vec3(finalLuma)) * toneChromaScale);
            finalLuma = max(dot(color, vec3(lumaRed, lumaGreen, lumaBlue)), toneEpsilon);

            float whiteClipRisk = smoothstep(0.92, 1.0, max(color.r, max(color.g, color.b)));
            float contrastWeight = darkroomContrastZoneWeight(z, contrastSaturationZone)
                * max(contrastSaturationMidtoneBias, 0.0);
            float highlightPull = max(-highlightsEV, 0.0) * highlightInfluence;
            float highlightLift = max(highlightsEV, 0.0) * highlightInfluence;
            float shadowLift = max(shadowsEV, 0.0) * shadowInfluence;
            float blackDensity = max(-blacksEV, 0.0) * blackInfluence;
            float highlightPullScale = darkroomRegionalPullDesaturationScale(highlightChromaMode);
            float highlightLiftScale = darkroomRegionalLiftDesaturationScale(highlightChromaMode);
            float shadowLiftScale = darkroomRegionalLiftDesaturationScale(shadowChromaMode);
            float highlightLiftDesat = max(highlightLiftDesaturation, 0.0)
                + darkroomRegionalLiftDesaturationFloor(highlightChromaMode)
                + max(highlightNearWhiteDesaturation, 0.0) * whiteInfluence * 0.5;
            float exposureSat = exposureEV * exposureChromaResponse
                * smoothstep(saturationMin, max(saturationMax, saturationMin + 0.001), finalLuma);
            float saturationDelta = contrastAffectsSaturation
                * (contrastSaturationAmount + colorContrastSaturationAmount)
                * abs(contrastStrength * contrastCurve)
                * contrastWeight
                + exposureSat
                - highlightPull * (highlightPullDesaturation + colorHighlightPullDesaturation) * highlightPullScale
                - highlightPull * whiteInfluence * (highlightNearWhiteDesaturation + colorHighlightNearWhiteDesaturation) * highlightPullScale
                - highlightLift * highlightLiftDesat * highlightLiftScale
                - shadowLift * (shadowLiftDesaturation + colorShadowLiftDesaturation) * shadowLiftScale
                + blackDensity * (blackDensitySaturationCoupling + colorBlackDensitySaturation)
                - whiteClipRisk * whiteInfluence * abs(whitesEV) * (whiteDesaturationNearClip + colorWhiteClipDesaturation);
            saturationDelta *= clamp(globalChromaPreservation, 0.0, 1.5);

            float minSaturation = clamp(min(saturationMin, exposureSaturationMin), 0.0, 2.0);
            float maxSaturation = clamp(max(saturationMax, exposureSaturationMax), minSaturation + 0.001, 3.0);
            float highlightActivity = clamp(highlightPull + highlightLift, 0.0, 1.0);
            float highlightSaturationCeiling = clamp(max(highlightSaturationClamp, minSaturation + 0.001), 0.001, 3.0);
            float effectiveMaxSaturation = mix(maxSaturation, min(maxSaturation, highlightSaturationCeiling), highlightActivity);
            float saturationMultiplier = clamp(
                darkroomChromaPreservationScale(globalChromaPreservation) + saturationDelta,
                minSaturation,
                effectiveMaxSaturation
            );
            float chroma = length(color - vec3(finalLuma));
            float neutralMask = 1.0 - smoothstep(
                0.0,
                max(overlayNeutralDriftThreshold * 4.0, 0.001),
                chroma
            );
            float chromaRatio = chroma / max(finalLuma, 0.02);
            float hueRisk = max(gamutRisk, smoothstep(0.65, 2.0, chromaRatio) * 0.4);
            float shadowNoiseControl = darkroomCenteredControl(
                (shadowNoiseChromaProtection + colorShadowNoiseChromaProtection) * 0.5,
                0.35
            );
            float highlightHueControl = darkroomCenteredControl(highlightHueProtection, 0.8);
            float shadowHueControl = darkroomCenteredControl(shadowHueProtection, 0.8);
            float contrastHueControl = darkroomCenteredControl(contrastHueProtection, 0.8);
            float whiteChromaControl = darkroomCenteredControl(
                (whiteChromaProtection + colorWhiteChromaProtection) * 0.5,
                0.35
            );
            float blackChromaControl = darkroomCenteredControl(
                (blackChromaProtection + colorBlackChromaProtection) * 0.5,
                0.45
            );
            float shadowNoiseMask = (1.0 - smoothstep(0.02, 0.2, finalLuma)) * shadowInfluence;
            float contrastActivity = clamp(abs(contrastStrength * contrastCurve), 0.0, 1.0);
            float positiveProtection = max(
                max(
                    max(neutralMask * clamp(neutralProtection, 0.0, 1.0), skinMask * max(skinControl, 0.0)),
                    max(hueRisk * max(hueControl, 0.0), shadowNoiseMask * max(shadowNoiseControl, 0.0))
                ),
                max(
                    max(highlightInfluence * hueRisk * max(highlightHueControl, 0.0), shadowInfluence * hueRisk * max(shadowHueControl, 0.0)),
                    max(
                        max(contrastActivity * hueRisk * max(contrastHueControl, 0.0), whiteInfluence * (0.35 + whiteClipRisk * 0.65) * max(whiteChromaControl, 0.0)),
                        blackInfluence * max(blackChromaControl, 0.0)
                    )
                )
            );
            positiveProtection = clamp(positiveProtection, 0.0, 0.95);
            float negativeFreedom = max(
                max(
                    max(skinMask * max(-skinControl, 0.0), hueRisk * max(-hueControl, 0.0)),
                    max(shadowNoiseMask * max(-shadowNoiseControl, 0.0), highlightInfluence * hueRisk * max(-highlightHueControl, 0.0))
                ),
                max(
                    max(shadowInfluence * hueRisk * max(-shadowHueControl, 0.0), contrastActivity * hueRisk * max(-contrastHueControl, 0.0)),
                    max(whiteInfluence * (0.35 + whiteClipRisk * 0.65) * max(-whiteChromaControl, 0.0), blackInfluence * max(-blackChromaControl, 0.0))
                )
            );
            negativeFreedom = clamp(negativeFreedom, 0.0, 1.0);
            float saturationChangeScale = clamp(1.0 - positiveProtection + negativeFreedom * 0.45, 0.0, 1.6);
            float protectedMultiplier = 1.0 + (saturationMultiplier - 1.0) * saturationChangeScale;
            color = max(vec3(0.0), vec3(finalLuma) + (color - vec3(finalLuma)) * protectedMultiplier);
            float postLuma = max(dot(color, vec3(lumaRed, lumaGreen, lumaBlue)), toneEpsilon);
            float compression = clamp(gamutCompressionAmount, 0.0, 1.0) * darkroomGamutRisk(color) * 0.85;
            color = max(vec3(0.0), vec3(postLuma) + (color - vec3(postLuma)) * (1.0 - compression));

            float overlayInfluence = 0.0;
            if (overlayMode > 0.5 && overlayMode < 1.5) {
                overlayInfluence = highlightInfluence;
            } else if (overlayMode > 1.5 && overlayMode < 2.5) {
                overlayInfluence = shadowInfluence;
            } else if (overlayMode > 2.5 && overlayMode < 3.5) {
                overlayInfluence = whiteInfluence;
            } else if (overlayMode > 3.5 && overlayMode < 4.5) {
                overlayInfluence = blackInfluence;
            } else if (overlayMode > 4.5 && overlayMode < 5.5) {
                float exposureStops = abs(log2(max(exposureGain, toneEpsilon)));
                overlayInfluence = clamp(exposureStops / 5.0, 0.0, 1.0)
                    * smoothstep(toneEpsilon, max(middleGray, toneEpsilon), safeLuma);
            } else if (overlayMode > 5.5 && overlayMode < 6.5) {
                overlayInfluence = clamp(abs(contrastStrength * contrastCurve), 0.0, 1.0);
            } else if (overlayMode > 6.5 && overlayMode < 7.5) {
                overlayInfluence = clamp(abs(saturationDelta) * overlaySaturationScale, 0.0, 1.0);
            } else if (overlayMode > 7.5 && overlayMode < 8.5) {
                overlayInfluence = max(
                    max(blackChromaProtection * blackInfluence, whiteChromaProtection * whiteInfluence),
                    max(shadowNoiseChromaProtection * shadowInfluence, highlightHueProtection * highlightInfluence)
                );
                overlayInfluence = max(overlayInfluence, max(positiveProtection, compression));
            } else if (overlayMode > 8.5 && overlayMode < 9.5) {
                float highClip = smoothstep(0.92, 1.0, max(color.r, max(color.g, color.b)));
                float lowClip = 1.0 - smoothstep(0.0, 0.04, min(color.r, min(color.g, color.b)));
                overlayInfluence = max(highClip, lowClip);
            } else if (overlayMode > 9.5 && overlayMode < 10.5) {
                overlayInfluence = smoothstep(
                    max(overlayNeutralDriftThreshold, 0.001),
                    max(overlayNeutralDriftThreshold * 6.0, 0.006),
                    chroma
                );
            }

            color = mix(color, vec3(1.0), clamp(overlayInfluence * overlayInfluenceOpacity, 0.0, overlayInfluenceOpacity));

            return vec4(color, pixel.a);
        }
        """
    )
}
