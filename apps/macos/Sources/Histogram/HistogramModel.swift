import CoreGraphics
import Foundation
import SwiftUI

@MainActor
final class HistogramModel: ObservableObject {
    @Published private(set) var status: HistogramStatus = .empty

    private var currentRequestID: HistogramRequestID?

    private var preparedSource: PipelinePreparedSource?
    private var preparedSourceFileID: String?
    private var preparedSourceRawBaseline: RawBaseline?

    private var settledWorkerTask: Task<Void, Never>?
    private var pendingSettledRequest: SettledHistogramRequest?

    private var fastWorkerTask: Task<Void, Never>?
    private var pendingFastRequest: FastHistogramRequest?

    private var neutralCache: NeutralHistogramBuffer?
    private var neutralCacheTask: Task<Void, Never>?

    private let contextProvider = ImagePipelineRenderContextProvider()
    private let interactiveMaximumPixelSize = CGSize(width: 128, height: 128)
    private let settledMaximumPixelSize = CGSize(width: 256, height: 256)

    func update(
        file: LocalImageFile?,
        previewTarget: PreviewTarget,
        editRecipe: EditRecipe,
        isInteractive: Bool = false,
        rawBaseline: RawBaseline = .darkRoomStandard
    ) {
        guard let file else {
            cancelAllWork()
            currentRequestID = nil
            preparedSource = nil
            preparedSourceFileID = nil
            preparedSourceRawBaseline = nil
            neutralCache = nil
            status = .empty
            return
        }

        let requestID = HistogramRequestID(
            fileID: file.id,
            previewTarget: previewTarget,
            editRecipe: editRecipe,
            isInteractive: isInteractive,
            rawBaseline: rawBaseline
        )

        guard requestID != currentRequestID else {
            return
        }

        let imageContextChanged = currentRequestID == nil
            || currentRequestID?.fileID != file.id
            || currentRequestID?.previewTarget.rawValue != previewTarget.rawValue
            || currentRequestID?.rawBaseline.rawValue != rawBaseline.rawValue

        currentRequestID = requestID

        if preparedSourceFileID != file.id
            || preparedSourceRawBaseline?.rawValue != rawBaseline.rawValue {
            preparedSource = nil
            preparedSourceFileID = nil
            preparedSourceRawBaseline = nil
        }

        if neutralCache?.fileID != file.id
            || neutralCache?.previewTargetRawValue != previewTarget.rawValue
            || neutralCache?.rawBaselineRawValue != rawBaseline.rawValue {
            neutralCache = nil
            neutralCacheTask?.cancel()
            neutralCacheTask = nil
        }

        if neutralCache == nil && neutralCacheTask == nil {
            spawnNeutralCacheTask(
                file: file,
                previewTarget: previewTarget,
                rawBaseline: rawBaseline
            )
        }

        if isInteractive, let cache = neutralCache {
            scheduleFastRender(
                cache: cache,
                requestID: requestID,
                light: editRecipe.light
            )
            return
        }

        if imageContextChanged && !status.hasReadyHistogram {
            status = .loading
        } else if !status.hasReadyHistogram {
            status = .loading
        }

        let request = SettledHistogramRequest(
            id: requestID,
            url: file.url,
            maximumPixelSize: settledMaximumPixelSize,
            cachedPreparedSource: preparedSource
        )

        pendingSettledRequest = request
        startNextSettledIfNeeded()
    }

    private func cancelAllWork() {
        settledWorkerTask?.cancel()
        settledWorkerTask = nil
        pendingSettledRequest = nil
        fastWorkerTask?.cancel()
        fastWorkerTask = nil
        pendingFastRequest = nil
        neutralCacheTask?.cancel()
        neutralCacheTask = nil
    }

    // MARK: - Neutral cache

    private func spawnNeutralCacheTask(
        file: LocalImageFile,
        previewTarget: PreviewTarget,
        rawBaseline: RawBaseline
    ) {
        let url = file.url
        let fileID = file.id
        let target = previewTarget
        let baseline = rawBaseline
        let interactiveSize = interactiveMaximumPixelSize
        let contextProvider = contextProvider
        let cachedSource: PipelinePreparedSource? =
            (preparedSourceFileID == fileID
                && preparedSourceRawBaseline?.rawValue == baseline.rawValue)
                ? preparedSource
                : nil

        neutralCacheTask = Task.detached(priority: .userInitiated) {
            let outcome = Self.buildNeutralCache(
                url: url,
                fileID: fileID,
                previewTarget: target,
                rawBaseline: baseline,
                maximumPixelSize: interactiveSize,
                cachedPreparedSource: cachedSource,
                contextProvider: contextProvider
            )

            await MainActor.run {
                self.finishNeutralCache(outcome: outcome)
            }
        }
    }

