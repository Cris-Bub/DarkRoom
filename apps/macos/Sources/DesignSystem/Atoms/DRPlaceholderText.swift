import SwiftUI

struct DRPlaceholderText: View {
    let text: String

    var body: some View {
        Text(text)
            .font(DarkRoomDesign.Typography.viewerPlaceholder)
            .foregroundStyle(.secondary)
    }
}
