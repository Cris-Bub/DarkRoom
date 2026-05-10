import Foundation
import ImageIO
import UniformTypeIdentifiers

struct LocalImageFile: Identifiable, Hashable {
    let url: URL

    var id: String {
        url.standardizedFileURL.path
    }

    var displayName: String {
        url.lastPathComponent
    }

    static let supportedExtensions: Set<String> = systemSupportedExtensions.union(curatedSupportedExtensions)

    static var supportedContentTypes: [UTType] {
        uniqueContentTypes(
            [.image] + curatedSupportedExtensions.compactMap { UTType(filenameExtension: $0) }
        )
    }

    static let rawExtensions: Set<String> = [
        "3fr",
        "ari",
        "arw",
        "bay",
        "cap",
        "cr2",
        "cr3",
        "crw",
        "dcr",
        "dng",
        "eip",
        "erf",
        "fff",
        "iiq",
        "kdc",
        "mef",
        "mos",
        "mrw",
        "nef",
        "nrw",
        "orf",
        "ori",
        "pef",
        "ptx",
        "raf",
        "raw",
        "rwl",
        "rw2",
        "sr2",
        "srf",
        "srw",
        "x3f"
    ]

    private static let curatedSupportedExtensions: Set<String> = rawExtensions.union([
        "avif",
        "bmp",
        "dib",
        "exr",
        "gif",
        "hdr",
        "heic",
        "heif",
        "hif",
        "ico",
        "j2k",
        "jfi",
        "jfif",
        "jif",
        "jp2",
        "jpe",
        "jpg",
        "jpeg",
        "jpf",
        "jpm",
        "jpx",
        "pic",
        "pict",
        "png",
        "psd",
        "tga",
        "tif",
        "tiff",
        "webp"
    ])

    static func isSupported(url: URL) -> Bool {
        let pathExtension = url.pathExtension.lowercased()

        if supportedExtensions.contains(pathExtension) {
            return true
        }

        return UTType(filenameExtension: pathExtension)?.conforms(to: .image) == true
    }

    static func isRaw(url: URL) -> Bool {
        rawExtensions.contains(url.pathExtension.lowercased())
    }

    private static var systemSupportedExtensions: Set<String> {
        let identifiers = CGImageSourceCopyTypeIdentifiers() as? [String] ?? []
        return Set(
            identifiers.compactMap { identifier in
                UTType(identifier)?.preferredFilenameExtension?.lowercased()
            }
        )
    }

    private static func uniqueContentTypes(_ types: [UTType]) -> [UTType] {
        var seen = Set<String>()
        return types.filter { type in
            seen.insert(type.identifier).inserted
        }
    }
}
