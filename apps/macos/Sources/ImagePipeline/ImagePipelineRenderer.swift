import AppKit
import CoreImage
import ImageIO

enum ImagePipelineRenderer {
    static func prepareSource(
        url: URL,
        rawBaseline: RawBaseline = .darkRoomStandard,
        rawDecoder: any RawDecoder = AppleRawDecoder()
    ) throws -> PipelinePreparedSource {
        try decodeSource(
            url: url,
            rawBaseline: rawBaseline,
            rawDecoder: rawDecoder
        )
    }

    static func renderDisplayPreview(
        url: URL,
        displayColorSpace: CGColorSpace,
        displayProfileName: String,
        previewTarget: PreviewTarget,
        editRecipe: EditRecipe,
        toneTuning: ToneTuning = .defaultV1,
        behaviorTuning: BehaviorTuning? = nil,
        toneOverlay: ToneRangeOverlay = .off,
        maximumPixelSize: CGSize? = nil,
        rawBaseline: RawBaseline = .darkRoomStandard,
        rawDecoder: any RawDecoder = AppleRawDecoder(),
        contextProvider: ImagePipelineRenderContextProvider = .shared
    ) throws -> PipelineRenderedImage {
        let source = try prepareSource(
            url: url,
            rawBaseline: rawBaseline,
            rawDecoder: rawDecoder
        )

        return try renderDisplayPreview(
            preparedSource: source,
            displayColorSpace: displayColorSpace,
            displayProfileName: displayProfileName,
            previewTarget: previewTarget,
            editRecipe: editRecipe,
            toneTuning: toneTuning,
            behaviorTuning: behaviorTuning,
            toneOverlay: toneOverlay,
            maximumPixelSize: maximumPixelSize,
            contextProvider: contextProvider
        )
    }

    static func renderDisplayPreview(
        preparedSource source: PipelinePreparedSource,
        displayColorSpace: CGColorSpace,
        displayProfileName: String,
        previewTarget: PreviewTarget,
        editRecipe: EditRecipe,
        toneTuning: ToneTuning = .defaultV1,
        behaviorTuning: BehaviorTuning? = nil,
        toneOverlay: ToneRangeOverlay = .off,
        maximumPixelSize: CGSize? = nil,
        contextProvider: ImagePipelineRenderContextProvider = .shared
    ) throws -> PipelineRenderedImage {
        let previewSourceImage = try scaledToFit(source.image, maximumPixelSize: maximumPixelSize)
        let editedImage = try EditRecipeRenderer.apply(
            editRecipe,
            to: previewSourceImage,
            toneTuning: toneTuning,
            behaviorTuning: behaviorTuning,
            overlay: toneOverlay
        )
        let proofedImage = try proof(
            editedImage,
            outputColorSpace: previewTarget.colorSpace,
            outputFormat: .RGBAh,
            contextProvider: contextProvider
        )

        let displayImage = CIImage(cgImage: proofedImage, options: [.colorSpace: previewTarget.colorSpace])
        let displayContext = contextProvider.displayContext(
            previewTargetColorSpace: previewTarget.colorSpace,
            displayColorSpace: displayColorSpace
        )

        guard let cgImage = displayContext.createCGImage(
            displayImage,
            from: displayImage.extent.integral,
            format: .RGBA16,
            colorSpace: displayColorSpace
        ) else {
            throw ImagePipelineRenderError.unableToRender
        }

        return PipelineRenderedImage(
            cgImage: cgImage,
            sourceKind: source.kind,
            sourceProfileName: source.profileName,
            sourceProfileWasAssumed: source.profileWasAssumed,
            previewTarget: previewTarget,
            rawBaseline: source.rawBaseline,
            editRecipe: editRecipe,
            workingColorSpaceName: WorkingColorSpace.displayName,
            displayProfileName: displayProfileName
        )
    }

