#if DEBUG
import AppKit
import SwiftUI

struct ToneLabView: View {
    @ObservedObject var library: FolderLibraryModel
    @ObservedObject var editSession: EditSessionModel
    @Binding var previewTarget: PreviewTarget
    @Binding var viewerBackground: ViewerBackground

    @State private var previewMode: ToneLabPreviewMode = .after
    @State private var overlay: ToneRangeOverlay = .off
    @State private var toneRecipe = EditRecipe.neutral
    @State private var toneTuning = ToneTuning.defaultV1
    @State private var displayProfile = ViewerDisplayProfile.current()
    @State private var isInteractiveEditing = false
    @State private var copyStatus: String?
    @State private var recipeExpanded = true
    @State private var globalExpanded = true
    @State private var contrastExpanded = true
    @State private var highlightsExpanded = true
    @State private var shadowsExpanded = true
    @State private var whitesExpanded = true
    @State private var blacksExpanded = true
    @State private var sliderMappingExpanded = true

    private var selectedFile: LocalImageFile? {
        library.selectedImage
    }

    private var previewRecipe: EditRecipe {
        previewMode == .before ? .neutral : toneRecipe
    }

    private var previewTuning: ToneTuning {
        previewMode == .before ? .defaultV1 : toneTuning
    }

    private var previewOverlay: ToneRangeOverlay {
        previewMode == .before ? .off : overlay
    }

    var body: some View {
        HStack(spacing: 0) {
            previewColumn

            Rectangle()
                .fill(DarkRoomDesign.Palette.inspectorBorder)
                .frame(width: 1)

            controlsColumn
        }
        .background(DarkRoomDesign.Palette.inspectorBackground)
        .onAppear(perform: loadSelectedRecipe)
        .onChange(of: selectedFile?.id) { _, _ in
            loadSelectedRecipe()
        }
    }

