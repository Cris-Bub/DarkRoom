import AppKit
import CoreImage
import ImageIO

enum ViewerImageRenderer {
    static func render(
        url: URL,
        displayProfile: ViewerDisplayProfile,
        previewTarget: PreviewTarget,
        rawBaseline: RawBaseline = .darkRoomStandard,
        rawDecoder: any RawDecoder = AppleRawDecoder()
    ) throws -> RenderedViewerImage {
        if LocalImageFile.isRaw(url: url),
           let rawImage = try renderRawImageIfAvailable(
            url: url,
            displayProfile: displayProfile,
            previewTarget: previewTarget,
            rawBaseline: rawBaseline,
            rawDecoder: rawDecoder
           ) {
            return rawImage
        }

        return try renderImageIOImage(
            url: url,
            displayProfile: displayProfile,
            previewTarget: previewTarget
        )
    }

    private static func renderRawImageIfAvailable(
        url: URL,
        displayProfile: ViewerDisplayProfile,
        previewTarget: PreviewTarget,
        rawBaseline: RawBaseline,
        rawDecoder: any RawDecoder
    ) throws -> RenderedViewerImage? {
        guard rawDecoder.canDecode(fileURL: url) else {
            return nil
        }

        let decodedImage = try rawDecoder.decode(
            fileURL: url,
            options: RawDecodeOptions(baseline: rawBaseline)
        )

        let cgImage = try render(
            decodedImage.image,
            displayProfile: displayProfile,
            previewTarget: previewTarget
        )

        return RenderedViewerImage(
            cgImage: cgImage,
            sourceKind: .raw,
            sourceProfileName: decodedImage.metadata.sourceDescription,
            sourceProfileWasAssumed: false,
            previewTarget: previewTarget,
            rawBaseline: rawBaseline,
            workingColorSpaceName: WorkingColorSpace.displayName,
            displayProfileName: displayProfile.displayName
        )
    }

    private static func renderImageIOImage(
        url: URL,
        displayProfile: ViewerDisplayProfile,
        previewTarget: PreviewTarget
    ) throws -> RenderedViewerImage {
        let options = [
            kCGImageSourceShouldCache: true,
            kCGImageSourceShouldCacheImmediately: true
        ] as CFDictionary

        guard let source = CGImageSourceCreateWithURL(url as CFURL, options),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, options) else {
            throw ViewerRenderError.unableToDecode(url.lastPathComponent)
        }

        let sourceProfileWasAssumed = cgImage.colorSpace == nil
        let sourceColorSpace = cgImage.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!
        var ciImage = CIImage(cgImage: cgImage, options: [.colorSpace: sourceColorSpace as Any])

        if let orientation = imageOrientation(from: source) {
            ciImage = ciImage.oriented(forExifOrientation: Int32(orientation))
        }

        let renderedImage = try render(
            ciImage,
            displayProfile: displayProfile,
            previewTarget: previewTarget
        )

        return RenderedViewerImage(
            cgImage: renderedImage,
            sourceKind: .raster,
            sourceProfileName: colorSpaceName(sourceColorSpace),
            sourceProfileWasAssumed: sourceProfileWasAssumed,
            previewTarget: previewTarget,
            rawBaseline: nil,
            workingColorSpaceName: WorkingColorSpace.displayName,
            displayProfileName: displayProfile.displayName
        )
    }

    private static func render(
        _ image: CIImage,
        displayProfile: ViewerDisplayProfile,
        previewTarget: PreviewTarget
    ) throws -> CGImage {
        let proofContext = CIContext(options: [
            .workingColorSpace: WorkingColorSpace.linearROMMRGB,
            .outputColorSpace: previewTarget.colorSpace,
            .workingFormat: CIFormat.RGBAh
        ])

        let extent = image.extent.integral
        guard !extent.isEmpty,
              let proofedImage = proofContext.createCGImage(
                image,
                from: extent,
                format: .RGBAh,
                colorSpace: previewTarget.colorSpace
              ) else {
            throw ViewerRenderError.unableToRender
        }

        let displayImage = CIImage(cgImage: proofedImage, options: [.colorSpace: previewTarget.colorSpace])
        let displayContext = CIContext(options: [
            .workingColorSpace: previewTarget.colorSpace,
            .outputColorSpace: displayProfile.colorSpace,
            .workingFormat: CIFormat.RGBAh
        ])

        guard let cgImage = displayContext.createCGImage(
            displayImage,
            from: displayImage.extent.integral,
            format: .RGBA16,
            colorSpace: displayProfile.colorSpace
              ) else {
            throw ViewerRenderError.unableToRender
        }

        return cgImage
    }

    private static func imageOrientation(from source: CGImageSource) -> Int? {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let orientation = properties[kCGImagePropertyOrientation] as? Int else {
            return nil
        }

        return orientation
    }

    private static func colorSpaceName(_ colorSpace: CGColorSpace) -> String {
        colorSpace.name as String? ?? "Embedded ICC"
    }
}

struct RenderedViewerImage: @unchecked Sendable {
    let cgImage: CGImage
    let sourceKind: ViewerSourceKind
    let sourceProfileName: String
    let sourceProfileWasAssumed: Bool
    let previewTarget: PreviewTarget
    let rawBaseline: RawBaseline?
    let workingColorSpaceName: String
    let displayProfileName: String
}

enum ViewerSourceKind: Sendable, Equatable {
    case raw
    case raster
}

enum ViewerRenderError: LocalizedError {
    case unableToDecode(String)
    case unableToRender

    var errorDescription: String? {
        switch self {
        case .unableToDecode(let filename):
            "Could not decode \(filename)."
        case .unableToRender:
            "Could not render a display preview."
        }
    }
}
