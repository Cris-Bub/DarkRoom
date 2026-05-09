import SwiftUI

struct DREmptyState: View {
    let systemImage: String
    let title: String
    let message: String?
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        systemImage: String,
        title: String,
        message: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: DarkRoomDesign.Spacing.small) {
            Image(systemName: systemImage)
                .font(.title2)

            Text(title)
                .font(DarkRoomDesign.Typography.emptyStateTitle)

            if let message {
                Text(message)
                    .font(DarkRoomDesign.Typography.emptyStateMessage)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                Button(actionTitle, action: action)
            }
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DarkRoomDesign.Spacing.large)
    }
}
