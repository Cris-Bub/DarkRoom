import CoreImage
import MetalKit
import SwiftUI

struct ViewerMetalImageView: NSViewRepresentable {
    let file: LocalImageFile
    let background: ViewerBackground
    let previewTarget: PreviewTarget
    let editRecipe: EditRecipe
    var toneTuning: ToneTuning = .defaultV1
    var behaviorTuning: BehaviorTuning?
    var toneOverlay: ToneRangeOverlay = .off
    let displayProfile: ViewerDisplayProfile
    let isInteractiveEditing: Bool
    let rawBaseline: RawBaseline = .darkRoomStandard

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: context.coordinator.device)
        view.delegate = context.coordinator
        view.framebufferOnly = false
        view.isPaused = true
        view.enableSetNeedsDisplay = false
        view.colorPixelFormat = .bgra8Unorm
        view.clearColor = background.clearColor

        return view
    }

    func updateNSView(_ nsView: MTKView, context: Context) {
        nsView.clearColor = background.clearColor
        context.coordinator.update(
            file: file,
            previewTarget: previewTarget,
            editRecipe: editRecipe,
            toneTuning: toneTuning,
            behaviorTuning: behaviorTuning,
            toneOverlay: toneOverlay,
            displayProfile: displayProfile,
            isInteractiveEditing: isInteractiveEditing,
            rawBaseline: rawBaseline,
            view: nsView
        )
    }

    @MainActor
    final class Coordinator: NSObject, MTKViewDelegate {
        let device: MTLDevice

        private let commandQueue: MTLCommandQueue
        private let ciContext: CIContext
        private let stateQueue = DispatchQueue(label: "dev.darkroom.viewer.metal.state")
        private var source: PipelinePreparedSource?
        private var sourceFileID: String?
        private var sourceTask: Task<Void, Never>?
        private var previewTarget: PreviewTarget = .webInstagram
        private var editRecipe: EditRecipe = .neutral
        private var toneTuning: ToneTuning = .defaultV1
        private var behaviorTuning: BehaviorTuning?
        private var toneOverlay: ToneRangeOverlay = .off
        private var displayProfile = ViewerDisplayProfile.current()
        private var isInteractiveEditing = false

        override init() {
            guard let device = MTLCreateSystemDefaultDevice(),
                  let commandQueue = device.makeCommandQueue() else {
                fatalError("Metal is required for the DarkRoom viewer.")
            }

            self.device = device
            self.commandQueue = commandQueue
            self.ciContext = CIContext(
                mtlDevice: device,
                options: [
                    .workingColorSpace: WorkingColorSpace.linearROMMRGB,
                    .workingFormat: CIFormat.RGBAh
                ]
            )

            super.init()
        }

        func update(
            file: LocalImageFile,
            previewTarget: PreviewTarget,
            editRecipe: EditRecipe,
            toneTuning: ToneTuning,
            behaviorTuning: BehaviorTuning?,
            toneOverlay: ToneRangeOverlay,
            displayProfile: ViewerDisplayProfile,
            isInteractiveEditing: Bool,
            rawBaseline: RawBaseline,
            view: MTKView
        ) {
            stateQueue.sync {
                self.previewTarget = previewTarget
                self.editRecipe = editRecipe
                self.toneTuning = toneTuning
                self.behaviorTuning = behaviorTuning
                self.toneOverlay = toneOverlay
                self.displayProfile = displayProfile
                self.isInteractiveEditing = isInteractiveEditing
            }

            prepareSourceIfNeeded(file: file, rawBaseline: rawBaseline, view: view)
            view.draw()
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            view.draw()
        }

        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let commandBuffer = commandQueue.makeCommandBuffer() else {
                return
            }

            clear(drawable: drawable, in: view, commandBuffer: commandBuffer)

            guard let renderState = stateQueue.sync(execute: currentRenderState(for: view)) else {
                commandBuffer.present(drawable)
                commandBuffer.commit()
                return
            }

            do {
                let image = try renderedImage(for: renderState)
                ciContext.render(
                    image,
                    to: drawable.texture,
                    commandBuffer: commandBuffer,
                    bounds: renderState.drawableBounds,
                    colorSpace: renderState.displayColorSpace
                )
            } catch {
                assertionFailure("Viewer Metal render failed: \(error.localizedDescription)")
            }

            commandBuffer.present(drawable)
            commandBuffer.commit()
        }

        private func prepareSourceIfNeeded(
            file: LocalImageFile,
            rawBaseline: RawBaseline,
            view: MTKView
        ) {
            let fileID = file.id
            let shouldLoad = stateQueue.sync {
                sourceFileID != fileID
            }

            guard shouldLoad else {
                return
            }

            stateQueue.sync {
                source = nil
                sourceFileID = nil
            }
            sourceTask?.cancel()

            let url = file.url
            sourceTask = Task { @MainActor in
                do {
                    let preparedSource = try await Task.detached(priority: .userInitiated) {
                        try ImagePipelineRenderer.prepareSource(
                            url: url,
                            rawBaseline: rawBaseline
                        )
                    }.value

                    guard !Task.isCancelled else {
                        return
                    }

                    self.stateQueue.sync {
                        self.source = preparedSource
                        self.sourceFileID = fileID
                    }
                    view.draw()
                } catch {
                    guard !Task.isCancelled else {
                        return
                    }

                    assertionFailure("Viewer source prepare failed: \(error.localizedDescription)")
                }
            }
        }

        private func currentRenderState(for view: MTKView) -> () -> RenderState? {
            {
                guard let source = self.source else {
                    return nil
                }

                let drawableSize = view.drawableSize
                guard drawableSize.width > 0, drawableSize.height > 0 else {
                    return nil
                }

                return RenderState(
                    source: source,
                    previewTarget: self.previewTarget,
                    editRecipe: self.editRecipe,
                    toneTuning: self.toneTuning,
                    behaviorTuning: self.behaviorTuning,
                    toneOverlay: self.toneOverlay,
                    displayColorSpace: self.displayProfile.colorSpace,
                    drawableBounds: CGRect(origin: .zero, size: drawableSize),
                    isInteractiveEditing: self.isInteractiveEditing
                )
            }
        }

        private func renderedImage(for state: RenderState) throws -> CIImage {
            let imageExtent = state.source.image.extent.integral
            guard !imageExtent.isEmpty else {
                throw ImagePipelineRenderError.unableToRender
            }

            let scale = min(
                state.drawableBounds.width / imageExtent.width,
                state.drawableBounds.height / imageExtent.height
            )
            let targetSize = CGSize(
                width: imageExtent.width * scale,
                height: imageExtent.height * scale
            )
            let targetOrigin = CGPoint(
                x: (state.drawableBounds.width - targetSize.width) / 2,
                y: (state.drawableBounds.height - targetSize.height) / 2
            )
            let maximumInteractiveLongEdge = 900.0
            let interactiveScale = state.isInteractiveEditing
                ? min(1, maximumInteractiveLongEdge / max(targetSize.width, targetSize.height))
                : 1
            let sourceToWorkingScale = scale * interactiveScale
            let sourceToWorkingTransform = CGAffineTransform(
                a: sourceToWorkingScale,
                b: 0,
                c: 0,
                d: sourceToWorkingScale,
                tx: -imageExtent.minX * sourceToWorkingScale,
                ty: -imageExtent.minY * sourceToWorkingScale
            )
            let workingSizedImage = state.source.image.transformed(by: sourceToWorkingTransform)
            let editedImage = try EditRecipeRenderer.apply(
                state.editRecipe,
                to: workingSizedImage,
                toneTuning: state.toneTuning,
                behaviorTuning: state.behaviorTuning,
                overlay: state.toneOverlay
            )

            guard interactiveScale < 1 else {
                return editedImage.transformed(
                    by: CGAffineTransform(translationX: targetOrigin.x, y: targetOrigin.y)
                )
            }

            return editedImage.transformed(
                by: CGAffineTransform(
                    a: 1 / interactiveScale,
                    b: 0,
                    c: 0,
                    d: 1 / interactiveScale,
                    tx: targetOrigin.x,
                    ty: targetOrigin.y
                )
            )
        }

        private func clear(
            drawable: CAMetalDrawable,
            in view: MTKView,
            commandBuffer: MTLCommandBuffer
        ) {
            guard let descriptor = MTLRenderPassDescriptor().configuredForClear(
                texture: drawable.texture,
                clearColor: view.clearColor
            ),
                  let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
                return
            }

            encoder.endEncoding()
        }
    }
}

