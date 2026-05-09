import AppKit
import SwiftUI

@MainActor
final class ViewerRenderModel: ObservableObject {
    @Published private(set) var status: ViewerRenderStatus = .empty
    @Published private(set) var image: NSImage?
    @Published private(set) var renderedFileID: String?
    @Published private(set) var displayProfile = ViewerDisplayProfile.current()

    private var currentFile: LocalImageFile?
    private var renderTask: Task<Void, Never>?

    func render(file: LocalImageFile?) {
        currentFile = file
        renderTask?.cancel()

        guard let file else {
            image = nil
            renderedFileID = nil
            status = .empty
            return
        }

        let fileID = file.id
        let url = file.url
        let profile = displayProfile

        image = nil
        renderedFileID = nil
        status = .loading

        renderTask = Task.detached(priority: .userInitiated) {
            do {
                let renderedImage = try ViewerImageRenderer.render(url: url, displayProfile: profile)

                guard !Task.isCancelled else {
                    return
                }

                await MainActor.run {
                    guard self.currentFile?.id == fileID else {
                        return
                    }

                    self.image = NSImage(
                        cgImage: renderedImage.cgImage,
                        size: NSSize(width: renderedImage.cgImage.width, height: renderedImage.cgImage.height)
                    )
                    self.renderedFileID = fileID
                    self.status = .ready(renderedImage)
                }
            } catch {
                guard !Task.isCancelled else {
                    return
                }

                await MainActor.run {
                    guard self.currentFile?.id == fileID else {
                        return
                    }

                    self.image = nil
                    self.renderedFileID = nil
                    self.status = .failed(error.localizedDescription)
                }
            }
        }
    }

    func updateDisplayProfile(colorSpace: NSColorSpace?, displayName: String?) {
        let nextProfile = ViewerDisplayProfile(colorSpace: colorSpace, displayName: displayName)

        guard nextProfile.identity != displayProfile.identity else {
            return
        }

        displayProfile = nextProfile
        render(file: currentFile)
    }

    func isReady(for file: LocalImageFile?) -> Bool {
        guard let file else {
            return false
        }

        return renderedFileID == file.id && status.isReady
    }
}

enum ViewerRenderStatus {
    case empty
    case loading
    case ready(RenderedViewerImage)
    case failed(String)

    var isReady: Bool {
        if case .ready = self {
            return true
        }

        return false
    }
}
