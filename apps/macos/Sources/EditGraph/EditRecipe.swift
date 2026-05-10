import Foundation

struct EditRecipe: Codable, Equatable, Hashable, Sendable {
    var light = LightAdjustments()

    static let neutral = EditRecipe()

    var isNeutral: Bool {
        self == .neutral
    }
}

struct LightAdjustments: Codable, Equatable, Hashable, Sendable {
    static let curveModel = "darkroom_tonal_curve_v1"

    var exposureEV = 0.0
    var contrast = 0.0
    var pivotEV = 0.0
    var highlights = 0.0
    var shadows = 0.0
    var whites = 0.0
    var blacks = 0.0

    static let exposureRange = -5.0...5.0
    static let contrastRange = -100.0...100.0
    static let pivotRange = -2.0...2.0
    static let highlightsRange = -100.0...100.0
    static let shadowsRange = -100.0...100.0
    static let whitesRange = -100.0...100.0
    static let blacksRange = -100.0...100.0

    var exposureGain: Double {
        DarkroomCoreLightMath.exposureGain(exposureEV: exposureEV)
    }

    var normalizedHighlights: Double {
        DarkroomCoreLightMath.normalizedSlider(highlights)
    }

    var normalizedShadows: Double {
        DarkroomCoreLightMath.normalizedSlider(shadows)
    }

    var normalizedWhites: Double {
        DarkroomCoreLightMath.normalizedSlider(whites)
    }

    var normalizedBlacks: Double {
        DarkroomCoreLightMath.normalizedSlider(blacks)
    }

    var kernelParameters: [Float] {
        DarkroomCoreLightMath.kernelParameters(for: self)
    }

    func kernelParameters(toneTuning: ToneTuning) -> [Float] {
        DarkroomCoreLightMath.kernelParameters(for: self, toneTuning: toneTuning)
    }
}
