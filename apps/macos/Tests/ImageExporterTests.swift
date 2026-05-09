import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import XCTest
@testable import DarkRoom

final class ImageExporterTests: XCTestCase {
    func testExporterWritesPngFromSourceRecipeAndOutputProfile() throws {
        let sourceURL = try makeSolidPNG(red: 64, green: 64, blue: 64)
        let destinationURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")
        defer {
            try? FileManager.default.removeItem(at: sourceURL)
            try? FileManager.default.removeItem(at: destinationURL)
        }

        var recipe = EditRecipe.neutral
        recipe.light.exposureEV = 1

        let result = try ImageExporter.export(
            ExportRequest(
                sourceURL: sourceURL,
                destinationURL: destinationURL,
                format: .png,
                outputTarget: .webInstagram,
                editRecipe: recipe
            )
        )

        XCTAssertEqual(result.destinationURL, destinationURL)
        XCTAssertEqual(result.format, .png)
        XCTAssertEqual(result.outputTarget, .webInstagram)
        XCTAssertEqual(result.width, 2)
        XCTAssertEqual(result.height, 2)
        XCTAssertTrue(FileManager.default.fileExists(atPath: destinationURL.path))

        let exportedImage = try loadCGImage(from: destinationURL)
        XCTAssertNotNil(exportedImage.colorSpace)
        XCTAssertGreaterThan(try firstPixelRed(from: exportedImage), 64)
    }

    func testExportFormatDetectsCommonExtensions() {
        XCTAssertEqual(ExportFormat(url: URL(fileURLWithPath: "/tmp/a.jpg")), .jpeg)
        XCTAssertEqual(ExportFormat(url: URL(fileURLWithPath: "/tmp/a.jpeg")), .jpeg)
        XCTAssertEqual(ExportFormat(url: URL(fileURLWithPath: "/tmp/a.png")), .png)
        XCTAssertEqual(ExportFormat(url: URL(fileURLWithPath: "/tmp/a.tif")), .tiff)
        XCTAssertEqual(ExportFormat(url: URL(fileURLWithPath: "/tmp/a.tiff")), .tiff)
        XCTAssertNil(ExportFormat(url: URL(fileURLWithPath: "/tmp/a.raw")))
    }

    private func makeSolidPNG(red: UInt8, green: UInt8, blue: UInt8) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")
        var pixels = [UInt8](
            repeating: 0,
            count: 2 * 2 * 4
        )

        for index in stride(from: 0, to: pixels.count, by: 4) {
            pixels[index] = red
            pixels[index + 1] = green
            pixels[index + 2] = blue
            pixels[index + 3] = 255
        }

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

        return url
    }

    private func loadCGImage(from url: URL) throws -> CGImage {
        let source = try XCTUnwrap(CGImageSourceCreateWithURL(url as CFURL, nil))
        return try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
    }

    private func firstPixelRed(from image: CGImage) throws -> UInt8 {
        var pixel = [UInt8](repeating: 0, count: 4)
        let context = try XCTUnwrap(
            CGContext(
                data: &pixel,
                width: 1,
                height: 1,
                bitsPerComponent: 8,
                bytesPerRow: 4,
                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )

        context.draw(image, in: CGRect(x: 0, y: 0, width: 1, height: 1))

        return pixel[0]
    }
}
