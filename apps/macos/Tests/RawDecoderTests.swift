import CoreImage
import Foundation
import XCTest
@testable import DarkRoom

final class RawDecoderTests: XCTestCase {
    func testMockRawDecoderCanSatisfyRawDecoderContract() throws {
        let decoder = MockRawDecoder()
        let url = URL(fileURLWithPath: "/tmp/example.arw")

        XCTAssertTrue(decoder.canDecode(fileURL: url))

        let decoded = try decoder.decode(fileURL: url, options: .neutral)

        XCTAssertEqual(decoded.metadata.sourceDescription, "Mock RAW")
        XCTAssertEqual(decoded.metadata.cameraModel, "Test Camera")
    }
}

private struct MockRawDecoder: RawDecoder {
    func canDecode(fileURL: URL) -> Bool {
        LocalImageFile.isRaw(url: fileURL)
    }

    func decode(fileURL: URL, options: RawDecodeOptions) throws -> DecodedRawImage {
        DecodedRawImage(
            image: CIImage(color: .gray).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1)),
            metadata: try readMetadata(fileURL: fileURL)
        )
    }

    func readMetadata(fileURL: URL) throws -> RawMetadata {
        RawMetadata(
            sourceDescription: "Mock RAW",
            cameraModel: "Test Camera",
            orientation: .up,
            neutralTemperature: 5_500,
            neutralTint: 0,
            nativeSize: CGSize(width: 1, height: 1),
            bitDepth: 14
        )
    }
}
