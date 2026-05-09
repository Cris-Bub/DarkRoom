import SwiftUI

struct DRAdjustmentSlider: View {
    @Environment(\.isEnabled) private var isEnabled

    @Binding var value: Double
    let range: ClosedRange<Double>

    private let trackHeight: CGFloat = 3
    private let knobSize: CGFloat = 22

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, knobSize)
            let progress = normalizedProgress
            let knobX = (width - knobSize) * progress + knobSize / 2

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(DarkRoomDesign.Palette.sliderTrack)
                    .frame(height: trackHeight)
                    .padding(.horizontal, knobSize / 2)
                    .opacity(isEnabled ? 1 : 0.45)

                Circle()
                    .fill(DarkRoomDesign.Palette.inspectorBackground)
                    .frame(width: knobSize, height: knobSize)
                    .overlay(
                        Circle()
                            .stroke(DarkRoomDesign.Palette.sliderKnobStroke, lineWidth: 3)
                    )
                    .opacity(isEnabled ? 1 : 0.55)
                    .position(x: knobX, y: proxy.size.height / 2)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { drag in
                                guard isEnabled else {
                                    return
                                }

                                let clampedX = min(max(drag.location.x, knobSize / 2), width - knobSize / 2)
                                let nextProgress = (clampedX - knobSize / 2) / max(width - knobSize, 1)
                                value = range.lowerBound + (range.upperBound - range.lowerBound) * nextProgress
                            }
                    )
            }
        }
        .frame(height: 28)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Adjustment")
        .accessibilityValue(displayString)
    }

    private var normalizedProgress: CGFloat {
        guard range.upperBound > range.lowerBound else {
            return 0
        }

        let clamped = min(max(value, range.lowerBound), range.upperBound)
        return CGFloat((clamped - range.lowerBound) / (range.upperBound - range.lowerBound))
    }

    private var displayString: String {
        value.formatted(.number.precision(.fractionLength(0...2)))
    }
}
