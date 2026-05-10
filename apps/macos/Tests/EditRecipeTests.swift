import XCTest
@testable import DarkRoom

final class EditRecipeTests: XCTestCase {
    func testNeutralRecipeUsesExpectedLightDefaults() {
        let recipe = EditRecipe.neutral

        XCTAssertTrue(recipe.isNeutral)
        XCTAssertEqual(recipe.light.exposureEV, 0)
        XCTAssertEqual(recipe.light.contrast, 0)
        XCTAssertEqual(recipe.light.pivotEV, 0)
        XCTAssertEqual(recipe.light.highlights, 0)
        XCTAssertEqual(recipe.light.shadows, 0)
        XCTAssertEqual(recipe.light.whites, 0)
        XCTAssertEqual(recipe.light.blacks, 0)
        XCTAssertEqual(recipe.light.exposureGain, 1, accuracy: 0.000_001)
        XCTAssertEqual(recipe.light.kernelParameters.count, DarkroomCoreLightMath.kernelParameterCount)
        XCTAssertEqual(ToneTuning.defaultV1.flatParameters.count, DarkroomCoreLightMath.toneTuningParameterCount)
        XCTAssertEqual(ToneTuning.defaultV1.flatParameters, DarkroomCoreLightMath.defaultToneTuningParameters())
        XCTAssertEqual(BehaviorTuning.defaultV2.flatParameters.count, DarkroomCoreLightMath.behaviorTuningParameterCount)
        XCTAssertEqual(BehaviorTuning.defaultV2.flatParameters, DarkroomCoreLightMath.defaultBehaviorTuningParameters())
    }

    func testLightAdjustmentMappingsAreCenteredOnNeutral() {
        var light = LightAdjustments()
        light.exposureEV = 1
        light.contrast = 100
        light.pivotEV = -1.25
        light.highlights = -50
        light.shadows = 25
        light.whites = 75
        light.blacks = -25

        XCTAssertEqual(light.exposureGain, 2, accuracy: 0.000_001)
        XCTAssertEqual(light.kernelParameters[1], 1, accuracy: 0.000_001)
        XCTAssertEqual(light.kernelParameters[2], -1.25, accuracy: 0.000_001)
        XCTAssertEqual(light.normalizedHighlights, -0.5, accuracy: 0.000_001)
        XCTAssertEqual(light.normalizedShadows, 0.15625, accuracy: 0.000_001)
        XCTAssertGreaterThan(light.normalizedWhites, 0)
        XCTAssertLessThan(light.normalizedBlacks, 0)
    }

    func testToneTuningChangesKernelParametersWithoutMutatingRecipeValues() {
        var light = LightAdjustments()
        light.highlights = -100
        light.shadows = 100

        var tuning = ToneTuning.defaultV1
        tuning.highlights.maxPullEV = -3
        tuning.highlights.startEV = 0.35
        tuning.shadows.maxLiftEV = 3
        tuning.shadows.startEV = -0.35

        let defaultParameters = light.kernelParameters
        let tunedParameters = light.kernelParameters(toneTuning: tuning)

        XCTAssertLessThan(tunedParameters[3], defaultParameters[3])
        XCTAssertGreaterThan(tunedParameters[4], defaultParameters[4])
        XCTAssertLessThan(tunedParameters[16], defaultParameters[16])
        XCTAssertLessThan(tunedParameters[14], defaultParameters[14])
        XCTAssertEqual(light.highlights, -100)
        XCTAssertEqual(light.shadows, 100)
    }

    func testPerSliderMappingsCanTuneOneSliderResponse() {
        var light = LightAdjustments()
        light.highlights = 100
        light.shadows = 100

        var tuning = ToneTuning.defaultV1
        tuning.sliderMappings.highlights.softLimit = 0.25

        let defaultParameters = light.kernelParameters
        let tunedParameters = light.kernelParameters(toneTuning: tuning)

        XCTAssertLessThan(tunedParameters[3], defaultParameters[3])
        XCTAssertEqual(tunedParameters[4], defaultParameters[4], accuracy: 0.000_001)
    }

    func testBehaviorTuningDrivesKernelParametersWithoutChangingExposureStops() {
        var light = LightAdjustments()
        light.exposureEV = 1

        var behavior = BehaviorTuning.defaultV2
        behavior.exposureFeelTuning.responseExponent = 2.0
        behavior.exposureFeelTuning.shadowVisibilityPerEV = 0.5

        let tunedParameters = light.kernelParameters(behaviorTuning: behavior)

        XCTAssertEqual(tunedParameters[0], 2, accuracy: 0.000_001)
        XCTAssertGreaterThan(tunedParameters[40], 0)
    }

    func testToneTuningCopiesAsReadableJSON() throws {
        let json = ToneTuning.suggestedCandidate01.prettyPrintedJSON
        let decoded = try JSONDecoder().decode(ToneTuning.self, from: Data(json.utf8))

        XCTAssertEqual(decoded, .suggestedCandidate01)
        XCTAssertTrue(json.contains("\"highlights\""))
        XCTAssertTrue(json.contains("\"sliderMappings\""))
    }

