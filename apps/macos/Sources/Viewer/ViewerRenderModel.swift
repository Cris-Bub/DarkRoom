import AppKit
import SwiftUI

@MainActor
final class ViewerRenderModel: ObservableObject {
    @Published private(set) var status: ViewerRenderStatus = .empty
    @Published private(set) var image: NSImage?
    @Published private(set) var renderedFileID: String?
    @Published private(set) var displayProfile = ViewerDisplayProfile.current()
    @Published private(set) var renderedPreviewTarget: PreviewTarget?

    private var currentFile: LocalImageFile?
    private var currentPreviewTarget: PreviewTarget = .webInstagram
    private var currentEditRecipe: EditRecipe = .neutral
    private var currentRawBaseline: RawBaseline = .darkRoomStandard
    private var currentMaximumPixelSize: CGSize?
    private var renderWorkerTask: Task<Void, Never>?
    private var pendingRenderRequest: ViewerRenderRequest?
    private var preparedSource: PreparedViewerSource?
    private var preparedSourceFileID: String?
    private var preparedSourceRawBaseline: RawBaseline?
    private let contextProvider = ImagePipelineRenderContextProvider()

    func render(
        file: LocalImageFile?,
        previewTarget: PreviewTarget,
        editRecipe: EditRecipe,
        maximumPixelSize: CGSize? = nil,
        rawBaseline: RawBaseline = .darkRoomStandard
    ) {
        currentFile = file
        currentPreviewTarget = previewTarget
        currentEditRecipe = editRecipe
        currentRawBaseline = rawBaseline
        currentMaximumPixelSize = maximumPixelSize

        guard let file else {
            image = nil
            renderedFileID = nil
            renderedPreviewTarget = nil
            pendingRenderRequest = nil
            preparedSource = nil
            preparedSourceFileID = nil
            preparedSourceRawBaseline = nil
            status = .empty
            return
        }

        let fileID = file.id
        let url = file.url
        let profile = displayProfile
        let target = previewTarget
        let recipe = editRecipe
        let baseline = rawBaseline
        let requestedMaximumPixelSize = maximumPixelSize
        let shouldClearImage = renderedFileID != fileID || renderedPreviewTarget != target
        let cachedPreparedSource = preparedSourceFileID == fileID && preparedSourceRawBaseline == baseline
            ? preparedSource
            : nil
        let request = ViewerRenderRequest(
            fileID: fileID,
            url: url,
            displayProfile: profile,
            previewTarget: target,
            editRecipe: recipe,
            rawBaseline: baseline,
            maximumPixelSize: requestedMaximumPixelSize,
            cachedPreparedSource: cachedPreparedSource
        )

        if shouldClearImage {
            image = nil
            renderedFileID = nil
            renderedPreviewTarget = nil
        }

        if preparedSourceFileID != fileID || preparedSourceRawBaseline != baseline {
            preparedSource = nil
            preparedSourceFileID = nil
            preparedSourceRawBaseline = nil
        }

        status = .loading
        pendingRenderRequest = request
        startNextRenderIfNeeded()
    }

    private func startNextRenderIfNeeded() {
        guard renderWorkerTask == nil,
              let request = pendingRenderRequest else {
            return
        }

        pendingRenderRequest = nil
        let contextProvider = contextProvider

        renderWorkerTask = Task.detached(priority: .userInitiated) {
            let outcome = Self.render(request, contextProvider: contextProvider)

            await MainActor.run {
                self.finishRender(request, outcome: outcome)
            }
        }
    }

