import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import XCTest
@testable import DarkRoom

final class HistogramTests: XCTestCase {
    func testHistogramDetectsShadowAndHighlightClipping() throws {
        let image = try makeImage(
            width: 2,
            height: 1,
            pixels: [
                0, 0, 0, 255,
                255, 255, 255, 255
            ]
        )

        let histogram = try HistogramCalculator.makeHistogram(from: image)

        XCTAssertEqual(histogram.sampledPixelCount, 2)
        XCTAssertEqual(histogram.shadowClippedPixelCount, 1)
        XCTAssertEqual(histogram.highlightClippedPixelCount, 1)
        XCTAssertTrue(histogram.hasShadowClipping)
        XCTAssertTrue(histogram.hasHighlightClipping)
        XCTAssertEqual(histogram.luminance[0], 1)
        XCTAssertEqual(histogram.luminance[255], 1)
    }

    func testHistogramSeparatesRGBChannels() throws {
        let image = try makeImage(
            width: 3,
            height: 1,
            pixels: [
                255, 0, 0, 255,
                0, 255, 0, 255,
                0, 0, 255, 255
            ]
        )

        let histogram = try HistogramCalculator.makeHistogram(from: image)

        XCTAssertEqual(histogram.red[255], 1)
        XCTAssertEqual(histogram.green[255], 1)
        XCTAssertEqual(histogram.blue[255], 1)
    }

    func testHistogramRenderReflectsRecipeChanges() throws {
        let url = try writeSolidPNG(red: 64, green: 64, blue: 64)
        defer {
            try? FileManager.default.removeItem(at: url)
        }

        var brightRecipe = EditRecipe.neutral
        brightRecipe.light.exposureEV = 1

        let neutralRender = try ImagePipelineRenderer.renderHistogramPreview(
            url: url,
            previewTarget: .webInstagram,
            editRecipe: .neutral,
            maximumPixelSize: CGSize(width: 2, height: 2)
        )
        let brightRender = try ImagePipelineRenderer.renderHistogramPreview(
            url: url,
            previewTarget: .webInstagram,
            editRecipe: brightRecipe,
            maximumPixelSize: CGSize(width: 2, height: 2)
        )
        let neutralHistogram = try HistogramCalculator.makeHistogram(from: neutralRender.cgImage)
        let brightHistogram = try HistogramCalculator.makeHistogram(from: brightRender.cgImage)

        XCTAssertGreaterThan(
            dominantBin(in: brightHistogram.luminance),
            dominantBin(in: neutralHistogram.luminance)
        )
    }

    private func makeImage(width: Int, height: Int, pixels: [UInt8]) throws -> CGImage {
        var pixels = pixels
        let context = try XCTUnwrap(
            CGContext(
                data: &pixels,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                    | CGBitmapInfo.byteOrder32Big.rawValue
            )
        )

        return try XCTUnwrap(context.makeImage())
    }

    private func writeSolidPNG(red: UInt8, green: UInt8, blue: UInt8) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")
        var pixels = [UInt8](repeating: 0, count: 2 * 2 * 4)

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
                    | CGBitmapInfo.byteOrder32Big.rawValue
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

    private func dominantBin(in bins: [Int]) -> Int {
        bins.indices.max { bins[$0] < bins[$1] } ?? 0
    }
}
