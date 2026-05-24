import Foundation

struct ToneTuning: Codable, Equatable, Hashable, Sendable {
    var version: String
    var global: GlobalToneTuning
    var contrast: ContrastTuning
    var highlights: RangeToneTuning
    var shadows: RangeToneTuning
    var whites: EndpointToneTuning
    var blacks: EndpointToneTuning
    var sliderMappings: SliderMappingsTuning

    static let defaultV1 = ToneTuning(
        version: "darkroom_tonal_curve_v1_current",
        global: GlobalToneTuning(
            middleGray: 0.18,
            baseContrast: 1.0,
            toeStrength: 0.0,
            toeLengthEV: 2.5,
            shoulderStrength: 0.0,
            shoulderLengthEV: 3.0,
            outputSoftClip: 0.0,
            sceneBlackEV: -7.0,
            sceneWhiteEV: 4.0,
            displayMiddleGray: 0.44,
            toeLift: 0.0,
            shoulderRollStrength: 0.0
        ),
        contrast: ContrastTuning(
            maxSlopeBoost: 1.35,
            maxSlopeReduction: 1.35,
            pivotMinEV: -2.0,
            pivotMaxEV: 2.0,
            contrastSoftness: 2.0,
            mode: .rgbRatioPreserve,
            affectsSaturation: true,
            saturationAmount: 0.08,
            saturationZone: .midtones,
            hueProtection: 0.8,
            neutralProtection: 1.0
        ),
        highlights: RangeToneTuning(
            startEV: 0.5,
            fullEV: 4.0,
            maxLiftEV: 1.8,
            maxPullEV: -1.8,
            falloff: 1.0,
            midtoneProtection: 0.0,
            endpointProtection: 0.0,
            falloffShape: .smooth,
            chromaMode: .preserveHue,
            pullDesaturation: 0.16,
            nearEndpointDesaturation: 0.12,
            saturationClamp: 1.15,
            liftDesaturation: 0.0,
            noiseChromaProtection: 0.0,
            hueProtection: 0.8,
            bodyBias: 0.0,
            peakDamping: 0.0
        ),
        shadows: RangeToneTuning(
            startEV: -0.5,
            fullEV: -4.0,
            maxLiftEV: 1.8,
            maxPullEV: -1.8,
            falloff: 1.0,
            midtoneProtection: 0.0,
            endpointProtection: 0.0,
            falloffShape: .smooth,
            chromaMode: .preserveHue,
            pullDesaturation: 0.0,
            nearEndpointDesaturation: 0.0,
            saturationClamp: 1.15,
            liftDesaturation: 0.12,
            noiseChromaProtection: 0.35,
            hueProtection: 0.8,
            bodyBias: 0.0,
            peakDamping: 0.0
        ),
        whites: EndpointToneTuning(
            startEV: 1.0,
            fullEV: 5.0,
            strength: 1.0,
            maxShiftEV: 2.0,
            softness: 2.0,
            protection: 0.0,
            falloffShape: .smooth,
            shoulderCoupling: 0.5,
            toeCoupling: 0.0,
            chromaProtection: 0.35,
            desaturationNearClip: 0.1,
            densitySaturationCoupling: 0.0,
            bodyBias: 0.0,
            peakDamping: 0.0
        ),
        blacks: EndpointToneTuning(
            startEV: -1.0,
            fullEV: -5.0,
            strength: 1.0,
            maxShiftEV: 2.0,
            softness: 2.0,
            protection: 0.0,
            falloffShape: .smooth,
            shoulderCoupling: 0.0,
            toeCoupling: 0.6,
            chromaProtection: 0.45,
            desaturationNearClip: 0.0,
            densitySaturationCoupling: 0.04,
            bodyBias: 0.0,
            peakDamping: 0.0
        ),
        sliderMappings: .defaultV1
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
            outputSoftClip: 0.6,
            sceneBlackEV: -7.0,
            sceneWhiteEV: 4.0,
            displayMiddleGray: 0.44,
            toeLift: 0.08,
            shoulderRollStrength: 0.35
        ),
        contrast: ContrastTuning(
            maxSlopeBoost: 1.75,
            maxSlopeReduction: 0.55,
            pivotMinEV: -2.0,
            pivotMaxEV: 2.0,
            contrastSoftness: 0.65,
            mode: .hybrid,
            affectsSaturation: true,
            saturationAmount: 0.08,
            saturationZone: .midtones,
            hueProtection: 0.8,
            neutralProtection: 1.0
        ),
        highlights: RangeToneTuning(
            startEV: -0.85,
            fullEV: 2.8,
            maxLiftEV: 1.6,
            maxPullEV: -3.0,
            falloff: 0.75,
            midtoneProtection: 0.25,
            endpointProtection: 0.55,
            falloffShape: .smooth,
            chromaMode: .desaturatePull,
            pullDesaturation: 0.16,
            nearEndpointDesaturation: 0.12,
            saturationClamp: 1.15,
            liftDesaturation: 0.0,
            noiseChromaProtection: 0.0,
            hueProtection: 0.8,
            bodyBias: 0.45,
            peakDamping: 0.25
        ),
        shadows: RangeToneTuning(
            startEV: 0.65,
            fullEV: -3.0,
            maxLiftEV: 3.0,
            maxPullEV: -1.7,
            falloff: 0.75,
            midtoneProtection: 0.2,
            endpointProtection: 0.5,
            falloffShape: .smooth,
            chromaMode: .protectChroma,
            pullDesaturation: 0.0,
            nearEndpointDesaturation: 0.0,
            saturationClamp: 1.15,
            liftDesaturation: 0.12,
            noiseChromaProtection: 0.35,
            hueProtection: 0.8,
            bodyBias: 0.35,
            peakDamping: 0.2
        ),
        whites: EndpointToneTuning(
            startEV: 2.0,
            fullEV: 3.3,
            strength: 1.0,
            maxShiftEV: 2.0,
            softness: 0.65,
            protection: 0.45,
            falloffShape: .smooth,
            shoulderCoupling: 0.5,
            toeCoupling: 0.0,
            chromaProtection: 0.35,
            desaturationNearClip: 0.1,
            densitySaturationCoupling: 0.0,
            bodyBias: 0.2,
            peakDamping: 0.35
        ),
        blacks: EndpointToneTuning(
            startEV: -2.2,
            fullEV: -3.6,
            strength: 1.0,
            maxShiftEV: 2.0,
            softness: 0.7,
            protection: 0.4,
            falloffShape: .smooth,
            shoulderCoupling: 0.0,
            toeCoupling: 0.6,
            chromaProtection: 0.45,
            desaturationNearClip: 0.0,
            densitySaturationCoupling: 0.04,
            bodyBias: 0.2,
            peakDamping: 0.25
        ),
        sliderMappings: .suggestedCandidate01
    )

    var flatParameters: [Float] {
        var parameters: [Float] = [
            Float(global.middleGray),
            Float(global.baseContrast),
            Float(global.toeStrength),
            Float(global.toeLengthEV),
            Float(global.shoulderStrength),
            Float(global.shoulderLengthEV),
            Float(global.outputSoftClip),
            Float(global.sceneBlackEV),
            Float(global.sceneWhiteEV),
            Float(global.displayMiddleGray),
            Float(global.toeLift),
            Float(global.shoulderRollStrength),
            Float(contrast.maxSlopeBoost),
            Float(contrast.maxSlopeReduction),
            Float(contrast.pivotMinEV),
            Float(contrast.pivotMaxEV),
            Float(contrast.contrastSoftness),
            Float(contrast.mode.kernelValue),
            contrast.affectsSaturation ? 1 : 0,
            Float(contrast.saturationAmount),
            Float(contrast.saturationZone.kernelValue),
            Float(contrast.hueProtection),
            Float(contrast.neutralProtection),
            Float(highlights.startEV),
            Float(highlights.fullEV),
            Float(highlights.maxLiftEV),
            Float(highlights.maxPullEV),
            Float(highlights.falloff),
            Float(highlights.midtoneProtection),
            Float(highlights.endpointProtection),
            Float(highlights.falloffShape.kernelValue),
            Float(highlights.chromaMode.kernelValue),
            Float(highlights.pullDesaturation),
            Float(highlights.nearEndpointDesaturation),
            Float(highlights.saturationClamp),
            Float(highlights.liftDesaturation),
            Float(highlights.noiseChromaProtection),
            Float(highlights.hueProtection),
            Float(highlights.bodyBias),
            Float(highlights.peakDamping),
            Float(shadows.startEV),
            Float(shadows.fullEV),
            Float(shadows.maxLiftEV),
            Float(shadows.maxPullEV),
            Float(shadows.falloff),
            Float(shadows.midtoneProtection),
            Float(shadows.endpointProtection),
            Float(shadows.falloffShape.kernelValue),
            Float(shadows.chromaMode.kernelValue),
            Float(shadows.pullDesaturation),
            Float(shadows.nearEndpointDesaturation),
            Float(shadows.saturationClamp),
            Float(shadows.liftDesaturation),
            Float(shadows.noiseChromaProtection),
            Float(shadows.hueProtection),
            Float(shadows.bodyBias),
            Float(shadows.peakDamping),
            Float(whites.startEV),
            Float(whites.fullEV),
            Float(whites.strength),
            Float(whites.maxShiftEV),
            Float(whites.softness),
            Float(whites.protection),
            Float(whites.falloffShape.kernelValue),
            Float(whites.shoulderCoupling),
            Float(whites.toeCoupling),
            Float(whites.chromaProtection),
            Float(whites.desaturationNearClip),
            Float(whites.densitySaturationCoupling),
            Float(whites.bodyBias),
            Float(whites.peakDamping),
            Float(blacks.startEV),
            Float(blacks.fullEV),
            Float(blacks.strength),
            Float(blacks.maxShiftEV),
            Float(blacks.softness),
            Float(blacks.protection),
            Float(blacks.falloffShape.kernelValue),
            Float(blacks.shoulderCoupling),
            Float(blacks.toeCoupling),
            Float(blacks.chromaProtection),
            Float(blacks.desaturationNearClip),
            Float(blacks.densitySaturationCoupling),
            Float(blacks.bodyBias),
            Float(blacks.peakDamping),
        ]
        parameters.append(contentsOf: sliderMappings.flatParameters)
        return parameters
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
    var sceneBlackEV: Double
    var sceneWhiteEV: Double
    var displayMiddleGray: Double
    var toeLift: Double
    var shoulderRollStrength: Double
}

