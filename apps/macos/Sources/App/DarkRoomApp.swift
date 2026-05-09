import SwiftUI

@main
struct DarkRoomApp: App {
    @StateObject private var library = FolderLibraryModel()
    @AppStorage("viewerBackground") private var viewerBackgroundRaw = ViewerBackground.darkGray.rawValue

    var body: some Scene {
        WindowGroup {
            RootView(
                library: library,
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
