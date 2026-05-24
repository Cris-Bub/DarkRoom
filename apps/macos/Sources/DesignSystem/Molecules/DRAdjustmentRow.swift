import Foundation
import SwiftUI

struct DRAdjustmentRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let displayValue: String
    var helpText: String?
    var resetValue: Double? = nil
    var showsHelpButton = false
    var onEditingChanged: (Bool) -> Void = { _ in }

    @FocusState private var isValueFieldFocused: Bool
    @State private var isEditingValue = false
    @State private var draftValue = ""

    var body: some View {
        VStack(alignment: .leading, spacing: DarkRoomDesign.Spacing.small) {
            HStack {
                HStack(spacing: DarkRoomDesign.Spacing.xSmall) {
                    Text(title)
                        .font(DarkRoomDesign.Typography.controlLabel)
                        .foregroundStyle(DarkRoomDesign.Palette.subtleText)

                    if showsHelpButton, let helpText {
                        DRHelpPopoverButton(title: title, helpText: helpText)
                    }
                }

                Spacer()

                HStack(spacing: DarkRoomDesign.Spacing.small) {
                    valueControl

                    if let resetValue {
                        resetButton(resetValue)
                    }
                }
            }

            DRAdjustmentSlider(
                value: $value,
                range: range,
                onEditingChanged: onEditingChanged
            )
        }
        .help(showsHelpButton ? title : (helpText ?? title))
    }

    private func resetButton(_ resetValue: Double) -> some View {
        Button {
            reset(to: resetValue)
        } label: {
            Image(systemName: "arrow.counterclockwise")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(DarkRoomDesign.Palette.subtleText)
                .frame(width: 18, height: 18)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(value == resetValue)
        .opacity(value == resetValue ? 0.32 : 1)
        .help("Reset \(title)")
    }

    @ViewBuilder
    private var valueControl: some View {
        if isEditingValue {
            TextField("Value", text: $draftValue)
                .font(DarkRoomDesign.Typography.controlValue)
                .foregroundStyle(DarkRoomDesign.Palette.primaryText)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.plain)
                .focused($isValueFieldFocused)
                .frame(width: 78)
                .padding(.horizontal, DarkRoomDesign.Spacing.small)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DarkRoomDesign.Palette.inspectorRaised)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(DarkRoomDesign.Palette.inspectorBorder, lineWidth: 1)
                )
                .onSubmit(commitDraftValue)
                .onExitCommand(perform: cancelDraftValue)
                .onChange(of: isValueFieldFocused) { _, isFocused in
                    guard isEditingValue, !isFocused else {
                        return
                    }

                    commitDraftValue()
                }
        } else {
            Button(action: beginValueEditing) {
                Text(displayValue)
                    .font(DarkRoomDesign.Typography.controlValue)
                    .foregroundStyle(DarkRoomDesign.Palette.subtleText)
                    .frame(minWidth: 44, alignment: .trailing)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Click to enter a custom value")
        }
    }

    private func beginValueEditing() {
        draftValue = editableValueString
        isEditingValue = true
        onEditingChanged(true)

        DispatchQueue.main.async {
            isValueFieldFocused = true
        }
    }

    private func commitDraftValue() {
        if let parsedValue = parsedDraftValue {
            value = min(max(parsedValue, range.lowerBound), range.upperBound)
        }

        finishValueEditing()
    }

    private func cancelDraftValue() {
        finishValueEditing()
    }

    private func reset(to resetValue: Double) {
        value = min(max(resetValue, range.lowerBound), range.upperBound)
        finishValueEditing()
        onEditingChanged(false)
    }

    private func finishValueEditing() {
        guard isEditingValue else {
            return
        }

        isEditingValue = false
        isValueFieldFocused = false
        onEditingChanged(false)
    }

    private var parsedDraftValue: Double? {
        let normalizedDraft = draftValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "−", with: "-")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "+ ", with: "+")
            .replacingOccurrences(of: "- ", with: "-")

        guard !normalizedDraft.isEmpty else {
            return nil
        }

        return Double(normalizedDraft)
    }

    private var editableValueString: String {
        String(format: "%.4f", value)
            .replacingOccurrences(of: "0+$", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\.$", with: "", options: .regularExpression)
    }
}

struct DRHelpPopoverButton: View {
    let title: String
    let helpText: String

    @State private var isPresented = false
    @State private var closeTask: Task<Void, Never>?

    var body: some View {
        Button {
            closeTask?.cancel()
            isPresented.toggle()
        } label: {
            Image(systemName: "info.circle")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(DarkRoomDesign.Palette.subtleText)
                .frame(width: 14, height: 14)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(0.78)
        .accessibilityLabel("About \(title)")
        .onHover(perform: updateHover)
        .popover(isPresented: $isPresented, arrowEdge: .top) {
            VStack(alignment: .leading, spacing: DarkRoomDesign.Spacing.xSmall) {
                Text(title)
                    .font(DarkRoomDesign.Typography.controlLabel)
                    .foregroundStyle(DarkRoomDesign.Palette.primaryText)

                Text(helpText)
                    .font(DarkRoomDesign.Typography.detailLabel)
                    .foregroundStyle(DarkRoomDesign.Palette.subtleText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: 260, alignment: .leading)
            .padding(DarkRoomDesign.Spacing.medium)
        }
    }

    private func updateHover(_ isHovering: Bool) {
        closeTask?.cancel()

        if isHovering {
            isPresented = true
        } else {
            closeTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 260_000_000)
                guard !Task.isCancelled else {
                    return
                }

                isPresented = false
            }
        }
    }
}
