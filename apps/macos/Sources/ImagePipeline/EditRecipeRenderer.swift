import CoreImage
import Foundation

enum EditRecipeRenderer {
    static func apply(_ recipe: EditRecipe, to image: CIImage) throws -> CIImage {
        guard !recipe.isNeutral else {
            return image
        }

        guard let kernel = lightKernel else {
            throw ImagePipelineRenderError.unableToCreateEditKernel
        }

        let light = recipe.light
        let arguments: [Any] = [
            image,
            light.exposureGain,
            light.contrastExponent,
            LightAdjustments.contrastPivot,
            light.normalizedHighlights,
            light.normalizedShadows,
            light.shadowLiftLimit,
            light.shadowDropLimit,
            light.highlightPullLimit,
            light.highlightBoostLimit,
            light.shadowMaskStart,
            light.shadowMaskEnd,
            light.shadowBlackAnchorEnd,
            light.highlightMaskStart,
            light.highlightMaskEnd
        ]

        guard let editedImage = kernel.apply(extent: image.extent, arguments: arguments) else {
            throw ImagePipelineRenderError.unableToApplyEditRecipe
        }

        return editedImage
    }

    private static let lightKernel = CIColorKernel(source:
        """
        kernel vec4 darkroom_light(
            __sample pixel,
            float exposureGain,
            float contrastExponent,
            float pivot,
            float highlights,
            float shadows,
            float shadowLiftLimit,
            float shadowDropLimit,
            float highlightPullLimit,
            float highlightBoostLimit,
            float shadowMaskStart,
            float shadowMaskEnd,
            float shadowBlackAnchorEnd,
            float highlightMaskStart,
            float highlightMaskEnd
        ) {
            vec3 color = pixel.rgb * exposureGain;

            color = pivot * pow(max(color / pivot, vec3(0.0)), vec3(contrastExponent));

            float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
            float shadowMask = 1.0 - smoothstep(shadowMaskStart, shadowMaskEnd, luma);
            float shadowLiftMask = shadowMask * smoothstep(0.0, shadowBlackAnchorEnd, luma);
            float highlightMask = smoothstep(highlightMaskStart, highlightMaskEnd, luma);
            float targetLuma = luma;

            if (shadows >= 0.0) {
                float distanceToPivot = max(pivot - targetLuma, 0.0);
                targetLuma += distanceToPivot * shadows * shadowLiftLimit * shadowLiftMask;
            } else {
                float darken = -shadows * shadowDropLimit * shadowMask;
                targetLuma *= max(0.0, 1.0 - darken);
            }

            if (highlights >= 0.0) {
                targetLuma *= 1.0 + highlights * highlightBoostLimit * highlightMask;
            } else {
                float distanceFromPivot = max(targetLuma - pivot, 0.0);
                targetLuma -= distanceFromPivot * -highlights * highlightPullLimit * highlightMask;
            }

            float ratio = targetLuma / max(luma, 0.000001);
            color *= max(0.0, ratio);

            return vec4(color, pixel.a);
        }
        """
    )
}
