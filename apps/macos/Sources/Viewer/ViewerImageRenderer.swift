import AppKit
import CoreImage
import ImageIO

enum ViewerImageRenderer {
    static func render(url: URL, displayProfile: ViewerDisplayProfile) throws -> RenderedViewerImage {
        if LocalImageFile.isRaw(url: url), let rawImage = try renderRawImageIfAvailable(url: url, displayProfile: displayProfile) {
            return rawImage
        }

        return try renderImageIOImage(url: url, displayProfile: displayProfile)
    }

    private static func renderRawImageIfAvailable(url: URL, displayProfile: ViewerDisplayProfile) throws -> RenderedViewerImage? {
        guard let rawFilter = CIRAWFilter(imageURL: url) else {
            return nil
        }

        rawFilter.isDraftModeEnabled = false
        rawFilter.scaleFactor = 1
        rawFilter.isGamutMappingEnabled = true
        rawFilter.extendedDynamicRangeAmount = 0

        if rawFilter.isLensCorrectionSupported {
            rawFilter.isLensCorrectionEnabled = true
        }

        guard let outputImage = rawFilter.outputImage else {
            throw ViewerRenderError.unableToDecode(url.lastPathComponent)
        }

        let cgImage = try render(
            outputImage,
            displayProfile: displayProfile,
            fallbackColorSpace: CGColorSpace(name: CGColorSpace.extendedLinearDisplayP3)
        )

        return RenderedViewerImage(
            cgImage: cgImage,
            sourceKind: .raw,
            displayProfileName: displayProfile.displayName
        )
    }

    private static func renderImageIOImage(url: URL, displayProfile: ViewerDisplayProfile) throws -> RenderedViewerImage {
        let options = [
            kCGImageSourceShouldCache: true,
            kCGImageSourceShouldCacheImmediately: true
        ] as CFDictionary

        guard let source = CGImageSourceCreateWithURL(url as CFURL, options),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, options) else {
            throw ViewerRenderError.unableToDecode(url.lastPathComponent)
        }

        let sourceColorSpace = cgImage.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!
        var ciImage = CIImage(cgImage: cgImage, options: [.colorSpace: sourceColorSpace as Any])

        if let orientation = imageOrientation(from: source) {
            ciImage = ciImage.oriented(forExifOrientation: Int32(orientation))
        }

        let renderedImage = try render(
            ciImage,
            displayProfile: displayProfile,
            fallbackColorSpace: sourceColorSpace
        )

        return RenderedViewerImage(
            cgImage: renderedImage,
            sourceKind: .raster,
            displayProfileName: displayProfile.displayName
        )
    }

    private static func render(
        _ image: CIImage,
        displayProfile: ViewerDisplayProfile,
        fallbackColorSpace: CGColorSpace?
    ) throws -> CGImage {
        let workingColorSpace = CGColorSpace(name: CGColorSpace.extendedLinearDisplayP3)
            ?? fallbackColorSpace
            ?? displayProfile.colorSpace

        let context = CIContext(options: [
            .workingColorSpace: workingColorSpace,
            .outputColorSpace: displayProfile.colorSpace,
            .workingFormat: CIFormat.RGBAh
        ])

        let extent = image.extent.integral
        guard !extent.isEmpty,
              let cgImage = context.createCGImage(
                image,
                from: extent,
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
}

struct RenderedViewerImage: @unchecked Sendable {
    let cgImage: CGImage
    let sourceKind: ViewerSourceKind
    let displayProfileName: String
}

enum ViewerSourceKind: Sendable {
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
