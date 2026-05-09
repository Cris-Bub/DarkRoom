import Foundation

enum DarkroomCoreLightMath {
    static func exposureGain(exposureEV: Double) -> Double {
        Double(darkroomLightExposureGain(Float(exposureEV)))
    }

    static func contrastExponent(contrast: Double) -> Double {
        Double(darkroomLightContrastExponent(Float(contrast)))
    }

    static var contrastPivot: Double {
        Double(darkroomLightContrastPivot())
    }

    static func normalizedSlider(_ value: Double) -> Double {
        Double(darkroomLightNormalizedSlider(Float(value)))
    }

    static var shadowLiftLimit: Double {
        Double(darkroomLightShadowLiftLimit())
    }

    static var shadowDropLimit: Double {
        Double(darkroomLightShadowDropLimit())
    }

    static var highlightPullLimit: Double {
        Double(darkroomLightHighlightPullLimit())
    }

    static var highlightBoostLimit: Double {
        Double(darkroomLightHighlightBoostLimit())
    }

    static var shadowMaskStart: Double {
        Double(darkroomLightShadowMaskStart())
    }

    static var shadowMaskEnd: Double {
        Double(darkroomLightShadowMaskEnd())
    }

    static var shadowBlackAnchorEnd: Double {
        Double(darkroomLightShadowBlackAnchorEnd())
    }

    static var highlightMaskStart: Double {
        Double(darkroomLightHighlightMaskStart())
    }

    static var highlightMaskEnd: Double {
        Double(darkroomLightHighlightMaskEnd())
    }
}

@_silgen_name("darkroom_light_exposure_gain")
private func darkroomLightExposureGain(_ exposureEV: Float) -> Float

@_silgen_name("darkroom_light_contrast_exponent")
private func darkroomLightContrastExponent(_ contrast: Float) -> Float

@_silgen_name("darkroom_light_contrast_pivot")
private func darkroomLightContrastPivot() -> Float

@_silgen_name("darkroom_light_normalized_slider")
private func darkroomLightNormalizedSlider(_ value: Float) -> Float

@_silgen_name("darkroom_light_shadow_lift_limit")
private func darkroomLightShadowLiftLimit() -> Float

@_silgen_name("darkroom_light_shadow_drop_limit")
private func darkroomLightShadowDropLimit() -> Float

@_silgen_name("darkroom_light_highlight_pull_limit")
private func darkroomLightHighlightPullLimit() -> Float

@_silgen_name("darkroom_light_highlight_boost_limit")
private func darkroomLightHighlightBoostLimit() -> Float

@_silgen_name("darkroom_light_shadow_mask_start")
private func darkroomLightShadowMaskStart() -> Float

@_silgen_name("darkroom_light_shadow_mask_end")
private func darkroomLightShadowMaskEnd() -> Float

@_silgen_name("darkroom_light_shadow_black_anchor_end")
private func darkroomLightShadowBlackAnchorEnd() -> Float

@_silgen_name("darkroom_light_highlight_mask_start")
private func darkroomLightHighlightMaskStart() -> Float

@_silgen_name("darkroom_light_highlight_mask_end")
private func darkroomLightHighlightMaskEnd() -> Float
