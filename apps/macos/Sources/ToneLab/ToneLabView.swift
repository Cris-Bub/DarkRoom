#if DEBUG
import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ToneLabView: View {
    @ObservedObject var library: FolderLibraryModel
    @ObservedObject var editSession: EditSessionModel
    @Binding var previewTarget: PreviewTarget
    @Binding var viewerBackground: ViewerBackground

    @State private var previewMode: ToneLabPreviewMode = .after
    @State private var overlay: ToneRangeOverlay = .off
    @State private var toneRecipe = EditRecipe.neutral
    @State private var behaviorTuning = BehaviorTuning.defaultV2
    @State private var displayProfile = ViewerDisplayProfile.current()
    @State private var isInteractiveEditing = false
    @State private var copyStatus: String?
    @State private var soloSlider: ToneLabSliderTarget = .all
    @State private var sweepSlider: ToneLabSliderTarget = .highlights
    @State private var mappingTarget: ToneLabMappingTarget = .highlights
    @State private var recipeExpanded = true
    @State private var exposureFeelExpanded = true
    @State private var globalExpanded = true
    @State private var contrastExpanded = true
    @State private var highlightsExpanded = true
    @State private var shadowsExpanded = true
    @State private var whitesExpanded = true
    @State private var blacksExpanded = true
    @State private var colorCouplingExpanded = true
    @State private var sliderMappingExpanded = true
    @State private var overlaysExpanded = true

    private var selectedFile: LocalImageFile? {
        library.selectedImage
    }

    private var previewRecipe: EditRecipe {
        guard previewMode == .after else {
            return .neutral
        }

        return soloSlider.recipe(from: toneRecipe)
    }

    private var previewTuning: ToneTuning {
        previewMode == .before ? .defaultV1 : behaviorTuning.rendererToneTuning
    }

    private var previewBehaviorTuning: BehaviorTuning? {
        previewMode == .before ? nil : behaviorTuning
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
                .frame(width: 210)

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
                        behaviorTuning: previewBehaviorTuning,
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
        .frame(width: 430)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DarkRoomDesign.Spacing.small) {
            Text("Tone Lab V2")
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
            isExpanded: $recipeExpanded,
            resetTitle: "Reset Test Light Sliders",
            isResetDisabled: toneRecipe.isNeutral && soloSlider == .all,
            onReset: resetRecipeSection
        ) {
            Picker("Solo Slider", selection: $soloSlider) {
                ForEach(ToneLabSliderTarget.allCases) { target in
                    Text(target.label).tag(target)
                }
            }
            .pickerStyle(.menu)

            ToneLabSlider(title: "Exposure", value: $toneRecipe.light.exposureEV, range: LightAdjustments.exposureRange, defaultValue: EditRecipe.neutral.light.exposureEV, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Contrast", value: $toneRecipe.light.contrast, range: LightAdjustments.contrastRange, defaultValue: EditRecipe.neutral.light.contrast, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Pivot", value: $toneRecipe.light.pivotEV, range: LightAdjustments.pivotRange, defaultValue: EditRecipe.neutral.light.pivotEV, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Highlights", value: $toneRecipe.light.highlights, range: LightAdjustments.highlightsRange, defaultValue: EditRecipe.neutral.light.highlights, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Shadows", value: $toneRecipe.light.shadows, range: LightAdjustments.shadowsRange, defaultValue: EditRecipe.neutral.light.shadows, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Whites", value: $toneRecipe.light.whites, range: LightAdjustments.whitesRange, defaultValue: EditRecipe.neutral.light.whites, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Blacks", value: $toneRecipe.light.blacks, range: LightAdjustments.blacksRange, defaultValue: EditRecipe.neutral.light.blacks, onEditingChanged: handleEditingChanged)

            Picker("Sweep Slider", selection: $sweepSlider) {
                ForEach(ToneLabSliderTarget.sweepTargets) { target in
                    Text(target.label).tag(target)
                }
            }
            .pickerStyle(.menu)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 48), spacing: DarkRoomDesign.Spacing.small)], spacing: DarkRoomDesign.Spacing.small) {
                ForEach(ToneLabSliderTarget.sweepValues, id: \.self) { value in
                    Button(value.formatted(.number.precision(.fractionLength(0)))) {
                        applySweepValue(value)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private var tuningSections: some View {
        Group {
            exposureFeelSection
            globalSection
            contrastSection

            rangeSection(
                title: "Highlights Behavior",
                systemImage: "sun.max",
                tuning: $behaviorTuning.toneTuning.highlights,
                isExpanded: $highlightsExpanded,
                startRange: -6.0...8.0,
                fullRange: -6.0...12.0,
                endpointLabel: "White Protection",
                defaultTuning: ToneTuning.defaultV1.highlights,
                resetTitle: "Reset Highlights",
                role: .highlights,
                onReset: resetHighlightsSection
            )

            rangeSection(
                title: "Shadows Behavior",
                systemImage: "moon",
                tuning: $behaviorTuning.toneTuning.shadows,
                isExpanded: $shadowsExpanded,
                startRange: -8.0...6.0,
                fullRange: -12.0...6.0,
                endpointLabel: "Black Protection",
                defaultTuning: ToneTuning.defaultV1.shadows,
                resetTitle: "Reset Shadows",
                role: .shadows,
                onReset: resetShadowsSection
            )

            endpointSection(
                title: "Whites Behavior",
                systemImage: "circle.tophalf.filled",
                tuning: $behaviorTuning.toneTuning.whites,
                isExpanded: $whitesExpanded,
                startRange: -4.0...8.0,
                fullRange: -4.0...12.0,
                protectionLabel: "Clip Protection",
                defaultTuning: ToneTuning.defaultV1.whites,
                resetTitle: "Reset Whites",
                role: .whites,
                onReset: resetWhitesSection
            )

            endpointSection(
                title: "Blacks Behavior",
                systemImage: "circle.bottomhalf.filled",
                tuning: $behaviorTuning.toneTuning.blacks,
                isExpanded: $blacksExpanded,
                startRange: -8.0...4.0,
                fullRange: -12.0...4.0,
                protectionLabel: "Crush Protection",
                defaultTuning: ToneTuning.defaultV1.blacks,
                resetTitle: "Reset Blacks",
                role: .blacks,
                onReset: resetBlacksSection
            )

            colorCouplingSection
            perSliderMappingSection
            overlaysSection
        }
    }

    private var exposureFeelSection: some View {
        DRCollapsibleSection(
            "Exposure Feel",
            systemImage: "plus.forwardslash.minus",
            isExpanded: $exposureFeelExpanded,
            resetTitle: "Reset Exposure Feel",
            isResetDisabled: behaviorTuning.exposureFeelTuning == .defaultV2,
            onReset: resetExposureFeelSection
        ) {
            ToneLabExposureShadowCurveEditor(
                tuning: $behaviorTuning.exposureFeelTuning,
                onEditingChanged: handleEditingChanged
            )

            ToneLabSlider(title: "EV Gain Scale", value: $behaviorTuning.exposureFeelTuning.evGainScale, range: 0.25...2.5, defaultValue: ExposureFeelTuning.defaultV2.evGainScale, fractionDigits: 3, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Exposure Response Exponent", value: $behaviorTuning.exposureFeelTuning.responseExponent, range: 0.2...4.0, defaultValue: ExposureFeelTuning.defaultV2.responseExponent, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Black Participation", value: $behaviorTuning.exposureFeelTuning.blackParticipation, range: 0.0...2.0, defaultValue: ExposureFeelTuning.defaultV2.blackParticipation, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Toe Follow Amount", value: $behaviorTuning.exposureFeelTuning.toeFollowAmount, range: 0.0...2.0, defaultValue: ExposureFeelTuning.defaultV2.toeFollowAmount, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Shadow Visibility Per EV", value: $behaviorTuning.exposureFeelTuning.shadowVisibilityPerEV, range: 0.0...1.5, defaultValue: ExposureFeelTuning.defaultV2.shadowVisibilityPerEV, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Exposure Shadow Start EV", value: $behaviorTuning.exposureFeelTuning.shadowStartEV, range: -2.0...2.0, defaultValue: ExposureFeelTuning.defaultV2.shadowStartEV, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Exposure Shadow Full EV", value: $behaviorTuning.exposureFeelTuning.shadowFullEV, range: -8.0...2.0, defaultValue: ExposureFeelTuning.defaultV2.shadowFullEV, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Exposure Shadow Build", value: $behaviorTuning.exposureFeelTuning.shadowFalloff, range: 0.1...4.0, defaultValue: ExposureFeelTuning.defaultV2.shadowFalloff, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Exposure Shadow Midtone Protection", value: $behaviorTuning.exposureFeelTuning.shadowMidtoneProtection, range: 0.0...1.0, defaultValue: ExposureFeelTuning.defaultV2.shadowMidtoneProtection, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Exposure Shadow Endpoint Protection", value: $behaviorTuning.exposureFeelTuning.shadowEndpointProtection, range: 0.0...1.0, defaultValue: ExposureFeelTuning.defaultV2.shadowEndpointProtection, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Exposure Shadow Body Bias", value: $behaviorTuning.exposureFeelTuning.shadowBodyBias, range: -1.0...1.0, defaultValue: ExposureFeelTuning.defaultV2.shadowBodyBias, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Exposure Shadow Peak Damping", value: $behaviorTuning.exposureFeelTuning.shadowPeakDamping, range: 0.0...1.0, defaultValue: ExposureFeelTuning.defaultV2.shadowPeakDamping, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Highlight Protection Per EV", value: $behaviorTuning.exposureFeelTuning.highlightProtectionPerEV, range: 0.0...2.0, defaultValue: ExposureFeelTuning.defaultV2.highlightProtectionPerEV, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Exposure Chroma Response", value: $behaviorTuning.exposureFeelTuning.exposureChromaResponse, range: -1.0...1.0, defaultValue: ExposureFeelTuning.defaultV2.exposureChromaResponse, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Exposure Saturation Min", value: $behaviorTuning.exposureFeelTuning.saturationMin, range: 0.5...1.0, defaultValue: ExposureFeelTuning.defaultV2.saturationMin, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Exposure Saturation Max", value: $behaviorTuning.exposureFeelTuning.saturationMax, range: 1.0...1.5, defaultValue: ExposureFeelTuning.defaultV2.saturationMax, fractionDigits: 2, onEditingChanged: handleEditingChanged)
        }
    }

    private var globalSection: some View {
        DRCollapsibleSection(
            "Global Base Curve",
            systemImage: "circle.lefthalf.filled",
            isExpanded: $globalExpanded,
            resetTitle: "Reset Global Base Curve",
            isResetDisabled: behaviorTuning.toneTuning.global == ToneTuning.defaultV1.global,
            onReset: resetGlobalSection
        ) {
            ToneLabSlider(title: "Middle Gray", value: $behaviorTuning.toneTuning.global.middleGray, range: 0.08...0.35, defaultValue: ToneTuning.defaultV1.global.middleGray, fractionDigits: 3, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Base Contrast", value: $behaviorTuning.toneTuning.global.baseContrast, range: 0.6...1.6, defaultValue: ToneTuning.defaultV1.global.baseContrast, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Toe Strength", value: $behaviorTuning.toneTuning.global.toeStrength, range: 0.0...2.0, defaultValue: ToneTuning.defaultV1.global.toeStrength, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Toe Length EV", value: $behaviorTuning.toneTuning.global.toeLengthEV, range: 0.5...6.0, defaultValue: ToneTuning.defaultV1.global.toeLengthEV, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Shoulder Strength", value: $behaviorTuning.toneTuning.global.shoulderStrength, range: 0.0...2.0, defaultValue: ToneTuning.defaultV1.global.shoulderStrength, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Shoulder Length EV", value: $behaviorTuning.toneTuning.global.shoulderLengthEV, range: 0.5...6.0, defaultValue: ToneTuning.defaultV1.global.shoulderLengthEV, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Output Soft Clip", value: $behaviorTuning.toneTuning.global.outputSoftClip, range: 0.0...2.0, defaultValue: ToneTuning.defaultV1.global.outputSoftClip, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Scene Black EV", value: $behaviorTuning.toneTuning.global.sceneBlackEV, range: -12.0 ... -2.0, defaultValue: ToneTuning.defaultV1.global.sceneBlackEV, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Scene White EV", value: $behaviorTuning.toneTuning.global.sceneWhiteEV, range: 1.0...8.0, defaultValue: ToneTuning.defaultV1.global.sceneWhiteEV, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Display Middle Gray", value: $behaviorTuning.toneTuning.global.displayMiddleGray, range: 0.3...0.6, defaultValue: ToneTuning.defaultV1.global.displayMiddleGray, fractionDigits: 3, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Toe Lift", value: $behaviorTuning.toneTuning.global.toeLift, range: 0.0...1.0, defaultValue: ToneTuning.defaultV1.global.toeLift, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Shoulder Roll Strength", value: $behaviorTuning.toneTuning.global.shoulderRollStrength, range: 0.0...2.0, defaultValue: ToneTuning.defaultV1.global.shoulderRollStrength, fractionDigits: 2, onEditingChanged: handleEditingChanged)
        }
    }

    private var contrastSection: some View {
        DRCollapsibleSection(
            "Contrast / Pivot Behavior",
            systemImage: "arrow.up.left.and.arrow.down.right",
            isExpanded: $contrastExpanded,
            resetTitle: "Reset Contrast / Pivot",
            isResetDisabled: behaviorTuning.toneTuning.contrast == ToneTuning.defaultV1.contrast,
            onReset: resetContrastSection
        ) {
            Picker("Contrast Mode", selection: $behaviorTuning.toneTuning.contrast.mode) {
                ForEach(ContrastMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.menu)

            Toggle("Contrast Affects Saturation", isOn: $behaviorTuning.toneTuning.contrast.affectsSaturation)

            Picker("Contrast Saturation Zone", selection: $behaviorTuning.toneTuning.contrast.saturationZone) {
                ForEach(ToneZoneBias.allCases) { zone in
                    Text(zone.label).tag(zone)
                }
            }
            .pickerStyle(.menu)

            ToneLabSlider(title: "Max Slope Boost", value: $behaviorTuning.toneTuning.contrast.maxSlopeBoost, range: 0.0...3.0, defaultValue: ToneTuning.defaultV1.contrast.maxSlopeBoost, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Max Slope Reduction", value: $behaviorTuning.toneTuning.contrast.maxSlopeReduction, range: 0.0...3.0, defaultValue: ToneTuning.defaultV1.contrast.maxSlopeReduction, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Contrast Softness", value: $behaviorTuning.toneTuning.contrast.contrastSoftness, range: 0.2...4.0, defaultValue: ToneTuning.defaultV1.contrast.contrastSoftness, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Pivot Min EV", value: $behaviorTuning.toneTuning.contrast.pivotMinEV, range: -4.0...0.0, defaultValue: ToneTuning.defaultV1.contrast.pivotMinEV, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Pivot Max EV", value: $behaviorTuning.toneTuning.contrast.pivotMaxEV, range: 0.0...4.0, defaultValue: ToneTuning.defaultV1.contrast.pivotMaxEV, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Contrast Saturation Amount", value: $behaviorTuning.toneTuning.contrast.saturationAmount, range: -0.5...0.5, defaultValue: ToneTuning.defaultV1.contrast.saturationAmount, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Contrast Hue Protection", value: $behaviorTuning.toneTuning.contrast.hueProtection, range: 0.0...1.0, defaultValue: ToneTuning.defaultV1.contrast.hueProtection, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Contrast Neutral Protection", value: $behaviorTuning.toneTuning.contrast.neutralProtection, range: 0.0...1.0, defaultValue: ToneTuning.defaultV1.contrast.neutralProtection, fractionDigits: 2, onEditingChanged: handleEditingChanged)
        }
    }

    private func rangeSection(
        title: String,
        systemImage: String,
        tuning: Binding<RangeToneTuning>,
        isExpanded: Binding<Bool>,
        startRange: ClosedRange<Double>,
        fullRange: ClosedRange<Double>,
        endpointLabel: String,
        defaultTuning: RangeToneTuning,
        resetTitle: String,
        role: ToneLabRangeRole,
        onReset: @escaping () -> Void
    ) -> some View {
        DRCollapsibleSection(
            title,
            systemImage: systemImage,
            isExpanded: isExpanded,
            resetTitle: resetTitle,
            isResetDisabled: tuning.wrappedValue == defaultTuning,
            onReset: onReset
        ) {
            Picker("Falloff Shape", selection: tuning.falloffShape) {
                ForEach(FalloffShape.allCases) { shape in
                    Text(shape.label).tag(shape)
                }
            }
            .pickerStyle(.menu)

            regionalChromaModePicker(
                role.chromaModeLabel,
                selection: tuning.chromaMode
            )

            ToneLabRangeCurveEditor(
                tuning: tuning,
                evLimit: role.curveEVLimit,
                onEditingChanged: handleEditingChanged
            )

            ToneLabSlider(title: "Range Start EV", value: tuning.startEV, range: startRange, defaultValue: defaultTuning.startEV, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Full Strength EV", value: tuning.fullEV, range: fullRange, defaultValue: defaultTuning.fullEV, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Lift Strength EV", value: tuning.maxLiftEV, range: 0.0...8.0, defaultValue: defaultTuning.maxLiftEV, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Pull Strength EV", value: tuning.maxPullEV, range: -8.0...0.0, defaultValue: defaultTuning.maxPullEV, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Build", value: tuning.falloff, range: 0.1...4.0, defaultValue: defaultTuning.falloff, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Body Bias", value: tuning.bodyBias, range: -1.0...1.0, defaultValue: defaultTuning.bodyBias, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Peak Damping", value: tuning.peakDamping, range: 0.0...1.0, defaultValue: defaultTuning.peakDamping, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Midtone Protection", value: tuning.midtoneProtection, range: 0.0...1.0, defaultValue: defaultTuning.midtoneProtection, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: endpointLabel, value: tuning.endpointProtection, range: 0.0...1.0, defaultValue: defaultTuning.endpointProtection, fractionDigits: 2, onEditingChanged: handleEditingChanged)

            if role == .highlights {
                ToneLabSlider(title: "Highlight Lift Desaturation", value: tuning.liftDesaturation, range: 0.0...0.8, defaultValue: defaultTuning.liftDesaturation, fractionDigits: 2, onEditingChanged: handleEditingChanged)
                ToneLabSlider(title: "Highlight Pull Desaturation", value: tuning.pullDesaturation, range: 0.0...0.6, defaultValue: defaultTuning.pullDesaturation, fractionDigits: 2, onEditingChanged: handleEditingChanged)
                ToneLabSlider(title: "Highlight Near-White Desaturation", value: tuning.nearEndpointDesaturation, range: 0.0...0.6, defaultValue: defaultTuning.nearEndpointDesaturation, fractionDigits: 2, onEditingChanged: handleEditingChanged)
                ToneLabSlider(title: "Highlight Saturation Clamp", value: tuning.saturationClamp, range: 0.8...1.5, defaultValue: defaultTuning.saturationClamp, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            } else {
                ToneLabSlider(title: "Shadow Lift Desaturation", value: tuning.liftDesaturation, range: 0.0...0.6, defaultValue: defaultTuning.liftDesaturation, fractionDigits: 2, onEditingChanged: handleEditingChanged)
                ToneLabSlider(title: "Shadow Noise Chroma Protection", value: tuning.noiseChromaProtection, range: 0.0...1.0, defaultValue: defaultTuning.noiseChromaProtection, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            }

            ToneLabSlider(title: "Hue Protection", value: tuning.hueProtection, range: 0.0...1.0, defaultValue: defaultTuning.hueProtection, fractionDigits: 2, onEditingChanged: handleEditingChanged)
        }
    }

    private func endpointSection(
        title: String,
        systemImage: String,
        tuning: Binding<EndpointToneTuning>,
        isExpanded: Binding<Bool>,
        startRange: ClosedRange<Double>,
        fullRange: ClosedRange<Double>,
        protectionLabel: String,
        defaultTuning: EndpointToneTuning,
        resetTitle: String,
        role: ToneLabEndpointRole,
        onReset: @escaping () -> Void
    ) -> some View {
        DRCollapsibleSection(
            title,
            systemImage: systemImage,
            isExpanded: isExpanded,
            resetTitle: resetTitle,
            isResetDisabled: tuning.wrappedValue == defaultTuning,
            onReset: onReset
        ) {
            Picker("Falloff Shape", selection: tuning.falloffShape) {
                ForEach(FalloffShape.allCases) { shape in
                    Text(shape.label).tag(shape)
                }
            }
            .pickerStyle(.menu)

            ToneLabEndpointCurveEditor(
                tuning: tuning,
                evLimit: role.curveEVLimit,
                onEditingChanged: handleEditingChanged
            )

            ToneLabSlider(title: "Range Start EV", value: tuning.startEV, range: startRange, defaultValue: defaultTuning.startEV, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Full Strength EV", value: tuning.fullEV, range: fullRange, defaultValue: defaultTuning.fullEV, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Strength", value: tuning.strength, range: 0.0...2.0, defaultValue: defaultTuning.strength, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Shift Strength EV", value: tuning.maxShiftEV, range: 0.0...8.0, defaultValue: defaultTuning.maxShiftEV, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Build", value: tuning.softness, range: 0.1...6.0, defaultValue: defaultTuning.softness, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Body Bias", value: tuning.bodyBias, range: -1.0...1.0, defaultValue: defaultTuning.bodyBias, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Peak Damping", value: tuning.peakDamping, range: 0.0...1.0, defaultValue: defaultTuning.peakDamping, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: protectionLabel, value: tuning.protection, range: 0.0...1.0, defaultValue: defaultTuning.protection, fractionDigits: 2, onEditingChanged: handleEditingChanged)

            if role == .whites {
                ToneLabSlider(title: "Shoulder Coupling", value: tuning.shoulderCoupling, range: 0.0...1.0, defaultValue: defaultTuning.shoulderCoupling, fractionDigits: 2, onEditingChanged: handleEditingChanged)
                ToneLabSlider(title: "White Chroma Protection", value: tuning.chromaProtection, range: 0.0...1.0, defaultValue: defaultTuning.chromaProtection, fractionDigits: 2, onEditingChanged: handleEditingChanged)
                ToneLabSlider(title: "White Desat Near Clip", value: tuning.desaturationNearClip, range: 0.0...0.6, defaultValue: defaultTuning.desaturationNearClip, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            } else {
                ToneLabSlider(title: "Toe Coupling", value: tuning.toeCoupling, range: 0.0...1.0, defaultValue: defaultTuning.toeCoupling, fractionDigits: 2, onEditingChanged: handleEditingChanged)
                ToneLabSlider(title: "Black Chroma Protection", value: tuning.chromaProtection, range: 0.0...1.0, defaultValue: defaultTuning.chromaProtection, fractionDigits: 2, onEditingChanged: handleEditingChanged)
                ToneLabSlider(title: "Density Saturation Coupling", value: tuning.densitySaturationCoupling, range: -0.3...0.3, defaultValue: defaultTuning.densitySaturationCoupling, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            }
        }
    }

    private var colorCouplingSection: some View {
        DRCollapsibleSection(
            "Color Coupling",
            systemImage: "paintpalette",
            isExpanded: $colorCouplingExpanded,
            resetTitle: "Reset Color Coupling",
            isResetDisabled: behaviorTuning.colorCouplingTuning == .defaultV2,
            onReset: resetColorCouplingSection
        ) {
            toneChromaModePicker(
                "Tone Chroma Mode",
                selection: $behaviorTuning.colorCouplingTuning.toneChromaMode
            )

            ToneLabSlider(title: "Global Chroma Preservation", value: $behaviorTuning.colorCouplingTuning.globalChromaPreservation, range: 0.0...1.0, defaultValue: ColorCouplingTuning.defaultV2.globalChromaPreservation, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Saturation Minimum", value: $behaviorTuning.colorCouplingTuning.saturationMin, range: 0.5...1.0, defaultValue: ColorCouplingTuning.defaultV2.saturationMin, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Saturation Maximum", value: $behaviorTuning.colorCouplingTuning.saturationMax, range: 1.0...1.6, defaultValue: ColorCouplingTuning.defaultV2.saturationMax, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Neutral Protection", value: $behaviorTuning.colorCouplingTuning.neutralProtection, range: 0.0...1.0, defaultValue: ColorCouplingTuning.defaultV2.neutralProtection, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Skin Protection", value: $behaviorTuning.colorCouplingTuning.skinProtection, range: 0.0...1.0, defaultValue: ColorCouplingTuning.defaultV2.skinProtection, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Hue Stability", value: $behaviorTuning.colorCouplingTuning.hueStability, range: 0.0...1.0, defaultValue: ColorCouplingTuning.defaultV2.hueStability, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Gamut Compression Amount", value: $behaviorTuning.colorCouplingTuning.gamutCompressionAmount, range: 0.0...1.0, defaultValue: ColorCouplingTuning.defaultV2.gamutCompressionAmount, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Contrast Saturation Amount", value: $behaviorTuning.colorCouplingTuning.contrastSaturationAmount, range: -0.5...0.5, defaultValue: ColorCouplingTuning.defaultV2.contrastSaturationAmount, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Contrast Saturation Midtone Bias", value: $behaviorTuning.colorCouplingTuning.contrastSaturationMidtoneBias, range: 0.0...2.0, defaultValue: ColorCouplingTuning.defaultV2.contrastSaturationMidtoneBias, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Highlight Pull Desaturation", value: $behaviorTuning.colorCouplingTuning.highlightPullDesaturation, range: 0.0...0.6, defaultValue: ColorCouplingTuning.defaultV2.highlightPullDesaturation, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Highlight Near-White Desaturation", value: $behaviorTuning.colorCouplingTuning.highlightNearWhiteDesaturation, range: 0.0...0.6, defaultValue: ColorCouplingTuning.defaultV2.highlightNearWhiteDesaturation, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Shadow Lift Desaturation", value: $behaviorTuning.colorCouplingTuning.shadowLiftDesaturation, range: 0.0...0.6, defaultValue: ColorCouplingTuning.defaultV2.shadowLiftDesaturation, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Shadow Noise Chroma Protection", value: $behaviorTuning.colorCouplingTuning.shadowNoiseChromaProtection, range: 0.0...1.0, defaultValue: ColorCouplingTuning.defaultV2.shadowNoiseChromaProtection, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Black Density Saturation", value: $behaviorTuning.colorCouplingTuning.blackDensitySaturation, range: -0.3...0.3, defaultValue: ColorCouplingTuning.defaultV2.blackDensitySaturation, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Black Chroma Protection", value: $behaviorTuning.colorCouplingTuning.blackChromaProtection, range: 0.0...1.0, defaultValue: ColorCouplingTuning.defaultV2.blackChromaProtection, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "White Clip Desaturation", value: $behaviorTuning.colorCouplingTuning.whiteClipDesaturation, range: 0.0...0.6, defaultValue: ColorCouplingTuning.defaultV2.whiteClipDesaturation, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "White Chroma Protection", value: $behaviorTuning.colorCouplingTuning.whiteChromaProtection, range: 0.0...1.0, defaultValue: ColorCouplingTuning.defaultV2.whiteChromaProtection, fractionDigits: 2, onEditingChanged: handleEditingChanged)
        }
    }

    private func regionalChromaModePicker(
        _ title: String,
        selection: Binding<RegionalChromaMode>
    ) -> some View {
        HStack(spacing: DarkRoomDesign.Spacing.small) {
            HStack(spacing: DarkRoomDesign.Spacing.xSmall) {
                Text(title)
                    .font(DarkRoomDesign.Typography.controlLabel)
                    .foregroundStyle(DarkRoomDesign.Palette.subtleText)

                if let helpText = ToneLabHelpText.text(for: title) {
                    DRHelpPopoverButton(title: title, helpText: helpText)
                }
            }

            Spacer()

            Picker("", selection: selection) {
                ForEach(RegionalChromaMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(width: 180)
        }
    }

    private func toneChromaModePicker(
        _ title: String,
        selection: Binding<ToneChromaMode>
    ) -> some View {
        HStack(spacing: DarkRoomDesign.Spacing.small) {
            HStack(spacing: DarkRoomDesign.Spacing.xSmall) {
                Text(title)
                    .font(DarkRoomDesign.Typography.controlLabel)
                    .foregroundStyle(DarkRoomDesign.Palette.subtleText)

                if let helpText = ToneLabHelpText.text(for: title) {
                    DRHelpPopoverButton(title: title, helpText: helpText)
                }
            }

            Spacer()

            Picker("", selection: selection) {
                ForEach(ToneChromaMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(width: 180)
        }
    }

    private var perSliderMappingSection: some View {
        DRCollapsibleSection(
            "Per-Slider Mapping",
            systemImage: "dial.low",
            isExpanded: $sliderMappingExpanded,
            resetTitle: "Reset Per-Slider Mapping",
            isResetDisabled: behaviorTuning.sliderMappings == .defaultV1,
            onReset: resetSliderMappingSection
        ) {
            Picker("Slider", selection: $mappingTarget) {
                ForEach(ToneLabMappingTarget.allCases) { target in
                    Text(target.label).tag(target)
                }
            }
            .pickerStyle(.menu)

            ToneLabSliderResponseGraph(
                target: mappingTarget,
                mapping: mappingTarget.mappingBinding(in: $behaviorTuning.sliderMappings),
                defaultMapping: mappingTarget.defaultMapping,
                currentSliderPosition: mappingTarget.sliderPosition(in: toneRecipe)
            )

            mappingControls(
                mappingTarget.mappingBinding(in: $behaviorTuning.sliderMappings),
                defaultMapping: mappingTarget.defaultMapping
            )
        }
    }

    private func mappingControls(_ mapping: Binding<PerSliderMapping>, defaultMapping: PerSliderMapping) -> some View {
        Group {
            ToneLabSlider(title: "Near Zero Sensitivity", value: mapping.nearZeroSensitivity, range: 0.0...2.0, defaultValue: defaultMapping.nearZeroSensitivity, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Mid Sensitivity", value: mapping.midSensitivity, range: 0.0...2.0, defaultValue: defaultMapping.midSensitivity, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Extreme Sensitivity", value: mapping.extremeSensitivity, range: 0.0...2.0, defaultValue: defaultMapping.extremeSensitivity, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Response Exponent", value: mapping.responseExponent, range: 0.25...3.0, defaultValue: defaultMapping.responseExponent, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Soft Limit", value: mapping.softLimit, range: 0.1...1.0, defaultValue: defaultMapping.softLimit, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Dead Zone", value: mapping.deadZone, range: 0.0...0.2, defaultValue: defaultMapping.deadZone, fractionDigits: 3, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Positive / Negative Symmetry", value: mapping.positiveNegativeSymmetry, range: 0.0...2.0, defaultValue: defaultMapping.positiveNegativeSymmetry, fractionDigits: 2, onEditingChanged: handleEditingChanged)
        }
    }

    private var overlaysSection: some View {
        DRCollapsibleSection(
            "Overlays / Diagnostics",
            systemImage: "scope",
            isExpanded: $overlaysExpanded,
            resetTitle: "Reset Overlay Tuning",
            isResetDisabled: behaviorTuning.overlayTuning == .defaultV2 && overlay == .off,
            onReset: resetOverlaysSection
        ) {
            Picker("Overlay", selection: $overlay) {
                ForEach(ToneRangeOverlay.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
            .pickerStyle(.menu)

            ToneLabSlider(title: "Influence Opacity", value: $behaviorTuning.overlayTuning.influenceOpacity, range: 0.0...1.0, defaultValue: OverlayTuning.defaultV2.influenceOpacity, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Saturation Overlay Scale", value: $behaviorTuning.overlayTuning.saturationOverlayScale, range: 0.0...2.0, defaultValue: OverlayTuning.defaultV2.saturationOverlayScale, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Neutral Drift Threshold", value: $behaviorTuning.overlayTuning.neutralDriftThreshold, range: 0.0...0.2, defaultValue: OverlayTuning.defaultV2.neutralDriftThreshold, fractionDigits: 3, onEditingChanged: handleEditingChanged)
        }
    }

    private var candidateBar: some View {
        VStack(alignment: .leading, spacing: DarkRoomDesign.Spacing.small) {
            HStack {
                Button("Copy JSON", action: copyJSON)
                    .buttonStyle(.borderedProminent)
                Button("Load JSON", action: loadJSONFromClipboard)
                    .buttonStyle(.bordered)
                Button("Candidate 01", action: loadSuggestedCandidate)
                    .buttonStyle(.bordered)
                Spacer()
            }

            HStack {
                Button("Save Local", action: saveCandidateLocally)
                    .buttonStyle(.bordered)
                Button("Load Local", action: loadCandidateLocally)
                    .buttonStyle(.bordered)
                Button("Compare", action: compareCurrentToDefault)
                    .buttonStyle(.bordered)
                Button("Reset All", action: resetAll)
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

    private func applySweepValue(_ value: Double) {
        sweepSlider.applySweepValue(value, to: &toneRecipe)
        if soloSlider == .all {
            soloSlider = sweepSlider
        }
        copyStatus = "Previewing \(sweepSlider.label) at \(value.formatted(.number.precision(.fractionLength(0))))"
    }

    private func copyJSON() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(behaviorTuning.prettyPrintedJSON, forType: .string)
        copyStatus = "Copied \(behaviorTuning.name)"
    }

    private func loadJSONFromClipboard() {
        guard let json = NSPasteboard.general.string(forType: .string) else {
            copyStatus = "Clipboard does not contain JSON"
            return
        }

        loadCandidateJSON(json, source: "clipboard")
    }

    private func saveCandidateLocally() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "\(behaviorTuning.name).json"

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        do {
            try behaviorTuning.prettyPrintedJSON.write(to: url, atomically: true, encoding: .utf8)
            copyStatus = "Saved \(url.lastPathComponent)"
        } catch {
            copyStatus = "Could not save candidate"
        }
    }

    private func loadCandidateLocally() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        do {
            let json = try String(contentsOf: url, encoding: .utf8)
            loadCandidateJSON(json, source: url.lastPathComponent)
        } catch {
            copyStatus = "Could not read candidate"
        }
    }

    private func loadCandidateJSON(_ json: String, source: String) {
        let data = Data(json.utf8)
        let decoder = JSONDecoder()

        if let behavior = try? decoder.decode(BehaviorTuning.self, from: data) {
            behaviorTuning = behavior
            copyStatus = "Loaded behavior JSON from \(source)"
            return
        }

        if let tone = try? decoder.decode(ToneTuning.self, from: data) {
            behaviorTuning.toneTuning = tone
            behaviorTuning.sliderMappings = tone.sliderMappings
            copyStatus = "Loaded tone tuning JSON from \(source)"
            return
        }

        copyStatus = "Could not decode JSON from \(source)"
    }

    private func compareCurrentToDefault() {
        var changedSections: [String] = []
        if behaviorTuning.toneTuning.global != ToneTuning.defaultV1.global { changedSections.append("global") }
        if behaviorTuning.exposureFeelTuning != .defaultV2 { changedSections.append("exposure feel") }
        if behaviorTuning.toneTuning.contrast != ToneTuning.defaultV1.contrast { changedSections.append("contrast") }
        if behaviorTuning.toneTuning.highlights != ToneTuning.defaultV1.highlights { changedSections.append("highlights") }
        if behaviorTuning.toneTuning.shadows != ToneTuning.defaultV1.shadows { changedSections.append("shadows") }
        if behaviorTuning.toneTuning.whites != ToneTuning.defaultV1.whites { changedSections.append("whites") }
        if behaviorTuning.toneTuning.blacks != ToneTuning.defaultV1.blacks { changedSections.append("blacks") }
        if behaviorTuning.colorCouplingTuning != .defaultV2 { changedSections.append("color") }
        if behaviorTuning.sliderMappings != .defaultV1 { changedSections.append("mappings") }
        if behaviorTuning.viewTransformTuning != .defaultV2 { changedSections.append("view transform") }
        if behaviorTuning.overlayTuning != .defaultV2 { changedSections.append("overlays") }

        copyStatus = changedSections.isEmpty ? "Matches defaults" : "Changed: \(changedSections.joined(separator: ", "))"
    }

    private func resetAll() {
        behaviorTuning = .defaultV2
        finishSectionReset("Reset all behavior tuning")
    }

    private func resetRecipeSection() {
        toneRecipe = .neutral
        soloSlider = .all
        finishSectionReset("Reset test light sliders")
    }

    private func resetExposureFeelSection() {
        behaviorTuning.exposureFeelTuning = .defaultV2
        finishSectionReset("Reset exposure feel")
    }

    private func resetGlobalSection() {
        behaviorTuning.toneTuning.global = ToneTuning.defaultV1.global
        finishSectionReset("Reset global base curve")
    }

    private func resetContrastSection() {
        behaviorTuning.toneTuning.contrast = ToneTuning.defaultV1.contrast
        finishSectionReset("Reset contrast / pivot")
    }

    private func resetHighlightsSection() {
        behaviorTuning.toneTuning.highlights = ToneTuning.defaultV1.highlights
        finishSectionReset("Reset highlights")
    }

    private func resetShadowsSection() {
        behaviorTuning.toneTuning.shadows = ToneTuning.defaultV1.shadows
        finishSectionReset("Reset shadows")
    }

    private func resetWhitesSection() {
        behaviorTuning.toneTuning.whites = ToneTuning.defaultV1.whites
        finishSectionReset("Reset whites")
    }

    private func resetBlacksSection() {
        behaviorTuning.toneTuning.blacks = ToneTuning.defaultV1.blacks
        finishSectionReset("Reset blacks")
    }

    private func resetColorCouplingSection() {
        behaviorTuning.colorCouplingTuning = .defaultV2
        finishSectionReset("Reset color coupling")
    }

    private func resetSliderMappingSection() {
        behaviorTuning.sliderMappings = .defaultV1
        finishSectionReset("Reset per-slider mapping")
    }

    private func resetOverlaysSection() {
        overlay = .off
        behaviorTuning.overlayTuning = .defaultV2
        finishSectionReset("Reset overlays")
    }

    private func loadSuggestedCandidate() {
        behaviorTuning = .suggestedCandidate01
        copyStatus = "Loaded suggested candidate 01"
    }

    private func finishSectionReset(_ message: String) {
        isInteractiveEditing = false
        copyStatus = message
    }
}

private struct ToneLabSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let defaultValue: Double
    var fractionDigits = 2
    var onEditingChanged: (Bool) -> Void

    var body: some View {
        DRAdjustmentRow(
            title: title,
            value: $value,
            range: range,
            displayValue: formattedValue,
            helpText: ToneLabHelpText.text(for: title),
            resetValue: defaultValue,
            showsHelpButton: true,
            onEditingChanged: onEditingChanged
        )
    }

    private var formattedValue: String {
        value.formatted(.number.precision(.fractionLength(fractionDigits)))
    }
}

private enum ToneLabHelpText {
    static func text(for title: String) -> String? {
        switch title {
        case "Exposure":
            "Moves overall brightness in real stops before tone shaping."
        case "Contrast":
            "Changes tonal separation around the pivot without reversing the tone curve."
        case "Pivot":
            "Moves the balance point that contrast expands around."
        case "Highlights":
            "Pushes or pulls bright values through the tuned highlight range and fade."
        case "Shadows":
            "Opens or deepens darker values through the tuned shadow range and fade."
        case "Whites":
            "Shapes the approach to white and the shoulder."
        case "Blacks":
            "Shapes the approach to black and the toe."
        case "EV Gain Scale":
            "Scales only the hidden behavior helpers that react to exposure. The real exposure gain still uses camera-like stops."
        case "Exposure Response Exponent":
            "Changes whether exposure response feels faster near zero or stronger near the ends."
        case "Black Participation":
            "Controls how much positive exposure is allowed to add black and deep-shadow visibility."
        case "Toe Follow Amount":
            "Lets the toe follow exposure so lifted shadows stay smoother."
        case "Shadow Visibility Per EV":
            "Sets the amount of extra shadow lift added for each positive exposure stop."
        case "Exposure Shadow Start EV":
            "Scene stop where positive-exposure shadow visibility begins. Move it upward to let midtones participate sooner."
        case "Exposure Shadow Full EV":
            "Scene stop where positive-exposure shadow visibility reaches full strength. Push it deeper to pull blacks into the response."
        case "Exposure Shadow Build":
            "How quickly the exposure shadow lift builds between the start and full-strength stops."
        case "Exposure Shadow Midtone Protection":
            "Reduces the exposure shadow lift near midtones while keeping deeper shadows active."
        case "Exposure Shadow Endpoint Protection":
            "Reduces the exposure shadow lift at the deepest end so blacks stay anchored."
        case "Exposure Shadow Body Bias":
            "Moves more of the exposure shadow lift into the body of the selected range without changing the endpoints."
        case "Exposure Shadow Peak Damping":
            "Softens the full-strength part of the exposure shadow lift curve."
        case "Highlight Protection Per EV":
            "Sets how strongly highlights are protected as exposure rises."
        case "Exposure Chroma Response":
            "Couples exposure movement to saturation behavior."
        case "Exposure Saturation Min":
            "Lowest saturation scale exposure behavior may apply."
        case "Exposure Saturation Max":
            "Highest saturation scale exposure behavior may apply."
        case "Middle Gray":
            "Reference gray that anchors scene-linear tone behavior."
        case "Base Contrast":
            "Default tone-scale contrast before slider-specific changes."
        case "Toe Strength":
            "How strongly the dark-end curve bends into the toe."
        case "Toe Length EV":
            "How much scene range the toe occupies."
        case "Shoulder Strength":
            "How strongly the bright-end curve bends into the shoulder."
        case "Shoulder Length EV":
            "How much scene range the shoulder occupies."
        case "Output Soft Clip":
            "Softens the final approach to display white."
        case "Scene Black EV":
            "Scene stop used as the practical black boundary."
        case "Scene White EV":
            "Scene stop used as the practical white boundary."
        case "Display Middle Gray":
            "Display-side gray target used by the tone scale."
        case "Toe Lift":
            "Raises the lowest tones before the curve reaches black."
        case "Shoulder Roll Strength":
            "Adds extra highlight rolloff near the top of the display range."
        case "Max Slope Boost":
            "Maximum contrast increase available at the positive end."
        case "Max Slope Reduction":
            "Maximum contrast decrease available at the negative end."
        case "Contrast Softness":
            "Controls how gradually contrast builds around the pivot."
        case "Pivot Min EV":
            "Lowest allowed pivot position in scene stops."
        case "Pivot Max EV":
            "Highest allowed pivot position in scene stops."
        case "Contrast Saturation Amount":
            "How much contrast movement changes saturation."
        case "Contrast Hue Protection":
            "Centered on reset. Raise it to damp contrast-driven color drift; lower it to let contrast move color more freely."
        case "Contrast Neutral Protection":
            "How strongly contrast protects near-neutral colors."
        case "Range Start EV":
            "Scene stop where this tonal range starts to fade in."
        case "Full Strength EV":
            "Scene stop where this tonal range reaches full influence."
        case "Lift Strength EV":
            "Maximum positive lift available to this range."
        case "Pull Strength EV":
            "Maximum negative pull available to this range."
        case "Strength":
            "Overall endpoint control strength."
        case "Shift Strength EV":
            "Maximum endpoint shift in scene stops."
        case "Build":
            "How quickly influence builds between start and full strength."
        case "Body Bias":
            "Moves more influence into the body of the range without changing the endpoints."
        case "Peak Damping":
            "Softens how the influence curve approaches full strength before it reaches the far end."
        case "Midtone Protection":
            "Keeps this control from spilling too heavily into midtones."
        case "White Protection", "Black Protection", "Clip Protection", "Crush Protection":
            "Reduces extra influence past full strength so the far endpoint is less likely to clip or crush."
        case "Tone Chroma Mode":
            "Chooses the broad color behavior after luminance tone changes: ratio preserve keeps color closest, luminance preserve quiets bright color, per-channel RGB is more assertive, and hybrid splits the difference."
        case "Highlight Chroma Mode":
            "Chooses how highlight moves affect color. Preserve keeps the old response, Desaturate Pull emphasizes highlight pull-down cleanup, Protect Chroma limits strong high-end color, and Hybrid also damps lifted highlights."
        case "Shadow Chroma Mode":
            "Chooses how shadow moves affect color. Preserve keeps the old response, Protect Chroma and Hybrid reduce color lift when shadows are opened."
        case "Highlight Lift Desaturation":
            "Desaturates highlights as they are lifted upward, which is the control to use when bright colors feel too preserved."
        case "Highlight Pull Desaturation":
            "Desaturates highlights as they are pulled down; it has little effect when the Highlights slider is lifting upward."
        case "Highlight Near-White Desaturation":
            "Reduces color near the white endpoint."
        case "Highlight Saturation Clamp":
            "Caps saturation while highlight controls are active."
        case "Shadow Lift Desaturation":
            "Reduces color lift artifacts when shadows are opened."
        case "Shadow Noise Chroma Protection":
            "Centered on reset. Raise it to damp chroma changes in deep lifted shadows; lower it to let shadow color move more."
        case "Hue Protection":
            "Centered on reset. Raise it to damp hue/chroma shifts in this range; lower it to let the range color response breathe."
        case "Shoulder Coupling":
            "Couples the whites control to the global shoulder."
        case "White Chroma Protection":
            "Centered on reset. Raise it to protect high-end chroma while whites move; lower it to allow stronger white-end color response."
        case "White Desat Near Clip":
            "Desaturates color as whites approach clipping."
        case "Toe Coupling":
            "Couples the blacks control to the global toe."
        case "Black Chroma Protection":
            "Centered on reset. Raise it to protect low-end chroma while blacks move; lower it to allow stronger black-end color response."
        case "Density Saturation Coupling":
            "Changes saturation as black density increases or relaxes."
        case "Global Chroma Preservation":
            "Directly scales how much chroma survives tone changes. Lower values make color changes easier to see."
        case "Saturation Minimum":
            "Lower clamp for the final saturation scale. It is most visible when another chroma control tries to desaturate below this floor."
        case "Saturation Maximum":
            "Upper clamp for the final saturation scale. It is most visible when another chroma control tries to push color above this ceiling."
        case "Neutral Protection":
            "Protects near-gray color from unwanted saturation movement."
        case "Skin Protection":
            "Centered on reset. Raise it to protect skin-like warm hues from chroma shifts; lower it to let those hues follow the grade more."
        case "Hue Stability":
            "Centered on reset. Raise it to damp color movement near gamut edges; lower it to make hue/chroma response more permissive."
        case "Gamut Compression Amount":
            "Pulls saturated high-risk colors inward before channel clipping. Most visible on bright saturated colors."
        case "Contrast Saturation Midtone Bias":
            "Focuses contrast saturation coupling around midtones or away from them."
        case "Black Density Saturation":
            "Changes saturation as black density is added."
        case "White Clip Desaturation":
            "Reduces saturation near clipped white."
        case "Near Zero Sensitivity":
            "How quickly the slider wakes up around neutral."
        case "Mid Sensitivity":
            "How much response the middle of the slider travel has."
        case "Extreme Sensitivity":
            "How much response the ends of the slider travel keep."
        case "Response Exponent":
            "Bends the response curve toward slower starts or faster endings."
        case "Soft Limit":
            "Caps maximum internal response before a slider reaches the end."
        case "Dead Zone":
            "Neutral area around zero where movement has no effect."
        case "Positive / Negative Symmetry":
            "Scales the negative side compared with the positive side."
        case "Influence Opacity":
            "Opacity of range and diagnostic overlays."
        case "Saturation Overlay Scale":
            "How strongly saturation diagnostics are visualized."
        case "Neutral Drift Threshold":
            "Amount of neutral movement needed before neutral-drift diagnostics light up."
        default:
            nil
        }
    }
}

private struct ToneLabSliderResponseGraph: View {
    let target: ToneLabMappingTarget
    let mapping: Binding<PerSliderMapping>
    let defaultMapping: PerSliderMapping
    let currentSliderPosition: Double

    private let height: CGFloat = 150

    var body: some View {
        VStack(alignment: .leading, spacing: DarkRoomDesign.Spacing.small) {
            HStack {
                Text("\(target.label) Response")
                    .font(DarkRoomDesign.Typography.controlLabel)
                    .foregroundStyle(DarkRoomDesign.Palette.primaryText)

                Spacer()

                Text("\(currentSliderPosition.formatted(.number.precision(.fractionLength(0))))")
                    .font(DarkRoomDesign.Typography.controlValue)
                    .foregroundStyle(DarkRoomDesign.Palette.subtleText)
            }

            GeometryReader { proxy in
                Canvas { context, canvasSize in
                    drawGraph(context: context, size: canvasSize)
                }
                .overlay(alignment: .bottomLeading) {
                    legend
                        .padding(.leading, DarkRoomDesign.Spacing.small)
                        .padding(.bottom, DarkRoomDesign.Spacing.xSmall)
                }
            }
            .frame(height: height)

            HStack {
                responseReadout("-50", response(slider: -50, mapping: mapping.wrappedValue))
                responseReadout("0", response(slider: 0, mapping: mapping.wrappedValue))
                responseReadout("+50", response(slider: 50, mapping: mapping.wrappedValue))
                responseReadout("Limit", mapping.wrappedValue.softLimit)
            }
        }
        .padding(DarkRoomDesign.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(DarkRoomDesign.Palette.inspectorRaised)
        )
        .help("White curve is the current mapping. Gray curve is the production default. The center band is dead zone, and horizontal guides show the soft limit.")
    }

    private var legend: some View {
        HStack(spacing: DarkRoomDesign.Spacing.small) {
            legendItem("Default", color: DarkRoomDesign.Palette.subtleText)
            legendItem("Current", color: DarkRoomDesign.Palette.primaryText)
            legendItem("Dead", color: .orange.opacity(0.8))
            legendItem("Limit", color: .yellow.opacity(0.8))
        }
    }

    private func legendItem(_ label: String, color: Color) -> some View {
        HStack(spacing: DarkRoomDesign.Spacing.xSmall) {
            Capsule()
                .fill(color)
                .frame(width: 12, height: 3)
            Text(label)
                .font(DarkRoomDesign.Typography.detailLabel)
                .foregroundStyle(DarkRoomDesign.Palette.subtleText)
        }
    }

    private func drawGraph(context: GraphicsContext, size: CGSize) {
        drawGrid(context: context, size: size)
        drawDeadZone(context: context, size: size)
        drawSoftLimit(context: context, size: size)
        drawCurve(
            context: context,
            size: size,
            mapping: defaultMapping,
            color: DarkRoomDesign.Palette.subtleText.opacity(0.65),
            style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round, dash: [4, 4])
        )
        drawCurve(
            context: context,
            size: size,
            mapping: mapping.wrappedValue,
            color: DarkRoomDesign.Palette.primaryText,
            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
        )
        drawCurrentPosition(context: context, size: size)
    }

    private func drawGrid(context: GraphicsContext, size: CGSize) {
        var grid = Path()
        for slider in stride(from: -50.0, through: 50.0, by: 50.0) {
            let x = point(slider: slider, response: 0, size: size).x
            grid.move(to: CGPoint(x: x, y: 0))
            grid.addLine(to: CGPoint(x: x, y: size.height))
        }
        for response in stride(from: -0.5, through: 0.5, by: 0.5) {
            let y = point(slider: 0, response: response, size: size).y
            grid.move(to: CGPoint(x: 0, y: y))
            grid.addLine(to: CGPoint(x: size.width, y: y))
        }
        context.stroke(grid, with: .color(DarkRoomDesign.Palette.inspectorBorder.opacity(0.7)), lineWidth: 1)

        var zeroAxis = Path()
        zeroAxis.move(to: CGPoint(x: 0, y: point(slider: 0, response: 0, size: size).y))
        zeroAxis.addLine(to: CGPoint(x: size.width, y: point(slider: 0, response: 0, size: size).y))
        context.stroke(zeroAxis, with: .color(DarkRoomDesign.Palette.sliderTrack.opacity(0.45)), lineWidth: 1)
    }

    private func drawDeadZone(context: GraphicsContext, size: CGSize) {
        let deadZone = mapping.wrappedValue.deadZone.clamped(to: 0...0.95)
        guard deadZone > 0 else {
            return
        }

        let left = point(slider: -deadZone * 100, response: 0, size: size).x
        let right = point(slider: deadZone * 100, response: 0, size: size).x
        let rect = CGRect(x: left, y: 0, width: max(right - left, 1), height: size.height)
        context.fill(Path(rect), with: .color(.orange.opacity(0.14)))
    }

    private func drawSoftLimit(context: GraphicsContext, size: CGSize) {
        let limit = mapping.wrappedValue.softLimit.clamped(to: 0.05...1.0)
        guard limit < 0.999 else {
            return
        }

        var guides = Path()
        for response in [limit, -limit] {
            let y = point(slider: 0, response: response, size: size).y
            guides.move(to: CGPoint(x: 0, y: y))
            guides.addLine(to: CGPoint(x: size.width, y: y))
        }
        context.stroke(guides, with: .color(.yellow.opacity(0.48)), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
    }

    private func drawCurve(
        context: GraphicsContext,
        size: CGSize,
        mapping: PerSliderMapping,
        color: Color,
        style: StrokeStyle
    ) {
        var path = Path()
        let samples = 160
        for index in 0...samples {
            let slider = -100.0 + 200.0 * Double(index) / Double(samples)
            let nextPoint = point(slider: slider, response: response(slider: slider, mapping: mapping), size: size)
            if index == 0 {
                path.move(to: nextPoint)
            } else {
                path.addLine(to: nextPoint)
            }
        }
        context.stroke(path, with: .color(color), style: style)
    }

    private func drawCurrentPosition(context: GraphicsContext, size: CGSize) {
        let slider = currentSliderPosition.clamped(to: -100...100)
        let currentResponse = response(slider: slider, mapping: mapping.wrappedValue)
        let graphPoint = point(slider: slider, response: currentResponse, size: size)

        var marker = Path()
        marker.move(to: CGPoint(x: graphPoint.x, y: 0))
        marker.addLine(to: CGPoint(x: graphPoint.x, y: size.height))
        context.stroke(marker, with: .color(.cyan.opacity(0.55)), style: StrokeStyle(lineWidth: 1, dash: [2, 3]))

        let rect = CGRect(x: graphPoint.x - 4, y: graphPoint.y - 4, width: 8, height: 8)
        context.fill(Path(ellipseIn: rect), with: .color(DarkRoomDesign.Palette.inspectorBackground))
        context.stroke(Path(ellipseIn: rect), with: .color(.cyan.opacity(0.9)), lineWidth: 1.5)
    }

    private func response(slider: Double, mapping: PerSliderMapping) -> Double {
        DarkroomCoreLightMath.sliderResponse(slider: slider, mapping: mapping).clamped(to: -1...1)
    }

    private func point(slider: Double, response: Double, size: CGSize) -> CGPoint {
        CGPoint(
            x: size.width * CGFloat((slider.clamped(to: -100...100) + 100) / 200),
            y: size.height * CGFloat(1 - ((response.clamped(to: -1...1) + 1) / 2))
        )
    }

    private func responseReadout(_ label: String, _ value: Double) -> some View {
        Text("\(label) \(value.formatted(.number.precision(.fractionLength(2))))")
            .font(DarkRoomDesign.Typography.controlValue)
            .foregroundStyle(DarkRoomDesign.Palette.subtleText)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}

private struct ToneLabExposureShadowCurveEditor: View {
    let tuning: Binding<ExposureFeelTuning>
    let onEditingChanged: (Bool) -> Void

    private let evLimit = 8.0

    var body: some View {
        ToneLabCurveCanvas(
            title: "Exposure Shadow Lift Curve",
            startEV: Binding(
                get: { tuning.wrappedValue.shadowStartEV },
                set: { updateStart($0) }
            ),
            fullEV: Binding(
                get: { tuning.wrappedValue.shadowFullEV },
                set: { updateFull($0) }
            ),
            bodyBias: tuning.shadowBodyBias,
            peakDamping: tuning.shadowPeakDamping,
            evLimit: evLimit,
            sample: { position in
                DarkroomCoreLightMath.zoneInfluenceSample(
                    distanceEV: position,
                    startEV: tuning.wrappedValue.shadowStartEV,
                    fullEV: tuning.wrappedValue.shadowFullEV,
                    falloff: tuning.wrappedValue.shadowFalloff,
                    midtoneProtection: tuning.wrappedValue.shadowMidtoneProtection,
                    endpointProtection: tuning.wrappedValue.shadowEndpointProtection,
                    falloffShape: .smooth,
                    bodyBias: tuning.wrappedValue.shadowBodyBias,
                    peakDamping: tuning.wrappedValue.shadowPeakDamping
                )
            },
            onEditingChanged: onEditingChanged
        )
    }

    private func updateStart(_ position: Double) {
        var next = tuning.wrappedValue
        next.shadowStartEV = min(max(position, -evLimit), evLimit)
        tuning.wrappedValue = next
    }

    private func updateFull(_ position: Double) {
        var next = tuning.wrappedValue
        next.shadowFullEV = min(max(position, -evLimit), evLimit)
        tuning.wrappedValue = next
    }
}

private struct ToneLabRangeCurveEditor: View {
    let tuning: Binding<RangeToneTuning>
    let evLimit: Double
    let onEditingChanged: (Bool) -> Void

    var body: some View {
        ToneLabCurveCanvas(
            title: "Influence Curve",
            startEV: Binding(
                get: { tuning.wrappedValue.startEV },
                set: { updateStart($0) }
            ),
            fullEV: Binding(
                get: { tuning.wrappedValue.fullEV },
                set: { updateFull($0) }
            ),
            bodyBias: tuning.bodyBias,
            peakDamping: tuning.peakDamping,
            evLimit: evLimit,
            sample: { position in
                DarkroomCoreLightMath.zoneInfluenceSample(
                    distanceEV: position,
                    startEV: tuning.wrappedValue.startEV,
                    fullEV: tuning.wrappedValue.fullEV,
                    falloff: tuning.wrappedValue.falloff,
                    midtoneProtection: tuning.wrappedValue.midtoneProtection,
                    endpointProtection: tuning.wrappedValue.endpointProtection,
                    falloffShape: tuning.wrappedValue.falloffShape,
                    bodyBias: tuning.wrappedValue.bodyBias,
                    peakDamping: tuning.wrappedValue.peakDamping
                )
            },
            onEditingChanged: onEditingChanged
        )
    }

    private func updateStart(_ position: Double) {
        var next = tuning.wrappedValue
        next.startEV = min(max(position, -evLimit), evLimit)
        tuning.wrappedValue = next
    }

    private func updateFull(_ position: Double) {
        var next = tuning.wrappedValue
        next.fullEV = min(max(position, -evLimit), evLimit)
        tuning.wrappedValue = next
    }
}

private struct ToneLabEndpointCurveEditor: View {
    let tuning: Binding<EndpointToneTuning>
    let evLimit: Double
    let onEditingChanged: (Bool) -> Void

    var body: some View {
        ToneLabCurveCanvas(
            title: "Endpoint Curve",
            startEV: Binding(
                get: { tuning.wrappedValue.startEV },
                set: { updateStart($0) }
            ),
            fullEV: Binding(
                get: { tuning.wrappedValue.fullEV },
                set: { updateFull($0) }
            ),
            bodyBias: tuning.bodyBias,
            peakDamping: tuning.peakDamping,
            evLimit: evLimit,
            sample: { position in
                DarkroomCoreLightMath.zoneInfluenceSample(
                    distanceEV: position,
                    startEV: tuning.wrappedValue.startEV,
                    fullEV: tuning.wrappedValue.fullEV,
                    falloff: tuning.wrappedValue.softness,
                    midtoneProtection: 0,
                    endpointProtection: tuning.wrappedValue.protection,
                    falloffShape: tuning.wrappedValue.falloffShape,
                    bodyBias: tuning.wrappedValue.bodyBias,
                    peakDamping: tuning.wrappedValue.peakDamping
                )
            },
            onEditingChanged: onEditingChanged
        )
    }

    private func updateStart(_ position: Double) {
        var next = tuning.wrappedValue
        next.startEV = min(max(position, -evLimit), evLimit)
        tuning.wrappedValue = next
    }

    private func updateFull(_ position: Double) {
        var next = tuning.wrappedValue
        next.fullEV = min(max(position, -evLimit), evLimit)
        tuning.wrappedValue = next
    }
}

private struct ToneLabCurveCanvas: View {
    let title: String
    @Binding var startEV: Double
    @Binding var fullEV: Double
    @Binding var bodyBias: Double
    @Binding var peakDamping: Double
    let evLimit: Double
    let sample: (Double) -> Double
    let onEditingChanged: (Bool) -> Void

    private let height: CGFloat = 150
    private let handleSize: CGFloat = 12

    var body: some View {
        VStack(alignment: .leading, spacing: DarkRoomDesign.Spacing.small) {
            HStack {
                Text(title)
                    .font(DarkRoomDesign.Typography.controlLabel)
                    .foregroundStyle(DarkRoomDesign.Palette.primaryText)

                Spacer()

                Text("±\(evLimit.formatted(.number.precision(.fractionLength(0)))) EV")
                    .font(DarkRoomDesign.Typography.controlValue)
                    .foregroundStyle(DarkRoomDesign.Palette.subtleText)
            }

            GeometryReader { proxy in
                ZStack {
                    curveBackground(size: proxy.size)

                    handle("Range Start", at: point(position: startEV, influence: 0, size: proxy.size))
                        .gesture(evDrag(size: proxy.size) { startEV = $0 })

                    handle("Full Strength", at: point(position: fullEV, influence: 1, size: proxy.size))
                        .gesture(evDrag(size: proxy.size) { fullEV = $0 })

                    handle("Body", at: point(position: (startEV + fullEV) * 0.5, influence: (bodyBias + 1) * 0.5, size: proxy.size))
                        .gesture(unitDrag(size: proxy.size) { bodyBias = min(max($0 * 2 - 1, -1), 1) })

                    handle("Peak", at: point(position: peakHandlePosition, influence: 1 - peakDamping, size: proxy.size))
                        .gesture(unitDrag(size: proxy.size) { peakDamping = min(max(1 - $0, 0), 1) })
                }
            }
            .frame(height: height)

            HStack {
                curveReadout("Start", startEV)
                curveReadout("Full", fullEV)
                curveReadout("Body", bodyBias)
                curveReadout("Peak", peakDamping)
            }
        }
        .padding(DarkRoomDesign.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(DarkRoomDesign.Palette.inspectorRaised)
        )
    }

    private func curveBackground(size: CGSize) -> some View {
        Canvas { context, canvasSize in
            var grid = Path()
            for fraction in stride(from: 0.25, through: 0.75, by: 0.25) {
                grid.move(to: CGPoint(x: canvasSize.width * fraction, y: 0))
                grid.addLine(to: CGPoint(x: canvasSize.width * fraction, y: canvasSize.height))
                grid.move(to: CGPoint(x: 0, y: canvasSize.height * fraction))
                grid.addLine(to: CGPoint(x: canvasSize.width, y: canvasSize.height * fraction))
            }
            context.stroke(grid, with: .color(DarkRoomDesign.Palette.inspectorBorder.opacity(0.6)), lineWidth: 1)

            var path = Path()
            let samples = 96
            for index in 0...samples {
                let position = -evLimit + (evLimit * 2) * Double(index) / Double(samples)
                let influence = min(max(sample(position), 0), 1)
                let point = point(position: position, influence: influence, size: canvasSize)
                if index == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            context.stroke(path, with: .color(DarkRoomDesign.Palette.primaryText), lineWidth: 2)
        }
    }

    private func handle(_ label: String, at point: CGPoint) -> some View {
        Circle()
            .fill(DarkRoomDesign.Palette.inspectorBackground)
            .frame(width: handleSize, height: handleSize)
            .overlay(
                Circle()
                    .stroke(DarkRoomDesign.Palette.sliderKnobStroke, lineWidth: 2)
            )
            .position(point)
            .help(label)
    }

    private func evDrag(size: CGSize, update: @escaping (Double) -> Void) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                onEditingChanged(true)
                update(position(at: value.location.x, size: size))
            }
            .onEnded { value in
                update(position(at: value.location.x, size: size))
                onEditingChanged(false)
            }
    }

    private func unitDrag(size: CGSize, update: @escaping (Double) -> Void) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                onEditingChanged(true)
                update(unitY(at: value.location.y, size: size))
            }
            .onEnded { value in
                update(unitY(at: value.location.y, size: size))
                onEditingChanged(false)
            }
    }

    private var peakHandlePosition: Double {
        let direction = fullEV >= startEV ? 1.0 : -1.0
        return min(max(fullEV + direction * evLimit * 0.18, -evLimit), evLimit)
    }

    private func point(position: Double, influence: Double, size: CGSize) -> CGPoint {
        CGPoint(
            x: size.width * min(max((position + evLimit) / (evLimit * 2), 0), 1),
            y: size.height * (1 - min(max(influence, 0), 1))
        )
    }

    private func position(at x: CGFloat, size: CGSize) -> Double {
        -evLimit + (evLimit * 2) * Double(min(max(x / max(size.width, 1), 0), 1))
    }

    private func unitY(at y: CGFloat, size: CGSize) -> Double {
        Double(1 - min(max(y / max(size.height, 1), 0), 1))
    }

    private func curveReadout(_ label: String, _ value: Double) -> some View {
        Text("\(label) \(value.formatted(.number.precision(.fractionLength(2))))")
            .font(DarkRoomDesign.Typography.controlValue)
            .foregroundStyle(DarkRoomDesign.Palette.subtleText)
            .lineLimit(1)
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

private enum ToneLabSliderTarget: String, CaseIterable, Identifiable {
    case all
    case exposure
    case contrast
    case pivot
    case highlights
    case shadows
    case whites
    case blacks

    static let sweepValues: [Double] = [-100, -75, -50, -25, 0, 25, 50, 75, 100]
    static let sweepTargets: [ToneLabSliderTarget] = [.exposure, .contrast, .pivot, .highlights, .shadows, .whites, .blacks]

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all:
            "All Sliders"
        case .exposure:
            "Exposure"
        case .contrast:
            "Contrast"
        case .pivot:
            "Pivot"
        case .highlights:
            "Highlights"
        case .shadows:
            "Shadows"
        case .whites:
            "Whites"
        case .blacks:
            "Blacks"
        }
    }

    func recipe(from recipe: EditRecipe) -> EditRecipe {
        guard self != .all else {
            return recipe
        }

        var solo = EditRecipe.neutral
        switch self {
        case .all:
            return recipe
        case .exposure:
            solo.light.exposureEV = recipe.light.exposureEV
        case .contrast:
            solo.light.contrast = recipe.light.contrast
        case .pivot:
            solo.light.pivotEV = recipe.light.pivotEV
        case .highlights:
            solo.light.highlights = recipe.light.highlights
        case .shadows:
            solo.light.shadows = recipe.light.shadows
        case .whites:
            solo.light.whites = recipe.light.whites
        case .blacks:
            solo.light.blacks = recipe.light.blacks
        }
        return solo
    }

    func applySweepValue(_ value: Double, to recipe: inout EditRecipe) {
        switch self {
        case .all:
            return
        case .exposure:
            recipe.light.exposureEV = (value / 100.0) * max(abs(LightAdjustments.exposureRange.lowerBound), abs(LightAdjustments.exposureRange.upperBound))
        case .contrast:
            recipe.light.contrast = value
        case .pivot:
            recipe.light.pivotEV = (value / 100.0) * max(abs(LightAdjustments.pivotRange.lowerBound), abs(LightAdjustments.pivotRange.upperBound))
        case .highlights:
            recipe.light.highlights = value
        case .shadows:
            recipe.light.shadows = value
        case .whites:
            recipe.light.whites = value
        case .blacks:
            recipe.light.blacks = value
        }
    }
}

private enum ToneLabRangeRole {
    case highlights
    case shadows

    var chromaModeLabel: String {
        switch self {
        case .highlights:
            "Highlight Chroma Mode"
        case .shadows:
            "Shadow Chroma Mode"
        }
    }

    var curveEVLimit: Double {
        switch self {
        case .highlights:
            12
        case .shadows:
            12
        }
    }
}

private enum ToneLabEndpointRole {
    case whites
    case blacks

    var curveEVLimit: Double {
        12
    }
}

private enum ToneLabMappingTarget: String, CaseIterable, Identifiable {
    case exposure
    case contrast
    case highlights
    case shadows
    case whites
    case blacks

    var id: String { rawValue }

    var label: String {
        switch self {
        case .exposure:
            "Exposure"
        case .contrast:
            "Contrast"
        case .highlights:
            "Highlights"
        case .shadows:
            "Shadows"
        case .whites:
            "Whites"
        case .blacks:
            "Blacks"
        }
    }

    var defaultMapping: PerSliderMapping {
        switch self {
        case .exposure:
            SliderMappingsTuning.defaultV1.exposure
        case .contrast:
            SliderMappingsTuning.defaultV1.contrast
        case .highlights:
            SliderMappingsTuning.defaultV1.highlights
        case .shadows:
            SliderMappingsTuning.defaultV1.shadows
        case .whites:
            SliderMappingsTuning.defaultV1.whites
        case .blacks:
            SliderMappingsTuning.defaultV1.blacks
        }
    }

    func sliderPosition(in recipe: EditRecipe) -> Double {
        switch self {
        case .exposure:
            return recipe.light.exposureEV.percentPosition(in: LightAdjustments.exposureRange)
        case .contrast:
            return recipe.light.contrast.clamped(to: -100...100)
        case .highlights:
            return recipe.light.highlights.clamped(to: -100...100)
        case .shadows:
            return recipe.light.shadows.clamped(to: -100...100)
        case .whites:
            return recipe.light.whites.clamped(to: -100...100)
        case .blacks:
            return recipe.light.blacks.clamped(to: -100...100)
        }
    }

    func mappingBinding(in mappings: Binding<SliderMappingsTuning>) -> Binding<PerSliderMapping> {
        Binding(
            get: {
                switch self {
                case .exposure:
                    mappings.wrappedValue.exposure
                case .contrast:
                    mappings.wrappedValue.contrast
                case .highlights:
                    mappings.wrappedValue.highlights
                case .shadows:
                    mappings.wrappedValue.shadows
                case .whites:
                    mappings.wrappedValue.whites
                case .blacks:
                    mappings.wrappedValue.blacks
                }
            },
            set: { nextValue in
                switch self {
                case .exposure:
                    mappings.wrappedValue.exposure = nextValue
                case .contrast:
                    mappings.wrappedValue.contrast = nextValue
                case .highlights:
                    mappings.wrappedValue.highlights = nextValue
                case .shadows:
                    mappings.wrappedValue.shadows = nextValue
                case .whites:
                    mappings.wrappedValue.whites = nextValue
                case .blacks:
                    mappings.wrappedValue.blacks = nextValue
                }
            }
        )
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }

    func percentPosition(in range: ClosedRange<Double>) -> Double {
        let extent = max(abs(range.lowerBound), abs(range.upperBound))
        guard extent > 0 else {
            return 0
        }

        return ((self / extent) * 100).clamped(to: -100...100)
    }
}
#endif
