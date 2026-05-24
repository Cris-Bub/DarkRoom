import Foundation

enum DarkroomCoreLightMath {
    static var kernelParameterCount: Int {
        Int(darkroomLightKernelParameterCount())
    }

    static var toneTuningParameterCount: Int {
        Int(darkroomToneTuningParameterCount())
    }

    static var behaviorTuningParameterCount: Int {
        Int(darkroomBehaviorTuningParameterCount())
    }

    static func defaultToneTuningParameters() -> [Float] {
        var parameters = [Float](repeating: 0, count: toneTuningParameterCount)
        let result = parameters.withUnsafeMutableBufferPointer { buffer in
            darkroomLightDefaultTuning(buffer.baseAddress, buffer.count)
        }

        guard result == 1 else {
            return []
        }

        return parameters
    }

    static func defaultBehaviorTuningParameters() -> [Float] {
        var parameters = [Float](repeating: 0, count: behaviorTuningParameterCount)
        let result = parameters.withUnsafeMutableBufferPointer { buffer in
            darkroomLightDefaultBehaviorTuning(buffer.baseAddress, buffer.count)
        }

        guard result == 1 else {
            return []
        }

        return parameters
    }

    static func kernelParameters(for light: LightAdjustments) -> [Float] {
        kernelParameters(for: light, toneTuning: .defaultV1)
    }

    static func kernelParameters(for light: LightAdjustments, toneTuning: ToneTuning) -> [Float] {
        var parameters = [Float](repeating: 0, count: kernelParameterCount)
        let tuningParameters = toneTuning.flatParameters
        let result = tuningParameters.withUnsafeBufferPointer { tuningBuffer in
            parameters.withUnsafeMutableBufferPointer { buffer in
                darkroomLightKernelParametersWithTuning(
                    Float(light.exposureEV),
                    Float(light.contrast),
                    Float(light.pivotEV),
                    Float(light.highlights),
                    Float(light.shadows),
                    Float(light.whites),
                    Float(light.blacks),
                    tuningBuffer.baseAddress,
                    tuningBuffer.count,
                    buffer.baseAddress,
                    buffer.count
                )
            }
        }

        guard result == 1 else {
            return [Float](repeating: 0, count: kernelParameterCount)
        }

        return parameters
    }

    static func kernelParameters(for light: LightAdjustments, behaviorTuning: BehaviorTuning) -> [Float] {
        var parameters = [Float](repeating: 0, count: kernelParameterCount)
        let behaviorParameters = behaviorTuning.flatParameters
        let result = behaviorParameters.withUnsafeBufferPointer { behaviorBuffer in
            parameters.withUnsafeMutableBufferPointer { buffer in
                darkroomLightKernelParametersWithBehaviorTuning(
                    Float(light.exposureEV),
                    Float(light.contrast),
                    Float(light.pivotEV),
                    Float(light.highlights),
                    Float(light.shadows),
                    Float(light.whites),
                    Float(light.blacks),
                    behaviorBuffer.baseAddress,
                    behaviorBuffer.count,
                    buffer.baseAddress,
                    buffer.count
                )
            }
        }

        guard result == 1 else {
            return [Float](repeating: 0, count: kernelParameterCount)
        }

        return parameters
    }

    static func exposureGain(exposureEV: Double) -> Double {
        Double(darkroomLightExposureGain(Float(exposureEV)))
    }

    static func normalizedSlider(_ value: Double) -> Double {
        Double(darkroomLightNormalizedSlider(Float(value)))
    }

    static func sliderResponse(slider: Double, mapping: PerSliderMapping) -> Double {
        Double(
            darkroomLightSliderResponseWithMapping(
                Float(slider),
                Float(mapping.nearZeroSensitivity),
                Float(mapping.midSensitivity),
                Float(mapping.extremeSensitivity),
                Float(mapping.responseExponent),
                Float(mapping.softLimit),
                Float(mapping.deadZone),
                Float(mapping.positiveNegativeSymmetry)
            )
        )
    }