    nonisolated private static func buildNeutralCache(
        url: URL,
        fileID: String,
        previewTarget: PreviewTarget,
        rawBaseline: RawBaseline,
        maximumPixelSize: CGSize,
        cachedPreparedSource: PipelinePreparedSource?,
        contextProvider: ImagePipelineRenderContextProvider
    ) -> NeutralHistogramOutcome {
        do {
            let source: PipelinePreparedSource
            if let cachedPreparedSource {
                source = cachedPreparedSource
            } else {
                source = try ImagePipelineRenderer.prepareSource(
                    url: url,
                    rawBaseline: rawBaseline
                )
            }

            let rendered = try ImagePipelineRenderer.renderHistogramPreview(
                preparedSource: source,
                previewTarget: previewTarget,
                editRecipe: .neutral,
                maximumPixelSize: maximumPixelSize,
                contextProvider: contextProvider
            )

            let extracted = try Self.extractRGBA8(from: rendered.cgImage)
            let buffer = NeutralHistogramBuffer(
                pixels: extracted.pixels,
                pixelCount: extracted.pixelCount,
                fileID: fileID,
                previewTargetRawValue: previewTarget.rawValue,
                rawBaselineRawValue: rawBaseline.rawValue
            )

            return .built(buffer, source)
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    nonisolated private static func extractRGBA8(
        from image: CGImage
    ) throws -> (pixels: [UInt8], pixelCount: Int) {
        let width = image.width
        let height = image.height

        guard width > 0, height > 0 else {
            throw HistogramError.emptyImage
        }

        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let colorSpace = image.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
            | CGBitmapInfo.byteOrder32Big.rawValue

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            throw HistogramError.unableToReadPixels
        }

        context.interpolationQuality = .none
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        return (pixels, width * height)
    }

    private func finishNeutralCache(outcome: NeutralHistogramOutcome) {
        defer {
            neutralCacheTask = nil
        }

        switch outcome {
        case .built(let buffer, let source):
            preparedSource = source
            preparedSourceFileID = buffer.fileID
            if let baseline = RawBaseline(rawValue: buffer.rawBaselineRawValue) {
                preparedSourceRawBaseline = baseline
            }
            neutralCache = buffer

            if let requestID = currentRequestID,
               requestID.isInteractive,
               requestID.fileID == buffer.fileID,
               requestID.previewTarget.rawValue == buffer.previewTargetRawValue,
               requestID.rawBaseline.rawValue == buffer.rawBaselineRawValue {
                scheduleFastRender(
                    cache: buffer,
                    requestID: requestID,
                    light: requestID.editRecipe.light
                )
            }
        case .failed:
            break
        }
    }

    // MARK: - Fast interactive path

    private func scheduleFastRender(
        cache: NeutralHistogramBuffer,
        requestID: HistogramRequestID,
        light: LightAdjustments
    ) {
        pendingFastRequest = FastHistogramRequest(
            id: requestID,
            cache: cache,
            light: light
        )
        startNextFastIfNeeded()
    }

    private func startNextFastIfNeeded() {
        guard fastWorkerTask == nil,
              let request = pendingFastRequest else {
            return
        }
        pendingFastRequest = nil

        fastWorkerTask = Task.detached(priority: .userInitiated) {
            let histogram = Self.runFast(request)

            await MainActor.run {
                self.finishFast(request: request, histogram: histogram)
            }
        }
    }

    nonisolated private static func runFast(_ request: FastHistogramRequest) -> ImageHistogram? {
        do {
            return try DarkroomCoreHistogramMath.makeHistogramApplyingRecipe(
                rgbaPixels: request.cache.pixels,
                pixelCount: request.cache.pixelCount,
                light: request.light
            )
        } catch {
            return nil
        }
    }

    private func finishFast(request: FastHistogramRequest, histogram: ImageHistogram?) {
        defer {
            fastWorkerTask = nil
            startNextFastIfNeeded()
        }

        guard currentRequestID == request.id, let histogram else {
            return
        }

        status = .ready(histogram)
    }

    // MARK: - Settled (full pipeline) path

    private func startNextSettledIfNeeded() {
        guard settledWorkerTask == nil,
              var request = pendingSettledRequest else {
            return
        }

        if request.cachedPreparedSource == nil,
           preparedSourceFileID == request.id.fileID,
           preparedSourceRawBaseline?.rawValue == request.id.rawBaseline.rawValue {
            request.cachedPreparedSource = preparedSource
        }

        pendingSettledRequest = nil
        let contextProvider = contextProvider

        settledWorkerTask = Task.detached(priority: .userInitiated) {
            let outcome = Self.runSettled(request, contextProvider: contextProvider)

            await MainActor.run {
                self.finishSettled(request, outcome: outcome)
            }
        }
    }

    nonisolated private static func runSettled(
        _ request: SettledHistogramRequest,
        contextProvider: ImagePipelineRenderContextProvider
    ) -> SettledHistogramOutcome {
        do {
            let source: PipelinePreparedSource
            if let cachedPreparedSource = request.cachedPreparedSource {
                source = cachedPreparedSource
            } else {
                source = try ImagePipelineRenderer.prepareSource(
                    url: request.url,
                    rawBaseline: request.id.rawBaseline
                )
            }

            guard !Task.isCancelled else {
                return .cancelled
            }

            let renderedImage = try ImagePipelineRenderer.renderHistogramPreview(
                preparedSource: source,
                previewTarget: request.id.previewTarget,
                editRecipe: request.id.editRecipe,
                maximumPixelSize: request.maximumPixelSize,
                contextProvider: contextProvider
            )
            let histogram = try HistogramCalculator.makeHistogram(from: renderedImage.cgImage)

            guard !Task.isCancelled else {
                return .cancelled
            }

            return .rendered(histogram, source)
        } catch {
            guard !Task.isCancelled else {
                return .cancelled
            }

            return .failed(error.localizedDescription)
        }
    }

    private func finishSettled(_ request: SettledHistogramRequest, outcome: SettledHistogramOutcome) {
        defer {
            settledWorkerTask = nil
            startNextSettledIfNeeded()
        }

        if case .rendered(_, let source) = outcome,
           currentRequestID?.fileID == request.id.fileID,
           currentRequestID?.rawBaseline.rawValue == request.id.rawBaseline.rawValue {
            preparedSource = source
            preparedSourceFileID = request.id.fileID
            preparedSourceRawBaseline = request.id.rawBaseline
        }

        guard currentRequestID == request.id else {
            return
        }

        switch outcome {
        case .rendered(let histogram, _):
            status = .ready(histogram)
        case .failed(let message):
            status = .failed(message)
        case .cancelled:
            break
        }
    }
}

private struct HistogramRequestID: Equatable, Sendable {
    let fileID: String
    let previewTarget: PreviewTarget
    let editRecipe: EditRecipe
    let isInteractive: Bool
    let rawBaseline: RawBaseline

