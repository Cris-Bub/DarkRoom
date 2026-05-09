pub const DEFAULT_CONTRAST_PIVOT: f32 = 0.18;
pub const SHADOW_MASK_START: f32 = 0.03;
pub const SHADOW_MASK_END: f32 = 0.36;
pub const SHADOW_BLACK_ANCHOR_END: f32 = 0.045;
pub const HIGHLIGHT_MASK_START: f32 = 0.26;
pub const HIGHLIGHT_MASK_END: f32 = 0.85;
pub const SHADOW_LIFT_LIMIT: f32 = 0.58;
pub const SHADOW_DROP_LIMIT: f32 = 0.50;
pub const HIGHLIGHT_PULL_LIMIT: f32 = 0.50;
pub const HIGHLIGHT_BOOST_LIMIT: f32 = 0.35;

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
    pub amount: f32,
    pub pivot: f32,
}

impl Default for Contrast {
    fn default() -> Self {
        Self {
            amount: 1.0,
            pivot: DEFAULT_CONTRAST_PIVOT,
        }
    }
}

impl Contrast {
    pub fn from_slider(slider: f32) -> Self {
        Self {
            amount: contrast_slider_to_exponent(slider),
            pivot: DEFAULT_CONTRAST_PIVOT,
        }
    }

    pub fn apply(self, scene_linear: f32) -> f32 {
        apply_pivoted_contrast_scene_linear(scene_linear, self.amount, self.pivot)
    }
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub struct LightRecipe {
    pub exposure_ev: f32,
    pub contrast_slider: f32,
    pub highlights_slider: f32,
    pub shadows_slider: f32,
}

impl Default for LightRecipe {
    fn default() -> Self {
        Self {
            exposure_ev: 0.0,
            contrast_slider: 0.0,
            highlights_slider: 0.0,
            shadows_slider: 0.0,
        }
    }
}

impl LightRecipe {
    pub fn kernel_parameters(self) -> LightKernelParameters {
        LightKernelParameters {
            exposure_gain: exposure_ev_to_gain(self.exposure_ev),
            contrast_exponent: contrast_slider_to_exponent(self.contrast_slider),
            contrast_pivot: DEFAULT_CONTRAST_PIVOT,
            highlights: normalize_adjustment_slider(self.highlights_slider),
            shadows: normalize_adjustment_slider(self.shadows_slider),
            shadow_lift_limit: SHADOW_LIFT_LIMIT,
            shadow_drop_limit: SHADOW_DROP_LIMIT,
            highlight_pull_limit: HIGHLIGHT_PULL_LIMIT,
            highlight_boost_limit: HIGHLIGHT_BOOST_LIMIT,
            shadow_mask_start: SHADOW_MASK_START,
            shadow_mask_end: SHADOW_MASK_END,
            shadow_black_anchor_end: SHADOW_BLACK_ANCHOR_END,
            highlight_mask_start: HIGHLIGHT_MASK_START,
            highlight_mask_end: HIGHLIGHT_MASK_END,
        }
    }

    pub fn apply_luma_reference(self, scene_linear: f32) -> f32 {
        let parameters = self.kernel_parameters();
        apply_light_luma_reference(scene_linear, parameters)
    }
}

#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct LightKernelParameters {
    pub exposure_gain: f32,
    pub contrast_exponent: f32,
    pub contrast_pivot: f32,
    pub highlights: f32,
    pub shadows: f32,
    pub shadow_lift_limit: f32,
    pub shadow_drop_limit: f32,
    pub highlight_pull_limit: f32,
    pub highlight_boost_limit: f32,
    pub shadow_mask_start: f32,
    pub shadow_mask_end: f32,
    pub shadow_black_anchor_end: f32,
    pub highlight_mask_start: f32,
    pub highlight_mask_end: f32,
}