struct ContrastTuning: Codable, Equatable, Hashable, Sendable {
    var maxSlopeBoost: Double
    var maxSlopeReduction: Double
    var pivotMinEV: Double
    var pivotMaxEV: Double
    var contrastSoftness: Double
    var mode: ContrastMode
    var affectsSaturation: Bool
    var saturationAmount: Double
    var saturationZone: ToneZoneBias
    var hueProtection: Double
    var neutralProtection: Double
}

struct RangeToneTuning: Codable, Equatable, Hashable, Sendable {
    var startEV: Double
    var fullEV: Double
    var maxLiftEV: Double
    var maxPullEV: Double
    var falloff: Double
    var midtoneProtection: Double
    var endpointProtection: Double
    var falloffShape: FalloffShape
    var chromaMode: RegionalChromaMode
    var pullDesaturation: Double
    var nearEndpointDesaturation: Double
    var saturationClamp: Double
    var liftDesaturation: Double
    var noiseChromaProtection: Double
    var hueProtection: Double

    var bodyBias: Double
    var peakDamping: Double

    init(
        startEV: Double,
        fullEV: Double,
        maxLiftEV: Double,
        maxPullEV: Double,
        falloff: Double,
        midtoneProtection: Double,
        endpointProtection: Double,
        falloffShape: FalloffShape,
        chromaMode: RegionalChromaMode,
        pullDesaturation: Double,
        nearEndpointDesaturation: Double,
        saturationClamp: Double,
        liftDesaturation: Double,
        noiseChromaProtection: Double,
        hueProtection: Double,
        bodyBias: Double,
        peakDamping: Double
    ) {
        self.startEV = startEV
        self.fullEV = fullEV
        self.maxLiftEV = maxLiftEV
        self.maxPullEV = maxPullEV
        self.falloff = falloff
        self.midtoneProtection = midtoneProtection
        self.endpointProtection = endpointProtection
        self.falloffShape = falloffShape
        self.chromaMode = chromaMode
        self.pullDesaturation = pullDesaturation
        self.nearEndpointDesaturation = nearEndpointDesaturation
        self.saturationClamp = saturationClamp
        self.liftDesaturation = liftDesaturation
        self.noiseChromaProtection = noiseChromaProtection
        self.hueProtection = hueProtection
        self.bodyBias = bodyBias
        self.peakDamping = peakDamping
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        startEV = try container.decode(Double.self, forKey: .startEV)
        fullEV = try container.decode(Double.self, forKey: .fullEV)
        maxLiftEV = try container.decode(Double.self, forKey: .maxLiftEV)
        maxPullEV = try container.decode(Double.self, forKey: .maxPullEV)
        falloff = try container.decode(Double.self, forKey: .falloff)
        midtoneProtection = try container.decode(Double.self, forKey: .midtoneProtection)
        endpointProtection = try container.decode(Double.self, forKey: .endpointProtection)
        falloffShape = try container.decodeIfPresent(FalloffShape.self, forKey: .falloffShape) ?? .smooth
        chromaMode = try container.decodeIfPresent(RegionalChromaMode.self, forKey: .chromaMode) ?? .preserveHue
        pullDesaturation = try container.decodeIfPresent(Double.self, forKey: .pullDesaturation) ?? 0
        nearEndpointDesaturation = try container.decodeIfPresent(Double.self, forKey: .nearEndpointDesaturation) ?? 0
        saturationClamp = try container.decodeIfPresent(Double.self, forKey: .saturationClamp) ?? 1.15
        liftDesaturation = try container.decodeIfPresent(Double.self, forKey: .liftDesaturation) ?? 0
        noiseChromaProtection = try container.decodeIfPresent(Double.self, forKey: .noiseChromaProtection) ?? 0
        hueProtection = try container.decodeIfPresent(Double.self, forKey: .hueProtection) ?? 0.8
        bodyBias = try container.decodeIfPresent(Double.self, forKey: .bodyBias) ?? 0
        peakDamping = try container.decodeIfPresent(Double.self, forKey: .peakDamping) ?? 0
    }
}

