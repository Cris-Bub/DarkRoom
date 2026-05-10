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
            float distanceEV,
            float startEV,
            float fullEV,
            float falloff,
            float midtoneProtection,
            float endpointProtection,
            float falloffShape
        ) {
            float distance = max(distanceEV, 0.0);
            float start = max(abs(startEV), 0.0);
            float full = max(abs(fullEV), start + 0.001);
            float linearBase = clamp((distance - start) / max(full - start, 0.001), 0.0, 1.0);
            float smoothBase = smoothstep(start, full, distance);
            float base = smoothBase;
            if (falloffShape >= 2.5) {
                base = pow(smoothBase, 1.75);
            } else if (falloffShape >= 1.5) {
                base = pow(smoothBase, 0.65);
            } else if (falloffShape >= 0.5) {
                base = linearBase;
            }
            float shaped = pow(base, 1.0 / clamp(falloff, 0.1, 4.0));
            float midtoneGuard = 1.0 - clamp(midtoneProtection, 0.0, 0.95)
                * (1.0 - smoothstep(0.0, max(start, 0.001), distance));
            float endpointGuard = 1.0 - clamp(endpointProtection, 0.0, 0.95)
                * smoothstep(full, full + 2.0, distance);

            return shaped * clamp(midtoneGuard, 0.05, 1.0) * clamp(endpointGuard, 0.05, 1.0);
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
            float shadowFalloffShape,
            float shadowLiftDesaturation,
            float shadowNoiseChromaProtection,
            float shadowHueProtection,
            float whiteFalloffShape,
            float whiteShoulderCoupling,
            float whiteChromaProtection,
            float whiteDesaturationNearClip,
            float blackFalloffShape,
            float blackToeCoupling,
            float blackChromaProtection,
            float blackDensitySaturationCoupling,
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
            z -= effectiveToeStrength * darkroomInfluence(-z, 0.0, toeLengthEV, 1.0, 0.0, 0.0, 0.0);
            z += max(exposureShadowLiftEV, 0.0) * darkroomInfluence(-z, 0.0, shadowZoneStartEV, 1.0, 0.0, 0.0, 0.0);
            float effectiveShoulderStrength = max(shoulderStrength, 0.0)
                + max(exposureEV, 0.0) * max(exposureHighlightProtectionPerEV, 0.0)
                + max(whiteShoulderCoupling, 0.0) * max(whitesEV, 0.0);
            z -= effectiveShoulderStrength * darkroomInfluence(z, 0.0, shoulderLengthEV, 1.0, 0.0, 0.0, 0.0);

            float shadowInfluence = darkroomInfluence(
                -z,
                shadowZoneStartEV,
                shadowZoneFullEV,
                shadowFalloff,
                shadowMidtoneProtection,
                shadowEndpointProtection,
                shadowFalloffShape
            );
            z += shadowsEV * shadowInfluence;

            float highlightInfluence = darkroomInfluence(
                z,
                highlightZoneStartEV,
                highlightZoneFullEV,
                highlightFalloff,
                highlightMidtoneProtection,
                highlightEndpointProtection,
                highlightFalloffShape
            );
            z += highlightsEV * highlightInfluence;

            float blackInfluence = darkroomInfluence(
                -z,
                blackZoneStartEV,
                blackZoneFullEV,
                blackSoftness,
                0.0,
                blackProtection,
                blackFalloffShape
            );
            z += blacksEV * blackInfluence;

            float whiteInfluence = darkroomInfluence(
                z,
                whiteZoneStartEV,
                whiteZoneFullEV,
                whiteSoftness,
                0.0,
                whiteProtection,
                whiteFalloffShape
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
            float whiteClipRisk = smoothstep(0.92, 1.0, max(color.r, max(color.g, color.b)));
            float contrastWeight = darkroomContrastZoneWeight(z, contrastSaturationZone)
                * max(contrastSaturationMidtoneBias, 0.0);
            float highlightPull = max(-highlightsEV, 0.0) * highlightInfluence;
            float shadowLift = max(shadowsEV, 0.0) * shadowInfluence;
            float blackDensity = max(-blacksEV, 0.0) * blackInfluence;
            float exposureSat = exposureEV * exposureChromaResponse
                * smoothstep(saturationMin, max(saturationMax, saturationMin + 0.001), finalLuma);
            float saturationDelta = contrastAffectsSaturation
                * (contrastSaturationAmount + colorContrastSaturationAmount)
                * abs(contrastStrength * contrastCurve)
                * contrastWeight
                + exposureSat
                - highlightPull * (highlightPullDesaturation + colorHighlightPullDesaturation)
                - highlightPull * whiteInfluence * (highlightNearWhiteDesaturation + colorHighlightNearWhiteDesaturation)
                - shadowLift * (shadowLiftDesaturation + colorShadowLiftDesaturation)
                + blackDensity * (blackDensitySaturationCoupling + colorBlackDensitySaturation)
                - whiteClipRisk * whiteInfluence * abs(whitesEV) * (whiteDesaturationNearClip + colorWhiteClipDesaturation);
            saturationDelta *= clamp(globalChromaPreservation, 0.0, 1.5);

            float minSaturation = clamp(min(saturationMin, exposureSaturationMin), 0.0, 2.0);
            float maxSaturation = clamp(max(saturationMax, exposureSaturationMax), minSaturation + 0.001, 3.0);
            float saturationMultiplier = clamp(1.0 + saturationDelta, minSaturation, maxSaturation);
            float chroma = length(color - vec3(finalLuma));
            float neutralMask = 1.0 - smoothstep(
                0.0,
                max(overlayNeutralDriftThreshold * 4.0, 0.001),
                chroma
            );
            float protectedMultiplier = 1.0 + (saturationMultiplier - 1.0)
                * (1.0 - neutralMask * clamp(neutralProtection, 0.0, 1.0));
            color = max(vec3(0.0), vec3(finalLuma) + (color - vec3(finalLuma)) * protectedMultiplier);

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
