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
            pivot: 0.18,
        }
    }
}

impl Contrast {
    pub fn apply(self, scene_linear: f32) -> f32 {
        apply_pivoted_contrast_scene_linear(scene_linear, self.amount, self.pivot)
    }
}

#[derive(Debug, Clone, Copy, Default, PartialEq)]
pub struct LightRecipe {
    pub exposure: Exposure,
    pub contrast: Contrast,
}

impl LightRecipe {
    pub fn apply_reference(self, scene_linear: f32) -> f32 {
        let exposed = self.exposure.apply(scene_linear);
        self.contrast.apply(exposed)
    }
}

#[derive(Debug, Clone, Copy, Default, PartialEq)]
pub struct EditRecipe {
    pub light: LightRecipe,
}

impl EditRecipe {
    pub fn apply_luma_reference(self, scene_linear: f32) -> f32 {
        self.light.apply_reference(scene_linear)
    }
}

pub fn apply_exposure_scene_linear(input: f32, ev: f32) -> f32 {
    if !input.is_finite() || !ev.is_finite() {
        return input;
    }

    input * 2.0_f32.powf(ev)
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
    fn light_recipe_applies_exposure_then_contrast() {
        let recipe = LightRecipe {
            exposure: Exposure { ev: 1.0 },
            contrast: Contrast {
                amount: 1.0,
                pivot: 0.18,
            },
        };

        assert_close(recipe.apply_reference(0.18), 0.36);
    }
}
