pub const DARKROOM_TONAL_CURVE_V1: &str = "darkroom_tonal_curve_v1";
pub const DEFAULT_CONTRAST_PIVOT: f32 = MIDDLE_GRAY;
pub const MIDDLE_GRAY: f32 = 0.18;
pub const TONE_EPSILON: f32 = 1.0e-6;
pub const LIGHT_KERNEL_PARAMETER_COUNT: usize = 39;
pub const TONE_TUNING_PARAMETER_COUNT: usize = 40;

const LUMA_RED: f32 = 0.288_040_2;
const LUMA_GREEN: f32 = 0.711_874_1;
const LUMA_BLUE: f32 = 0.000_085_7;

const CONTRAST_MAX_EV: f32 = 1.35;
const CONTRAST_ROLLOFF_EV: f32 = 2.0;
const HIGHLIGHT_SHADOW_MAX_EV: f32 = 1.8;
const ENDPOINT_MAX_EV: f32 = 2.0;
const SHADOW_ZONE_START_EV: f32 = 0.5;
const SHADOW_ZONE_FULL_EV: f32 = 4.0;
const HIGHLIGHT_ZONE_START_EV: f32 = 0.5;
const HIGHLIGHT_ZONE_FULL_EV: f32 = 4.0;
const BLACK_ZONE_START_EV: f32 = 1.0;
const BLACK_ZONE_FULL_EV: f32 = 5.0;
const WHITE_ZONE_START_EV: f32 = 1.0;
const WHITE_ZONE_FULL_EV: f32 = 5.0;
const PIVOT_EV_MIN: f32 = -2.0;
const PIVOT_EV_MAX: f32 = 2.0;

#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Exposure {
    pub ev: f32,
}

impl Default for Exposure {
    fn default() -> Self {
        Self { ev: 0.0 }
    }
}

impl Exposure {
    pub fn apply(self, scene_linear: f32) -> f32 {
        apply_exposure_scene_linear(scene_linear, self.ev)
    }
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Contrast {
    pub strength: f32,
    pub pivot_ev: f32,
}

impl Default for Contrast {
    fn default() -> Self {
        Self {
            strength: 0.0,
            pivot_ev: 0.0,
        }
    }
}

impl Contrast {
    pub fn from_slider(slider: f32, pivot_ev: f32) -> Self {
        Self {
            strength: contrast_slider_to_strength(slider),
            pivot_ev: sanitize_pivot_ev(pivot_ev),
        }
    }

