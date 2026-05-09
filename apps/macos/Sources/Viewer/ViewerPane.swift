import AppKit
import SwiftUI

struct ViewerPane: View {
    let file: LocalImageFile?
    let background: ViewerBackground
    @ObservedObject var renderModel: ViewerRenderModel

    var body: some View {
        ZStack {
            background.color
                .ignoresSafeArea()

            if let image = renderModel.image, renderModel.isReady(for: file) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(DarkRoomDesign.Spacing.viewerPadding)
            } else if file != nil, case .loading = renderModel.status {
                ProgressView()
                    .controlSize(.small)
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
        .task(id: file?.id) {
            renderModel.render(file: file)
        }
    }
}
