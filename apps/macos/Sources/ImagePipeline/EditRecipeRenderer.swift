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

        let arguments: [Any] = [image] + recipe.light.kernelParameters.map { Double($0) }

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
            float endpointMaxEV
        ) {
            vec3 color = max(pixel.rgb * exposureGain, vec3(0.0));
            float luma = dot(color, vec3(lumaRed, lumaGreen, lumaBlue));
            float safeLuma = max(luma, toneEpsilon);
            float z = log2(safeLuma / max(middleGray, toneEpsilon));

            z += shadowsEV * smoothstep(shadowZoneStartEV, shadowZoneFullEV, -z);
            z += highlightsEV * smoothstep(highlightZoneStartEV, highlightZoneFullEV, z);
            z += blacksEV * smoothstep(blackZoneStartEV, blackZoneFullEV, -z);
            z += whitesEV * smoothstep(whiteZoneStartEV, whiteZoneFullEV, z);

            float centered = z - pivotEV;
            float scaledCenter = centered / max(contrastRolloffEV, 0.001);
            float contrastCurve = scaledCenter / (1.0 + abs(scaledCenter));
            z += contrastStrength * contrastMaxEV * contrastCurve;

            float targetLuma = max(middleGray, toneEpsilon) * pow(2.0, z);
            float ratio = targetLuma / safeLuma;
            color *= max(0.0, ratio);

            return vec4(color, pixel.a);
        }
        """
    )
}
