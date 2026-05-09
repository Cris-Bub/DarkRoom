import SwiftUI

struct SidebarView: View {
    @ObservedObject var library: FolderLibraryModel

    var body: some View {
        VStack(spacing: 0) {
            if let sourceTitle = library.sourceTitle {
                DRPanelHeader(title: sourceTitle)
            }

            List(selection: selectedImageID) {
                ForEach(library.images) { file in
                    Text(file.displayName)
                        .lineLimit(1)
                        .tag(file.id)
                }
            }

            if library.images.isEmpty {
                DREmptyState(
                    systemImage: DarkRoomDesign.Icon.emptyLibrary,
                    title: "No Images",
                    message: library.lastError,
                    actionTitle: "Open Images or Folder",
                    action: library.openFolder
                )
            }
        }
    }

    private var selectedImageID: Binding<String?> {
        Binding(
            get: { library.selectedImage?.id },
            set: { id in
                library.selectedImage = library.images.first { $0.id == id }
            }
        )
    }
}
