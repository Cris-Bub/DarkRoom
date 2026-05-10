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

            ToneLabSlider(title: "Exposure", value: $toneRecipe.light.exposureEV, range: LightAdjustments.exposureRange, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Contrast", value: $toneRecipe.light.contrast, range: LightAdjustments.contrastRange, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Pivot", value: $toneRecipe.light.pivotEV, range: LightAdjustments.pivotRange, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Highlights", value: $toneRecipe.light.highlights, range: LightAdjustments.highlightsRange, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Shadows", value: $toneRecipe.light.shadows, range: LightAdjustments.shadowsRange, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Whites", value: $toneRecipe.light.whites, range: LightAdjustments.whitesRange, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Blacks", value: $toneRecipe.light.blacks, range: LightAdjustments.blacksRange, onEditingChanged: handleEditingChanged)

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
                startRange: 0.0...4.0,
                fullRange: 0.5...6.0,
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
                startRange: -4.0...0.0,
                fullRange: -6.0 ... -0.5,
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
                startRange: 0.0...6.0,
                fullRange: 0.5...8.0,
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
                startRange: -6.0...0.0,
                fullRange: -8.0 ... -0.5,
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
            ToneLabSlider(title: "EV Gain Scale", value: $behaviorTuning.exposureFeelTuning.evGainScale, range: 0.5...1.5, fractionDigits: 3, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Exposure Response Exponent", value: $behaviorTuning.exposureFeelTuning.responseExponent, range: 0.4...2.5, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Black Participation", value: $behaviorTuning.exposureFeelTuning.blackParticipation, range: 0.0...1.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Toe Follow Amount", value: $behaviorTuning.exposureFeelTuning.toeFollowAmount, range: 0.0...1.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Shadow Visibility Per EV", value: $behaviorTuning.exposureFeelTuning.shadowVisibilityPerEV, range: 0.0...1.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Highlight Protection Per EV", value: $behaviorTuning.exposureFeelTuning.highlightProtectionPerEV, range: 0.0...1.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Exposure Chroma Response", value: $behaviorTuning.exposureFeelTuning.exposureChromaResponse, range: -0.5...0.5, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Exposure Saturation Min", value: $behaviorTuning.exposureFeelTuning.saturationMin, range: 0.5...1.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Exposure Saturation Max", value: $behaviorTuning.exposureFeelTuning.saturationMax, range: 1.0...1.5, fractionDigits: 2, onEditingChanged: handleEditingChanged)
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
            ToneLabSlider(title: "Middle Gray", value: $behaviorTuning.toneTuning.global.middleGray, range: 0.08...0.35, fractionDigits: 3, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Base Contrast", value: $behaviorTuning.toneTuning.global.baseContrast, range: 0.6...1.6, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Toe Strength", value: $behaviorTuning.toneTuning.global.toeStrength, range: 0.0...2.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Toe Length EV", value: $behaviorTuning.toneTuning.global.toeLengthEV, range: 0.5...6.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Shoulder Strength", value: $behaviorTuning.toneTuning.global.shoulderStrength, range: 0.0...2.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Shoulder Length EV", value: $behaviorTuning.toneTuning.global.shoulderLengthEV, range: 0.5...6.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Output Soft Clip", value: $behaviorTuning.toneTuning.global.outputSoftClip, range: 0.0...2.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Scene Black EV", value: $behaviorTuning.toneTuning.global.sceneBlackEV, range: -12.0 ... -2.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Scene White EV", value: $behaviorTuning.toneTuning.global.sceneWhiteEV, range: 1.0...8.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Display Middle Gray", value: $behaviorTuning.toneTuning.global.displayMiddleGray, range: 0.3...0.6, fractionDigits: 3, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Toe Lift", value: $behaviorTuning.toneTuning.global.toeLift, range: 0.0...1.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Shoulder Roll Strength", value: $behaviorTuning.toneTuning.global.shoulderRollStrength, range: 0.0...2.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
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

            ToneLabSlider(title: "Max Slope Boost", value: $behaviorTuning.toneTuning.contrast.maxSlopeBoost, range: 0.0...3.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Max Slope Reduction", value: $behaviorTuning.toneTuning.contrast.maxSlopeReduction, range: 0.0...3.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Contrast Softness", value: $behaviorTuning.toneTuning.contrast.contrastSoftness, range: 0.2...4.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Pivot Min EV", value: $behaviorTuning.toneTuning.contrast.pivotMinEV, range: -4.0...0.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Pivot Max EV", value: $behaviorTuning.toneTuning.contrast.pivotMaxEV, range: 0.0...4.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Contrast Saturation Amount", value: $behaviorTuning.toneTuning.contrast.saturationAmount, range: -0.5...0.5, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Contrast Hue Protection", value: $behaviorTuning.toneTuning.contrast.hueProtection, range: 0.0...1.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Contrast Neutral Protection", value: $behaviorTuning.toneTuning.contrast.neutralProtection, range: 0.0...1.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
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

            Picker(role.chromaModeLabel, selection: tuning.chromaMode) {
                ForEach(RegionalChromaMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.menu)

            ToneLabSlider(title: "Start EV", value: tuning.startEV, range: startRange, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Full EV", value: tuning.fullEV, range: fullRange, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Max Lift EV", value: tuning.maxLiftEV, range: 0.0...5.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Max Pull EV", value: tuning.maxPullEV, range: -5.0...0.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Falloff Softness", value: tuning.falloff, range: 0.2...2.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Midtone Protection", value: tuning.midtoneProtection, range: 0.0...1.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: endpointLabel, value: tuning.endpointProtection, range: 0.0...1.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)

            if role == .highlights {
                ToneLabSlider(title: "Highlight Pull Desaturation", value: tuning.pullDesaturation, range: 0.0...0.6, fractionDigits: 2, onEditingChanged: handleEditingChanged)
                ToneLabSlider(title: "Highlight Near-White Desaturation", value: tuning.nearEndpointDesaturation, range: 0.0...0.6, fractionDigits: 2, onEditingChanged: handleEditingChanged)
                ToneLabSlider(title: "Highlight Saturation Clamp", value: tuning.saturationClamp, range: 0.8...1.5, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            } else {
                ToneLabSlider(title: "Shadow Lift Desaturation", value: tuning.liftDesaturation, range: 0.0...0.6, fractionDigits: 2, onEditingChanged: handleEditingChanged)
                ToneLabSlider(title: "Shadow Noise Chroma Protection", value: tuning.noiseChromaProtection, range: 0.0...1.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            }

            ToneLabSlider(title: "Hue Protection", value: tuning.hueProtection, range: 0.0...1.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
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

            ToneLabSlider(title: "Start EV", value: tuning.startEV, range: startRange, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Full EV", value: tuning.fullEV, range: fullRange, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Strength", value: tuning.strength, range: 0.0...2.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Max Shift EV", value: tuning.maxShiftEV, range: 0.0...4.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Falloff Softness", value: tuning.softness, range: 0.2...4.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: protectionLabel, value: tuning.protection, range: 0.0...1.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)

            if role == .whites {
                ToneLabSlider(title: "Shoulder Coupling", value: tuning.shoulderCoupling, range: 0.0...1.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
                ToneLabSlider(title: "White Chroma Protection", value: tuning.chromaProtection, range: 0.0...1.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
                ToneLabSlider(title: "White Desat Near Clip", value: tuning.desaturationNearClip, range: 0.0...0.6, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            } else {
                ToneLabSlider(title: "Toe Coupling", value: tuning.toeCoupling, range: 0.0...1.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
                ToneLabSlider(title: "Black Chroma Protection", value: tuning.chromaProtection, range: 0.0...1.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
                ToneLabSlider(title: "Density Saturation Coupling", value: tuning.densitySaturationCoupling, range: -0.3...0.3, fractionDigits: 2, onEditingChanged: handleEditingChanged)
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
            Picker("Tone Chroma Mode", selection: $behaviorTuning.colorCouplingTuning.toneChromaMode) {
                ForEach(ToneChromaMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.menu)

            ToneLabSlider(title: "Global Chroma Preservation", value: $behaviorTuning.colorCouplingTuning.globalChromaPreservation, range: 0.0...1.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Saturation Minimum", value: $behaviorTuning.colorCouplingTuning.saturationMin, range: 0.5...1.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Saturation Maximum", value: $behaviorTuning.colorCouplingTuning.saturationMax, range: 1.0...1.6, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Neutral Protection", value: $behaviorTuning.colorCouplingTuning.neutralProtection, range: 0.0...1.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Skin Protection", value: $behaviorTuning.colorCouplingTuning.skinProtection, range: 0.0...1.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Hue Stability", value: $behaviorTuning.colorCouplingTuning.hueStability, range: 0.0...1.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Gamut Compression Amount", value: $behaviorTuning.colorCouplingTuning.gamutCompressionAmount, range: 0.0...1.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Contrast Saturation Amount", value: $behaviorTuning.colorCouplingTuning.contrastSaturationAmount, range: -0.5...0.5, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Contrast Saturation Midtone Bias", value: $behaviorTuning.colorCouplingTuning.contrastSaturationMidtoneBias, range: 0.0...2.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Highlight Pull Desaturation", value: $behaviorTuning.colorCouplingTuning.highlightPullDesaturation, range: 0.0...0.6, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Highlight Near-White Desaturation", value: $behaviorTuning.colorCouplingTuning.highlightNearWhiteDesaturation, range: 0.0...0.6, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Shadow Lift Desaturation", value: $behaviorTuning.colorCouplingTuning.shadowLiftDesaturation, range: 0.0...0.6, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Shadow Noise Chroma Protection", value: $behaviorTuning.colorCouplingTuning.shadowNoiseChromaProtection, range: 0.0...1.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Black Density Saturation", value: $behaviorTuning.colorCouplingTuning.blackDensitySaturation, range: -0.3...0.3, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Black Chroma Protection", value: $behaviorTuning.colorCouplingTuning.blackChromaProtection, range: 0.0...1.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "White Clip Desaturation", value: $behaviorTuning.colorCouplingTuning.whiteClipDesaturation, range: 0.0...0.6, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "White Chroma Protection", value: $behaviorTuning.colorCouplingTuning.whiteChromaProtection, range: 0.0...1.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
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

            mappingControls(mappingTarget.mappingBinding(in: $behaviorTuning.sliderMappings))
        }
    }

    private func mappingControls(_ mapping: Binding<PerSliderMapping>) -> some View {
        Group {
            ToneLabSlider(title: "Near Zero Sensitivity", value: mapping.nearZeroSensitivity, range: 0.0...2.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Mid Sensitivity", value: mapping.midSensitivity, range: 0.0...2.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Extreme Sensitivity", value: mapping.extremeSensitivity, range: 0.0...2.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Response Exponent", value: mapping.responseExponent, range: 0.25...3.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Soft Limit", value: mapping.softLimit, range: 0.1...1.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Dead Zone", value: mapping.deadZone, range: 0.0...0.2, fractionDigits: 3, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Positive / Negative Symmetry", value: mapping.positiveNegativeSymmetry, range: 0.0...2.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
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

            ToneLabSlider(title: "Influence Opacity", value: $behaviorTuning.overlayTuning.influenceOpacity, range: 0.0...1.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Saturation Overlay Scale", value: $behaviorTuning.overlayTuning.saturationOverlayScale, range: 0.0...2.0, fractionDigits: 2, onEditingChanged: handleEditingChanged)
            ToneLabSlider(title: "Neutral Drift Threshold", value: $behaviorTuning.overlayTuning.neutralDriftThreshold, range: 0.0...0.2, fractionDigits: 3, onEditingChanged: handleEditingChanged)
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
}

private enum ToneLabEndpointRole {
    case whites
    case blacks
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
#endif
