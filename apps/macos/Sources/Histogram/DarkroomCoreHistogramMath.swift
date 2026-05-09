import Foundation

enum DarkroomCoreHistogramMath {
    static func makeHistogram(rgbaPixels: [UInt8], pixelCount: Int) throws -> ImageHistogram {
        guard pixelCount > 0,
              rgbaPixels.count == pixelCount * 4 else {
            throw HistogramError.unableToReadPixels
        }

        var red = emptyBins()
        var green = emptyBins()
        var blue = emptyBins()
        var luminance = emptyBins()
        var sampledPixelCount: UInt32 = 0
        var shadowClippedPixelCount: UInt32 = 0
        var highlightClippedPixelCount: UInt32 = 0

        let result = rgbaPixels.withUnsafeBufferPointer { pixels in
            red.withUnsafeMutableBufferPointer { redBins in
                green.withUnsafeMutableBufferPointer { greenBins in
                    blue.withUnsafeMutableBufferPointer { blueBins in
                        luminance.withUnsafeMutableBufferPointer { lumaBins in
                            darkroomHistogramRGBA8(
                                pixels.baseAddress,
                                rgbaPixels.count,
                                redBins.baseAddress,
                                greenBins.baseAddress,
                                blueBins.baseAddress,
                                lumaBins.baseAddress,
                                &sampledPixelCount,
                                &shadowClippedPixelCount,
                                &highlightClippedPixelCount
                            )
                        }
                    }
                }
            }
        }

        guard result == 1 else {
            throw HistogramError.unableToReadPixels
        }

        return ImageHistogram(
            luminance: luminance.map(Int.init),
            red: red.map(Int.init),
            green: green.map(Int.init),
            blue: blue.map(Int.init),
            shadowClippedPixelCount: Int(shadowClippedPixelCount),
            highlightClippedPixelCount: Int(highlightClippedPixelCount),
            sampledPixelCount: Int(sampledPixelCount)
        )
    }

    static func makeHistogramApplyingRecipe(
        rgbaPixels: [UInt8],
        pixelCount: Int,
        light: LightAdjustments
    ) throws -> ImageHistogram {
        guard pixelCount > 0,
              rgbaPixels.count == pixelCount * 4 else {
            throw HistogramError.unableToReadPixels
        }

        var red = emptyBins()
        var green = emptyBins()
        var blue = emptyBins()
        var luminance = emptyBins()
        var sampledPixelCount: UInt32 = 0
        var shadowClippedPixelCount: UInt32 = 0
        var highlightClippedPixelCount: UInt32 = 0

        let parameterFloats: [Float] = [
            Float(light.exposureGain),
            Float(light.contrastExponent),
            Float(LightAdjustments.contrastPivot),
            Float(light.normalizedHighlights),
            Float(light.normalizedShadows),
            Float(light.shadowLiftLimit),
            Float(light.shadowDropLimit),
            Float(light.highlightPullLimit),
            Float(light.highlightBoostLimit),
            Float(light.shadowMaskStart),
            Float(light.shadowMaskEnd),
            Float(light.shadowBlackAnchorEnd),
            Float(light.highlightMaskStart),
            Float(light.highlightMaskEnd)
        ]

        let result = rgbaPixels.withUnsafeBufferPointer { pixels in
            parameterFloats.withUnsafeBufferPointer { parameters in
                red.withUnsafeMutableBufferPointer { redBins in
                    green.withUnsafeMutableBufferPointer { greenBins in
                        blue.withUnsafeMutableBufferPointer { blueBins in
                            luminance.withUnsafeMutableBufferPointer { lumaBins in
                                darkroomHistogramApplyRecipeRGBA8(
                                    pixels.baseAddress,
                                    rgbaPixels.count,
                                    parameters.baseAddress,
                                    redBins.baseAddress,
                                    greenBins.baseAddress,
                                    blueBins.baseAddress,
                                    lumaBins.baseAddress,
                                    &sampledPixelCount,
                                    &shadowClippedPixelCount,
                                    &highlightClippedPixelCount
                                )
                            }
                        }
                    }
                }
            }
        }

        guard result == 1 else {
            throw HistogramError.unableToReadPixels
        }

        return ImageHistogram(
            luminance: luminance.map(Int.init),
            red: red.map(Int.init),
            green: green.map(Int.init),
            blue: blue.map(Int.init),
            shadowClippedPixelCount: Int(shadowClippedPixelCount),
            highlightClippedPixelCount: Int(highlightClippedPixelCount),
            sampledPixelCount: Int(sampledPixelCount)
        )
    }

    private static func emptyBins() -> [UInt32] {
        [UInt32](repeating: 0, count: ImageHistogram.binCount)
    }
}

@_silgen_name("darkroom_histogram_rgba8")
private func darkroomHistogramRGBA8(
    _ rgbaPixels: UnsafePointer<UInt8>?,
    _ byteLen: Int,
    _ redBins: UnsafeMutablePointer<UInt32>?,
    _ greenBins: UnsafeMutablePointer<UInt32>?,
    _ blueBins: UnsafeMutablePointer<UInt32>?,
    _ lumaBins: UnsafeMutablePointer<UInt32>?,
    _ sampledPixelCount: UnsafeMutablePointer<UInt32>?,
    _ shadowClippedPixelCount: UnsafeMutablePointer<UInt32>?,
    _ highlightClippedPixelCount: UnsafeMutablePointer<UInt32>?
) -> UInt8

@_silgen_name("darkroom_histogram_apply_recipe_rgba8")
private func darkroomHistogramApplyRecipeRGBA8(
    _ rgbaPixels: UnsafePointer<UInt8>?,
    _ byteLen: Int,
    _ parameterFloats: UnsafePointer<Float>?,
    _ redBins: UnsafeMutablePointer<UInt32>?,
    _ greenBins: UnsafeMutablePointer<UInt32>?,
    _ blueBins: UnsafeMutablePointer<UInt32>?,
    _ lumaBins: UnsafeMutablePointer<UInt32>?,
    _ sampledPixelCount: UnsafeMutablePointer<UInt32>?,
    _ shadowClippedPixelCount: UnsafeMutablePointer<UInt32>?,
    _ highlightClippedPixelCount: UnsafeMutablePointer<UInt32>?
) -> UInt8
