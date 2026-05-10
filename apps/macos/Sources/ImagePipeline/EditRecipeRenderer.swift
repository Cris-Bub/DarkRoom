import CoreImage
import Foundation

enum EditRecipeRenderer {
    static func apply(
        _ recipe: EditRecipe,
        to image: CIImage,
        toneTuning: ToneTuning = .defaultV1,
        overlay: ToneRangeOverlay = .off
    ) throws -> CIImage {
        guard !recipe.isNeutral || toneTuning != .defaultV1 || overlay != .off else {
            return image
        }

        guard let kernel = lightKernel else {
            throw ImagePipelineRenderError.unableToCreateEditKernel
        }

        let arguments: [Any] = [image]
            + recipe.light.kernelParameters(toneTuning: toneTuning).map { Double($0) }
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
            float endpointProtection
        ) {
            float distance = max(distanceEV, 0.0);
            float start = max(abs(startEV), 0.0);
            float full = max(abs(fullEV), start + 0.001);
            float base = smoothstep(start, full, distance);
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
            float overlayMode
        ) {
            vec3 color = max(pixel.rgb * exposureGain, vec3(0.0));
            float luma = dot(color, vec3(lumaRed, lumaGreen, lumaBlue));
            float safeLuma = max(luma, toneEpsilon);
            float z = log2(safeLuma / max(middleGray, toneEpsilon)) * max(baseContrast, 0.001);

            z -= max(toeStrength, 0.0) * darkroomInfluence(-z, 0.0, toeLengthEV, 1.0, 0.0, 0.0);
            z -= max(shoulderStrength, 0.0) * darkroomInfluence(z, 0.0, shoulderLengthEV, 1.0, 0.0, 0.0);

            float shadowInfluence = darkroomInfluence(
                -z,
                shadowZoneStartEV,
                shadowZoneFullEV,
                shadowFalloff,
                shadowMidtoneProtection,
                shadowEndpointProtection
            );
            z += shadowsEV * shadowInfluence;

            float highlightInfluence = darkroomInfluence(
                z,
                highlightZoneStartEV,
                highlightZoneFullEV,
                highlightFalloff,
                highlightMidtoneProtection,
                highlightEndpointProtection
            );
            z += highlightsEV * highlightInfluence;

            float blackInfluence = darkroomInfluence(
                -z,
                blackZoneStartEV,
                blackZoneFullEV,
                1.0,
                0.0,
                blackProtection
            );
            z += blacksEV * blackInfluence;

            float whiteInfluence = darkroomInfluence(
                z,
                whiteZoneStartEV,
                whiteZoneFullEV,
                1.0,
                0.0,
                whiteProtection
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

            float overlayInfluence = 0.0;
            if (overlayMode > 0.5 && overlayMode < 1.5) {
                overlayInfluence = highlightInfluence;
            } else if (overlayMode > 1.5 && overlayMode < 2.5) {
                overlayInfluence = shadowInfluence;
            } else if (overlayMode > 2.5 && overlayMode < 3.5) {
                overlayInfluence = whiteInfluence;
            } else if (overlayMode > 3.5 && overlayMode < 4.5) {
                overlayInfluence = blackInfluence;
            }

            color = mix(color, vec3(1.0), clamp(overlayInfluence * 0.55, 0.0, 0.55));

            return vec4(color, pixel.a);
        }
        """
    )
}
