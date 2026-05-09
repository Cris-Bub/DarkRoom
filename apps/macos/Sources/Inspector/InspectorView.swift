import SwiftUI

struct InspectorView: View {
    let selectedFile: LocalImageFile?
    @Binding var previewTarget: PreviewTarget
    @Binding var viewerBackground: ViewerBackground
    @Binding var editRecipe: EditRecipe
    let histogramStatus: HistogramStatus
    let isReadOnly: Bool
    var onAdjustmentEditingChanged: (Bool) -> Void = { _ in }
    let onResetEdits: () -> Void

    @State private var selectedMode: InspectorMode = .edit
    @State private var showsImageDetails = false
    @State private var profileExpanded = true
    @State private var viewerExpanded = true
    @State private var lightExpanded = true
    @State private var curveExpanded = true

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                Group {
                    switch selectedMode {
                    case .edit:
                        editPage
                    case .crop:
                        placeholderPage(title: "Crop", message: "Crop tools will live here.")
                    case .mask:
                        placeholderPage(title: "Mask", message: "Masking tools will live here.")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if showsImageDetails {
                    imageDetailsPanel
                        .padding(DarkRoomDesign.Spacing.medium)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .background(DarkRoomDesign.Palette.inspectorBackground)

            Rectangle()
                .fill(DarkRoomDesign.Palette.inspectorBorder)
                .frame(width: 1)

            modeRail
        }
        .background(DarkRoomDesign.Palette.inspectorBackground)
    }

    private var editPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                InspectorHistogramView(status: histogramStatus)

                Text("Edit")
                    .font(DarkRoomDesign.Typography.inspectorTitle)
                    .foregroundStyle(DarkRoomDesign.Palette.primaryText)
                    .padding(.horizontal, DarkRoomDesign.Spacing.large)
                    .padding(.top, DarkRoomDesign.Spacing.xLarge)
                    .padding(.bottom, DarkRoomDesign.Spacing.large)

                quickActions

                DRCollapsibleSection("Profile", systemImage: "camera.filters", isExpanded: $profileExpanded) {
                    HStack {
                        Text("Profile")
                            .foregroundStyle(DarkRoomDesign.Palette.subtleText)

                        Text("DarkRoom Color")
                            .foregroundStyle(DarkRoomDesign.Palette.primaryText)

                        Image(systemName: "chevron.down")
                            .foregroundStyle(DarkRoomDesign.Palette.subtleText)

                        Spacer()
                    }
                }

                DRCollapsibleSection("Viewer", systemImage: "rectangle.dashed", isExpanded: $viewerExpanded) {
                    Picker("View As", selection: $previewTarget) {
                        ForEach(PreviewTarget.allCases) { target in
                            Text(target.label).tag(target)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("Background", selection: $viewerBackground) {
                        ForEach(ViewerBackground.allCases) { background in
                            Text(background.label).tag(background)
                        }
                    }
                    .pickerStyle(.menu)
                }

                DRCollapsibleSection("Light", systemImage: "sun.max", isExpanded: $lightExpanded) {
                    DRAdjustmentRow(
                        title: "Exposure",
                        value: $editRecipe.light.exposureEV,
                        range: LightAdjustments.exposureRange,
                        displayValue: signedValue(editRecipe.light.exposureEV, fractionDigits: 2),
                        helpText: "Changes brightness in real stops before the image is tone-mapped.",
                        onEditingChanged: onAdjustmentEditingChanged
                    )

                    DRAdjustmentRow(
                        title: "Contrast",
                        value: $editRecipe.light.contrast,
                        range: LightAdjustments.contrastRange,
                        displayValue: signedValue(editRecipe.light.contrast),
                        helpText: "Changes midtone separation while keeping the toe and shoulder smooth.",
                        onEditingChanged: onAdjustmentEditingChanged
                    )

                    DRAdjustmentRow(
                        title: "Pivot",
                        value: $editRecipe.light.pivotEV,
                        range: LightAdjustments.pivotRange,
                        displayValue: signedValue(editRecipe.light.pivotEV, fractionDigits: 2),
                        helpText: "Moves the tonal balance point for contrast.",
                        onEditingChanged: onAdjustmentEditingChanged
                    )

                    DRAdjustmentRow(
                        title: "Highlights",
                        value: $editRecipe.light.highlights,
                        range: LightAdjustments.highlightsRange,
                        displayValue: signedValue(editRecipe.light.highlights),
                        helpText: "Shapes bright detail without acting as RAW highlight reconstruction.",
                        onEditingChanged: onAdjustmentEditingChanged
                    )

                    DRAdjustmentRow(
                        title: "Shadows",
                        value: $editRecipe.light.shadows,
                        range: LightAdjustments.shadowsRange,
                        displayValue: signedValue(editRecipe.light.shadows),
                        helpText: "Opens or deepens darker tones with soft falloff.",
                        onEditingChanged: onAdjustmentEditingChanged
                    )

                    DRAdjustmentRow(
                        title: "Whites",
                        value: $editRecipe.light.whites,
                        range: LightAdjustments.whitesRange,
                        displayValue: signedValue(editRecipe.light.whites),
                        helpText: "Controls how the image approaches white.",
                        onEditingChanged: onAdjustmentEditingChanged
                    )

                    DRAdjustmentRow(
                        title: "Blacks",
                        value: $editRecipe.light.blacks,
                        range: LightAdjustments.blacksRange,
                        displayValue: signedValue(editRecipe.light.blacks),
                        helpText: "Controls how the image approaches black.",
                        onEditingChanged: onAdjustmentEditingChanged
                    )

                    Button("Reset Light", action: onResetEdits)
                        .buttonStyle(.borderless)
                        .foregroundStyle(DarkRoomDesign.Palette.subtleText)
                        .disabled(editRecipe.isNeutral)
                }

                DRCollapsibleSection("Curve", systemImage: "point.topleft.down.curvedto.point.bottomright.up", isExpanded: $curveExpanded) {
                    curvePlaceholder
                }
            }
        }
        .disabled(isReadOnly)
        .opacity(isReadOnly ? 0.46 : 1)
    }

