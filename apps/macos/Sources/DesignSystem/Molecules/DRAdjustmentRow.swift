import SwiftUI

struct DRAdjustmentRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let displayValue: String

    var body: some View {
        VStack(alignment: .leading, spacing: DarkRoomDesign.Spacing.small) {
            HStack {
                Text(title)
                    .font(DarkRoomDesign.Typography.controlLabel)
                    .foregroundStyle(DarkRoomDesign.Palette.subtleText)

                Spacer()

                Text(displayValue)
                    .font(DarkRoomDesign.Typography.controlValue)
                    .foregroundStyle(DarkRoomDesign.Palette.subtleText)
            }

            DRAdjustmentSlider(value: $value, range: range)
        }
    }
}
