import SwiftUI

@main
struct DarkRoomApp: App {
    @StateObject private var library = FolderLibraryModel()
    @StateObject private var viewerRenderModel = ViewerRenderModel()
    @StateObject private var editSession = EditSessionModel()
    @StateObject private var exportModel = ImageExportModel()
    @StateObject private var histogramModel = HistogramModel()
    @AppStorage("viewerBackground") private var viewerBackgroundRaw = ViewerBackground.darkGray.rawValue
    @AppStorage("previewTarget") private var previewTargetRaw = PreviewTarget.webInstagram.rawValue

    var body: some Scene {
        mainWindow

        #if DEBUG
        toneLabWindow
        #endif
    }

    private var mainWindow: some Scene {
        WindowGroup {
            RootView(
                library: library,
                viewerRenderModel: viewerRenderModel,
                editSession: editSession,
                exportModel: exportModel,
                histogramModel: histogramModel,
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
        #if DEBUG
        .commands {
            DeveloperCommands()
        }
        #endif
    }

#if DEBUG
    private var toneLabWindow: some Scene {
        Window("Tone Lab", id: ToneLabWindow.id) {
            ToneLabView(
                library: library,
                editSession: editSession,
                previewTarget: Binding(
                    get: { PreviewTarget(rawValue: previewTargetRaw) ?? .webInstagram },
                    set: { previewTargetRaw = $0.rawValue }
                ),
                viewerBackground: Binding(
                    get: { ViewerBackground(rawValue: viewerBackgroundRaw) ?? .darkGray },
                    set: { viewerBackgroundRaw = $0.rawValue }
                )
            )
            .frame(minWidth: 980, minHeight: 720)
        }
    }
#endif
}

#if DEBUG
private enum ToneLabWindow {
    static let id = "tone-lab"
}

private struct DeveloperCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandMenu("Developer") {
            Button("Tone Lab") {
                openWindow(id: ToneLabWindow.id)
            }
            .keyboardShortcut("t", modifiers: [.command, .option])
        }
    }
}
#endif