struct EndpointToneTuning: Codable, Equatable, Hashable, Sendable {
    var startEV: Double
    var fullEV: Double
    var strength: Double
    var maxShiftEV: Double
    var softness: Double
    var protection: Double
    var falloffShape: FalloffShape
    var shoulderCoupling: Double
    var toeCoupling: Double
    var chromaProtection: Double
    var desaturationNearClip: Double
    var densitySaturationCoupling: Double
    var bodyBias: Double
    var peakDamping: Double

    init(
        startEV: Double,
        fullEV: Double,
        strength: Double,
        maxShiftEV: Double,
        softness: Double,
        protection: Double,
        falloffShape: FalloffShape,
        shoulderCoupling: Double,
        toeCoupling: Double,
        chromaProtection: Double,
        desaturationNearClip: Double,
        densitySaturationCoupling: Double,
        bodyBias: Double,
        peakDamping: Double
    ) {
        self.startEV = startEV
        self.fullEV = fullEV
        self.strength = strength
        self.maxShiftEV = maxShiftEV
        self.softness = softness
        self.protection = protection
        self.falloffShape = falloffShape
        self.shoulderCoupling = shoulderCoupling
        self.toeCoupling = toeCoupling
        self.chromaProtection = chromaProtection
        self.desaturationNearClip = desaturationNearClip
        self.densitySaturationCoupling = densitySaturationCoupling
        self.bodyBias = bodyBias
        self.peakDamping = peakDamping
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        startEV = try container.decode(Double.self, forKey: .startEV)
        strength = try container.decode(Double.self, forKey: .strength)
        maxShiftEV = try container.decode(Double.self, forKey: .maxShiftEV)
        softness = try container.decode(Double.self, forKey: .softness)
        fullEV = try container.decodeIfPresent(Double.self, forKey: .fullEV)
            ?? Self.derivedFullEV(startEV: startEV, maxShiftEV: maxShiftEV, softness: softness)
        protection = try container.decode(Double.self, forKey: .protection)
        falloffShape = try container.decodeIfPresent(FalloffShape.self, forKey: .falloffShape) ?? .smooth
        shoulderCoupling = try container.decodeIfPresent(Double.self, forKey: .shoulderCoupling) ?? 0
        toeCoupling = try container.decodeIfPresent(Double.self, forKey: .toeCoupling) ?? 0
        chromaProtection = try container.decodeIfPresent(Double.self, forKey: .chromaProtection) ?? 0
        desaturationNearClip = try container.decodeIfPresent(Double.self, forKey: .desaturationNearClip) ?? 0
        densitySaturationCoupling = try container.decodeIfPresent(Double.self, forKey: .densitySaturationCoupling) ?? 0
        bodyBias = try container.decodeIfPresent(Double.self, forKey: .bodyBias) ?? 0
        peakDamping = try container.decodeIfPresent(Double.self, forKey: .peakDamping) ?? 0
    }