impl Default for LightKernelParameters {
    fn default() -> Self {
        LightRecipe::default().kernel_parameters()
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

pub fn contrast_slider_to_exponent(slider: f32) -> f32 {
    if !slider.is_finite() {
        return 1.0;
    }

    2.0_f32.powf(slider / 100.0)
}

pub fn normalize_adjustment_slider(slider: f32) -> f32 {
    if !slider.is_finite() {
        return 0.0;
    }

    slider / 100.0
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

    let exposed = input * parameters.exposure_gain;
    let contrasted = apply_pivoted_contrast_scene_linear(
        exposed,
        parameters.contrast_exponent,
        parameters.contrast_pivot,
    );

    apply_tonal_recovery_luma(contrasted, parameters)
}

pub fn apply_tonal_recovery_luma(input: f32, parameters: LightKernelParameters) -> f32 {
    if !input.is_finite() || input <= 0.0 {
        return input;
    }

    let shadow_mask = 1.0
        - smoothstep(
            parameters.shadow_mask_start,
            parameters.shadow_mask_end,
            input,
        );
    let shadow_lift_mask = shadow_mask * smoothstep(0.0, parameters.shadow_black_anchor_end, input);
    let highlight_mask = smoothstep(
        parameters.highlight_mask_start,
        parameters.highlight_mask_end,
        input,
    );

    let mut output = input;

    if parameters.shadows >= 0.0 {
        let distance_to_pivot = (parameters.contrast_pivot - output).max(0.0);
        output += distance_to_pivot
            * parameters.shadows
            * parameters.shadow_lift_limit
            * shadow_lift_mask;
    } else {
        let darken = (-parameters.shadows) * parameters.shadow_drop_limit * shadow_mask;
        output *= (1.0 - darken).max(0.0);
    }

    if parameters.highlights >= 0.0 {
        output *= 1.0 + parameters.highlights * parameters.highlight_boost_limit * highlight_mask;
    } else {
        let distance_from_pivot = (output - parameters.contrast_pivot).max(0.0);
        output -= distance_from_pivot
            * (-parameters.highlights)
            * parameters.highlight_pull_limit
            * highlight_mask;
    }

    output.max(0.0)
}

fn smoothstep(edge0: f32, edge1: f32, value: f32) -> f32 {
    if edge0 == edge1 {
        return if value < edge0 { 0.0 } else { 1.0 };
    }

    let t = ((value - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
    t * t * (3.0 - 2.0 * t)
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
pub extern "C" fn darkroom_light_shadow_lift_limit() -> f32 {
    SHADOW_LIFT_LIMIT
}

#[no_mangle]
pub extern "C" fn darkroom_light_shadow_drop_limit() -> f32 {
    SHADOW_DROP_LIMIT
}

#[no_mangle]
pub extern "C" fn darkroom_light_highlight_pull_limit() -> f32 {
    HIGHLIGHT_PULL_LIMIT
}

#[no_mangle]
pub extern "C" fn darkroom_light_highlight_boost_limit() -> f32 {
    HIGHLIGHT_BOOST_LIMIT
}

#[no_mangle]
pub extern "C" fn darkroom_light_shadow_mask_start() -> f32 {
    SHADOW_MASK_START
}

#[no_mangle]
pub extern "C" fn darkroom_light_shadow_mask_end() -> f32 {
    SHADOW_MASK_END
}

#[no_mangle]
pub extern "C" fn darkroom_light_shadow_black_anchor_end() -> f32 {
    SHADOW_BLACK_ANCHOR_END
}

#[no_mangle]
pub extern "C" fn darkroom_light_highlight_mask_start() -> f32 {
    HIGHLIGHT_MASK_START
}

#[no_mangle]
pub extern "C" fn darkroom_light_highlight_mask_end() -> f32 {
    HIGHLIGHT_MASK_END
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
    fn contrast_one_is_identity() {
        assert_close(apply_pivoted_contrast_scene_linear(0.36, 1.0, 0.18), 0.36);
    }

    #[test]
    fn contrast_preserves_pivot() {
        assert_close(apply_pivoted_contrast_scene_linear(0.18, 2.0, 0.18), 0.18);
    }

    #[test]
    fn contrast_expands_around_pivot() {
        assert_close(apply_pivoted_contrast_scene_linear(0.36, 2.0, 0.18), 0.72);
        assert_close(apply_pivoted_contrast_scene_linear(0.09, 2.0, 0.18), 0.045);
    }

    #[test]
    fn slider_values_map_to_kernel_parameters() {
        let recipe = LightRecipe {
            exposure_ev: 1.0,
            contrast_slider: 100.0,
            highlights_slider: -50.0,
            shadows_slider: 25.0,
        };
        let parameters = recipe.kernel_parameters();

        assert_close(parameters.exposure_gain, 2.0);
        assert_close(parameters.contrast_exponent, 2.0);
        assert_close(parameters.contrast_pivot, DEFAULT_CONTRAST_PIVOT);
        assert_close(parameters.highlights, -0.5);
        assert_close(parameters.shadows, 0.25);
        assert_close(parameters.shadow_lift_limit, SHADOW_LIFT_LIMIT);
        assert_close(parameters.highlight_pull_limit, HIGHLIGHT_PULL_LIMIT);
        assert_close(parameters.highlight_mask_start, HIGHLIGHT_MASK_START);
    }

    #[test]
    fn light_recipe_applies_exposure_then_contrast() {
        let recipe = LightRecipe {
            exposure_ev: 1.0,
            ..Default::default()
        };

        assert_close(recipe.apply_luma_reference(0.18), 0.36);
    }

    #[test]
    fn light_recipe_shadow_control_affects_dark_luma() {
        let lift_shadows = LightRecipe {
            shadows_slider: 50.0,
            ..Default::default()
        };
        let neutral = LightRecipe::default();

        assert!(lift_shadows.apply_luma_reference(0.1) > neutral.apply_luma_reference(0.1));
    }

    #[test]
    fn shadow_lift_preserves_black_and_stays_below_middle_gray() {
        let parameters = LightRecipe {
            shadows_slider: 100.0,
            ..Default::default()
        }
        .kernel_parameters();

        assert_close(apply_tonal_recovery_luma(0.0, parameters), 0.0);

        let lifted_shadow = apply_tonal_recovery_luma(0.08, parameters);
        assert!(lifted_shadow > 0.08);
        assert!(lifted_shadow < DEFAULT_CONTRAST_PIVOT);
    }

    #[test]
    fn light_recipe_highlight_control_affects_bright_luma() {
        let pull_highlights = LightRecipe {
            highlights_slider: -50.0,
            ..Default::default()
        };
        let neutral = LightRecipe::default();

        assert!(pull_highlights.apply_luma_reference(0.8) < neutral.apply_luma_reference(0.8));
    }

    #[test]
    fn highlight_recovery_does_not_pull_bright_tones_below_middle_gray() {
        let parameters = LightRecipe {
            highlights_slider: -100.0,
            ..Default::default()
        }
        .kernel_parameters();

        let recovered_highlight = apply_tonal_recovery_luma(1.0, parameters);
        assert!(recovered_highlight < 1.0);
        assert!(recovered_highlight > DEFAULT_CONTRAST_PIVOT);
    }

    #[test]
    fn extreme_recovery_curve_remains_monotonic() {
        let parameters = LightRecipe {
            highlights_slider: -100.0,
            shadows_slider: 100.0,
            ..Default::default()
        }
        .kernel_parameters();
        let mut previous = apply_tonal_recovery_luma(0.0, parameters);

        for step in 1..=400 {
            let input = step as f32 / 200.0;
            let output = apply_tonal_recovery_luma(input, parameters);
            assert!(
                output + EPSILON >= previous,
                "curve inverted at input {input}: {output} < {previous}"
            );
            previous = output;
        }
    }
}
