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

pub fn apply_light_rgb_kernel(
    red: f32,
    green: f32,
    blue: f32,
    parameters: LightKernelParameters,
) -> (f32, f32, f32) {
    let r1 = (red * parameters.exposure_gain).max(0.0);
    let g1 = (green * parameters.exposure_gain).max(0.0);
    let b1 = (blue * parameters.exposure_gain).max(0.0);

    let r2 = apply_pivoted_contrast_per_channel(
        r1,
        parameters.contrast_exponent,
        parameters.contrast_pivot,
    );
    let g2 = apply_pivoted_contrast_per_channel(
        g1,
        parameters.contrast_exponent,
        parameters.contrast_pivot,
    );
    let b2 = apply_pivoted_contrast_per_channel(
        b1,
        parameters.contrast_exponent,
        parameters.contrast_pivot,
    );

    let luma = 0.2126 * r2 + 0.7152 * g2 + 0.0722 * b2;
    let target_luma = apply_tonal_recovery_luma(luma, parameters);
    let ratio = (target_luma / luma.max(1e-6)).max(0.0);

    (r2 * ratio, g2 * ratio, b2 * ratio)
}

fn apply_pivoted_contrast_per_channel(input: f32, contrast: f32, pivot: f32) -> f32 {
    if !input.is_finite() || !contrast.is_finite() || !pivot.is_finite() {
        return input;
    }

    if pivot <= 0.0 || contrast <= 0.0 {
        return input;
    }

    if input <= 0.0 {
        return 0.0;
    }

    pivot * (input / pivot).powf(contrast)
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

    let parameters_slice = std::slice::from_raw_parts(parameters_floats, 14);
    let parameters = LightKernelParameters {
        exposure_gain: parameters_slice[0],
        contrast_exponent: parameters_slice[1],
        contrast_pivot: parameters_slice[2],
        highlights: parameters_slice[3],
        shadows: parameters_slice[4],
        shadow_lift_limit: parameters_slice[5],
        shadow_drop_limit: parameters_slice[6],
        highlight_pull_limit: parameters_slice[7],
        highlight_boost_limit: parameters_slice[8],
        shadow_mask_start: parameters_slice[9],
        shadow_mask_end: parameters_slice[10],
        shadow_black_anchor_end: parameters_slice[11],
        highlight_mask_start: parameters_slice[12],
        highlight_mask_end: parameters_slice[13],
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

    #[test]
    fn rgba_histogram_counts_channels_luma_and_clipping() {
        let pixels = [
            0_u8, 0, 0, 255,
            255, 255, 255, 255,
            255, 0, 0, 255,
        ];
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
        let parameters = LightRecipe {
            exposure_ev: 1.0,
            ..Default::default()
        }
        .kernel_parameters();
        let parameters_floats = light_kernel_parameters_to_floats(parameters);
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
        let parameters = LightRecipe::default().kernel_parameters();
        let parameters_floats = light_kernel_parameters_to_floats(parameters);
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

    fn light_kernel_parameters_to_floats(parameters: LightKernelParameters) -> [f32; 14] {
        [
            parameters.exposure_gain,
            parameters.contrast_exponent,
            parameters.contrast_pivot,
            parameters.highlights,
            parameters.shadows,
            parameters.shadow_lift_limit,
            parameters.shadow_drop_limit,
            parameters.highlight_pull_limit,
            parameters.highlight_boost_limit,
            parameters.shadow_mask_start,
            parameters.shadow_mask_end,
            parameters.shadow_black_anchor_end,
            parameters.highlight_mask_start,
            parameters.highlight_mask_end,
        ]
    }
}