    private static func derivedFullEV(startEV: Double, maxShiftEV: Double, softness: Double) -> Double {
        let sign = startEV < 0 ? -1.0 : 1.0
        return sign * (abs(startEV) + abs(maxShiftEV) * max(softness, 0.001))
    }
}

struct PerSliderMapping: Codable, Equatable, Hashable, Sendable {
    var nearZeroSensitivity: Double
    var midSensitivity: Double
    var extremeSensitivity: Double
    var responseExponent: Double
    var softLimit: Double
    var deadZone: Double
    var positiveNegativeSymmetry: Double

    static let defaultV1 = PerSliderMapping(
        nearZeroSensitivity: 0.0,
        midSensitivity: 1.0,
        extremeSensitivity: 1.0,
        responseExponent: 1.0,
        softLimit: 1.0,
        deadZone: 0.0,
        positiveNegativeSymmetry: 1.0
    )

    static let suggestedCandidate01 = PerSliderMapping(
        nearZeroSensitivity: 0.65,
        midSensitivity: 1.0,
        extremeSensitivity: 0.8,
        responseExponent: 1.0,
        softLimit: 1.0,
        deadZone: 0.0,
        positiveNegativeSymmetry: 1.0
    )

    var flatParameters: [Float] {
        [
            Float(nearZeroSensitivity),
            Float(midSensitivity),
            Float(extremeSensitivity),
            Float(responseExponent),
            Float(softLimit),
            Float(deadZone),
            Float(positiveNegativeSymmetry),
        ]
    }
}

