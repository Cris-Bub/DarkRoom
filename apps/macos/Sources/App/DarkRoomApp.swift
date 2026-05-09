import SwiftUI

@main
struct DarkRoomApp: App {
    @StateObject private var library = FolderLibraryModel()
    @StateObject private var viewerRenderModel = ViewerRenderModel()
    @AppStorage("viewerBackground") private var viewerBackgroundRaw = ViewerBackground.darkGray.rawValue
    @AppStorage("previewTarget") private var previewTargetRaw = PreviewTarget.webInstagram.rawValue

    var body: some Scene {
        WindowGroup {
            RootView(
                library: library,
                viewerRenderModel: viewerRenderModel,
                previewTarget: Binding(
                    get: { PreviewTarget(rawValue: previewTargetRaw) ?? .webInstagram },
                    set: { previewTargetRaw = $0.rawValue }
                ),
                viewerBackground: Binding(
                    get: { ViewerBackground(rawValue: viewerBackgroundRaw) ?? .darkGray },
                    set: { viewerBackgroundRaw = $0.rawValue }
                )
            )
            .frame(minWidth: 1120, minHeight: 720)
        }
        .windowStyle(.titleBar)
    }
}
