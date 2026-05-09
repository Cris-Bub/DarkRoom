import SwiftUI

struct RootView: View {
    @ObservedObject var library: FolderLibraryModel
    @ObservedObject var viewerRenderModel: ViewerRenderModel
    @Binding var viewerBackground: ViewerBackground

    var body: some View {
        NavigationSplitView {
            SidebarView(library: library)
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } content: {
            ViewerPane(
                file: library.selectedImage,
                background: viewerBackground,
                renderModel: viewerRenderModel
            )
                .navigationSplitViewColumnWidth(min: 560, ideal: 760)
        } detail: {
            InspectorView(
                selectedFile: library.selectedImage,
                viewerBackground: $viewerBackground,
                isReadOnly: !viewerRenderModel.isReady(for: library.selectedImage)
            )
                .navigationSplitViewColumnWidth(min: 320, ideal: 360, max: 440)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    library.openFolder()
                } label: {
                    Label("Open", systemImage: "folder.badge.plus")
                }
            }
        }
    }
}