    private var previewColumn: some View {
        VStack(spacing: 0) {
            HStack(spacing: DarkRoomDesign.Spacing.medium) {
                Picker("Preview", selection: $previewMode) {
                    ForEach(ToneLabPreviewMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)

                Picker("Overlay", selection: $overlay) {
                    ForEach(ToneRangeOverlay.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 170)

                Picker("View As", selection: $previewTarget) {
                    ForEach(PreviewTarget.allCases) { target in
                        Text(target.label).tag(target)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 190)

                Spacer()
            }
            .padding(DarkRoomDesign.Spacing.large)

            ZStack {
                viewerBackground.color

                if let selectedFile {
                    ViewerMetalImageView(
                        file: selectedFile,
                        background: viewerBackground,
                        previewTarget: previewTarget,
                        editRecipe: previewRecipe,
                        toneTuning: previewTuning,
                        toneOverlay: previewOverlay,
                        displayProfile: displayProfile,
                        isInteractiveEditing: isInteractiveEditing
                    )
                    .padding(DarkRoomDesign.Spacing.viewerPadding)
                } else {
                    DREmptyState(
                        systemImage: "photo.on.rectangle.angled",
                        title: "Select an image",
                        message: "Tone Lab uses the current DarkRoom selection for live tuning."
                    )
                }
            }
            .background(
                ViewerDisplayProfileReader { window in
                    displayProfile = ViewerDisplayProfile(
                        colorSpace: window?.colorSpace ?? window?.screen?.colorSpace,
                        displayName: window?.screen?.localizedName
                    )
                }
            )
        }
        .frame(minWidth: 620, maxWidth: .infinity, maxHeight: .infinity)
    }

    private var controlsColumn: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: DarkRoomDesign.Spacing.large) {
                    header
                    recipeSection
                    tuningSections
                }
                .padding(DarkRoomDesign.Spacing.large)
            }

            candidateBar
        }
        .frame(width: 390)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DarkRoomDesign.Spacing.small) {
            Text("Tone Lab")
                .font(DarkRoomDesign.Typography.inspectorTitle)
                .foregroundStyle(DarkRoomDesign.Palette.primaryText)

            Text(selectedFile?.url.lastPathComponent ?? "No selected image")
                .font(DarkRoomDesign.Typography.controlLabel)
                .foregroundStyle(DarkRoomDesign.Palette.subtleText)
                .lineLimit(1)
        }
    }

    private var recipeSection: some View {
        DRCollapsibleSection(
            "Test Light Sliders",
            systemImage: "slider.horizontal.3",
            isExpanded: $recipeExpanded
        ) {
            ToneLabSlider(
                title: "Exposure",
                value: $toneRecipe.light.exposureEV,
                range: LightAdjustments.exposureRange,
                fractionDigits: 2,
                onEditingChanged: handleEditingChanged
            )
            ToneLabSlider(
                title: "Contrast",
                value: $toneRecipe.light.contrast,
                range: LightAdjustments.contrastRange,
                onEditingChanged: handleEditingChanged
            )
            ToneLabSlider(
                title: "Pivot",
                value: $toneRecipe.light.pivotEV,
                range: LightAdjustments.pivotRange,
                fractionDigits: 2,
                onEditingChanged: handleEditingChanged
            )
            ToneLabSlider(
                title: "Highlights",
                value: $toneRecipe.light.highlights,
                range: LightAdjustments.highlightsRange,
                onEditingChanged: handleEditingChanged
            )
            ToneLabSlider(
                title: "Shadows",
                value: $toneRecipe.light.shadows,
                range: LightAdjustments.shadowsRange,
                onEditingChanged: handleEditingChanged
            )
            ToneLabSlider(
                title: "Whites",
                value: $toneRecipe.light.whites,
                range: LightAdjustments.whitesRange,
                onEditingChanged: handleEditingChanged
            )
            ToneLabSlider(
                title: "Blacks",
                value: $toneRecipe.light.blacks,
                range: LightAdjustments.blacksRange,
                onEditingChanged: handleEditingChanged
            )
        }
    }

    private var tuningSections: some View {
        Group {
            DRCollapsibleSection(
                "Global Base Curve",
                systemImage: "circle.lefthalf.filled",
                isExpanded: $globalExpanded
            ) {
                ToneLabSlider(title: "Middle Gray", value: $toneTuning.global.middleGray, range: 0.08...0.35, fractionDigits: 3, onEditingChanged: handleEditingChanged)
                ToneLabSlider(title: "Base Contrast", value: $toneTuning.global.baseContrast, range: 0.6...1.6, fractionDigits: 2, onEditingChanged: handleEditingChanged)
                ToneLabSlider(title: "Toe Strength", value: $toneTuning.global.toeStrength, range: 0.0...2.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
                ToneLabSlider(title: "Toe Length EV", value: $toneTuning.global.toeLengthEV, range: 0.5...6.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
                ToneLabSlider(title: "Shoulder Strength", value: $toneTuning.global.shoulderStrength, range: 0.0...2.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
                ToneLabSlider(title: "Shoulder Length EV", value: $toneTuning.global.shoulderLengthEV, range: 0.5...6.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
                ToneLabSlider(title: "Output Soft Clip", value: $toneTuning.global.outputSoftClip, range: 0.0...2.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            }

            DRCollapsibleSection(
                "Contrast / Pivot",
                systemImage: "arrow.up.left.and.arrow.down.right",
                isExpanded: $contrastExpanded
            ) {
                ToneLabSlider(title: "Max Slope Boost", value: $toneTuning.contrast.maxSlopeBoost, range: 0.0...3.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
                ToneLabSlider(title: "Max Slope Reduction", value: $toneTuning.contrast.maxSlopeReduction, range: 0.0...3.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
                ToneLabSlider(title: "Contrast Softness", value: $toneTuning.contrast.contrastSoftness, range: 0.2...4.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
                ToneLabSlider(title: "Pivot Min EV", value: $toneTuning.contrast.pivotMinEV, range: -4.0...0.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
                ToneLabSlider(title: "Pivot Max EV", value: $toneTuning.contrast.pivotMaxEV, range: 0.0...4.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            }

            rangeSection(
                title: "Highlights",
                systemImage: "sun.max",
                tuning: $toneTuning.highlights,
                isExpanded: $highlightsExpanded,
                startRange: 0.0...4.0,
                fullRange: 0.5...6.0,
                endpointLabel: "White Protection"
            )

            rangeSection(
                title: "Shadows",
                systemImage: "moon",
                tuning: $toneTuning.shadows,
                isExpanded: $shadowsExpanded,
                startRange: -4.0...0.0,
                fullRange: -6.0 ... -0.5,
                endpointLabel: "Black Protection"
            )

            endpointSection(
                title: "Whites",
                systemImage: "circle.tophalf.filled",
                tuning: $toneTuning.whites,
                isExpanded: $whitesExpanded,
                startRange: 0.0...6.0,
                protectionLabel: "Clip Protection"
            )

            endpointSection(
                title: "Blacks",
                systemImage: "circle.bottomhalf.filled",
                tuning: $toneTuning.blacks,
                isExpanded: $blacksExpanded,
                startRange: -6.0...0.0,
                protectionLabel: "Crush Protection"
            )

            DRCollapsibleSection(
                "Slider Mapping",
                systemImage: "dial.low",
                isExpanded: $sliderMappingExpanded
            ) {
                ToneLabSlider(title: "Near Zero Sensitivity", value: $toneTuning.sliderMapping.nearZeroSensitivity, range: 0.0...2.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
                ToneLabSlider(title: "Mid Sensitivity", value: $toneTuning.sliderMapping.midSensitivity, range: 0.0...2.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
                ToneLabSlider(title: "Extreme Taper", value: $toneTuning.sliderMapping.extremeTaper, range: 0.0...1.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
                ToneLabSlider(title: "Dead Zone", value: $toneTuning.sliderMapping.deadZone, range: 0.0...0.2, fractionDigits: 3, onEditingChanged: handleEditingChanged)
            }
        }
    }

    private func rangeSection(
        title: String,
        systemImage: String,
        tuning: Binding<RangeToneTuning>,
        isExpanded: Binding<Bool>,
        startRange: ClosedRange<Double>,
        fullRange: ClosedRange<Double>,
        endpointLabel: String
    ) -> some View {
        DRCollapsibleSection(title, systemImage: systemImage, isExpanded: isExpanded) {
            ToneLabSlider(title: "Start EV", value: tuning.startEV, range: startRange, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Full EV", value: tuning.fullEV, range: fullRange, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Max Lift EV", value: tuning.maxLiftEV, range: 0.0...5.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Max Pull EV", value: tuning.maxPullEV, range: -5.0...0.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Falloff", value: tuning.falloff, range: 0.2...2.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Midtone Protection", value: tuning.midtoneProtection, range: 0.0...1.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: endpointLabel, value: tuning.endpointProtection, range: 0.0...1.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
        }
    }

    private func endpointSection(
        title: String,
        systemImage: String,
        tuning: Binding<EndpointToneTuning>,
        isExpanded: Binding<Bool>,
        startRange: ClosedRange<Double>,
        protectionLabel: String
    ) -> some View {
        DRCollapsibleSection(title, systemImage: systemImage, isExpanded: isExpanded) {
            ToneLabSlider(title: "Start EV", value: tuning.startEV, range: startRange, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Strength", value: tuning.strength, range: 0.0...2.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Max Shift EV", value: tuning.maxShiftEV, range: 0.0...4.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Softness", value: tuning.softness, range: 0.2...4.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: protectionLabel, value: tuning.protection, range: 0.0...1.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
        }
    }

    private var candidateBar: some View {
        VStack(alignment: .leading, spacing: DarkRoomDesign.Spacing.small) {
            HStack {
                Button("Copy JSON", action: copyJSON)
                    .buttonStyle(.borderedProminent)

                Button("Reset", action: resetTuning)
                    .buttonStyle(.bordered)

                Button("Candidate 01", action: loadSuggestedCandidate)
                    .buttonStyle(.bordered)

                Spacer()
            }

            if let copyStatus {
                Text(copyStatus)
                    .font(.caption)
                    .foregroundStyle(DarkRoomDesign.Palette.subtleText)
            }
        }
        .padding(DarkRoomDesign.Spacing.large)
        .background(DarkRoomDesign.Palette.inspectorRaised)
    }

    private func handleEditingChanged(_ isEditing: Bool) {
        isInteractiveEditing = isEditing
    }

    private func loadSelectedRecipe() {
        toneRecipe = editSession.recipe(for: selectedFile)
    }

    private func copyJSON() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(toneTuning.prettyPrintedJSON, forType: .string)
        copyStatus = "Copied \(toneTuning.version)"
    }

    private func resetTuning() {
        toneTuning = .defaultV1
        copyStatus = "Reset to current V1 defaults"
    }

    private func loadSuggestedCandidate() {
        toneTuning = .suggestedCandidate01
        copyStatus = "Loaded suggested candidate 01"
    }
}

private struct ToneLabSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var fractionDigits = 2
    var onEditingChanged: (Bool) -> Void

    var body: some View {
        DRAdjustmentRow(
            title: title,
            value: $value,
            range: range,
            displayValue: formattedValue,
            onEditingChanged: onEditingChanged
        )
    }

    private var formattedValue: String {
        value.formatted(.number.precision(.fractionLength(fractionDigits)))
    }
}

private enum ToneLabPreviewMode: String, CaseIterable, Identifiable {
    case before
    case after

    var id: String { rawValue }

    var label: String {
        switch self {
        case .before:
            "Before"
        case .after:
            "After"
        }
    }
}
#endif
