import SwiftUI

struct DRCollapsibleSection<Content: View>: View {
    let title: String
    let systemImage: String?
    @Binding var isExpanded: Bool
    @ViewBuilder let content: () -> Content

    init(
        _ title: String,
        systemImage: String? = nil,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self._isExpanded = isExpanded
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.16)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: DarkRoomDesign.Spacing.medium) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))

                    if let systemImage {
                        Image(systemName: systemImage)
                            .frame(width: 18)
                    }

                    Text(title)
                        .font(DarkRoomDesign.Typography.sectionHeader)

                    Spacer()
                }
                .foregroundStyle(DarkRoomDesign.Palette.primaryText)
                .contentShape(Rectangle())
                .padding(.horizontal, DarkRoomDesign.Spacing.large)
                .padding(.vertical, DarkRoomDesign.Spacing.medium)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: DarkRoomDesign.Spacing.large) {
                    content()
                }
                .padding(.horizontal, DarkRoomDesign.Spacing.large)
                .padding(.bottom, DarkRoomDesign.Spacing.large)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(DarkRoomDesign.Palette.inspectorBackground)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DarkRoomDesign.Palette.inspectorBorder)
                .frame(height: 1)
        }
    }
}
