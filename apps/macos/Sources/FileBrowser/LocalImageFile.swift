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

    private static let curatedSupportedExtensions: Set<String> = [
        "3fr",
        "ari",
        "arw",
        "avif",
        "bay",
        "bmp",
        "cap",
        "cr2",
        "cr3",
        "crw",
        "dcr",
        "dib",
        "dng",
        "eip",
        "erf",
        "exr",
        "fff",
        "gif",
        "hdr",
        "heic",
        "heif",
        "hif",
        "iiq",
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
        "kdc",
        "mef",
        "mos",
        "mrw",
        "nef",
        "nrw",
        "orf",
        "ori",
        "pef",
        "pic",
        "pict",
        "png",
        "psd",
        "ptx",
        "raf",
        "raw",
        "rwl",
        "rw2",
        "sr2",
        "srf",
        "srw",
        "tga",
        "tif",
        "tiff",
        "webp",
        "x3f"
    ]

    static func isSupported(url: URL) -> Bool {
        let pathExtension = url.pathExtension.lowercased()

        if supportedExtensions.contains(pathExtension) {
            return true
        }

        return UTType(filenameExtension: pathExtension)?.conforms(to: .image) == true
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
