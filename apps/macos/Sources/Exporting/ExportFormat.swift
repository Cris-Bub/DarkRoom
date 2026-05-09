import CoreImage
import UniformTypeIdentifiers

enum ExportFormat: String, CaseIterable, Identifiable, Sendable {
    case jpeg
    case png
    case tiff

    var id: String {
        rawValue
    }

    var contentType: UTType {
        switch self {
        case .jpeg:
            .jpeg
        case .png:
            .png
        case .tiff:
            .tiff
        }
    }

    var fileExtension: String {
        switch self {
        case .jpeg:
            "jpg"
        case .png:
            "png"
        case .tiff:
            "tif"
        }
    }

    var outputFormat: CIFormat {
        switch self {
        case .jpeg, .png:
            .RGBA8
        case .tiff:
            .RGBA16
        }
    }

    init?(url: URL) {
        switch url.pathExtension.lowercased() {
        case "jpg", "jpeg":
            self = .jpeg
        case "png":
            self = .png
        case "tif", "tiff":
            self = .tiff
        default:
            return nil
        }
    }

    func normalizedDestinationURL(_ url: URL) -> URL {
        guard url.pathExtension.isEmpty else {
            return url
        }

        return url.appendingPathExtension(fileExtension)
    }
}
