import CoreGraphics

enum WorkingColorSpace {
    static var linearROMMRGB: CGColorSpace {
        let rommRGB = CGColorSpace(name: CGColorSpace.rommrgb)!
        return CGColorSpaceCreateExtendedLinearized(rommRGB) ?? rommRGB
    }

    static var displayName: String {
        "Linear ROMM RGB"
    }
}
