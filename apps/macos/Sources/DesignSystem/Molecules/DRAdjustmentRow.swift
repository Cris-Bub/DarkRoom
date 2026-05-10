import Foundation
import SwiftUI

struct DRAdjustmentRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let displayValue: String
    var helpText: String?
    var onEditingChanged: (Bool) -> Void = { _ in }

    @FocusState private var isValueFieldFocused: Bool
    @State private var isEditingValue = false
    @State private var draftValue = ""

    var body: some View {
        VStack(alignment: .leading, spacing: DarkRoomDesign.Spacing.small) {
            HStack {
                Text(title)
                    .font(DarkRoomDesign.Typography.controlLabel)
                    .foregroundStyle(DarkRoomDesign.Palette.subtleText)

                Spacer()

                valueControl
            }

            DRAdjustmentSlider(
                value: $value,
                range: range,
                onEditingChanged: onEditingChanged
            )
        }
        .help(helpText ?? title)
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
