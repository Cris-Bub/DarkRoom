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

    func testToneTuningCopiesAsReadableJSON() throws {
        let json = ToneTuning.suggestedCandidate01.prettyPrintedJSON
        let decoded = try JSONDecoder().decode(ToneTuning.self, from: Data(json.utf8))

        XCTAssertEqual(decoded, .suggestedCandidate01)
        XCTAssertTrue(json.contains("\"highlights\""))
        XCTAssertTrue(json.contains("\"sliderMapping\""))
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
