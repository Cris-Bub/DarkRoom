import CoreGraphics
import Foundation

enum HistogramCalculator {
    private static let bitsPerComponent = 8
    private static let bytesPerPixel = 4
    static func makeHistogram(from image: CGImage) throws -> ImageHistogram {
        let width = image.width
        let height = image.height
        guard width > 0, height > 0 else {
            throw HistogramError.emptyImage
        }

        var pixels = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        let colorSpace = image.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
            | CGBitmapInfo.byteOrder32Big.rawValue

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: width * bytesPerPixel,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            throw HistogramError.unableToReadPixels
        }

        context.interpolationQuality = .none
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        return try DarkroomCoreHistogramMath.makeHistogram(
            rgbaPixels: pixels,
            pixelCount: width * height
        )
    }
}

enum HistogramError: LocalizedError {
    case emptyImage
    case unableToReadPixels

    var errorDescription: String? {
        switch self {
        case .emptyImage:
            "Could not calculate a histogram for an empty image."
        case .unableToReadPixels:
            "Could not read image pixels for the histogram."
        }
    }
}

