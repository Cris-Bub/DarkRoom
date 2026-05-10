import AppKit
import ImageIO
import UniformTypeIdentifiers
import XCTest
@testable import DarkRoom

final class ViewerImageRendererTests: XCTestCase {
    func testRasterRendererProofsSyntheticImageForPreviewTargets() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")
        defer {
            try? FileManager.default.removeItem(at: url)
        }

        try writeTestPNG(to: url)

        let displayProfile = ViewerDisplayProfile(
            colorSpace: NSColorSpace(cgColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!),
            displayName: "Test Display"
        )

        for previewTarget in PreviewTarget.allCases {
            let renderedImage = try ViewerImageRenderer.render(
                url: url,
                displayProfile: displayProfile,
                previewTarget: previewTarget
            )

            XCTAssertEqual(renderedImage.sourceKind, .raster)
            XCTAssertEqual(renderedImage.previewTarget, previewTarget)
            XCTAssertEqual(renderedImage.cgImage.width, 2)
            XCTAssertEqual(renderedImage.cgImage.height, 2)
        }
    }

    func testPreparedSourceCanRenderMultipleRecipesWithoutReloadingSource() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")
        defer {
            try? FileManager.default.removeItem(at: url)
        }

        try writeTestPNG(to: url)

        let displayProfile = ViewerDisplayProfile(
            colorSpace: NSColorSpace(cgColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!),
            displayName: "Test Display"
        )
        let preparedSource = try ViewerImageRenderer.prepareSource(url: url)
        var editedRecipe = EditRecipe.neutral
        editedRecipe.light.exposureEV = 1.0

        let neutralImage = try ViewerImageRenderer.render(
            preparedSource: preparedSource,
            displayProfile: displayProfile,
            previewTarget: .webInstagram,
            editRecipe: .neutral
        )
        let editedImage = try ViewerImageRenderer.render(
            preparedSource: preparedSource,
            displayProfile: displayProfile,
            previewTarget: .webInstagram,
            editRecipe: editedRecipe
        )

        XCTAssertEqual(neutralImage.cgImage.width, 2)
        XCTAssertEqual(editedImage.cgImage.width, 2)
        XCTAssertEqual(editedImage.editRecipe, editedRecipe)
    }

    func testDisplayPreviewCanRenderBoundedPreviewSize() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")
        defer {
            try? FileManager.default.removeItem(at: url)
        }

        try writeTestPNG(to: url)

        let displayProfile = ViewerDisplayProfile(
            colorSpace: NSColorSpace(cgColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!),
            displayName: "Test Display"
        )
        let preparedSource = try ViewerImageRenderer.prepareSource(url: url)

        let renderedImage = try ViewerImageRenderer.render(
            preparedSource: preparedSource,
            displayProfile: displayProfile,
            previewTarget: .webInstagram,
            maximumPixelSize: CGSize(width: 1, height: 1)
        )

        XCTAssertLessThanOrEqual(renderedImage.cgImage.width, 1)
        XCTAssertLessThanOrEqual(renderedImage.cgImage.height, 1)
    }

    func testExtremeShadowHighlightRecipeKeepsRenderedGradientOrdered() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")
        defer {
            try? FileManager.default.removeItem(at: url)
        }

        try writeGradientPNG(to: url, width: 32)

        let displayProfile = ViewerDisplayProfile(
            colorSpace: NSColorSpace(cgColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!),
            displayName: "Test Display"
        )
        var recipe = EditRecipe.neutral
        recipe.light.contrast = 100
        recipe.light.pivotEV = -2
        recipe.light.shadows = 100
        recipe.light.highlights = -100
        recipe.light.whites = -100
        recipe.light.blacks = -100

        let renderedImage = try ViewerImageRenderer.render(
            url: url,
            displayProfile: displayProfile,
            previewTarget: .webInstagram,
            editRecipe: recipe
        )
        let samples = try redSamples(from: renderedImage.cgImage)

        for index in samples.indices.dropFirst() {
            XCTAssertGreaterThanOrEqual(
                Int(samples[index]) + 1,
                Int(samples[index - 1]),
                "Extreme tone recovery inverted the rendered gradient at sample \(index)."
            )
        }

        XCTAssertLessThan(samples[0], samples[samples.count / 2])
        XCTAssertLessThan(samples[samples.count / 2], samples[samples.count - 1])
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

    private func writeGradientPNG(to url: URL, width: Int) throws {
        var pixels = [UInt8](repeating: 0, count: width * 4)

        for x in 0..<width {
            let value = UInt8((Double(x) / Double(width - 1) * 255.0).rounded())
            let index = x * 4
            pixels[index] = value
            pixels[index + 1] = value
            pixels[index + 2] = value
            pixels[index + 3] = 255
        }

        let context = try XCTUnwrap(
            CGContext(
                data: &pixels,
                width: width,
                height: 1,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
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

    private func redSamples(from image: CGImage) throws -> [UInt8] {
        var pixels = [UInt8](repeating: 0, count: image.width * image.height * 4)
        let context = try XCTUnwrap(
            CGContext(
                data: &pixels,
                width: image.width,
                height: image.height,
                bitsPerComponent: 8,
                bytesPerRow: image.width * 4,
                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )
        context.interpolationQuality = .none
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))

        return stride(from: 0, to: pixels.count, by: 4).map { pixels[$0] }
    }
}
