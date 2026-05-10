import CoreImage
import Foundation
import ImageIO

enum ImageExporter {
    static func export(_ request: ExportRequest) throws -> ExportResult {
        let destinationURL = request.format.normalizedDestinationURL(request.destinationURL)
        let renderedImage = try ImagePipelineRenderer.renderExport(
            url: request.sourceURL,
            outputTarget: request.outputTarget,
            editRecipe: request.editRecipe,
            outputFormat: request.format.outputFormat,
            rawBaseline: request.rawBaseline
        )

        guard let destination = CGImageDestinationCreateWithURL(
            destinationURL as CFURL,
            request.format.contentType.identifier as CFString,
            1,
            nil
        ) else {
            throw ExportError.unableToCreateDestination(destinationURL.lastPathComponent)
        }

        CGImageDestinationAddImage(
            destination,
            renderedImage.cgImage,
            destinationProperties(for: request) as CFDictionary
        )

        guard CGImageDestinationFinalize(destination) else {
            throw ExportError.unableToWrite(destinationURL.lastPathComponent)
        }

        return ExportResult(
            destinationURL: destinationURL,
            format: request.format,
            outputTarget: request.outputTarget,
            width: renderedImage.cgImage.width,
            height: renderedImage.cgImage.height
        )
    }

    private static func destinationProperties(for request: ExportRequest) -> [CFString: Any] {
        var properties: [CFString: Any] = [
            kCGImagePropertyColorModel: kCGImagePropertyColorModelRGB
        ]

        properties[kCGImagePropertyProfileName] = request.outputTarget.profileName

        if request.format == .jpeg {
            properties[kCGImageDestinationLossyCompressionQuality] = request.jpegQuality
        }

        return properties
    }
}

struct ExportRequest: Sendable {
    let sourceURL: URL
    let destinationURL: URL
    let format: ExportFormat
    let outputTarget: PreviewTarget
    let editRecipe: EditRecipe
    let rawBaseline: RawBaseline
    let jpegQuality: Double

    init(
        sourceURL: URL,
        destinationURL: URL,
        format: ExportFormat,
        outputTarget: PreviewTarget,
        editRecipe: EditRecipe,
        rawBaseline: RawBaseline = .darkRoomStandard,
        jpegQuality: Double = 0.92
    ) {
        self.sourceURL = sourceURL
        self.destinationURL = destinationURL
        self.format = format
        self.outputTarget = outputTarget
        self.editRecipe = editRecipe
        self.rawBaseline = rawBaseline
        self.jpegQuality = jpegQuality
    }
}

struct ExportResult: Equatable, Sendable {
    let destinationURL: URL
    let format: ExportFormat
    let outputTarget: PreviewTarget
    let width: Int
    let height: Int
}

enum ExportError: LocalizedError {
    case noSelectedImage
    case unableToCreateDestination(String)
    case unableToWrite(String)

    var errorDescription: String? {
        switch self {
        case .noSelectedImage:
            "Select an image before exporting."
        case .unableToCreateDestination(let filename):
            "Could not create an export destination for \(filename)."
        case .unableToWrite(let filename):
            "Could not write \(filename)."
        }
    }
}
