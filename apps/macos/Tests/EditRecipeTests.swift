import XCTest
@testable import DarkRoom

final class EditRecipeTests: XCTestCase {
    func testNeutralRecipeUsesExpectedLightDefaults() {
        let recipe = EditRecipe.neutral

        XCTAssertTrue(recipe.isNeutral)
        XCTAssertEqual(recipe.light.exposureEV, 0)
        XCTAssertEqual(recipe.light.contrast, 0)
        XCTAssertEqual(recipe.light.highlights, 0)
        XCTAssertEqual(recipe.light.shadows, 0)
        XCTAssertEqual(recipe.light.exposureGain, 1, accuracy: 0.000_001)
        XCTAssertEqual(recipe.light.contrastExponent, 1, accuracy: 0.000_001)
    }

    func testLightAdjustmentMappingsAreCenteredOnNeutral() {
        var light = LightAdjustments()
        light.exposureEV = 1
        light.contrast = 100
        light.highlights = -50
        light.shadows = 25

        XCTAssertEqual(light.exposureGain, 2, accuracy: 0.000_001)
        XCTAssertEqual(light.contrastExponent, 2, accuracy: 0.000_001)
        XCTAssertEqual(light.normalizedHighlights, -0.5, accuracy: 0.000_001)
        XCTAssertEqual(light.normalizedShadows, 0.25, accuracy: 0.000_001)
        XCTAssertEqual(light.shadowLiftLimit, 0.58, accuracy: 0.000_001)
        XCTAssertEqual(light.highlightPullLimit, 0.50, accuracy: 0.000_001)
        XCTAssertLessThan(light.highlightMaskStart, light.highlightMaskEnd)
        XCTAssertLessThan(light.shadowMaskStart, light.shadowMaskEnd)
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
        recipe.light.highlights = -15
        recipe.light.shadows = 31

        try store.save(recipe, for: sourceURL)

        let sidecarURL = store.sidecarURL(for: sourceURL)
        let sidecar = try String(contentsOf: sidecarURL, encoding: .utf8)
        XCTAssertTrue(sidecar.contains("xmlns:dr=\"https://darkroom.dev/ns/edit/1.0/\""))
        XCTAssertTrue(sidecar.contains("dr:ExposureEV=\"-0.750000\""))
        XCTAssertEqual(try store.loadRecipe(for: sourceURL), recipe)
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
