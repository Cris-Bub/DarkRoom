import AppKit
import CoreGraphics

struct ViewerDisplayProfile: @unchecked Sendable {
    let colorSpace: CGColorSpace
    let displayName: String
    let identity: String

    init(colorSpace: NSColorSpace?, displayName: String?) {
        let resolvedColorSpace = colorSpace?.cgColorSpace ?? Self.fallbackColorSpace
        let colorSpaceName = resolvedColorSpace.name as String? ?? "unnamed"
        let resolvedDisplayName = displayName ?? colorSpace?.localizedName ?? "Current Display"

        self.colorSpace = resolvedColorSpace
        self.displayName = resolvedDisplayName
        self.identity = "\(resolvedDisplayName)|\(colorSpaceName)"
    }

    static func current() -> ViewerDisplayProfile {
        ViewerDisplayProfile(
            colorSpace: NSScreen.main?.colorSpace,
            displayName: NSScreen.main?.localizedName
        )
    }

    private static var fallbackColorSpace: CGColorSpace {
        CGColorSpace(name: CGColorSpace.displayP3) ?? CGColorSpace(name: CGColorSpace.sRGB)!
    }
}
