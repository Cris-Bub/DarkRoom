import Foundation

struct EditRecipe: Codable, Equatable, Hashable, Sendable {
    var light = LightAdjustments()

    static let neutral = EditRecipe()

    var isNeutral: Bool {
        self == .neutral
    }
}

struct LightAdjustments: Codable, Equatable, Hashable, Sendable {
    var exposureEV = 0.0
    var contrast = 0.0
    var highlights = 0.0
    var shadows = 0.0

    static let exposureRange = -5.0...5.0
    static let contrastRange = -100.0...100.0
    static let highlightsRange = -100.0...100.0
    static let shadowsRange = -100.0...100.0

    static var contrastPivot: Double {
        DarkroomCoreLightMath.contrastPivot
    }

    var exposureGain: Double {
        DarkroomCoreLightMath.exposureGain(exposureEV: exposureEV)
    }

    var contrastExponent: Double {
        DarkroomCoreLightMath.contrastExponent(contrast: contrast)
    }

    var normalizedHighlights: Double {
        DarkroomCoreLightMath.normalizedSlider(highlights)
    }

    var normalizedShadows: Double {
        DarkroomCoreLightMath.normalizedSlider(shadows)
    }

    var shadowLiftLimit: Double {
        DarkroomCoreLightMath.shadowLiftLimit
    }

    var shadowDropLimit: Double {
        DarkroomCoreLightMath.shadowDropLimit
    }

    var highlightPullLimit: Double {
        DarkroomCoreLightMath.highlightPullLimit
    }

    var highlightBoostLimit: Double {
        DarkroomCoreLightMath.highlightBoostLimit
    }

    var shadowMaskStart: Double {
        DarkroomCoreLightMath.shadowMaskStart
    }

    var shadowMaskEnd: Double {
        DarkroomCoreLightMath.shadowMaskEnd
    }

    var shadowBlackAnchorEnd: Double {
        DarkroomCoreLightMath.shadowBlackAnchorEnd
    }

    var highlightMaskStart: Double {
        DarkroomCoreLightMath.highlightMaskStart
    }

    var highlightMaskEnd: Double {
        DarkroomCoreLightMath.highlightMaskEnd
    }
}