struct SliderMappingsTuning: Codable, Equatable, Hashable, Sendable {
    var exposure: PerSliderMapping
    var contrast: PerSliderMapping
    var highlights: PerSliderMapping
    var shadows: PerSliderMapping
    var whites: PerSliderMapping
    var blacks: PerSliderMapping

    static let defaultV1 = SliderMappingsTuning(
        exposure: .defaultV1,
        contrast: .defaultV1,
        highlights: .defaultV1,
        shadows: .defaultV1,
        whites: .defaultV1,
        blacks: .defaultV1
    )

    static let suggestedCandidate01 = SliderMappingsTuning(
        exposure: .defaultV1,
        contrast: .suggestedCandidate01,
        highlights: .suggestedCandidate01,
        shadows: .suggestedCandidate01,
        whites: .suggestedCandidate01,
        blacks: .suggestedCandidate01
    )

    var flatParameters: [Float] {
        exposure.flatParameters
            + contrast.flatParameters
            + highlights.flatParameters
            + shadows.flatParameters
            + whites.flatParameters
            + blacks.flatParameters
    }
}

enum ContrastMode: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case lumaPreserve
    case rgbRatioPreserve
    case rgbCurveStyle
    case hybrid

    var id: String { rawValue }

    var label: String {
        switch self {
        case .lumaPreserve:
            "Luma Preserve"
        case .rgbRatioPreserve:
            "RGB Ratio Preserve"
        case .rgbCurveStyle:
            "RGB Curve Style"
        case .hybrid:
            "Hybrid"
        }
    }
}