    func testBehaviorTuningCopiesFullV2JSON() throws {
        let json = BehaviorTuning.suggestedCandidate01.prettyPrintedJSON
        let decoded = try JSONDecoder().decode(BehaviorTuning.self, from: Data(json.utf8))

        XCTAssertEqual(decoded.schemaVersion, 2)
        XCTAssertTrue(json.contains("\"toneTuning\""))
        XCTAssertTrue(json.contains("\"exposureFeelTuning\""))
        XCTAssertTrue(json.contains("\"colorCouplingTuning\""))
        XCTAssertTrue(json.contains("\"sliderMappings\""))
    }

    func testBehaviorTuningDecodesOlderEndpointJSONWithDerivedFullEV() throws {
        let json = """
        {
          "schemaVersion": 2,
          "name": "Legacy Candidate",
          "toneTuning": {
            "version": "darkroom_tonal_curve_v1_current",
            "global": {
              "baseContrast": 1.0,
              "displayMiddleGray": 0.44,
              "middleGray": 0.18,
              "outputSoftClip": 0.0,
              "sceneBlackEV": -7.0,
              "sceneWhiteEV": 4.0,
              "shoulderLengthEV": 3.0,
              "shoulderRollStrength": 0.0,
              "shoulderStrength": 0.0,
              "toeLengthEV": 2.5,
              "toeLift": 0.0,
              "toeStrength": 0.0
            },
            "contrast": {
              "affectsSaturation": true,
              "contrastSoftness": 2.0,
              "hueProtection": 0.8,
              "maxSlopeBoost": 1.35,
              "maxSlopeReduction": 1.35,
              "mode": "rgbRatioPreserve",
              "neutralProtection": 1.0,
              "pivotMaxEV": 2.0,
              "pivotMinEV": -2.0,
              "saturationAmount": 0.08,
              "saturationZone": "midtones"
            },
            "highlights": {
              "chromaMode": "preserveHue",
              "endpointProtection": 0.0,
              "falloff": 1.0,
              "falloffShape": "smooth",
              "fullEV": 4.0,
              "hueProtection": 0.8,
              "liftDesaturation": 0.0,
              "maxLiftEV": 1.8,
              "maxPullEV": -1.8,
              "midtoneProtection": 0.0,
              "nearEndpointDesaturation": 0.12,
              "noiseChromaProtection": 0.0,
              "pullDesaturation": 0.16,
              "saturationClamp": 1.15,
              "startEV": 0.5
            },
            "shadows": {
              "chromaMode": "preserveHue",
              "endpointProtection": 0.0,
              "falloff": 1.0,
              "falloffShape": "smooth",
              "fullEV": -4.0,
              "hueProtection": 0.8,
              "liftDesaturation": 0.12,
              "maxLiftEV": 1.8,
              "maxPullEV": -1.8,
              "midtoneProtection": 0.0,
              "nearEndpointDesaturation": 0.0,
              "noiseChromaProtection": 0.35,
              "pullDesaturation": 0.0,
              "saturationClamp": 1.15,
              "startEV": -0.5
            },
            "whites": {
              "chromaProtection": 0.35,
              "densitySaturationCoupling": 0.0,
              "desaturationNearClip": 0.1,
              "falloffShape": "smooth",
              "maxShiftEV": 2.0,
              "protection": 0.0,
              "shoulderCoupling": 0.5,
              "softness": 2.0,
              "startEV": 1.0,
              "strength": 1.0,
              "toeCoupling": 0.0
            },
            "blacks": {
              "chromaProtection": 0.45,
              "densitySaturationCoupling": 0.04,
              "desaturationNearClip": 0.0,
              "falloffShape": "smooth",
              "maxShiftEV": 2.0,
              "protection": 0.0,
              "shoulderCoupling": 0.0,
              "softness": 2.0,
              "startEV": -1.0,
              "strength": 1.0,
              "toeCoupling": 0.6
            },
            "sliderMappings": {
              "exposure": { "deadZone": 0.0, "extremeSensitivity": 1.0, "midSensitivity": 1.0, "nearZeroSensitivity": 0.0, "positiveNegativeSymmetry": 1.0, "responseExponent": 1.0, "softLimit": 1.0 },
              "contrast": { "deadZone": 0.0, "extremeSensitivity": 1.0, "midSensitivity": 1.0, "nearZeroSensitivity": 0.0, "positiveNegativeSymmetry": 1.0, "responseExponent": 1.0, "softLimit": 1.0 },
              "highlights": { "deadZone": 0.0, "extremeSensitivity": 1.0, "midSensitivity": 1.0, "nearZeroSensitivity": 0.0, "positiveNegativeSymmetry": 1.0, "responseExponent": 1.0, "softLimit": 1.0 },
              "shadows": { "deadZone": 0.0, "extremeSensitivity": 1.0, "midSensitivity": 1.0, "nearZeroSensitivity": 0.0, "positiveNegativeSymmetry": 1.0, "responseExponent": 1.0, "softLimit": 1.0 },
              "whites": { "deadZone": 0.0, "extremeSensitivity": 1.0, "midSensitivity": 1.0, "nearZeroSensitivity": 0.0, "positiveNegativeSymmetry": 1.0, "responseExponent": 1.0, "softLimit": 1.0 },
              "blacks": { "deadZone": 0.0, "extremeSensitivity": 1.0, "midSensitivity": 1.0, "nearZeroSensitivity": 0.0, "positiveNegativeSymmetry": 1.0, "responseExponent": 1.0, "softLimit": 1.0 }
            }
          }
        }
        """

        let decoded = try JSONDecoder().decode(BehaviorTuning.self, from: Data(json.utf8))

        XCTAssertEqual(decoded.toneTuning.whites.fullEV, 5.0, accuracy: 0.000_001)
        XCTAssertEqual(decoded.toneTuning.blacks.fullEV, -5.0, accuracy: 0.000_001)
        XCTAssertEqual(decoded.overlayTuning, .defaultV2)
    }

