import AppKit

enum ViewerImageRenderer {
    static func prepareSource(
        url: URL,
        rawBaseline: RawBaseline = .darkRoomStandard,
        rawDecoder: any RawDecoder = AppleRawDecoder()
    ) throws -> PreparedViewerSource {
        let preparedSource = try ImagePipelineRenderer.prepareSource(
            url: url,
            rawBaseline: rawBaseline,
            rawDecoder: rawDecoder
        )

        return PreparedViewerSource(pipelineSource: preparedSource)
    }

    static func render(
        url: URL,
        displayProfile: ViewerDisplayProfile,
        previewTarget: PreviewTarget,
        editRecipe: EditRecipe = .neutral,
        maximumPixelSize: CGSize? = nil,
        rawBaseline: RawBaseline = .darkRoomStandard,
        rawDecoder: any RawDecoder = AppleRawDecoder(),
        contextProvider: ImagePipelineRenderContextProvider = .shared
    ) throws -> RenderedViewerImage {
        let renderedImage = try ImagePipelineRenderer.renderDisplayPreview(
            url: url,
            displayColorSpace: displayProfile.colorSpace,
            displayProfileName: displayProfile.displayName,
            previewTarget: previewTarget,
            editRecipe: editRecipe,
            maximumPixelSize: maximumPixelSize,
            rawBaseline: rawBaseline,
            rawDecoder: rawDecoder,
            contextProvider: contextProvider
        )

        return renderedViewerImage(
            from: renderedImage,
            fallbackDisplayProfileName: displayProfile.displayName
        )
    }

    static func render(
        preparedSource: PreparedViewerSource,
        displayProfile: ViewerDisplayProfile,
        previewTarget: PreviewTarget,
        editRecipe: EditRecipe = .neutral,
        maximumPixelSize: CGSize? = nil,
        contextProvider: ImagePipelineRenderContextProvider = .shared
    ) throws -> RenderedViewerImage {
        let renderedImage = try ImagePipelineRenderer.renderDisplayPreview(
            preparedSource: preparedSource.pipelineSource,
            displayColorSpace: displayProfile.colorSpace,
            displayProfileName: displayProfile.displayName,
            previewTarget: previewTarget,
            editRecipe: editRecipe,
            maximumPixelSize: maximumPixelSize,
            contextProvider: contextProvider
        )

        return renderedViewerImage(
            from: renderedImage,
            fallbackDisplayProfileName: displayProfile.displayName
        )
    }

    private static func renderedViewerImage(
        from renderedImage: PipelineRenderedImage,
        fallbackDisplayProfileName: String
    ) -> RenderedViewerImage {
        return RenderedViewerImage(
            cgImage: renderedImage.cgImage,
            sourceKind: ViewerSourceKind(pipelineSourceKind: renderedImage.sourceKind),
            sourceProfileName: renderedImage.sourceProfileName,
            sourceProfileWasAssumed: renderedImage.sourceProfileWasAssumed,
            previewTarget: renderedImage.previewTarget,
            rawBaseline: renderedImage.rawBaseline,
            editRecipe: renderedImage.editRecipe,
            workingColorSpaceName: renderedImage.workingColorSpaceName,
            displayProfileName: renderedImage.displayProfileName ?? fallbackDisplayProfileName
        )
    }
}

struct PreparedViewerSource: @unchecked Sendable {
    fileprivate let pipelineSource: PipelinePreparedSource
}

struct RenderedViewerImage: @unchecked Sendable {
    let cgImage: CGImage
    let sourceKind: ViewerSourceKind
    let sourceProfileName: String
    let sourceProfileWasAssumed: Bool
    let previewTarget: PreviewTarget
    let rawBaseline: RawBaseline?
    let editRecipe: EditRecipe
    let workingColorSpaceName: String
    let displayProfileName: String
}

enum ViewerSourceKind: Sendable, Equatable {
    case raw
    case raster

    init(pipelineSourceKind: PipelineSourceKind) {
        switch pipelineSourceKind {
        case .raw:
            self = .raw
        case .raster:
            self = .raster
        }
    }
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
