import SwiftUI

struct InspectorHistogramView: View {
    let status: HistogramStatus

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.black.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(DarkRoomDesign.Palette.inspectorBorder, lineWidth: 1)
                )

            switch status {
            case .ready(let histogram):
                histogramCanvas(histogram)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay {
                        clippingIndicators(for: histogram)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Histogram")
                    .accessibilityValue(accessibilityValue(for: histogram))
            case .loading:
                ProgressView()
                    .controlSize(.small)
            case .failed:
                histogramPlaceholder("Histogram Unavailable")
            case .empty:
                histogramPlaceholder("No Histogram")
            }
        }
        .frame(height: 132)
        .padding(.horizontal, DarkRoomDesign.Spacing.large)
        .padding(.top, DarkRoomDesign.Spacing.medium)
        .padding(.bottom, DarkRoomDesign.Spacing.large)
    }

    private func histogramCanvas(_ histogram: ImageHistogram) -> some View {
        Canvas { context, size in
            guard size.width > 0, size.height > 0 else {
                return
            }

            let red = displayBins(for: histogram, channel: .red)
            let green = displayBins(for: histogram, channel: .green)
            let blue = displayBins(for: histogram, channel: .blue)
            let binCount = ImageHistogram.binCount

            guard red.count == binCount,
                  green.count == binCount,
                  blue.count == binCount else {
                return
            }

            let columnWidth = size.width / CGFloat(binCount) + 0.5

            for index in 0..<binCount {
                let x = CGFloat(index) * size.width / CGFloat(binCount)
                let entries: [(value: Double, channel: HistogramChannelKind)] = [
                    (red[index], .red),
                    (green[index], .green),
                    (blue[index], .blue)
                ]
                .sorted { $0.value < $1.value }

                let lowest = entries[0]
                let middle = entries[1]
                let highest = entries[2]

                if lowest.value > 0 {
                    let bottomY = size.height
                    let topY = size.height - CGFloat(lowest.value) * size.height
                    let rect = CGRect(x: x, y: topY, width: columnWidth, height: bottomY - topY)
                    context.fill(Path(rect), with: .color(allChannelsBodyColor))
                }

                if middle.value > lowest.value {
                    let bottomY = size.height - CGFloat(lowest.value) * size.height
                    let topY = size.height - CGFloat(middle.value) * size.height
                    let rect = CGRect(x: x, y: topY, width: columnWidth, height: bottomY - topY)
                    context.fill(
                        Path(rect),
                        with: .color(twoChannelBodyColor(middle.channel, highest.channel))
                    )
                }

                if highest.value > middle.value {
                    let bottomY = size.height - CGFloat(middle.value) * size.height
                    let topY = size.height - CGFloat(highest.value) * size.height
                    let rect = CGRect(x: x, y: topY, width: columnWidth, height: bottomY - topY)
                    context.fill(
                        Path(rect),
                        with: .color(singleChannelBodyColor(highest.channel))
                    )
                }
            }

            context.stroke(
                outlinePath(red, size: size),
                with: .color(redOutlineColor),
                lineWidth: 1
            )
            context.stroke(
                outlinePath(green, size: size),
                with: .color(greenOutlineColor),
                lineWidth: 1
            )
            context.stroke(
                outlinePath(blue, size: size),
                with: .color(blueOutlineColor),
                lineWidth: 1
            )
        }
    }

    private func clippingIndicators(for histogram: ImageHistogram) -> some View {
        HStack {
            HistogramClipTriangle(edge: .leading)
                .fill(clipColor(isActive: histogram.hasShadowClipping))
                .frame(width: 18, height: 18)
                .accessibilityLabel("Shadow clipping")

            Spacer()

            HistogramClipTriangle(edge: .trailing)
                .fill(clipColor(isActive: histogram.hasHighlightClipping))
                .frame(width: 18, height: 18)
                .accessibilityLabel("Highlight clipping")
        }
        .padding(4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func histogramPlaceholder(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(DarkRoomDesign.Palette.subtleText)
    }

    private func clipColor(isActive: Bool) -> Color {
        isActive ? DarkRoomDesign.Palette.primaryText : DarkRoomDesign.Palette.subtleText.opacity(0.36)
    }

    private func outlinePath(_ bins: [Double], size: CGSize) -> Path {
        guard !bins.isEmpty else {
            return Path()
        }

        let step = size.width / CGFloat(max(bins.count - 1, 1))
        var path = Path()
        path.move(to: CGPoint(x: 0, y: size.height - CGFloat(bins[0]) * size.height))

        for index in bins.indices.dropFirst() {
            let x = CGFloat(index) * step
            let y = size.height - CGFloat(bins[index]) * size.height
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }

    private func displayBins(for histogram: ImageHistogram, channel: HistogramChannel) -> [Double] {
        let counts = histogram.counts(for: channel)
        let maximum = Double(max(counts.max() ?? 0, 1))
        let denominator = log(maximum + 1)

        guard denominator > 0 else {
            return counts.map { _ in 0 }
        }

        return counts.map { log(Double($0) + 1) / denominator }
    }

    private func accessibilityValue(for histogram: ImageHistogram) -> String {
        let shadow = histogram.hasShadowClipping ? "shadow clipping" : "no shadow clipping"
        let highlight = histogram.hasHighlightClipping ? "highlight clipping" : "no highlight clipping"
        return "\(shadow), \(highlight)"
    }

    private var allChannelsBodyColor: Color {
        Color(white: 0.62).opacity(0.62)
    }

    private func twoChannelBodyColor(
        _ first: HistogramChannelKind,
        _ second: HistogramChannelKind
    ) -> Color {
        switch Set([first, second]) {
        case Set([.red, .green]):
            return mutedYellow
        case Set([.green, .blue]):
            return mutedCyan
        case Set([.red, .blue]):
            return mutedMagenta
        default:
            return allChannelsBodyColor
        }
    }

    private func singleChannelBodyColor(_ channel: HistogramChannelKind) -> Color {
        switch channel {
        case .red:
            return mutedRed
        case .green:
            return mutedGreen
        case .blue:
            return mutedBlue
        }
    }

    private var mutedRed: Color { Color(red: 0.74, green: 0.30, blue: 0.30).opacity(0.78) }
    private var mutedGreen: Color { Color(red: 0.30, green: 0.70, blue: 0.36).opacity(0.78) }
    private var mutedBlue: Color { Color(red: 0.34, green: 0.46, blue: 0.86).opacity(0.82) }
    private var mutedYellow: Color { Color(red: 0.66, green: 0.62, blue: 0.30).opacity(0.74) }
    private var mutedCyan: Color { Color(red: 0.32, green: 0.66, blue: 0.66).opacity(0.74) }
    private var mutedMagenta: Color { Color(red: 0.66, green: 0.32, blue: 0.66).opacity(0.74) }

    private var redOutlineColor: Color { Color(red: 1.00, green: 0.30, blue: 0.30) }
    private var greenOutlineColor: Color { Color(red: 0.30, green: 0.95, blue: 0.42) }
    private var blueOutlineColor: Color { Color(red: 0.42, green: 0.62, blue: 1.00) }
}

private enum HistogramChannelKind: Hashable {
    case red
    case green
    case blue
}

private struct HistogramClipTriangle: Shape {
    enum Edge {
        case leading
        case trailing
    }

    let edge: Edge

    func path(in rect: CGRect) -> Path {
        var path = Path()

        switch edge {
        case .leading:
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        case .trailing:
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        }

        path.closeSubpath()
        return path
    }
}
