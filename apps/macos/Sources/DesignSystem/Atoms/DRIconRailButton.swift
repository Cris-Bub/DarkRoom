import SwiftUI

struct DRIconRailButton: View {
    let systemImage: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(isSelected ? DarkRoomDesign.Palette.primaryText : DarkRoomDesign.Palette.subtleText)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? DarkRoomDesign.Palette.railSelected : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .help(title)
        .accessibilityLabel(title)
    }
}
