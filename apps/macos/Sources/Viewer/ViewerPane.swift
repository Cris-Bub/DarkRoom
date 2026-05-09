import AppKit
import SwiftUI

struct ViewerPane: View {
    let file: LocalImageFile?
    let background: ViewerBackground
    let previewTarget: PreviewTarget
    let editRecipe: EditRecipe
    let isInteractiveEditing: Bool
    @ObservedObject var renderModel: ViewerRenderModel

    var body: some View {
        GeometryReader { _ in
            ZStack {
                background.color
                    .ignoresSafeArea()

                if let file {
                    ViewerMetalImageView(
                        file: file,
                        background: background,
                        previewTarget: previewTarget,
                        editRecipe: editRecipe,
                        displayProfile: renderModel.displayProfile,
                        isInteractiveEditing: isInteractiveEditing
                    )
                        .padding(DarkRoomDesign.Spacing.viewerPadding)
                } else if case .failed(let message) = renderModel.status {
                    VStack(spacing: DarkRoomDesign.Spacing.small) {
                        DRPlaceholderText(text: "Preview Unavailable")

                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    DRPlaceholderText(text: "Select an Image")
                }
            }
            .background(
                ViewerDisplayProfileReader { window in
                    renderModel.updateDisplayProfile(
                        colorSpace: window?.colorSpace ?? window?.screen?.colorSpace,
                        displayName: window?.screen?.localizedName
                    )
                }
            )
            .task(id: readinessRequestID) {
                renderModel.render(
                    file: file,
                    previewTarget: previewTarget,
                    editRecipe: editRecipe,
                    maximumPixelSize: CGSize(width: 256, height: 256)
                )
            }
        }
    }

    private var readinessRequestID: ViewerReadinessRequestID {
        ViewerReadinessRequestID(
            fileID: file?.id,
            previewTarget: previewTarget
        )
    }
}

private struct ViewerReadinessRequestID: Equatable {
    let fileID: String?
    let previewTarget: PreviewTarget
}
