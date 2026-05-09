import SwiftUI

struct DRPanelHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(DarkRoomDesign.Typography.panelHeader)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DarkRoomDesign.Spacing.medium)
            .padding(.vertical, DarkRoomDesign.Spacing.small + DarkRoomDesign.Spacing.xSmall / 2)
    }
}