    static func zoneInfluenceSample(
        distanceEV: Double,
        startEV: Double,
        fullEV: Double,
        falloff: Double,
        midtoneProtection: Double,
        endpointProtection: Double,
        falloffShape: FalloffShape,
        bodyBias: Double,
        peakDamping: Double
    ) -> Double {
        Double(
            darkroomToneZoneInfluenceSample(
                Float(distanceEV),
                Float(startEV),
                Float(fullEV),
                Float(falloff),
                Float(midtoneProtection),
                Float(endpointProtection),
                Float(falloffShape.kernelValue),
                Float(bodyBias),
                Float(peakDamping)
            )
        )
    }
}

@_silgen_name("darkroom_light_exposure_gain")
private func darkroomLightExposureGain(_ exposureEV: Float) -> Float

@_silgen_name("darkroom_light_normalized_slider")
private func darkroomLightNormalizedSlider(_ value: Float) -> Float

@_silgen_name("darkroom_light_slider_response_with_mapping")
private func darkroomLightSliderResponseWithMapping(
    _ slider: Float,
    _ nearZeroSensitivity: Float,
    _ midSensitivity: Float,
    _ extremeSensitivity: Float,
    _ responseExponent: Float,
    _ softLimit: Float,
    _ deadZone: Float,
    _ positiveNegativeSymmetry: Float
) -> Float

@_silgen_name("darkroom_light_kernel_parameter_count")
private func darkroomLightKernelParameterCount() -> Int

@_silgen_name("darkroom_tone_zone_influence_sample")
private func darkroomToneZoneInfluenceSample(
    _ distanceEV: Float,
    _ startEV: Float,
    _ fullEV: Float,
    _ falloff: Float,
    _ midtoneProtection: Float,
    _ endpointProtection: Float,
    _ falloffShape: Float,
    _ bodyBias: Float,
    _ peakDamping: Float
) -> Float

@_silgen_name("darkroom_tone_tuning_parameter_count")
private func darkroomToneTuningParameterCount() -> Int

@_silgen_name("darkroom_behavior_tuning_parameter_count")
private func darkroomBehaviorTuningParameterCount() -> Int

@_silgen_name("darkroom_light_default_tuning")
private func darkroomLightDefaultTuning(
    _ outputParameters: UnsafeMutablePointer<Float>?,
    _ outputParameterCount: Int
) -> UInt8

@_silgen_name("darkroom_light_default_behavior_tuning")
private func darkroomLightDefaultBehaviorTuning(
    _ outputParameters: UnsafeMutablePointer<Float>?,
    _ outputParameterCount: Int
) -> UInt8

@_silgen_name("darkroom_light_kernel_parameters")
private func darkroomLightKernelParameters(
    _ exposureEV: Float,
    _ contrast: Float,
    _ pivotEV: Float,
    _ highlights: Float,
    _ shadows: Float,
    _ whites: Float,
    _ blacks: Float,
    _ outputParameters: UnsafeMutablePointer<Float>?,
    _ outputParameterCount: Int
) -> UInt8

@_silgen_name("darkroom_light_kernel_parameters_with_tuning")
private func darkroomLightKernelParametersWithTuning(
    _ exposureEV: Float,
    _ contrast: Float,
    _ pivotEV: Float,
    _ highlights: Float,
    _ shadows: Float,
    _ whites: Float,
    _ blacks: Float,
    _ tuningParameters: UnsafePointer<Float>?,
    _ tuningParameterCount: Int,
    _ outputParameters: UnsafeMutablePointer<Float>?,
    _ outputParameterCount: Int
) -> UInt8

@_silgen_name("darkroom_light_kernel_parameters_with_behavior_tuning")
private func darkroomLightKernelParametersWithBehaviorTuning(
    _ exposureEV: Float,
    _ contrast: Float,
    _ pivotEV: Float,
    _ highlights: Float,
    _ shadows: Float,
    _ whites: Float,
    _ blacks: Float,
    _ behaviorParameters: UnsafePointer<Float>?,
    _ behaviorParameterCount: Int,
    _ outputParameters: UnsafeMutablePointer<Float>?,
    _ outputParameterCount: Int
) -> UInt8