    @MainActor
    func testEditSessionPersistsRecipesPerFileAndDropsNeutralRecipes() async throws {
        let directory = try makeTemporaryDirectory()
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let sourceURL = directory.appendingPathComponent("test-a.arw")
        let file = LocalImageFile(url: sourceURL)
        let store = EditRecipeSidecarStore()
        let session = EditSessionModel(
            sidecarStore: store,
            coalescedPersistenceDelayNanoseconds: 10_000_000_000
        )
        var recipe = EditRecipe.neutral
        recipe.light.exposureEV = 1.25

        session.binding(for: file).wrappedValue = recipe
        XCTAssertEqual(session.recipe(for: file), recipe)
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.sidecarURL(for: sourceURL).path))

        await session.flushPendingPersistence(for: file)
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.sidecarURL(for: sourceURL).path))

        let reloadedSession = EditSessionModel(sidecarStore: store)
        XCTAssertEqual(reloadedSession.recipe(for: file), recipe)

        session.binding(for: file).wrappedValue = .neutral
        XCTAssertEqual(session.recipe(for: file), .neutral)
        await session.flushPendingPersistence(for: file)
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.sidecarURL(for: sourceURL).path))
    }

    func testSidecarStoreWritesReadableXMP() throws {
        let directory = try makeTemporaryDirectory()
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let sourceURL = directory.appendingPathComponent("image with spaces.arw")
        let store = EditRecipeSidecarStore()
        var recipe = EditRecipe.neutral
        recipe.light.exposureEV = -0.75
        recipe.light.contrast = 22
        recipe.light.pivotEV = 0.5
        recipe.light.highlights = -15
        recipe.light.shadows = 31
        recipe.light.whites = 44
        recipe.light.blacks = -12

        try store.save(recipe, for: sourceURL)

        let sidecarURL = store.sidecarURL(for: sourceURL)
        let sidecar = try String(contentsOf: sidecarURL, encoding: .utf8)
        XCTAssertTrue(sidecar.contains("xmlns:dr=\"https://darkroom.dev/ns/edit/1.0/\""))
        XCTAssertTrue(sidecar.contains("dr:ToneCurveModel=\"darkroom_tonal_curve_v1\""))
        XCTAssertTrue(sidecar.contains("dr:ExposureEV=\"-0.750000\""))
        XCTAssertTrue(sidecar.contains("dr:PivotEV=\"0.500000\""))
        XCTAssertTrue(sidecar.contains("dr:Whites=\"44.000000\""))
        XCTAssertTrue(sidecar.contains("dr:Blacks=\"-12.000000\""))
        XCTAssertEqual(try store.loadRecipe(for: sourceURL), recipe)
    }

    func testSidecarStoreLoadsOlderV1LightSidecarsWithNewToneDefaults() throws {
        let directory = try makeTemporaryDirectory()
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let sourceURL = directory.appendingPathComponent("legacy.arw")
        let store = EditRecipeSidecarStore()
        let sidecarURL = store.sidecarURL(for: sourceURL)
        let sidecar = """
        <?xpacket begin="" id="W5M0MpCehiHzreSzNTczkc9d"?>
        <x:xmpmeta xmlns:x="adobe:ns:meta/" x:xmptk="DarkRoom">
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <rdf:Description rdf:about=""
                xmlns:dr="https://darkroom.dev/ns/edit/1.0/"
                dr:RecipeVersion="1"
                dr:ExposureEV="-0.250000"
                dr:Contrast="12.000000"
                dr:Highlights="-8.000000"
                dr:Shadows="21.000000" />
          </rdf:RDF>
        </x:xmpmeta>
        <?xpacket end="w"?>
        """
        try sidecar.write(to: sidecarURL, atomically: true, encoding: .utf8)

        var expected = EditRecipe.neutral
        expected.light.exposureEV = -0.25
        expected.light.contrast = 12
        expected.light.highlights = -8
        expected.light.shadows = 21

        XCTAssertEqual(try store.loadRecipe(for: sourceURL), expected)
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
