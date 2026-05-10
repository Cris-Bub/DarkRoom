import SwiftUI

struct RootView: View {
    @ObservedObject var library: FolderLibraryModel
    @ObservedObject var viewerRenderModel: ViewerRenderModel
    @ObservedObject var editSession: EditSessionModel
    @ObservedObject var exportModel: ImageExportModel
    @ObservedObject var histogramModel: HistogramModel
    @Binding var previewTarget: PreviewTarget
    @Binding var viewerBackground: ViewerBackground
    @State private var isInteractiveEditing = false

    var body: some View {
        let currentRecipe = editSession.recipe(for: library.selectedImage)
        let histogramRequestID = RootHistogramRequestID(
            fileID: library.selectedImage?.id,
            previewTarget: previewTarget,
            editRecipe: currentRecipe,
            isInteractiveEditing: isInteractiveEditing
        )

        NavigationSplitView {
            SidebarView(library: library)
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } content: {
            ViewerPane(
                file: library.selectedImage,
                background: viewerBackground,
                previewTarget: previewTarget,
                editRecipe: currentRecipe,
                isInteractiveEditing: isInteractiveEditing,
                renderModel: viewerRenderModel
            )
                .navigationSplitViewColumnWidth(min: 560, ideal: 760)
        } detail: {
            InspectorView(
                selectedFile: library.selectedImage,
                previewTarget: $previewTarget,
                viewerBackground: $viewerBackground,
                editRecipe: editSession.binding(for: library.selectedImage),
                histogramStatus: histogramModel.status,
                isReadOnly: !viewerRenderModel.canEdit(
                    file: library.selectedImage,
                    previewTarget: previewTarget
                ),
                onAdjustmentEditingChanged: { isEditing in
                    isInteractiveEditing = isEditing
                    guard !isEditing else {
                        return
                    }

                    let selectedImage = library.selectedImage
                    Task {
                        await editSession.flushPendingPersistence(for: selectedImage)
                    }
                },
                onResetEdits: {
                    editSession.reset(file: library.selectedImage)
                }
            )
                .navigationSplitViewColumnWidth(min: 320, ideal: 360, max: 440)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if let exportLabel = exportModel.status.label {
                    HStack(spacing: DarkRoomDesign.Spacing.small) {
                        if exportModel.isExporting {
                            ProgressView()
                                .controlSize(.small)
                        }

                        Text(exportLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Button {
                    exportModel.export(
                        file: library.selectedImage,
                        editRecipe: currentRecipe,
                        outputTarget: previewTarget
                    )
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .disabled(library.selectedImage == nil || exportModel.isExporting)

                Button {
                    library.openFolder()
                } label: {
                    Label("Open", systemImage: "folder.badge.plus")
                }
            }
        }
        .alert(item: $exportModel.alert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            histogramModel.update(
                file: library.selectedImage,
                previewTarget: previewTarget,
                editRecipe: currentRecipe,
                isInteractive: isInteractiveEditing
            )
        }
        .onChange(of: histogramRequestID) { _, _ in
            histogramModel.update(
                file: library.selectedImage,
                previewTarget: previewTarget,
                editRecipe: currentRecipe,
                isInteractive: isInteractiveEditing
            )
        }
    }
}

private struct RootHistogramRequestID: Equatable {
    let fileID: String?
    let previewTarget: PreviewTarget
    let editRecipe: EditRecipe
    let isInteractiveEditing: Bool

    static func == (lhs: RootHistogramRequestID, rhs: RootHistogramRequestID) -> Bool {
        lhs.fileID == rhs.fileID
            && lhs.previewTarget.rawValue == rhs.previewTarget.rawValue
            && lhs.editRecipe == rhs.editRecipe
            && lhs.isInteractiveEditing == rhs.isInteractiveEditing
    }
}