private extension ContrastMode {
    var kernelValue: Double {
        switch self {
        case .lumaPreserve:
            0
        case .rgbRatioPreserve:
            1
        case .rgbCurveStyle:
            2
        case .hybrid:
            3
        }
    }
}

enum ToneZoneBias: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case shadows
    case midtones
    case highlights
    case fullRange

    var id: String { rawValue }

    var label: String {
        switch self {
        case .shadows:
            "Shadows"
        case .midtones:
            "Midtones"
        case .highlights:
            "Highlights"
        case .fullRange:
            "Full Range"
        }
    }
}

private extension ToneZoneBias {
    var kernelValue: Double {
        switch self {
        case .shadows:
            0
        case .midtones:
            1
        case .highlights:
            2
        case .fullRange:
            3
        }
    }
}

enum FalloffShape: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case smooth
    case linear
    case soft
    case steep

    var id: String { rawValue }

    var label: String {
        switch self {
        case .smooth:
            "Smooth"
        case .linear:
            "Linear"
        case .soft:
            "Soft"
        case .steep:
            "Steep"
        }
    }
}

extension FalloffShape {
    var kernelValue: Double {
        switch self {
        case .smooth:
            0
        case .linear:
            1
        case .soft:
            2
        case .steep:
            3
        }
    }
}

enum RegionalChromaMode: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case preserveHue
    case desaturatePull
    case protectChroma
    case hybrid

    var id: String { rawValue }

    var label: String {
        switch self {
        case .preserveHue:
            "Preserve Hue"
        case .desaturatePull:
            "Desaturate Pull"
        case .protectChroma:
            "Protect Chroma"
        case .hybrid:
            "Hybrid"
        }
    }
}

private extension RegionalChromaMode {
    var kernelValue: Double {
        switch self {
        case .preserveHue:
            0
        case .desaturatePull:
            1
        case .protectChroma:
            2
        case .hybrid:
            3
        }
    }
}

enum ToneRangeOverlay: String, CaseIterable, Identifiable, Sendable {
    case off
    case highlights
    case shadows
    case whites
    case blacks
    case exposure
    case contrast
    case saturationCoupling
    case chromaProtection
    case clipping
    case neutralDrift

    var id: String { rawValue }

    var label: String {
        switch self {
        case .off:
            "Overlay Off"
        case .highlights:
            "Highlights Influence"
        case .shadows:
            "Shadows Influence"
        case .whites:
            "Whites Influence"
        case .blacks:
            "Blacks Influence"
        case .exposure:
            "Exposure Influence"
        case .contrast:
            "Contrast Influence"
        case .saturationCoupling:
            "Saturation Coupling"
        case .chromaProtection:
            "Chroma Protection"
        case .clipping:
            "Clipping"
        case .neutralDrift:
            "Neutral Drift"
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
        case .exposure:
            5
        case .contrast:
            6
        case .saturationCoupling:
            7
        case .chromaProtection:
            8
        case .clipping:
            9
        case .neutralDrift:
            10
        }
    }
}
