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
}