    nonisolated private static func render(
        _ request: ViewerRenderRequest,
        contextProvider: ImagePipelineRenderContextProvider
    ) -> ViewerRenderOutcome {
        do {
            let source: PreparedViewerSource
            if let cachedPreparedSource = request.cachedPreparedSource {
                source = cachedPreparedSource
            } else {
                source = try ViewerImageRenderer.prepareSource(
                    url: request.url,
                    rawBaseline: request.rawBaseline
                )
            }

            let renderedImage = try ViewerImageRenderer.render(
                preparedSource: source,
                displayProfile: request.displayProfile,
                previewTarget: request.previewTarget,
                editRecipe: request.editRecipe,
                maximumPixelSize: request.maximumPixelSize,
                contextProvider: contextProvider
            )

            return .rendered(renderedImage, source)
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    private func finishRender(_ request: ViewerRenderRequest, outcome: ViewerRenderOutcome) {
        defer {
            renderWorkerTask = nil
            startNextRenderIfNeeded()
        }

        guard currentFile?.id == request.fileID,
              currentPreviewTarget == request.previewTarget,
              currentEditRecipe == request.editRecipe,
              currentRawBaseline == request.rawBaseline,
              currentMaximumPixelSize == request.maximumPixelSize,
              displayProfile.identity == request.displayProfile.identity else {
            return
        }

        switch outcome {
        case .rendered(let renderedImage, let source):
            preparedSource = source
            preparedSourceFileID = request.fileID
            preparedSourceRawBaseline = request.rawBaseline
            image = NSImage(
                cgImage: renderedImage.cgImage,
                size: NSSize(width: renderedImage.cgImage.width, height: renderedImage.cgImage.height)
            )
            renderedFileID = request.fileID
            renderedPreviewTarget = request.previewTarget
            status = .ready(renderedImage)
        case .failed(let message):
            status = .failed(message)
        }
    }

    func updateDisplayProfile(colorSpace: NSColorSpace?, displayName: String?) {
        let nextProfile = ViewerDisplayProfile(colorSpace: colorSpace, displayName: displayName)

        guard nextProfile.identity != displayProfile.identity else {
            return
        }

        displayProfile = nextProfile
        render(
            file: currentFile,
            previewTarget: currentPreviewTarget,
            editRecipe: currentEditRecipe,
            maximumPixelSize: currentMaximumPixelSize,
            rawBaseline: currentRawBaseline
        )
    }

    func isReady(for file: LocalImageFile?, previewTarget: PreviewTarget) -> Bool {
        guard let file else {
            return false
        }

        return renderedFileID == file.id && status.isReady(for: previewTarget)
    }

    func hasDisplayableImage(for file: LocalImageFile?, previewTarget: PreviewTarget) -> Bool {
        guard let file,
              image != nil,
              renderedFileID == file.id,
              renderedPreviewTarget == previewTarget,
              !status.isFailed else {
            return false
        }

        return true
    }

    func canEdit(file: LocalImageFile?, previewTarget: PreviewTarget) -> Bool {
        hasDisplayableImage(for: file, previewTarget: previewTarget)
    }

    func isReady(
        for file: LocalImageFile?,
        previewTarget: PreviewTarget,
        editRecipe: EditRecipe
    ) -> Bool {
        guard let file else {
            return false
        }

        return renderedFileID == file.id && status.isReady(
            for: previewTarget,
            editRecipe: editRecipe
        )
    }
}

private struct ViewerRenderRequest: Sendable {
    let fileID: String
    let url: URL
    let displayProfile: ViewerDisplayProfile
    let previewTarget: PreviewTarget
    let editRecipe: EditRecipe
    let rawBaseline: RawBaseline
    let maximumPixelSize: CGSize?
    let cachedPreparedSource: PreparedViewerSource?
}

private enum ViewerRenderOutcome: Sendable {
    case rendered(RenderedViewerImage, PreparedViewerSource)
    case failed(String)
}

enum ViewerRenderStatus {
    case empty
    case loading
    case ready(RenderedViewerImage)
    case failed(String)

    func isReady(for previewTarget: PreviewTarget) -> Bool {
        if case .ready(let renderedImage) = self {
            return renderedImage.previewTarget == previewTarget
        }

        return false
    }

    func isReady(for previewTarget: PreviewTarget, editRecipe: EditRecipe) -> Bool {
        if case .ready(let renderedImage) = self {
            return renderedImage.previewTarget == previewTarget && renderedImage.editRecipe == editRecipe
        }

        return false
    }

    var isFailed: Bool {
        if case .failed = self {
            return true
        }

        return false
    }
}
