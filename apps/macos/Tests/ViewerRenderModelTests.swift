import AppKit
import ImageIO
import UniformTypeIdentifiers
import XCTest
@testable import DarkRoom

@MainActor
final class ViewerRenderModelTests: XCTestCase {
    func testEditRerenderKeepsPreviousPreviewDisplayable() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")
        defer {
            try? FileManager.default.removeItem(at: url)
        }

        try writeTestPNG(to: url)

        let file = LocalImageFile(url: url)
        let model = ViewerRenderModel()
        let previewTarget = PreviewTarget.webInstagram

        model.render(
            file: file,
            previewTarget: previewTarget,
            editRecipe: .neutral
        )
        try await waitForReady(
            model,
            file: file,
            previewTarget: previewTarget,
            editRecipe: .neutral
        )

        var editedRecipe = EditRecipe.neutral
        editedRecipe.light.exposureEV = 0.75

        model.render(
            file: file,
            previewTarget: previewTarget,
            editRecipe: editedRecipe
        )

        XCTAssertTrue(
            model.hasDisplayableImage(for: file, previewTarget: previewTarget),
            "Editing should keep the last rendered preview visible while the next recipe renders."
        )

        try await waitForReady(
            model,
            file: file,
            previewTarget: previewTarget,
            editRecipe: editedRecipe
        )
    }

    func testPreviewTargetChangeClearsDisplayablePreviewUntilTargetRenders() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")
        defer {
            try? FileManager.default.removeItem(at: url)
        }

        try writeTestPNG(to: url)

        let file = LocalImageFile(url: url)
        let model = ViewerRenderModel()

        model.render(
            file: file,
            previewTarget: .webInstagram,
            editRecipe: .neutral
        )
        try await waitForReady(
            model,
            file: file,
            previewTarget: .webInstagram,
            editRecipe: .neutral
        )

        model.render(
            file: file,
            previewTarget: .appleDisplayP3,
            editRecipe: .neutral
        )

        XCTAssertFalse(
            model.hasDisplayableImage(for: file, previewTarget: .appleDisplayP3),
            "Changing proof targets should not show a preview rendered for the previous target."
        )
    }

    private func waitForReady(
        _ model: ViewerRenderModel,
        file: LocalImageFile,
        previewTarget: PreviewTarget,
        editRecipe: EditRecipe,
        file sourceFile: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let deadline = Date().addingTimeInterval(3)

        while Date() < deadline {
            if model.isReady(
                for: file,
                previewTarget: previewTarget,
                editRecipe: editRecipe
            ) {
                return
            }

            try await Task.sleep(nanoseconds: 10_000_000)
        }

        XCTFail("Timed out waiting for viewer render.", file: sourceFile, line: line)
        throw WaitError.timeout
    }

    private func writeTestPNG(to url: URL) throws {
        var pixels: [UInt8] = [
            230, 51, 26, 255,
            230, 51, 26, 255,
            230, 51, 26, 255,
            230, 51, 26, 255
        ]

        let context = try XCTUnwrap(
            CGContext(
                data: &pixels,
                width: 2,
                height: 2,
                bitsPerComponent: 8,
                bytesPerRow: 8,
                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )
        let image = try XCTUnwrap(context.makeImage())
        let destination = try XCTUnwrap(
            CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
        )

        CGImageDestinationAddImage(destination, image, nil)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
    }

    private enum WaitError: Error {
        case timeout
    }
}
