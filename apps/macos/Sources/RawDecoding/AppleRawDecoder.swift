import CoreGraphics
import CoreImage
import Foundation
import ImageIO

struct AppleRawDecoder: RawDecoder {
    func canDecode(fileURL: URL) -> Bool {
        LocalImageFile.isRaw(url: fileURL) && CIRAWFilter(imageURL: fileURL) != nil
    }

    func decode(fileURL: URL, options: RawDecodeOptions) throws -> DecodedRawImage {
        guard let rawFilter = configuredFilter(fileURL: fileURL, options: options) else {
            throw RawDecodeError.unsupported(fileURL.lastPathComponent)
        }

        guard let outputImage = rawFilter.outputImage else {
            throw RawDecodeError.unableToDecode(fileURL.lastPathComponent)
        }

        return DecodedRawImage(
            image: outputImage,
            metadata: metadata(from: rawFilter, sourceDescription: "Apple RAW")
        )
    }

    func readMetadata(fileURL: URL) throws -> RawMetadata {
        guard let rawFilter = CIRAWFilter(imageURL: fileURL) else {
            throw RawDecodeError.unsupported(fileURL.lastPathComponent)
        }

        return metadata(from: rawFilter, sourceDescription: "Apple RAW")
    }

    private func configuredFilter(fileURL: URL, options: RawDecodeOptions) -> CIRAWFilter? {
        guard let rawFilter = CIRAWFilter(imageURL: fileURL) else {
            return nil
        }

        rawFilter.isDraftModeEnabled = false
        rawFilter.scaleFactor = 1
        rawFilter.isGamutMappingEnabled = true
        rawFilter.extendedDynamicRangeAmount = 0

        if rawFilter.isLensCorrectionSupported {
            rawFilter.isLensCorrectionEnabled = true
        }

        applyBaseline(options.baseline, to: rawFilter)

        return rawFilter
    }

    private func applyBaseline(_ baseline: RawBaseline, to rawFilter: CIRAWFilter) {
        switch baseline {
        case .neutral:
            rawFilter.boostAmount = 0.35
            rawFilter.boostShadowAmount = 0.9
            rawFilter.contrastAmount = 0.0
            rawFilter.localToneMapAmount = 0.0
            rawFilter.extendedDynamicRangeAmount = 0
        case .darkRoomStandard:
            rawFilter.boostAmount = 0.75
            rawFilter.boostShadowAmount = 1.0
            rawFilter.contrastAmount = rawFilter.isContrastSupported ? 0.25 : rawFilter.contrastAmount
            rawFilter.localToneMapAmount = rawFilter.isLocalToneMapSupported ? 0.25 : rawFilter.localToneMapAmount
            rawFilter.extendedDynamicRangeAmount = 0
        }
    }

    private func metadata(from rawFilter: CIRAWFilter, sourceDescription: String) -> RawMetadata {
        let properties = rawFilter.properties
        let tiff = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any]

        return RawMetadata(
            sourceDescription: sourceDescription,
            cameraModel: tiff?[kCGImagePropertyTIFFModel as String] as? String,
            orientation: rawFilter.orientation,
            neutralTemperature: rawFilter.neutralTemperature,
            neutralTint: rawFilter.neutralTint,
            nativeSize: rawFilter.nativeSize,
            bitDepth: nil
        )
    }
}