    static func renderExport(
        url: URL,
        outputTarget: PreviewTarget,
        editRecipe: EditRecipe,
        toneTuning: ToneTuning = .defaultV1,
        behaviorTuning: BehaviorTuning? = nil,
        outputFormat: CIFormat,
        rawBaseline: RawBaseline = .darkRoomStandard,
        rawDecoder: any RawDecoder = AppleRawDecoder(),
        contextProvider: ImagePipelineRenderContextProvider = .shared
    ) throws -> PipelineRenderedImage {
        let source = try decodeSource(
            url: url,
            rawBaseline: rawBaseline,
            rawDecoder: rawDecoder
        )
        let editedImage = try EditRecipeRenderer.apply(
            editRecipe,
            to: source.image,
            toneTuning: toneTuning,
            behaviorTuning: behaviorTuning
        )
        let outputImage = try proof(
            editedImage,
            outputColorSpace: outputTarget.colorSpace,
            outputFormat: outputFormat,
            contextProvider: contextProvider
        )

        return PipelineRenderedImage(
            cgImage: outputImage,
            sourceKind: source.kind,
            sourceProfileName: source.profileName,
            sourceProfileWasAssumed: source.profileWasAssumed,
            previewTarget: outputTarget,
            rawBaseline: source.rawBaseline,
            editRecipe: editRecipe,
            workingColorSpaceName: WorkingColorSpace.displayName,
            displayProfileName: nil
        )
    }

    static func renderHistogramPreview(
        url: URL,
        previewTarget: PreviewTarget,
        editRecipe: EditRecipe,
        toneTuning: ToneTuning = .defaultV1,
        behaviorTuning: BehaviorTuning? = nil,
        maximumPixelSize: CGSize = CGSize(width: 256, height: 256),
        rawBaseline: RawBaseline = .darkRoomStandard,
        rawDecoder: any RawDecoder = AppleRawDecoder(),
        contextProvider: ImagePipelineRenderContextProvider = .shared
    ) throws -> PipelineRenderedImage {
        let source = try prepareSource(
            url: url,
            rawBaseline: rawBaseline,
            rawDecoder: rawDecoder
        )

        return try renderHistogramPreview(
            preparedSource: source,
            previewTarget: previewTarget,
            editRecipe: editRecipe,
            toneTuning: toneTuning,
            behaviorTuning: behaviorTuning,
            maximumPixelSize: maximumPixelSize,
            contextProvider: contextProvider
        )
    }

    static func renderHistogramPreview(
        preparedSource source: PipelinePreparedSource,
        previewTarget: PreviewTarget,
        editRecipe: EditRecipe,
        toneTuning: ToneTuning = .defaultV1,
        behaviorTuning: BehaviorTuning? = nil,
        maximumPixelSize: CGSize = CGSize(width: 256, height: 256),
        contextProvider: ImagePipelineRenderContextProvider = .shared
    ) throws -> PipelineRenderedImage {
        let previewSourceImage = try scaledToFit(source.image, maximumPixelSize: maximumPixelSize)
        let editedImage = try EditRecipeRenderer.apply(
            editRecipe,
            to: previewSourceImage,
            toneTuning: toneTuning,
            behaviorTuning: behaviorTuning
        )
        let outputImage = try proof(
            editedImage,
            outputColorSpace: previewTarget.colorSpace,
            outputFormat: .RGBA8,
            contextProvider: contextProvider
        )

        return PipelineRenderedImage(
            cgImage: outputImage,
            sourceKind: source.kind,
            sourceProfileName: source.profileName,
            sourceProfileWasAssumed: source.profileWasAssumed,
            previewTarget: previewTarget,
            rawBaseline: source.rawBaseline,
            editRecipe: editRecipe,
            workingColorSpaceName: WorkingColorSpace.displayName,
            displayProfileName: nil
        )
    }

    private static func decodeSource(
        url: URL,
        rawBaseline: RawBaseline,
        rawDecoder: any RawDecoder
    ) throws -> PipelinePreparedSource {
        if LocalImageFile.isRaw(url: url),
           rawDecoder.canDecode(fileURL: url) {
            let decodedImage = try rawDecoder.decode(
                fileURL: url,
                options: RawDecodeOptions(baseline: rawBaseline)
            )

            return PipelinePreparedSource(
                image: decodedImage.image,
                kind: .raw,
                profileName: decodedImage.metadata.sourceDescription,
                profileWasAssumed: false,
                rawBaseline: rawBaseline
            )
        }

        return try decodeRasterSource(url: url)
    }

    private static func decodeRasterSource(url: URL) throws -> PipelinePreparedSource {
        let options = [
            kCGImageSourceShouldCache: true,
            kCGImageSourceShouldCacheImmediately: true
        ] as CFDictionary

        guard let source = CGImageSourceCreateWithURL(url as CFURL, options),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, options) else {
            throw ImagePipelineRenderError.unableToDecode(url.lastPathComponent)
        }

        let sourceProfileWasAssumed = cgImage.colorSpace == nil
        let sourceColorSpace = cgImage.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!
        var ciImage = CIImage(cgImage: cgImage, options: [.colorSpace: sourceColorSpace as Any])

