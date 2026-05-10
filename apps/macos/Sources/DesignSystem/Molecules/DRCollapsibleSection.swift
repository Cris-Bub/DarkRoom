import SwiftUI

struct DRCollapsibleSection<Content: View>: View {
    let title: String
    let systemImage: String?
    let resetTitle: String?
    let isResetDisabled: Bool
    let onReset: (() -> Void)?
    @Binding var isExpanded: Bool
    @ViewBuilder let content: () -> Content

    init(
        _ title: String,
        systemImage: String? = nil,
        isExpanded: Binding<Bool>,
        resetTitle: String? = nil,
        isResetDisabled: Bool = false,
        onReset: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.resetTitle = resetTitle
        self.isResetDisabled = isResetDisabled
        self.onReset = onReset
        self._isExpanded = isExpanded
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                disclosureButton

                resetButton
            }

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

    @ViewBuilder
    private var disclosureButton: some View {
        if let onReset {
            baseDisclosureButton
                .contextMenu {
                    resetMenuButton(action: onReset)
                }
        } else {
            baseDisclosureButton
        }
    }

    private var baseDisclosureButton: some View {
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
            .padding(.leading, DarkRoomDesign.Spacing.large)
            .padding(.trailing, DarkRoomDesign.Spacing.medium)
            .padding(.vertical, DarkRoomDesign.Spacing.medium)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var resetButton: some View {
        if let onReset {
            Button(action: onReset) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(DarkRoomDesign.Palette.subtleText)
            .disabled(isResetDisabled)
            .opacity(isResetDisabled ? 0.36 : 1)
            .help(resetTitle ?? "Reset Section")
            .padding(.trailing, DarkRoomDesign.Spacing.medium)
        }
    }

    private func resetMenuButton(action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Label(resetTitle ?? "Reset Section", systemImage: "arrow.counterclockwise")
        }
        .disabled(isResetDisabled)
    }
}