    private var quickActions: some View {
        HStack {
            Button("Auto") {}
                .buttonStyle(.bordered)

            Button("B&W") {}
                .buttonStyle(.bordered)

            Spacer()

            Button("HDR") {}
                .buttonStyle(.bordered)
        }
        .padding(.horizontal, DarkRoomDesign.Spacing.large)
        .padding(.bottom, DarkRoomDesign.Spacing.large)
    }

    private var curvePlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(DarkRoomDesign.Palette.inspectorRaised)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(DarkRoomDesign.Palette.inspectorBorder, lineWidth: 1)
                )

            VStack(spacing: DarkRoomDesign.Spacing.small) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.title2)
                Text("Curve tools coming next")
                    .font(.caption)
            }
            .foregroundStyle(DarkRoomDesign.Palette.subtleText)
        }
        .frame(height: 180)
    }

    private var modeRail: some View {
        VStack(spacing: DarkRoomDesign.Spacing.large) {
            Spacer()
                .frame(height: DarkRoomDesign.Spacing.large)

            DRIconRailButton(
                systemImage: DarkRoomDesign.Icon.editMode,
                title: "Edit",
                isSelected: selectedMode == .edit
            ) {
                selectedMode = .edit
            }

            DRIconRailButton(
                systemImage: DarkRoomDesign.Icon.cropMode,
                title: "Crop",
                isSelected: selectedMode == .crop
            ) {
                selectedMode = .crop
            }

            DRIconRailButton(
                systemImage: DarkRoomDesign.Icon.maskMode,
                title: "Mask",
                isSelected: selectedMode == .mask
            ) {
                selectedMode = .mask
            }

            Spacer()

            DRIconRailButton(
                systemImage: DarkRoomDesign.Icon.imageDetails,
                title: "Image Details",
                isSelected: showsImageDetails
            ) {
                withAnimation(.easeInOut(duration: 0.16)) {
                    showsImageDetails.toggle()
                }
            }

            Spacer()
                .frame(height: DarkRoomDesign.Spacing.large)
        }
        .frame(width: 58)
        .background(DarkRoomDesign.Palette.railBackground)
    }

    private var imageDetailsPanel: some View {
        VStack(alignment: .leading, spacing: DarkRoomDesign.Spacing.small) {
            Text("Image Details")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DarkRoomDesign.Palette.primaryText)

            detailRow("File", selectedFile?.displayName ?? "None")

            if let selectedFile {
                detailRow("Folder", selectedFile.url.deletingLastPathComponent().lastPathComponent)
                detailRow("Type", selectedFile.url.pathExtension.uppercased())
            }
        }
        .padding(DarkRoomDesign.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(DarkRoomDesign.Palette.inspectorRaised)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(DarkRoomDesign.Palette.inspectorBorder, lineWidth: 1)
        )
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(DarkRoomDesign.Typography.detailLabel)
                .foregroundStyle(DarkRoomDesign.Palette.subtleText)

            Spacer()

            Text(value)
                .font(DarkRoomDesign.Typography.detailValue)
                .foregroundStyle(DarkRoomDesign.Palette.subtleText)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    private func placeholderPage(title: String, message: String) -> some View {
        VStack(spacing: DarkRoomDesign.Spacing.medium) {
            Text(title)
                .font(DarkRoomDesign.Typography.inspectorTitle)
                .foregroundStyle(DarkRoomDesign.Palette.primaryText)

            Text(message)
                .font(.callout)
                .foregroundStyle(DarkRoomDesign.Palette.subtleText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DarkRoomDesign.Spacing.large)
        .opacity(isReadOnly ? 0.46 : 1)
    }

    private func signedValue(_ value: Double, fractionDigits: Int = 0) -> String {
        if abs(value) < 0.0001 {
            return "0"
        }

        let sign = value > 0 ? "+" : "-"
        let magnitude = abs(value).formatted(.number.precision(.fractionLength(fractionDigits)))
        return "\(sign) \(magnitude)"
    }
}

private enum InspectorMode {
    case edit
    case crop
    case mask
}
