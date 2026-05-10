import Foundation

enum DarkroomCoreLightMath {
    static var kernelParameterCount: Int {
        Int(darkroomLightKernelParameterCount())
    }

    static var toneTuningParameterCount: Int {
        Int(darkroomToneTuningParameterCount())
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

    static func exposureGain(exposureEV: Double) -> Double {
        Double(darkroomLightExposureGain(Float(exposureEV)))
    }

    static func normalizedSlider(_ value: Double) -> Double {
        Double(darkroomLightNormalizedSlider(Float(value)))
    }
}

@_silgen_name("darkroom_light_exposure_gain")
private func darkroomLightExposureGain(_ exposureEV: Float) -> Float

@_silgen_name("darkroom_light_normalized_slider")
private func darkroomLightNormalizedSlider(_ value: Float) -> Float

@_silgen_name("darkroom_light_kernel_parameter_count")
private func darkroomLightKernelParameterCount() -> Int

@_silgen_name("darkroom_tone_tuning_parameter_count")
private func darkroomToneTuningParameterCount() -> Int

@_silgen_name("darkroom_light_default_tuning")
private func darkroomLightDefaultTuning(
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