    pub fn apply(self, scene_linear: f32) -> f32 {
        let parameters = LightKernelParameters {
            contrast_strength: self.strength,
            pivot_ev: self.pivot_ev,
            ..LightKernelParameters::default()
        };

        apply_darkroom_tonal_curve_v1_luma(scene_linear, parameters)
    }
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub struct LightRecipe {
    pub exposure_ev: f32,
    pub contrast_slider: f32,
    pub pivot_ev: f32,
    pub highlights_slider: f32,
    pub shadows_slider: f32,
    pub whites_slider: f32,
    pub blacks_slider: f32,
}

impl Default for LightRecipe {
    fn default() -> Self {
        Self {
            exposure_ev: 0.0,
            contrast_slider: 0.0,
            pivot_ev: 0.0,
            highlights_slider: 0.0,
            shadows_slider: 0.0,
            whites_slider: 0.0,
            blacks_slider: 0.0,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub struct ToneTuning {
    pub global: GlobalToneTuning,
    pub contrast: ContrastTuning,
    pub highlights: RangeToneTuning,
    pub shadows: RangeToneTuning,
    pub whites: EndpointToneTuning,
    pub blacks: EndpointToneTuning,
    pub slider_mapping: SliderMappingTuning,
}

impl Default for ToneTuning {
    fn default() -> Self {
        Self {
            global: GlobalToneTuning::default(),
            contrast: ContrastTuning::default(),
            highlights: RangeToneTuning {
                start_ev: HIGHLIGHT_ZONE_START_EV,
                full_ev: HIGHLIGHT_ZONE_FULL_EV,
                max_lift_ev: HIGHLIGHT_SHADOW_MAX_EV,
                max_pull_ev: -HIGHLIGHT_SHADOW_MAX_EV,
                falloff: 1.0,
                midtone_protection: 0.0,
                endpoint_protection: 0.0,
            },
            shadows: RangeToneTuning {
                start_ev: -SHADOW_ZONE_START_EV,
                full_ev: -SHADOW_ZONE_FULL_EV,
                max_lift_ev: HIGHLIGHT_SHADOW_MAX_EV,
                max_pull_ev: -HIGHLIGHT_SHADOW_MAX_EV,
                falloff: 1.0,
                midtone_protection: 0.0,
                endpoint_protection: 0.0,
            },
            whites: EndpointToneTuning {
                start_ev: WHITE_ZONE_START_EV,
                strength: 1.0,
                max_shift_ev: ENDPOINT_MAX_EV,
                softness: (WHITE_ZONE_FULL_EV - WHITE_ZONE_START_EV) / ENDPOINT_MAX_EV,
                protection: 0.0,
            },
            blacks: EndpointToneTuning {
                start_ev: -BLACK_ZONE_START_EV,
                strength: 1.0,
                max_shift_ev: ENDPOINT_MAX_EV,
                softness: (BLACK_ZONE_FULL_EV - BLACK_ZONE_START_EV) / ENDPOINT_MAX_EV,
                protection: 0.0,
            },
            slider_mapping: SliderMappingTuning::default(),
        }
    }
}

impl ToneTuning {
    pub fn to_floats(self) -> [f32; TONE_TUNING_PARAMETER_COUNT] {
        [
            self.global.middle_gray,
            self.global.base_contrast,
            self.global.toe_strength,
            self.global.toe_length_ev,
            self.global.shoulder_strength,
            self.global.shoulder_length_ev,
            self.global.output_soft_clip,
            self.contrast.max_slope_boost,
            self.contrast.max_slope_reduction,
            self.contrast.pivot_min_ev,
            self.contrast.pivot_max_ev,
            self.contrast.contrast_softness,
            self.highlights.start_ev,
            self.highlights.full_ev,
            self.highlights.max_lift_ev,
            self.highlights.max_pull_ev,
            self.highlights.falloff,
            self.highlights.midtone_protection,
            self.highlights.endpoint_protection,
            self.shadows.start_ev,
            self.shadows.full_ev,
            self.shadows.max_lift_ev,
            self.shadows.max_pull_ev,
            self.shadows.falloff,
            self.shadows.midtone_protection,
            self.shadows.endpoint_protection,
            self.whites.start_ev,
            self.whites.strength,
            self.whites.max_shift_ev,
            self.whites.softness,
            self.whites.protection,
            self.blacks.start_ev,
            self.blacks.strength,
            self.blacks.max_shift_ev,
            self.blacks.softness,
            self.blacks.protection,
            self.slider_mapping.near_zero_sensitivity,
            self.slider_mapping.mid_sensitivity,
            self.slider_mapping.extreme_taper,
            self.slider_mapping.dead_zone,
        ]
    }

    fn from_floats(parameters: &[f32]) -> Option<Self> {
        if parameters.len() < TONE_TUNING_PARAMETER_COUNT {
            return None;
        }

        Some(Self {
            global: GlobalToneTuning {
                middle_gray: parameters[0],
                base_contrast: parameters[1],
                toe_strength: parameters[2],
                toe_length_ev: parameters[3],
                shoulder_strength: parameters[4],
                shoulder_length_ev: parameters[5],
                output_soft_clip: parameters[6],
            },
            contrast: ContrastTuning {
                max_slope_boost: parameters[7],
                max_slope_reduction: parameters[8],
                pivot_min_ev: parameters[9],
                pivot_max_ev: parameters[10],
                contrast_softness: parameters[11],
            },
            highlights: RangeToneTuning {
                start_ev: parameters[12],
                full_ev: parameters[13],
                max_lift_ev: parameters[14],
                max_pull_ev: parameters[15],
                falloff: parameters[16],
                midtone_protection: parameters[17],
                endpoint_protection: parameters[18],
            },
            shadows: RangeToneTuning {
                start_ev: parameters[19],
                full_ev: parameters[20],
                max_lift_ev: parameters[21],
                max_pull_ev: parameters[22],
                falloff: parameters[23],
                midtone_protection: parameters[24],
                endpoint_protection: parameters[25],
            },
            whites: EndpointToneTuning {
                start_ev: parameters[26],
                strength: parameters[27],
                max_shift_ev: parameters[28],
                softness: parameters[29],
                protection: parameters[30],
            },
            blacks: EndpointToneTuning {
                start_ev: parameters[31],
                strength: parameters[32],
                max_shift_ev: parameters[33],
                softness: parameters[34],
                protection: parameters[35],
            },
            slider_mapping: SliderMappingTuning {
                near_zero_sensitivity: parameters[36],
                mid_sensitivity: parameters[37],
                extreme_taper: parameters[38],
                dead_zone: parameters[39],
            },
        })
    }
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub struct GlobalToneTuning {
    pub middle_gray: f32,
    pub base_contrast: f32,
    pub toe_strength: f32,
    pub toe_length_ev: f32,
    pub shoulder_strength: f32,
    pub shoulder_length_ev: f32,
    pub output_soft_clip: f32,
}

impl Default for GlobalToneTuning {
    fn default() -> Self {
        Self {
            middle_gray: MIDDLE_GRAY,
            base_contrast: 1.0,
            toe_strength: 0.0,
            toe_length_ev: 2.5,
            shoulder_strength: 0.0,
            shoulder_length_ev: 3.0,
            output_soft_clip: 0.0,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub struct ContrastTuning {
    pub max_slope_boost: f32,
    pub max_slope_reduction: f32,
    pub pivot_min_ev: f32,
    pub pivot_max_ev: f32,
    pub contrast_softness: f32,
}

impl Default for ContrastTuning {
    fn default() -> Self {
        Self {
            max_slope_boost: CONTRAST_MAX_EV,
            max_slope_reduction: CONTRAST_MAX_EV,
            pivot_min_ev: PIVOT_EV_MIN,
            pivot_max_ev: PIVOT_EV_MAX,
            contrast_softness: CONTRAST_ROLLOFF_EV,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub struct RangeToneTuning {
    pub start_ev: f32,
    pub full_ev: f32,
    pub max_lift_ev: f32,
    pub max_pull_ev: f32,
    pub falloff: f32,
    pub midtone_protection: f32,
    pub endpoint_protection: f32,
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub struct EndpointToneTuning {
    pub start_ev: f32,
    pub strength: f32,
    pub max_shift_ev: f32,
    pub softness: f32,
    pub protection: f32,
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub struct SliderMappingTuning {
    pub near_zero_sensitivity: f32,
    pub mid_sensitivity: f32,
    pub extreme_taper: f32,
    pub dead_zone: f32,
}

impl Default for SliderMappingTuning {
    fn default() -> Self {
        Self {
            near_zero_sensitivity: 0.0,
            mid_sensitivity: 1.0,
            extreme_taper: 0.0,
            dead_zone: 0.0,
        }
    }
}

impl LightRecipe {
    pub fn kernel_parameters(self) -> LightKernelParameters {
        self.kernel_parameters_with_tuning(ToneTuning::default())
    }

    pub fn kernel_parameters_with_tuning(self, tuning: ToneTuning) -> LightKernelParameters {
        let contrast_strength = slider_to_unit(self.contrast_slider, tuning.slider_mapping);
        let contrast_max_ev = if contrast_strength >= 0.0 {
            tuning.contrast.max_slope_boost.abs()
        } else {
            tuning.contrast.max_slope_reduction.abs()
        };
        let highlights_ev = range_slider_to_ev(
            self.highlights_slider,
            tuning.highlights,
            tuning.slider_mapping,
        );
        let shadows_ev =
            range_slider_to_ev(self.shadows_slider, tuning.shadows, tuning.slider_mapping);
        let whites_ev =
            endpoint_slider_to_ev_tuned(self.whites_slider, tuning.whites, tuning.slider_mapping);
        let blacks_ev =
            endpoint_slider_to_ev_tuned(self.blacks_slider, tuning.blacks, tuning.slider_mapping);

        LightKernelParameters {
            exposure_gain: exposure_ev_to_gain(self.exposure_ev),
            contrast_strength,
            pivot_ev: sanitize_pivot_ev_with_tuning(self.pivot_ev, tuning.contrast),
            highlights_ev,
            shadows_ev,
            whites_ev,
            blacks_ev,
            middle_gray: tuning.global.middle_gray,
            tone_epsilon: TONE_EPSILON,
            luma_red: LUMA_RED,
            luma_green: LUMA_GREEN,
            luma_blue: LUMA_BLUE,
            contrast_max_ev,
            contrast_rolloff_ev: tuning.contrast.contrast_softness,
            shadow_zone_start_ev: tuning.shadows.start_ev.abs(),
            shadow_zone_full_ev: tuning.shadows.full_ev.abs(),
            highlight_zone_start_ev: tuning.highlights.start_ev.abs(),
            highlight_zone_full_ev: tuning.highlights.full_ev.abs(),
            black_zone_start_ev: tuning.blacks.start_ev.abs(),
            black_zone_full_ev: endpoint_full_ev(tuning.blacks),
            white_zone_start_ev: tuning.whites.start_ev.abs(),
            white_zone_full_ev: endpoint_full_ev(tuning.whites),
            endpoint_max_ev: ENDPOINT_MAX_EV,
            base_contrast: tuning.global.base_contrast,
            toe_strength: tuning.global.toe_strength,
            toe_length_ev: tuning.global.toe_length_ev,
            shoulder_strength: tuning.global.shoulder_strength,
            shoulder_length_ev: tuning.global.shoulder_length_ev,
            output_soft_clip: tuning.global.output_soft_clip,
            shadow_falloff: tuning.shadows.falloff,
            shadow_midtone_protection: tuning.shadows.midtone_protection,
            shadow_endpoint_protection: tuning.shadows.endpoint_protection,
            highlight_falloff: tuning.highlights.falloff,
            highlight_midtone_protection: tuning.highlights.midtone_protection,
            highlight_endpoint_protection: tuning.highlights.endpoint_protection,
            black_softness: tuning.blacks.softness,
            black_protection: tuning.blacks.protection,
            white_softness: tuning.whites.softness,
            white_protection: tuning.whites.protection,
        }
    }

    pub fn apply_luma_reference(self, scene_linear: f32) -> f32 {
        apply_light_luma_reference(scene_linear, self.kernel_parameters())
    }
}

#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct LightKernelParameters {
    pub exposure_gain: f32,
    pub contrast_strength: f32,
    pub pivot_ev: f32,
    pub highlights_ev: f32,
    pub shadows_ev: f32,
    pub whites_ev: f32,
    pub blacks_ev: f32,
    pub middle_gray: f32,
    pub tone_epsilon: f32,
    pub luma_red: f32,
    pub luma_green: f32,
    pub luma_blue: f32,
    pub contrast_max_ev: f32,
    pub contrast_rolloff_ev: f32,
    pub shadow_zone_start_ev: f32,
    pub shadow_zone_full_ev: f32,
    pub highlight_zone_start_ev: f32,
    pub highlight_zone_full_ev: f32,
    pub black_zone_start_ev: f32,
    pub black_zone_full_ev: f32,
    pub white_zone_start_ev: f32,
    pub white_zone_full_ev: f32,
    pub endpoint_max_ev: f32,
    pub base_contrast: f32,
    pub toe_strength: f32,
    pub toe_length_ev: f32,
    pub shoulder_strength: f32,
    pub shoulder_length_ev: f32,
    pub output_soft_clip: f32,
    pub shadow_falloff: f32,
    pub shadow_midtone_protection: f32,
    pub shadow_endpoint_protection: f32,
    pub highlight_falloff: f32,
    pub highlight_midtone_protection: f32,
    pub highlight_endpoint_protection: f32,
    pub black_softness: f32,
    pub black_protection: f32,
    pub white_softness: f32,
    pub white_protection: f32,
}

impl Default for LightKernelParameters {
    fn default() -> Self {
        LightRecipe::default().kernel_parameters()
    }
}

impl LightKernelParameters {
    pub fn to_floats(self) -> [f32; LIGHT_KERNEL_PARAMETER_COUNT] {
        [
            self.exposure_gain,
            self.contrast_strength,
            self.pivot_ev,
            self.highlights_ev,
            self.shadows_ev,
            self.whites_ev,
            self.blacks_ev,
            self.middle_gray,
            self.tone_epsilon,
            self.luma_red,
            self.luma_green,
            self.luma_blue,
            self.contrast_max_ev,
            self.contrast_rolloff_ev,
            self.shadow_zone_start_ev,
            self.shadow_zone_full_ev,
            self.highlight_zone_start_ev,
            self.highlight_zone_full_ev,
            self.black_zone_start_ev,
            self.black_zone_full_ev,
            self.white_zone_start_ev,
            self.white_zone_full_ev,
            self.endpoint_max_ev,
            self.base_contrast,
            self.toe_strength,
            self.toe_length_ev,
            self.shoulder_strength,
            self.shoulder_length_ev,
            self.output_soft_clip,
            self.shadow_falloff,
            self.shadow_midtone_protection,
            self.shadow_endpoint_protection,
            self.highlight_falloff,
            self.highlight_midtone_protection,
            self.highlight_endpoint_protection,
            self.black_softness,
            self.black_protection,
            self.white_softness,
            self.white_protection,
        ]
    }

    fn from_floats(parameters: &[f32]) -> Option<Self> {
        if parameters.len() < LIGHT_KERNEL_PARAMETER_COUNT {
            return None;
        }

        Some(Self {
            exposure_gain: parameters[0],
            contrast_strength: parameters[1],
            pivot_ev: parameters[2],
            highlights_ev: parameters[3],
            shadows_ev: parameters[4],
            whites_ev: parameters[5],
            blacks_ev: parameters[6],
            middle_gray: parameters[7],
            tone_epsilon: parameters[8],
            luma_red: parameters[9],
            luma_green: parameters[10],
            luma_blue: parameters[11],
            contrast_max_ev: parameters[12],
            contrast_rolloff_ev: parameters[13],
            shadow_zone_start_ev: parameters[14],
            shadow_zone_full_ev: parameters[15],
            highlight_zone_start_ev: parameters[16],
            highlight_zone_full_ev: parameters[17],
            black_zone_start_ev: parameters[18],
            black_zone_full_ev: parameters[19],
            white_zone_start_ev: parameters[20],
            white_zone_full_ev: parameters[21],
            endpoint_max_ev: parameters[22],
            base_contrast: parameters[23],
            toe_strength: parameters[24],
            toe_length_ev: parameters[25],
            shoulder_strength: parameters[26],
            shoulder_length_ev: parameters[27],
            output_soft_clip: parameters[28],
            shadow_falloff: parameters[29],
            shadow_midtone_protection: parameters[30],
            shadow_endpoint_protection: parameters[31],
            highlight_falloff: parameters[32],
            highlight_midtone_protection: parameters[33],
            highlight_endpoint_protection: parameters[34],
            black_softness: parameters[35],
            black_protection: parameters[36],
            white_softness: parameters[37],
            white_protection: parameters[38],
        })
    }
}

#[derive(Debug, Clone, Copy, Default, PartialEq)]
pub struct EditRecipe {
    pub light: LightRecipe,
}

impl EditRecipe {
    pub fn apply_luma_reference(self, scene_linear: f32) -> f32 {
        self.light.apply_luma_reference(scene_linear)
    }
}

pub fn exposure_ev_to_gain(ev: f32) -> f32 {
    if !ev.is_finite() {
        return 1.0;
    }

    2.0_f32.powf(ev)
}

pub fn contrast_slider_to_strength(slider: f32) -> f32 {
    signed_smooth_unit(slider)
}

pub fn contrast_slider_to_exponent(slider: f32) -> f32 {
    if !slider.is_finite() {
        return 1.0;
    }

    2.0_f32.powf(slider / 100.0)
}

pub fn normalize_adjustment_slider(slider: f32) -> f32 {
    signed_smooth_unit(slider)
}

pub fn tonal_region_slider_to_ev(slider: f32) -> f32 {
    signed_smooth_unit(slider) * HIGHLIGHT_SHADOW_MAX_EV
}

pub fn endpoint_slider_to_ev(slider: f32) -> f32 {
    signed_smooth_unit(slider) * ENDPOINT_MAX_EV
}

pub fn apply_exposure_scene_linear(input: f32, ev: f32) -> f32 {
    if !input.is_finite() {
        return input;
    }

    input * exposure_ev_to_gain(ev)
}

pub fn apply_pivoted_contrast_scene_linear(input: f32, contrast: f32, pivot: f32) -> f32 {
    if !input.is_finite() || !contrast.is_finite() || !pivot.is_finite() {
        return input;
    }

    if input <= 0.0 || pivot <= 0.0 || contrast <= 0.0 {
        return input;
    }

    pivot * (input / pivot).powf(contrast)
}

pub fn apply_light_luma_reference(input: f32, parameters: LightKernelParameters) -> f32 {
    if !input.is_finite() {
        return input;
    }

    let exposed = (input * parameters.exposure_gain).max(0.0);
    apply_darkroom_tonal_curve_v1_luma(exposed, parameters)
}

pub fn apply_light_rgb_kernel(
    red: f32,
    green: f32,
    blue: f32,
    parameters: LightKernelParameters,
) -> (f32, f32, f32) {
    let r = (red * parameters.exposure_gain).max(0.0);
    let g = (green * parameters.exposure_gain).max(0.0);
    let b = (blue * parameters.exposure_gain).max(0.0);
    let luma = working_luminance(r, g, b, parameters);
    let target_luma = apply_darkroom_tonal_curve_v1_luma(luma, parameters);
    let ratio = (target_luma / luma.max(parameters.tone_epsilon)).max(0.0);

    (r * ratio, g * ratio, b * ratio)
}

pub fn apply_darkroom_tonal_curve_v1_luma(input: f32, parameters: LightKernelParameters) -> f32 {
    if !input.is_finite() || input <= 0.0 {
        return input;
    }

    let middle_gray = parameters.middle_gray.max(parameters.tone_epsilon);
    let safe_luma = input.max(parameters.tone_epsilon);
    let z = (safe_luma / middle_gray).log2();
    let shaped_z = apply_darkroom_tonal_curve_v1_z(z, parameters);

    middle_gray * 2.0_f32.powf(shaped_z).max(0.0)
}

pub fn apply_darkroom_tonal_curve_v1_z(input_z: f32, parameters: LightKernelParameters) -> f32 {
    if !input_z.is_finite() {
        return input_z;
    }

    let mut z = input_z * parameters.base_contrast.max(0.001);
    z -= parameters.toe_strength.max(0.0)
        * tone_zone_influence(-z, 0.0, parameters.toe_length_ev, 1.0, 0.0, 0.0);
    z -= parameters.shoulder_strength.max(0.0)
        * tone_zone_influence(z, 0.0, parameters.shoulder_length_ev, 1.0, 0.0, 0.0);

    z += parameters.shadows_ev
        * tone_zone_influence(
            -z,
            parameters.shadow_zone_start_ev,
            parameters.shadow_zone_full_ev,
            parameters.shadow_falloff,
            parameters.shadow_midtone_protection,
            parameters.shadow_endpoint_protection,
        );
    z += parameters.highlights_ev
        * tone_zone_influence(
            z,
            parameters.highlight_zone_start_ev,
            parameters.highlight_zone_full_ev,
            parameters.highlight_falloff,
            parameters.highlight_midtone_protection,
            parameters.highlight_endpoint_protection,
        );
    z += parameters.blacks_ev
        * tone_zone_influence(
            -z,
            parameters.black_zone_start_ev,
            parameters.black_zone_full_ev,
            1.0,
            0.0,
            parameters.black_protection,
        );
    z += parameters.whites_ev
        * tone_zone_influence(
            z,
            parameters.white_zone_start_ev,
            parameters.white_zone_full_ev,
            1.0,
            0.0,
            parameters.white_protection,
        );

    let centered = z - parameters.pivot_ev;
    let rolloff = parameters.contrast_rolloff_ev.max(0.001);
    let contrast_curve = softsign(centered / rolloff);
    z += parameters.contrast_strength * parameters.contrast_max_ev * contrast_curve;

    soft_clip_z(z, parameters.output_soft_clip)
}

fn working_luminance(red: f32, green: f32, blue: f32, parameters: LightKernelParameters) -> f32 {
    red * parameters.luma_red + green * parameters.luma_green + blue * parameters.luma_blue
}

fn sanitize_pivot_ev(pivot_ev: f32) -> f32 {
    if !pivot_ev.is_finite() {
        return 0.0;
    }

    pivot_ev.clamp(PIVOT_EV_MIN, PIVOT_EV_MAX)
}

fn sanitize_pivot_ev_with_tuning(pivot_ev: f32, tuning: ContrastTuning) -> f32 {
    if !pivot_ev.is_finite() {
        return 0.0;
    }

    let lower = tuning.pivot_min_ev.min(tuning.pivot_max_ev);
    let upper = tuning.pivot_min_ev.max(tuning.pivot_max_ev);
    pivot_ev.clamp(lower, upper)
}

fn slider_to_unit(slider: f32, mapping: SliderMappingTuning) -> f32 {
    if !slider.is_finite() {
        return 0.0;
    }

    let normalized = (slider / 100.0).clamp(-1.0, 1.0);
    let sign = normalized.signum();
    let dead_zone = mapping.dead_zone.clamp(0.0, 0.95);
    let mut magnitude = normalized.abs();

    if magnitude <= dead_zone {
        return 0.0;
    }

    magnitude = ((magnitude - dead_zone) / (1.0 - dead_zone)).clamp(0.0, 1.0);

    let smooth = magnitude * magnitude * (3.0 - 2.0 * magnitude);
    let near = magnitude * mapping.near_zero_sensitivity.max(0.0) * (1.0 - smooth) * 0.5;
    let mid = smooth * mapping.mid_sensitivity.max(0.0);
    let tapered = (mid + near) * (1.0 - mapping.extreme_taper.clamp(0.0, 0.95) * smooth * 0.25);

    sign * tapered.clamp(0.0, 1.0)
}

fn range_slider_to_ev(slider: f32, tuning: RangeToneTuning, mapping: SliderMappingTuning) -> f32 {
    let unit = slider_to_unit(slider, mapping);

    if unit >= 0.0 {
        unit * tuning.max_lift_ev.max(0.0)
    } else {
        -unit.abs() * tuning.max_pull_ev.abs()
    }
}

fn endpoint_slider_to_ev_tuned(
    slider: f32,
    tuning: EndpointToneTuning,
    mapping: SliderMappingTuning,
) -> f32 {
    slider_to_unit(slider, mapping) * tuning.max_shift_ev.abs() * tuning.strength.max(0.0)
}

fn endpoint_full_ev(tuning: EndpointToneTuning) -> f32 {
    tuning.start_ev.abs() + tuning.max_shift_ev.abs() * tuning.softness.max(0.001)
}

fn signed_smooth_unit(slider: f32) -> f32 {
    if !slider.is_finite() {
        return 0.0;
    }

    let normalized = (slider / 100.0).clamp(-1.0, 1.0);
    let magnitude = normalized.abs();
    let smoothed = magnitude * magnitude * (3.0 - 2.0 * magnitude);
    normalized.signum() * smoothed
}

fn tone_zone_influence(
    distance_ev: f32,
    start_ev: f32,
    full_ev: f32,
    falloff: f32,
    midtone_protection: f32,
    endpoint_protection: f32,
) -> f32 {
    let distance = distance_ev.max(0.0);
    let start = start_ev.abs().max(0.0);
    let mut full = full_ev.abs().max(start + 0.001);

    if full <= start {
        full = start + 0.001;
    }

    let base = smoothstep(start, full, distance);
    let shaped = base.powf(1.0 / falloff.clamp(0.1, 4.0));
    let midtone_guard = 1.0
        - midtone_protection.clamp(0.0, 0.95) * (1.0 - smoothstep(0.0, start.max(0.001), distance));
    let endpoint_guard =
        1.0 - endpoint_protection.clamp(0.0, 0.95) * smoothstep(full, full + 2.0, distance);

    shaped * midtone_guard.clamp(0.05, 1.0) * endpoint_guard.clamp(0.05, 1.0)
}

fn soft_clip_z(z: f32, amount: f32) -> f32 {
    let amount = amount.clamp(0.0, 2.0);
    if amount <= 0.0 {
        return z;
    }

    let limit = 16.0 / amount.max(0.001);
    limit * (z / limit).tanh()
}

fn smoothstep(edge0: f32, edge1: f32, value: f32) -> f32 {
    if edge0 == edge1 {
        return if value < edge0 { 0.0 } else { 1.0 };
    }

    let t = ((value - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
    t * t * (3.0 - 2.0 * t)
}

fn softsign(value: f32) -> f32 {
    value / (1.0 + value.abs())
}

#[no_mangle]
pub extern "C" fn darkroom_light_exposure_gain(exposure_ev: f32) -> f32 {
    exposure_ev_to_gain(exposure_ev)
}

#[no_mangle]
pub extern "C" fn darkroom_light_contrast_exponent(contrast_slider: f32) -> f32 {
    contrast_slider_to_exponent(contrast_slider)
}

#[no_mangle]
pub extern "C" fn darkroom_light_contrast_pivot() -> f32 {
    DEFAULT_CONTRAST_PIVOT
}

#[no_mangle]
pub extern "C" fn darkroom_light_normalized_slider(slider: f32) -> f32 {
    normalize_adjustment_slider(slider)
}

#[no_mangle]
pub extern "C" fn darkroom_light_kernel_parameter_count() -> usize {
    LIGHT_KERNEL_PARAMETER_COUNT
}

#[no_mangle]
pub extern "C" fn darkroom_tone_tuning_parameter_count() -> usize {
    TONE_TUNING_PARAMETER_COUNT
}

#[no_mangle]
pub unsafe extern "C" fn darkroom_light_default_tuning(
    output_parameters: *mut f32,
    output_parameter_count: usize,
) -> u8 {
    if output_parameters.is_null() || output_parameter_count < TONE_TUNING_PARAMETER_COUNT {
        return 0;
    }

    let parameters = ToneTuning::default().to_floats();
    let output = std::slice::from_raw_parts_mut(output_parameters, output_parameter_count);
    output[..TONE_TUNING_PARAMETER_COUNT].copy_from_slice(&parameters);

    1
}

#[no_mangle]
pub unsafe extern "C" fn darkroom_light_kernel_parameters(
    exposure_ev: f32,
    contrast_slider: f32,
    pivot_ev: f32,
    highlights_slider: f32,
    shadows_slider: f32,
    whites_slider: f32,
    blacks_slider: f32,
    output_parameters: *mut f32,
    output_parameter_count: usize,
) -> u8 {
    if output_parameters.is_null() || output_parameter_count < LIGHT_KERNEL_PARAMETER_COUNT {
        return 0;
    }

    let recipe = LightRecipe {
        exposure_ev,
        contrast_slider,
        pivot_ev,
        highlights_slider,
        shadows_slider,
        whites_slider,
        blacks_slider,
    };
    let parameters = recipe.kernel_parameters().to_floats();
    let output = std::slice::from_raw_parts_mut(output_parameters, output_parameter_count);
    output[..LIGHT_KERNEL_PARAMETER_COUNT].copy_from_slice(&parameters);

    1
}

#[no_mangle]
pub unsafe extern "C" fn darkroom_light_kernel_parameters_with_tuning(
    exposure_ev: f32,
    contrast_slider: f32,
    pivot_ev: f32,
    highlights_slider: f32,
    shadows_slider: f32,
    whites_slider: f32,
    blacks_slider: f32,
    tuning_parameters: *const f32,
    tuning_parameter_count: usize,
    output_parameters: *mut f32,
    output_parameter_count: usize,
) -> u8 {
    if output_parameters.is_null()
        || tuning_parameters.is_null()
        || output_parameter_count < LIGHT_KERNEL_PARAMETER_COUNT
        || tuning_parameter_count < TONE_TUNING_PARAMETER_COUNT
    {
        return 0;
    }

    let tuning_slice = std::slice::from_raw_parts(tuning_parameters, TONE_TUNING_PARAMETER_COUNT);
    let Some(tuning) = ToneTuning::from_floats(tuning_slice) else {
        return 0;
    };
    let recipe = LightRecipe {
        exposure_ev,
        contrast_slider,
        pivot_ev,
        highlights_slider,
        shadows_slider,
        whites_slider,
        blacks_slider,
    };
    let parameters = recipe.kernel_parameters_with_tuning(tuning).to_floats();
    let output = std::slice::from_raw_parts_mut(output_parameters, output_parameter_count);
    output[..LIGHT_KERNEL_PARAMETER_COUNT].copy_from_slice(&parameters);

    1
}

#[no_mangle]
pub unsafe extern "C" fn darkroom_histogram_rgba8(
    rgba_pixels: *const u8,
    byte_len: usize,
    red_bins: *mut u32,
    green_bins: *mut u32,
    blue_bins: *mut u32,
    luma_bins: *mut u32,
    sampled_pixel_count: *mut u32,
    shadow_clipped_pixel_count: *mut u32,
    highlight_clipped_pixel_count: *mut u32,
) -> u8 {
    if rgba_pixels.is_null()
        || red_bins.is_null()
        || green_bins.is_null()
        || blue_bins.is_null()
        || luma_bins.is_null()
        || sampled_pixel_count.is_null()
        || shadow_clipped_pixel_count.is_null()
        || highlight_clipped_pixel_count.is_null()
        || byte_len % 4 != 0
    {
        return 0;
    }

    let pixels = std::slice::from_raw_parts(rgba_pixels, byte_len);
    let red = std::slice::from_raw_parts_mut(red_bins, 256);
    let green = std::slice::from_raw_parts_mut(green_bins, 256);
    let blue = std::slice::from_raw_parts_mut(blue_bins, 256);
    let luma = std::slice::from_raw_parts_mut(luma_bins, 256);

    red.fill(0);
    green.fill(0);
    blue.fill(0);
    luma.fill(0);

    let mut sampled = 0_u32;
    let mut shadow_clipped = 0_u32;
    let mut highlight_clipped = 0_u32;

    for pixel in pixels.chunks_exact(4) {
        let red_value = pixel[0];
        let green_value = pixel[1];
        let blue_value = pixel[2];
        let luma_value = rgb_to_luma_u8(red_value, green_value, blue_value);

        red[red_value as usize] += 1;
        green[green_value as usize] += 1;
        blue[blue_value as usize] += 1;
        luma[luma_value as usize] += 1;

        if red_value == 0 && green_value == 0 && blue_value == 0 {
            shadow_clipped += 1;
        }

        if red_value == 255 || green_value == 255 || blue_value == 255 {
            highlight_clipped += 1;
        }

        sampled += 1;
    }

    *sampled_pixel_count = sampled;
    *shadow_clipped_pixel_count = shadow_clipped;
    *highlight_clipped_pixel_count = highlight_clipped;

    1
}

fn rgb_to_luma_u8(red: u8, green: u8, blue: u8) -> u8 {
    (0.2126 * red as f32 + 0.7152 * green as f32 + 0.0722 * blue as f32)
        .round()
        .clamp(0.0, 255.0) as u8
}

#[no_mangle]
pub unsafe extern "C" fn darkroom_histogram_apply_recipe_rgba8(
    rgba_pixels: *const u8,
    byte_len: usize,
    parameters_floats: *const f32,
    red_bins: *mut u32,
    green_bins: *mut u32,
    blue_bins: *mut u32,
    luma_bins: *mut u32,
    sampled_pixel_count: *mut u32,
    shadow_clipped_pixel_count: *mut u32,
    highlight_clipped_pixel_count: *mut u32,
) -> u8 {
    if rgba_pixels.is_null()
        || parameters_floats.is_null()
        || red_bins.is_null()
        || green_bins.is_null()
        || blue_bins.is_null()
        || luma_bins.is_null()
        || sampled_pixel_count.is_null()
        || shadow_clipped_pixel_count.is_null()
        || highlight_clipped_pixel_count.is_null()
        || byte_len % 4 != 0
    {
        return 0;
    }

    let parameters_slice =
        std::slice::from_raw_parts(parameters_floats, LIGHT_KERNEL_PARAMETER_COUNT);
    let Some(parameters) = LightKernelParameters::from_floats(parameters_slice) else {
        return 0;
    };

    let pixels = std::slice::from_raw_parts(rgba_pixels, byte_len);
    let red = std::slice::from_raw_parts_mut(red_bins, 256);
    let green = std::slice::from_raw_parts_mut(green_bins, 256);
    let blue = std::slice::from_raw_parts_mut(blue_bins, 256);
    let luma = std::slice::from_raw_parts_mut(luma_bins, 256);

    red.fill(0);
    green.fill(0);
    blue.fill(0);
    luma.fill(0);

    let mut sampled = 0_u32;
    let mut shadow_clipped = 0_u32;
    let mut highlight_clipped = 0_u32;

    for pixel in pixels.chunks_exact(4) {
        let r_in = pixel[0] as f32 / 255.0;
        let g_in = pixel[1] as f32 / 255.0;
        let b_in = pixel[2] as f32 / 255.0;
        let (r_out, g_out, b_out) = apply_light_rgb_kernel(r_in, g_in, b_in, parameters);

        let red_value = (r_out * 255.0).round().clamp(0.0, 255.0) as u8;
        let green_value = (g_out * 255.0).round().clamp(0.0, 255.0) as u8;
        let blue_value = (b_out * 255.0).round().clamp(0.0, 255.0) as u8;
        let luma_value = rgb_to_luma_u8(red_value, green_value, blue_value);

        red[red_value as usize] += 1;
        green[green_value as usize] += 1;
        blue[blue_value as usize] += 1;
        luma[luma_value as usize] += 1;

        if red_value == 0 && green_value == 0 && blue_value == 0 {
            shadow_clipped += 1;
        }

        if red_value == 255 || green_value == 255 || blue_value == 255 {
            highlight_clipped += 1;
        }

        sampled += 1;
    }

    *sampled_pixel_count = sampled;
    *shadow_clipped_pixel_count = shadow_clipped;
    *highlight_clipped_pixel_count = highlight_clipped;

    1
}

#[cfg(test)]
mod tests {
    use super::*;

    const EPSILON: f32 = 0.000_01;

    fn assert_close(actual: f32, expected: f32) {
        assert!(
            (actual - expected).abs() <= EPSILON,
            "expected {expected}, got {actual}"
        );
    }

    #[test]
    fn exposure_ev_zero_is_identity() {
        assert_close(apply_exposure_scene_linear(0.18, 0.0), 0.18);
    }

    #[test]
    fn exposure_positive_one_stop_doubles_scene_linear_input() {
        assert_close(apply_exposure_scene_linear(0.18, 1.0), 0.36);
    }

    #[test]
    fn exposure_negative_one_stop_halves_scene_linear_input() {
        assert_close(apply_exposure_scene_linear(0.18, -1.0), 0.09);
    }

    #[test]
    fn legacy_pivoted_contrast_reference_still_preserves_pivot() {
        assert_close(apply_pivoted_contrast_scene_linear(0.18, 2.0, 0.18), 0.18);
    }

    #[test]
    fn neutral_tonal_curve_is_luminance_identity() {
        let parameters = LightRecipe::default().kernel_parameters();

        for input in [0.01, 0.18, 0.72, 2.0] {
            assert_close(apply_light_luma_reference(input, parameters), input);
        }
    }

    #[test]
    fn slider_values_map_to_kernel_parameters() {
        let recipe = LightRecipe {
            exposure_ev: 1.0,
            contrast_slider: 100.0,
            pivot_ev: 1.5,
            highlights_slider: -50.0,
            shadows_slider: 25.0,
            whites_slider: 75.0,
            blacks_slider: -25.0,
        };
        let parameters = recipe.kernel_parameters();

        assert_close(parameters.exposure_gain, 2.0);
        assert_close(parameters.contrast_strength, 1.0);
        assert_close(parameters.pivot_ev, 1.5);
        assert_close(parameters.highlights_ev, -0.9);
        assert!(parameters.shadows_ev > 0.0);
        assert!(parameters.whites_ev > 0.0);
        assert!(parameters.blacks_ev < 0.0);
        assert_close(parameters.middle_gray, MIDDLE_GRAY);
        assert_eq!(parameters.to_floats().len(), LIGHT_KERNEL_PARAMETER_COUNT);
    }

    #[test]
    fn default_tuning_preserves_existing_slider_mapping() {
        let recipe = LightRecipe {
            highlights_slider: -50.0,
            shadows_slider: 25.0,
            whites_slider: 75.0,
            blacks_slider: -25.0,
            ..Default::default()
        };
        let parameters = recipe.kernel_parameters_with_tuning(ToneTuning::default());

        assert_close(parameters.highlights_ev, -0.9);
        assert!(parameters.shadows_ev > 0.0);
        assert!(parameters.whites_ev > 0.0);
        assert!(parameters.blacks_ev < 0.0);
        assert_close(parameters.base_contrast, 1.0);
        assert_close(parameters.toe_strength, 0.0);
        assert_close(parameters.shoulder_strength, 0.0);
    }

    #[test]
    fn custom_tuning_can_expand_highlight_and_shadow_strength() {
        let mut tuning = ToneTuning::default();
        tuning.highlights.start_ev = 0.35;
        tuning.highlights.full_ev = 2.4;
        tuning.highlights.max_pull_ev = -3.0;
        tuning.shadows.start_ev = -0.35;
        tuning.shadows.full_ev = -2.7;
        tuning.shadows.max_lift_ev = 3.0;

        let default_parameters = LightRecipe {
            highlights_slider: -100.0,
            shadows_slider: 100.0,
            ..Default::default()
        }
        .kernel_parameters();
        let tuned_parameters = LightRecipe {
            highlights_slider: -100.0,
            shadows_slider: 100.0,
            ..Default::default()
        }
        .kernel_parameters_with_tuning(tuning);

        assert!(tuned_parameters.highlights_ev < default_parameters.highlights_ev);
        assert!(tuned_parameters.shadows_ev > default_parameters.shadows_ev);
        assert!(
            tuned_parameters.highlight_zone_start_ev < default_parameters.highlight_zone_start_ev
        );
        assert!(tuned_parameters.shadow_zone_start_ev < default_parameters.shadow_zone_start_ev);
    }

    #[test]
    fn light_recipe_applies_exposure_as_real_stops() {
        let recipe = LightRecipe {
            exposure_ev: 1.0,
            ..Default::default()
        };

        assert_close(recipe.apply_luma_reference(0.18), 0.36);
    }

    #[test]
    fn contrast_increases_tonal_separation_around_pivot() {
        let high_contrast = LightRecipe {
            contrast_slider: 100.0,
            ..Default::default()
        };
        let neutral = LightRecipe::default();

        assert!(high_contrast.apply_luma_reference(0.36) > neutral.apply_luma_reference(0.36));
        assert!(high_contrast.apply_luma_reference(0.09) < neutral.apply_luma_reference(0.09));
        assert_close(high_contrast.apply_luma_reference(MIDDLE_GRAY), MIDDLE_GRAY);
    }

    #[test]
    fn pivot_changes_contrast_balance_without_moving_middle_gray_when_contrast_is_zero() {
        let pivot_only = LightRecipe {
            pivot_ev: 2.0,
            ..Default::default()
        };

        assert_close(pivot_only.apply_luma_reference(MIDDLE_GRAY), MIDDLE_GRAY);
    }

    #[test]
    fn light_recipe_shadow_control_affects_dark_luma() {
        let lift_shadows = LightRecipe {
            shadows_slider: 50.0,
            ..Default::default()
        };
        let neutral = LightRecipe::default();

        assert!(lift_shadows.apply_luma_reference(0.05) > neutral.apply_luma_reference(0.05));
        assert_close(
            lift_shadows.apply_luma_reference(0.72),
            neutral.apply_luma_reference(0.72),
        );
    }

    #[test]
    fn light_recipe_highlight_control_affects_bright_luma() {
        let pull_highlights = LightRecipe {
            highlights_slider: -50.0,
            ..Default::default()
        };
        let neutral = LightRecipe::default();

        assert!(pull_highlights.apply_luma_reference(0.8) < neutral.apply_luma_reference(0.8));
        assert_close(
            pull_highlights.apply_luma_reference(0.05),
            neutral.apply_luma_reference(0.05),
        );
    }

    #[test]
    fn whites_and_blacks_target_endpoints_more_than_midtones() {
        let brighter_whites = LightRecipe {
            whites_slider: 100.0,
            ..Default::default()
        };
        let deeper_blacks = LightRecipe {
            blacks_slider: -100.0,
            ..Default::default()
        };
        let neutral = LightRecipe::default();

        let white_delta =
            brighter_whites.apply_luma_reference(2.0) - neutral.apply_luma_reference(2.0);
        let white_mid_delta =
            brighter_whites.apply_luma_reference(0.18) - neutral.apply_luma_reference(0.18);
        assert!(white_delta > white_mid_delta.abs());

        let black_delta =
            neutral.apply_luma_reference(0.02) - deeper_blacks.apply_luma_reference(0.02);
        let black_mid_delta =
            neutral.apply_luma_reference(0.18) - deeper_blacks.apply_luma_reference(0.18);
        assert!(black_delta > black_mid_delta.abs());
    }

    #[test]
    fn rgb_tone_application_preserves_channel_ratios() {
        let recipe = LightRecipe {
            contrast_slider: 80.0,
            whites_slider: 60.0,
            ..Default::default()
        };
        let (r, g, b) = apply_light_rgb_kernel(0.4, 0.2, 0.1, recipe.kernel_parameters());

        assert_close(r / g, 2.0);
        assert_close(g / b, 2.0);
    }

    #[test]
    fn extreme_tonal_curve_remains_monotonic() {
        let parameters = LightRecipe {
            contrast_slider: 100.0,
            pivot_ev: -2.0,
            highlights_slider: -100.0,
            shadows_slider: 100.0,
            whites_slider: -100.0,
            blacks_slider: -100.0,
            ..Default::default()
        }
        .kernel_parameters();
        let mut previous = apply_darkroom_tonal_curve_v1_z(-12.0, parameters);

        for step in 1..=1200 {
            let input = -12.0 + step as f32 * 0.02;
            let output = apply_darkroom_tonal_curve_v1_z(input, parameters);
            assert!(
                output + EPSILON >= previous,
                "curve inverted at input {input}: {output} < {previous}"
            );
            previous = output;
        }
    }

    #[test]
    fn c_abi_fills_kernel_parameters() {
        let mut floats = [0.0_f32; LIGHT_KERNEL_PARAMETER_COUNT];
        let succeeded = unsafe {
            darkroom_light_kernel_parameters(
                1.0,
                100.0,
                -1.0,
                -50.0,
                25.0,
                75.0,
                -25.0,
                floats.as_mut_ptr(),
                floats.len(),
            )
        };

        assert_eq!(succeeded, 1);
        assert_close(floats[0], 2.0);
        assert_close(floats[1], 1.0);
        assert_close(floats[2], -1.0);
    }

    #[test]
    fn c_abi_fills_default_tuning_and_custom_kernel_parameters() {
        let mut tuning_floats = [0.0_f32; TONE_TUNING_PARAMETER_COUNT];
        let tuning_succeeded = unsafe {
            darkroom_light_default_tuning(tuning_floats.as_mut_ptr(), tuning_floats.len())
        };
        assert_eq!(tuning_succeeded, 1);
        assert_close(tuning_floats[0], MIDDLE_GRAY);
        assert_close(tuning_floats[36], 0.0);
        assert_close(tuning_floats[37], 1.0);

        tuning_floats[15] = -3.0;
        let mut kernel_floats = [0.0_f32; LIGHT_KERNEL_PARAMETER_COUNT];
        let kernel_succeeded = unsafe {
            darkroom_light_kernel_parameters_with_tuning(
                0.0,
                0.0,
                0.0,
                -100.0,
                0.0,
                0.0,
                0.0,
                tuning_floats.as_ptr(),
                tuning_floats.len(),
                kernel_floats.as_mut_ptr(),
                kernel_floats.len(),
            )
        };

        assert_eq!(kernel_succeeded, 1);
        assert_close(kernel_floats[3], -3.0);
    }

    #[test]
    fn rgba_histogram_counts_channels_luma_and_clipping() {
        let pixels = [0_u8, 0, 0, 255, 255, 255, 255, 255, 255, 0, 0, 255];
        let mut red = [99_u32; 256];
        let mut green = [99_u32; 256];
        let mut blue = [99_u32; 256];
        let mut luma = [99_u32; 256];
        let mut sampled = 0;
        let mut shadow_clipped = 0;
        let mut highlight_clipped = 0;

        let succeeded = unsafe {
            darkroom_histogram_rgba8(
                pixels.as_ptr(),
                pixels.len(),
                red.as_mut_ptr(),
                green.as_mut_ptr(),
                blue.as_mut_ptr(),
                luma.as_mut_ptr(),
                &mut sampled,
                &mut shadow_clipped,
                &mut highlight_clipped,
            )
        };

        assert_eq!(succeeded, 1);
        assert_eq!(sampled, 3);
        assert_eq!(shadow_clipped, 1);
        assert_eq!(highlight_clipped, 2);
        assert_eq!(red[0], 1);
        assert_eq!(red[255], 2);
        assert_eq!(green[0], 2);
        assert_eq!(green[255], 1);
        assert_eq!(blue[0], 2);
        assert_eq!(blue[255], 1);
        assert_eq!(luma[0], 1);
        assert_eq!(luma[54], 1);
        assert_eq!(luma[255], 1);
    }

    #[test]
    fn rgba_apply_recipe_one_stop_doubles_brightness() {
        let pixels = [64_u8, 64, 64, 255];
        let parameters_floats = LightRecipe {
            exposure_ev: 1.0,
            ..Default::default()
        }
        .kernel_parameters()
        .to_floats();
        let mut red = [99_u32; 256];
        let mut green = [99_u32; 256];
        let mut blue = [99_u32; 256];
        let mut luma = [99_u32; 256];
        let mut sampled = 0;
        let mut shadow_clipped = 0;
        let mut highlight_clipped = 0;

        let succeeded = unsafe {
            darkroom_histogram_apply_recipe_rgba8(
                pixels.as_ptr(),
                pixels.len(),
                parameters_floats.as_ptr(),
                red.as_mut_ptr(),
                green.as_mut_ptr(),
                blue.as_mut_ptr(),
                luma.as_mut_ptr(),
                &mut sampled,
                &mut shadow_clipped,
                &mut highlight_clipped,
            )
        };

        assert_eq!(succeeded, 1);
        assert_eq!(sampled, 1);
        let red_bin = red.iter().position(|&count| count > 0).unwrap();
        assert!(
            (red_bin as i32 - 128).abs() <= 2,
            "expected red bin near 128, got {red_bin}"
        );
        let green_bin = green.iter().position(|&count| count > 0).unwrap();
        let blue_bin = blue.iter().position(|&count| count > 0).unwrap();
        assert_eq!(red_bin, green_bin);
        assert_eq!(green_bin, blue_bin);
    }

    #[test]
    fn rgba_apply_recipe_neutral_recipe_matches_input_pixels() {
        let pixels = [10_u8, 80, 200, 255, 250, 15, 60, 255];
        let parameters_floats = LightRecipe::default().kernel_parameters().to_floats();
        let mut red = [0_u32; 256];
        let mut green = [0_u32; 256];
        let mut blue = [0_u32; 256];
        let mut luma = [0_u32; 256];
        let mut sampled = 0;
        let mut shadow_clipped = 0;
        let mut highlight_clipped = 0;

        let succeeded = unsafe {
            darkroom_histogram_apply_recipe_rgba8(
                pixels.as_ptr(),
                pixels.len(),
                parameters_floats.as_ptr(),
                red.as_mut_ptr(),
                green.as_mut_ptr(),
                blue.as_mut_ptr(),
                luma.as_mut_ptr(),
                &mut sampled,
                &mut shadow_clipped,
                &mut highlight_clipped,
            )
        };

        assert_eq!(succeeded, 1);
        assert_eq!(sampled, 2);
        assert_eq!(red[10], 1);
        assert_eq!(red[250], 1);
        assert_eq!(green[80], 1);
        assert_eq!(green[15], 1);
        assert_eq!(blue[200], 1);
        assert_eq!(blue[60], 1);
    }
}