private struct RenderState {
    let source: PipelinePreparedSource
    let previewTarget: PreviewTarget
    let editRecipe: EditRecipe
    let toneTuning: ToneTuning
    let behaviorTuning: BehaviorTuning?
    let toneOverlay: ToneRangeOverlay
    let displayColorSpace: CGColorSpace
    let drawableBounds: CGRect
    let isInteractiveEditing: Bool
}

private extension MTLRenderPassDescriptor {
    func configuredForClear(
        texture: MTLTexture,
        clearColor: MTLClearColor
    ) -> MTLRenderPassDescriptor? {
        guard let attachment = colorAttachments[0] else {
            return nil
        }

        attachment.texture = texture
        attachment.clearColor = clearColor
        attachment.loadAction = .clear
        attachment.storeAction = .store
        return self
    }
}

private extension ViewerBackground {
    var clearColor: MTLClearColor {
        switch self {
        case .black:
            MTLClearColorMake(0, 0, 0, 1)
        case .darkGray:
            MTLClearColorMake(0.13, 0.13, 0.13, 1)
        case .mediumGray:
            MTLClearColorMake(0.42, 0.42, 0.42, 1)
        case .lightGray:
            MTLClearColorMake(0.78, 0.78, 0.78, 1)
        case .white:
            MTLClearColorMake(1, 1, 1, 1)
        }
    }
}
