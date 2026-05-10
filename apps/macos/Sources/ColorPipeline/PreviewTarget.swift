import CoreGraphics

enum PreviewTarget: String, CaseIterable, Identifiable, Sendable {
    case webInstagram
    case appleDisplayP3

    var id: String {
        rawValue
    }

    var label: String {
        switch self {
        case .webInstagram:
            "Web / Instagram"
        case .appleDisplayP3:
            "Apple Display P3"
        }
    }

    var colorSpace: CGColorSpace {
        switch self {
        case .webInstagram:
            CGColorSpace(name: CGColorSpace.sRGB)!
        case .appleDisplayP3:
            CGColorSpace(name: CGColorSpace.displayP3)!
        }
    }

    var profileName: String {
        switch self {
        case .webInstagram:
            "sRGB"
        case .appleDisplayP3:
            "Display P3"
        }
    }
}