    static func == (lhs: HistogramRequestID, rhs: HistogramRequestID) -> Bool {
        lhs.fileID == rhs.fileID
            && lhs.previewTarget.rawValue == rhs.previewTarget.rawValue
            && lhs.editRecipe == rhs.editRecipe
            && lhs.isInteractive == rhs.isInteractive
            && lhs.rawBaseline.rawValue == rhs.rawBaseline.rawValue
    }
}

private struct NeutralHistogramBuffer: Sendable {
    let pixels: [UInt8]
    let pixelCount: Int
    let fileID: String
    let previewTargetRawValue: String
    let rawBaselineRawValue: String
}

private enum NeutralHistogramOutcome: @unchecked Sendable {
    case built(NeutralHistogramBuffer, PipelinePreparedSource)
    case failed(String)
}

private struct FastHistogramRequest: Sendable {
    let id: HistogramRequestID
    let cache: NeutralHistogramBuffer
    let light: LightAdjustments
}

private struct SettledHistogramRequest: @unchecked Sendable {
    let id: HistogramRequestID
    let url: URL
    let maximumPixelSize: CGSize
    var cachedPreparedSource: PipelinePreparedSource?
}

private enum SettledHistogramOutcome: @unchecked Sendable {
    case rendered(ImageHistogram, PipelinePreparedSource)
    case failed(String)
    case cancelled
}

private extension HistogramStatus {
    var hasReadyHistogram: Bool {
        if case .ready = self {
            return true
        }

        return false
    }
}
