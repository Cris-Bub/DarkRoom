import Foundation

struct BehaviorTuning: Codable, Equatable, Hashable, Sendable {
    var schemaVersion: Int
    var name: String
    var createdAt: String
    var notes: String
    var workingSpace: String
    var rawBaseline: String
    var toneTuning: ToneTuning
    var exposureFeelTuning: ExposureFeelTuning
    var colorCouplingTuning: ColorCouplingTuning
    var sliderMappings: SliderMappingsTuning
    var viewTransformTuning: ViewTransformTuning
    var overlayTuning: OverlayTuning

    static let defaultV2 = BehaviorTuning(
        schemaVersion: 2,
        name: "DarkRoom Tone Lab V2 Current",
        createdAt: "unsaved",
        notes: "",
        workingSpace: "linear ROMM RGB",
        rawBaseline: "current DarkRoom V1 raster/RAW baseline",
        toneTuning: .defaultV1,
        exposureFeelTuning: .defaultV2,
        colorCouplingTuning: .defaultV2,
        sliderMappings: .defaultV1,
        viewTransformTuning: .defaultV2,
        overlayTuning: .defaultV2
    )

    static let suggestedCandidate01 = BehaviorTuning(
        schemaVersion: 2,
        name: "DarkRoom Tone Lab V2 Candidate 01",
        createdAt: "unsaved",
        notes: "Suggested starting point from the Tone Lab V2 spec.",
        workingSpace: "linear ROMM RGB",
        rawBaseline: "current DarkRoom V1 raster/RAW baseline",
        toneTuning: .suggestedCandidate01,
        exposureFeelTuning: .suggestedCandidate01,
        colorCouplingTuning: .suggestedCandidate01,
        sliderMappings: .suggestedCandidate01,
        viewTransformTuning: .defaultV2,
        overlayTuning: .defaultV2
    )

    var rendererToneTuning: ToneTuning {
        var tuning = toneTuning
        tuning.sliderMappings = sliderMappings
        return tuning
    }

    var flatParameters: [Float] {
        rendererToneTuning.flatParameters
            + exposureFeelTuning.flatParameters
            + colorCouplingTuning.flatParameters
            + viewTransformTuning.flatParameters
            + overlayTuning.flatParameters
    }

    init(
        schemaVersion: Int,
        name: String,
        createdAt: String,
        notes: String,
        workingSpace: String,
        rawBaseline: String,
        toneTuning: ToneTuning,
        exposureFeelTuning: ExposureFeelTuning,
        colorCouplingTuning: ColorCouplingTuning,
        sliderMappings: SliderMappingsTuning,
        viewTransformTuning: ViewTransformTuning,
        overlayTuning: OverlayTuning
    ) {
        self.schemaVersion = schemaVersion
        self.name = name
        self.createdAt = createdAt
        self.notes = notes
        self.workingSpace = workingSpace
        self.rawBaseline = rawBaseline
        self.toneTuning = toneTuning
        self.exposureFeelTuning = exposureFeelTuning
        self.colorCouplingTuning = colorCouplingTuning
        self.sliderMappings = sliderMappings
        self.viewTransformTuning = viewTransformTuning
        self.overlayTuning = overlayTuning
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = Self.defaultV2
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? fallback.schemaVersion
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? fallback.name
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt) ?? fallback.createdAt
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? fallback.notes
        workingSpace = try container.decodeIfPresent(String.self, forKey: .workingSpace) ?? fallback.workingSpace
        rawBaseline = try container.decodeIfPresent(String.self, forKey: .rawBaseline) ?? fallback.rawBaseline
        toneTuning = try container.decodeIfPresent(ToneTuning.self, forKey: .toneTuning) ?? fallback.toneTuning
        exposureFeelTuning = try container.decodeIfPresent(ExposureFeelTuning.self, forKey: .exposureFeelTuning) ?? fallback.exposureFeelTuning
        colorCouplingTuning = try container.decodeIfPresent(ColorCouplingTuning.self, forKey: .colorCouplingTuning) ?? fallback.colorCouplingTuning
        sliderMappings = try container.decodeIfPresent(SliderMappingsTuning.self, forKey: .sliderMappings) ?? fallback.sliderMappings
        viewTransformTuning = try container.decodeIfPresent(ViewTransformTuning.self, forKey: .viewTransformTuning) ?? fallback.viewTransformTuning
        overlayTuning = try container.decodeIfPresent(OverlayTuning.self, forKey: .overlayTuning) ?? fallback.overlayTuning
    }

    var prettyPrintedJSON: String {
        var candidate = self
        candidate.createdAt = ISO8601DateFormatter().string(from: Date())

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(candidate),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }

        return json
    }
}

struct ExposureFeelTuning: Codable, Equatable, Hashable, Sendable {
    var evGainScale: Double
    var responseExponent: Double
    var blackParticipation: Double
    var toeFollowAmount: Double
    var shadowVisibilityPerEV: Double
    var highlightProtectionPerEV: Double
    var exposureChromaResponse: Double
    var saturationMin: Double
    var saturationMax: Double

