import SwiftUI

struct RootView: View {
    @ObservedObject var library: FolderLibraryModel
    @Binding var viewerBackground: ViewerBackground

    var body: some View {
        NavigationSplitView {
            SidebarView(library: library)
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } content: {
            ViewerPane(file: library.selectedImage, background: viewerBackground)
                .navigationSplitViewColumnWidth(min: 560, ideal: 760)
        } detail: {
            InspectorView(selectedFile: library.selectedImage, viewerBackground: $viewerBackground)
                .navigationSplitViewColumnWidth(min: 260, ideal: 300, max: 360)
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
