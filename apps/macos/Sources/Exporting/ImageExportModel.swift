import AppKit
import Foundation
import UniformTypeIdentifiers

@MainActor
final class ImageExportModel: ObservableObject {
    @Published private(set) var status: ExportStatus = .idle
    @Published var alert: ExportAlert?

    var isExporting: Bool {
        if case .exporting = status {
            return true
        }

        return false
    }

    func export(
        file: LocalImageFile?,
        editRecipe: EditRecipe,
        outputTarget: PreviewTarget
    ) {
        guard let file else {
            fail(ExportError.noSelectedImage)
            return
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = ExportFormat.allCases.map(\.contentType)
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.message = "Export the selected image with the current edit recipe."
        panel.nameFieldStringValue = defaultExportName(for: file, format: .jpeg)
        panel.prompt = "Export"

        guard panel.runModal() == .OK, let panelURL = panel.url else {
            return
        }

        let format = ExportFormat(url: panelURL) ?? .jpeg
        let request = ExportRequest(
            sourceURL: file.url,
            destinationURL: panelURL,
            format: format,
            outputTarget: outputTarget,
            editRecipe: editRecipe
        )

        status = .exporting

        Task.detached(priority: .userInitiated) {
            do {
                let result = try ImageExporter.export(request)

                await MainActor.run {
                    self.status = .succeeded(result)
                }
            } catch {
                await MainActor.run {
                    self.fail(error)
                }
            }
        }
    }

    private func fail(_ error: Error) {
        let message = error.localizedDescription
        status = .failed(message)
        alert = ExportAlert(title: "Export Failed", message: message)
    }

    private func defaultExportName(for file: LocalImageFile, format: ExportFormat) -> String {
        let baseName = file.url.deletingPathExtension().lastPathComponent
        return "\(baseName)-darkroom.\(format.fileExtension)"
    }
}

enum ExportStatus: Equatable {
    case idle
    case exporting
    case succeeded(ExportResult)
    case failed(String)

    var label: String? {
        switch self {
        case .idle:
            nil
        case .exporting:
            "Exporting..."
        case .succeeded(let result):
            "Exported \(result.destinationURL.lastPathComponent)"
        case .failed:
            "Export failed"
        }
    }
}

struct ExportAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