        if let orientation = imageOrientation(from: source) {
            ciImage = ciImage.oriented(forExifOrientation: Int32(orientation))
        }

        return PipelinePreparedSource(
            image: ciImage,
            kind: .raster,
            profileName: colorSpaceName(sourceColorSpace),
            profileWasAssumed: sourceProfileWasAssumed,
            rawBaseline: nil
        )
    }

    private static func proof(
        _ image: CIImage,
        outputColorSpace: CGColorSpace,
        outputFormat: CIFormat,
        contextProvider: ImagePipelineRenderContextProvider
    ) throws -> CGImage {
        let context = contextProvider.proofContext(outputColorSpace: outputColorSpace)

        let extent = image.extent.integral
        guard !extent.isEmpty,
              let proofedImage = context.createCGImage(
                image,
                from: extent,
                format: outputFormat,
                colorSpace: outputColorSpace
              ) else {
            throw ImagePipelineRenderError.unableToRender
        }

        return proofedImage
    }

    private static func scaledToFit(_ image: CIImage, maximumPixelSize: CGSize?) throws -> CIImage {
        guard let maximumPixelSize,
              maximumPixelSize.width > 0,
              maximumPixelSize.height > 0 else {
            return image
        }

        let extent = image.extent.integral
        guard !extent.isEmpty else {
            throw ImagePipelineRenderError.unableToRender
        }

        let scale = min(
            1,
            maximumPixelSize.width / extent.width,
            maximumPixelSize.height / extent.height
        )

        guard scale < 1 else {
            return image
        }

        return image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
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

struct PipelineRenderedImage: @unchecked Sendable {
    let cgImage: CGImage
    let sourceKind: PipelineSourceKind
    let sourceProfileName: String
    let sourceProfileWasAssumed: Bool
    let previewTarget: PreviewTarget
    let rawBaseline: RawBaseline?
    let editRecipe: EditRecipe
    let workingColorSpaceName: String
    let displayProfileName: String?
}

enum PipelineSourceKind: Sendable, Equatable {
    case raw
    case raster
}

struct PipelinePreparedSource: @unchecked Sendable {
    let image: CIImage
    let kind: PipelineSourceKind
    let profileName: String
    let profileWasAssumed: Bool
    let rawBaseline: RawBaseline?
}

final class ImagePipelineRenderContextProvider: @unchecked Sendable {
    static let shared = ImagePipelineRenderContextProvider()

    private let lock = NSLock()
    private var proofContexts: [String: CIContext] = [:]
    private var displayContexts: [String: CIContext] = [:]

    func proofContext(outputColorSpace: CGColorSpace) -> CIContext {
        let key = colorSpaceKey(outputColorSpace)

        lock.lock()
        defer {
            lock.unlock()
        }

        if let context = proofContexts[key] {
            return context
        }

        let context = CIContext(options: [
            .workingColorSpace: WorkingColorSpace.linearROMMRGB,
            .outputColorSpace: outputColorSpace,
            .workingFormat: CIFormat.RGBAh
        ])
        proofContexts[key] = context
        return context
    }

    func displayContext(
        previewTargetColorSpace: CGColorSpace,
        displayColorSpace: CGColorSpace
    ) -> CIContext {
        let key = [
            colorSpaceKey(previewTargetColorSpace),
            colorSpaceKey(displayColorSpace)
        ].joined(separator: "->")

        lock.lock()
        defer {
            lock.unlock()
        }

        if let context = displayContexts[key] {
            return context
        }

        let context = CIContext(options: [
            .workingColorSpace: previewTargetColorSpace,
            .outputColorSpace: displayColorSpace,
            .workingFormat: CIFormat.RGBAh
        ])
        displayContexts[key] = context
        return context
    }

    private func colorSpaceKey(_ colorSpace: CGColorSpace) -> String {
        if let name = colorSpace.name as String? {
            return name
        }

        if let data = colorSpace.copyICCData() as Data? {
            return "icc:\(data.count):\(data.hashValue)"
        }

        return "unnamed"
    }
}

enum ImagePipelineRenderError: LocalizedError {
    case unableToDecode(String)
    case unableToRender
    case unableToCreateEditKernel
    case unableToApplyEditRecipe

    var errorDescription: String? {
        switch self {
        case .unableToDecode(let filename):
            "Could not decode \(filename)."
        case .unableToRender:
            "Could not render the image."
        case .unableToCreateEditKernel:
            "Could not create the light adjustment kernel."
        case .unableToApplyEditRecipe:
            "Could not apply the edit recipe."
        }
    }
}
