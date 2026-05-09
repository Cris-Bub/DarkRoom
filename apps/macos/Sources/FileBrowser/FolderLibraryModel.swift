import AppKit
import Combine
import Foundation

@MainActor
final class FolderLibraryModel: ObservableObject {
    @Published private(set) var folderURL: URL?
    @Published private(set) var sourceTitle: String?
    @Published private(set) var images: [LocalImageFile] = []
    @Published var selectedImage: LocalImageFile?
    @Published var lastError: String?

    func openFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = LocalImageFile.supportedContentTypes
        panel.message = "Choose image files or folders containing images."
        panel.prompt = "Open"

        guard panel.runModal() == .OK else {
            return
        }

        open(urls: panel.urls)
    }

    func open(urls: [URL]) {
        do {
            let files = try imageFiles(from: urls)

            folderURL = primaryFolderURL(from: urls)
            sourceTitle = title(for: urls, files: files)
            images = files
            selectedImage = files.first
            lastError = files.isEmpty ? "No supported image files found." : nil
        } catch {
            folderURL = nil
            sourceTitle = nil
            images = []
            selectedImage = nil
            lastError = error.localizedDescription
        }
    }

    func scan(folder url: URL) {
        open(urls: [url])
    }

    private func imageFiles(from urls: [URL]) throws -> [LocalImageFile] {
        var files: [LocalImageFile] = []

        for url in urls {
            let didStartAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            if try isDirectory(url) {
                files.append(contentsOf: try imageFiles(in: url))
            } else if LocalImageFile.isSupported(url: url) {
                files.append(LocalImageFile(url: url))
            }
        }

        return unique(files).sorted { lhs, rhs in
            lhs.displayName.localizedStandardCompare(rhs.displayName) == .orderedAscending
        }
    }

    private func imageFiles(in folderURL: URL) throws -> [LocalImageFile] {
        let urls = try FileManager.default.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        return urls
            .filter(LocalImageFile.isSupported(url:))
            .map(LocalImageFile.init(url:))
    }

    private func isDirectory(_ url: URL) throws -> Bool {
        try url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true
    }

    private func primaryFolderURL(from urls: [URL]) -> URL? {
        if urls.count == 1, let url = urls.first {
            return (try? isDirectory(url)) == true ? url : url.deletingLastPathComponent()
        }

        let folders = urls.compactMap { url -> URL? in
            (try? isDirectory(url)) == true ? url : nil
        }

        return folders.count == 1 ? folders.first : nil
    }

    private func title(for urls: [URL], files: [LocalImageFile]) -> String? {
        if urls.count == 1, let url = urls.first {
            return (try? isDirectory(url)) == true ? url.lastPathComponent : url.deletingLastPathComponent().lastPathComponent
        }

        if let parent = commonParent(for: files) {
            return "\(parent.lastPathComponent) (\(files.count))"
        }

        return files.isEmpty ? nil : "Selection (\(files.count))"
    }

    private func commonParent(for files: [LocalImageFile]) -> URL? {
        let parents = Set(files.map { $0.url.deletingLastPathComponent() })
        return parents.count == 1 ? parents.first : nil
    }

    private func unique(_ files: [LocalImageFile]) -> [LocalImageFile] {
        var seen = Set<String>()
        return files.filter { file in
            seen.insert(file.id).inserted
        }
    }
}
