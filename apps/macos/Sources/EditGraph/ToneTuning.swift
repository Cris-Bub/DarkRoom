import Foundation

struct ToneTuning: Codable, Equatable, Hashable, Sendable {
    var version: String
    var global: GlobalToneTuning
    var contrast: ContrastTuning
    var highlights: RangeToneTuning
    var shadows: RangeToneTuning
    var whites: EndpointToneTuning
    var blacks: EndpointToneTuning
    var sliderMapping: SliderMappingTuning

    static let defaultV1 = ToneTuning(
        version: "darkroom_tonal_curve_v1_current",
        global: GlobalToneTuning(
            middleGray: 0.18,
            baseContrast: 1.0,
            toeStrength: 0.0,
            toeLengthEV: 2.5,
            shoulderStrength: 0.0,
            shoulderLengthEV: 3.0,
            outputSoftClip: 0.0
        ),
        contrast: ContrastTuning(
            maxSlopeBoost: 1.35,
            maxSlopeReduction: 1.35,
            pivotMinEV: -2.0,
            pivotMaxEV: 2.0,
            contrastSoftness: 2.0
        ),
        highlights: RangeToneTuning(
            startEV: 0.5,
            fullEV: 4.0,
            maxLiftEV: 1.8,
            maxPullEV: -1.8,
            falloff: 1.0,
            midtoneProtection: 0.0,
            endpointProtection: 0.0
        ),
        shadows: RangeToneTuning(
            startEV: -0.5,
            fullEV: -4.0,
            maxLiftEV: 1.8,
            maxPullEV: -1.8,
            falloff: 1.0,
            midtoneProtection: 0.0,
            endpointProtection: 0.0
        ),
        whites: EndpointToneTuning(
            startEV: 1.0,
            strength: 1.0,
            maxShiftEV: 2.0,
            softness: 2.0,
            protection: 0.0
        ),
        blacks: EndpointToneTuning(
            startEV: -1.0,
            strength: 1.0,
            maxShiftEV: 2.0,
            softness: 2.0,
            protection: 0.0
        ),
        sliderMapping: SliderMappingTuning(
            nearZeroSensitivity: 0.0,
            midSensitivity: 1.0,
            extremeTaper: 0.0,
            deadZone: 0.0
        )
    )

    static let suggestedCandidate01 = ToneTuning(
        version: "darkroom_tonal_curve_v1_candidate_01",
        global: GlobalToneTuning(
            middleGray: 0.18,
            baseContrast: 1.0,
            toeStrength: 0.35,
            toeLengthEV: 2.5,
            shoulderStrength: 0.45,
            shoulderLengthEV: 3.0,
            outputSoftClip: 0.6
        ),
        contrast: ContrastTuning(
            maxSlopeBoost: 1.75,
            maxSlopeReduction: 0.55,
            pivotMinEV: -2.0,
            pivotMaxEV: 2.0,
            contrastSoftness: 0.65
        ),
        highlights: RangeToneTuning(
            startEV: 0.55,
            fullEV: 2.4,
            maxLiftEV: 1.6,
            maxPullEV: -3.0,
            falloff: 0.75,
            midtoneProtection: 0.25,
            endpointProtection: 0.55
        ),
        shadows: RangeToneTuning(
            startEV: -0.45,
            fullEV: -2.7,
            maxLiftEV: 3.0,
            maxPullEV: -1.7,
            falloff: 0.75,
            midtoneProtection: 0.2,
            endpointProtection: 0.5
        ),
        whites: EndpointToneTuning(
            startEV: 2.0,
            strength: 1.0,
            maxShiftEV: 2.0,
            softness: 0.65,
            protection: 0.45
        ),
        blacks: EndpointToneTuning(
            startEV: -2.2,
            strength: 1.0,
            maxShiftEV: 2.0,
            softness: 0.7,
            protection: 0.4
        ),
        sliderMapping: SliderMappingTuning(
            nearZeroSensitivity: 0.65,
            midSensitivity: 1.0,
            extremeTaper: 0.35,
            deadZone: 0.0
        )
    )

    var flatParameters: [Float] {
        [
            Float(global.middleGray),
            Float(global.baseContrast),
            Float(global.toeStrength),
            Float(global.toeLengthEV),
            Float(global.shoulderStrength),
            Float(global.shoulderLengthEV),
            Float(global.outputSoftClip),
            Float(contrast.maxSlopeBoost),
            Float(contrast.maxSlopeReduction),
            Float(contrast.pivotMinEV),
            Float(contrast.pivotMaxEV),
            Float(contrast.contrastSoftness),
            Float(highlights.startEV),
            Float(highlights.fullEV),
            Float(highlights.maxLiftEV),
            Float(highlights.maxPullEV),
            Float(highlights.falloff),
            Float(highlights.midtoneProtection),
            Float(highlights.endpointProtection),
            Float(shadows.startEV),
            Float(shadows.fullEV),
            Float(shadows.maxLiftEV),
            Float(shadows.maxPullEV),
            Float(shadows.falloff),
            Float(shadows.midtoneProtection),
            Float(shadows.endpointProtection),
            Float(whites.startEV),
            Float(whites.strength),
            Float(whites.maxShiftEV),
            Float(whites.softness),
            Float(whites.protection),
            Float(blacks.startEV),
            Float(blacks.strength),
            Float(blacks.maxShiftEV),
            Float(blacks.softness),
            Float(blacks.protection),
            Float(sliderMapping.nearZeroSensitivity),
            Float(sliderMapping.midSensitivity),
            Float(sliderMapping.extremeTaper),
            Float(sliderMapping.deadZone)
        ]
    }

    var prettyPrintedJSON: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(self),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }

        return json
    }
}

struct GlobalToneTuning: Codable, Equatable, Hashable, Sendable {
    var middleGray: Double
    var baseContrast: Double
    var toeStrength: Double
    var toeLengthEV: Double
    var shoulderStrength: Double
    var shoulderLengthEV: Double
    var outputSoftClip: Double
}

struct ContrastTuning: Codable, Equatable, Hashable, Sendable {
    var maxSlopeBoost: Double
    var maxSlopeReduction: Double
    var pivotMinEV: Double
    var pivotMaxEV: Double
    var contrastSoftness: Double
}

struct RangeToneTuning: Codable, Equatable, Hashable, Sendable {
    var startEV: Double
    var fullEV: Double
    var maxLiftEV: Double
    var maxPullEV: Double
    var falloff: Double
    var midtoneProtection: Double
    var endpointProtection: Double
}

struct EndpointToneTuning: Codable, Equatable, Hashable, Sendable {
    var startEV: Double
    var strength: Double
    var maxShiftEV: Double
    var softness: Double
    var protection: Double
}

struct SliderMappingTuning: Codable, Equatable, Hashable, Sendable {
    var nearZeroSensitivity: Double
    var midSensitivity: Double
    var extremeTaper: Double
    var deadZone: Double
}

enum ToneRangeOverlay: String, CaseIterable, Identifiable, Sendable {
    case off
    case highlights
    case shadows
    case whites
    case blacks

    var id: String { rawValue }

    var label: String {
        switch self {
        case .off:
            "Overlay Off"
        case .highlights:
            "Highlights Mask"
        case .shadows:
            "Shadows Mask"
        case .whites:
            "Whites Mask"
        case .blacks:
            "Blacks Mask"
        }
    }

    var kernelMode: Double {
        switch self {
        case .off:
            0
        case .highlights:
            1
        case .shadows:
            2
        case .whites:
            3
        case .blacks:
            4
        }
    }
}
