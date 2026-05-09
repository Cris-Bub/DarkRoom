import Foundation

struct ImageHistogram: Equatable, Sendable {
    static let binCount = 256

    let luminance: [Int]
    let red: [Int]
    let green: [Int]
    let blue: [Int]
    let shadowClippedPixelCount: Int
    let highlightClippedPixelCount: Int
    let sampledPixelCount: Int

    init(
        luminance: [Int],
        red: [Int],
        green: [Int],
        blue: [Int],
        shadowClippedPixelCount: Int,
        highlightClippedPixelCount: Int,
        sampledPixelCount: Int
    ) {
        precondition(luminance.count == Self.binCount)
        precondition(red.count == Self.binCount)
        precondition(green.count == Self.binCount)
        precondition(blue.count == Self.binCount)

        self.luminance = luminance
        self.red = red
        self.green = green
        self.blue = blue
        self.shadowClippedPixelCount = shadowClippedPixelCount
        self.highlightClippedPixelCount = highlightClippedPixelCount
        self.sampledPixelCount = sampledPixelCount
    }

    var hasShadowClipping: Bool {
        shadowClippedPixelCount > 0
    }

    var hasHighlightClipping: Bool {
        highlightClippedPixelCount > 0
    }

    var maximumBinCount: Int {
        [
            luminance.max() ?? 0,
            red.max() ?? 0,
            green.max() ?? 0,
            blue.max() ?? 0
        ].max() ?? 0
    }

    func normalized(_ channel: HistogramChannel) -> [Double] {
        let bins = counts(for: channel)
        let maximum = max(maximumBinCount, 1)

        return bins.map { Double($0) / Double(maximum) }
    }

    func counts(for channel: HistogramChannel) -> [Int] {
        switch channel {
        case .luminance:
            luminance
        case .red:
            red
        case .green:
            green
        case .blue:
            blue
        }
    }
}

enum HistogramChannel: Sendable {
    case luminance
    case red
    case green
    case blue
}

enum HistogramStatus: Equatable, Sendable {
    case empty
    case loading
    case ready(ImageHistogram)
    case failed(String)
}
