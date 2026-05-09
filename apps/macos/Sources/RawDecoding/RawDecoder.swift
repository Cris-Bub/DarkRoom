import CoreGraphics
import CoreImage
import Foundation
import ImageIO

protocol RawDecoder {
    func canDecode(fileURL: URL) -> Bool
    func decode(fileURL: URL, options: RawDecodeOptions) throws -> DecodedRawImage
    func readMetadata(fileURL: URL) throws -> RawMetadata
}

struct RawDecodeOptions: Sendable {
    var baseline: RawBaseline

    static let darkRoomStandard = RawDecodeOptions(baseline: .darkRoomStandard)
    static let neutral = RawDecodeOptions(baseline: .neutral)
}

enum RawBaseline: String, CaseIterable, Identifiable, Sendable {
    case darkRoomStandard
    case neutral

    var id: String {
        rawValue
    }

    var label: String {
        switch self {
        case .darkRoomStandard:
            "DarkRoom Standard"
        case .neutral:
            "Neutral"
        }
    }
}

struct DecodedRawImage {
    let image: CIImage
    let metadata: RawMetadata
}

struct RawMetadata {
    var sourceDescription: String
    var cameraModel: String?
    var orientation: CGImagePropertyOrientation?
    var neutralTemperature: Float?
    var neutralTint: Float?
    var nativeSize: CGSize?
    var bitDepth: Int?
}

enum RawDecodeError: LocalizedError {
    case unsupported(String)
    case unableToDecode(String)

    var errorDescription: String? {
        switch self {
        case .unsupported(let filename):
            "No RAW decoder is available for \(filename)."
        case .unableToDecode(let filename):
            "Could not decode \(filename)."
        }
    }
}