    static let defaultV2 = ExposureFeelTuning(
        evGainScale: 1.0,
        responseExponent: 1.0,
        blackParticipation: 0.35,
        toeFollowAmount: 0.25,
        shadowVisibilityPerEV: 0.2,
        highlightProtectionPerEV: 0.15,
        exposureChromaResponse: 0.0,
        saturationMin: 0.92,
        saturationMax: 1.08
    )

    static let suggestedCandidate01 = defaultV2

    var flatParameters: [Float] {
        [
            Float(evGainScale),
            Float(responseExponent),
            Float(blackParticipation),
            Float(toeFollowAmount),
            Float(shadowVisibilityPerEV),
            Float(highlightProtectionPerEV),
            Float(exposureChromaResponse),
            Float(saturationMin),
            Float(saturationMax),
        ]
    }
}

struct ColorCouplingTuning: Codable, Equatable, Hashable, Sendable {
    var toneChromaMode: ToneChromaMode
    var globalChromaPreservation: Double
    var saturationMin: Double
    var saturationMax: Double
    var neutralProtection: Double
    var skinProtection: Double
    var hueStability: Double
    var gamutCompressionAmount: Double
    var contrastSaturationAmount: Double
    var contrastSaturationMidtoneBias: Double
    var highlightPullDesaturation: Double
    var highlightNearWhiteDesaturation: Double
    var shadowLiftDesaturation: Double
    var shadowNoiseChromaProtection: Double
    var blackDensitySaturation: Double
    var blackChromaProtection: Double
    var whiteClipDesaturation: Double
    var whiteChromaProtection: Double

    static let defaultV2 = ColorCouplingTuning(
        toneChromaMode: .rgbRatioPreserve,
        globalChromaPreservation: 0.9,
        saturationMin: 0.8,
        saturationMax: 1.15,
        neutralProtection: 1.0,
        skinProtection: 0.25,
        hueStability: 0.85,
        gamutCompressionAmount: 0.0,
        contrastSaturationAmount: 0.08,
        contrastSaturationMidtoneBias: 1.0,
        highlightPullDesaturation: 0.16,
        highlightNearWhiteDesaturation: 0.12,
        shadowLiftDesaturation: 0.12,
        shadowNoiseChromaProtection: 0.35,
        blackDensitySaturation: 0.04,
        blackChromaProtection: 0.45,
        whiteClipDesaturation: 0.1,
        whiteChromaProtection: 0.35
    )

    static let suggestedCandidate01 = defaultV2

    var flatParameters: [Float] {
        [
            Float(toneChromaMode.kernelValue),
            Float(globalChromaPreservation),
            Float(saturationMin),
            Float(saturationMax),
            Float(neutralProtection),
            Float(skinProtection),
            Float(hueStability),
            Float(gamutCompressionAmount),
            Float(contrastSaturationAmount),
            Float(contrastSaturationMidtoneBias),
            Float(highlightPullDesaturation),
            Float(highlightNearWhiteDesaturation),
            Float(shadowLiftDesaturation),
            Float(shadowNoiseChromaProtection),
            Float(blackDensitySaturation),
            Float(blackChromaProtection),
            Float(whiteClipDesaturation),
            Float(whiteChromaProtection),
        ]
    }
}

struct ViewTransformTuning: Codable, Equatable, Hashable, Sendable {
    var displayMiddleGray: Double
    var outputSoftClip: Double

    static let defaultV2 = ViewTransformTuning(
        displayMiddleGray: 0.44,
        outputSoftClip: 0.0
    )

    var flatParameters: [Float] {
        [
            Float(displayMiddleGray),
            Float(outputSoftClip),
        ]
    }
}

struct OverlayTuning: Codable, Equatable, Hashable, Sendable {
    var influenceOpacity: Double
    var saturationOverlayScale: Double
    var neutralDriftThreshold: Double

    static let defaultV2 = OverlayTuning(
        influenceOpacity: 0.55,
        saturationOverlayScale: 1.0,
        neutralDriftThreshold: 0.02
    )

    var flatParameters: [Float] {
        [
            Float(influenceOpacity),
            Float(saturationOverlayScale),
            Float(neutralDriftThreshold),
        ]
    }
}

enum ToneChromaMode: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case rgbRatioPreserve
    case luminancePreserve
    case perChannelRGB
    case hybrid

    var id: String { rawValue }

    var label: String {
        switch self {
        case .rgbRatioPreserve:
            "RGB Ratio Preserve"
        case .luminancePreserve:
            "Luminance Preserve"
        case .perChannelRGB:
            "Per-Channel RGB"
        case .hybrid:
            "Hybrid"
        }
    }
}

private extension ToneChromaMode {
    var kernelValue: Double {
        switch self {
        case .rgbRatioPreserve:
            0
        case .luminancePreserve:
            1
        case .perChannelRGB:
            2
        case .hybrid:
            3
        }
    }
}
