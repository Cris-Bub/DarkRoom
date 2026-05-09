import SwiftUI

enum DarkRoomDesign {
    enum Spacing {
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 22
        static let viewerPadding: CGFloat = 28
    }

    enum Typography {
        static let panelHeader: Font = .headline
        static let inspectorTitle: Font = .title3.weight(.semibold)
        static let sectionHeader: Font = .headline.weight(.semibold)
        static let controlLabel: Font = .body
        static let controlValue: Font = .body.monospacedDigit()
        static let emptyStateTitle: Font = .headline
        static let emptyStateMessage: Font = .caption
        static let viewerPlaceholder: Font = .title3
        static let detailLabel: Font = .caption
        static let detailValue: Font = .caption.monospacedDigit()
    }

    enum Palette {
        static let inspectorBackground = Color(white: 0.135)
        static let inspectorRaised = Color.white.opacity(0.045)
        static let inspectorBorder = Color.white.opacity(0.08)
        static let railBackground = Color(white: 0.105)
        static let railSelected = Color.white.opacity(0.11)
        static let sliderTrack = Color.white.opacity(0.48)
        static let sliderKnobStroke = Color.white.opacity(0.72)
        static let subtleText = Color.white.opacity(0.56)
        static let primaryText = Color.white.opacity(0.86)
    }

    enum Icon {
        static let emptyLibrary = "photo.on.rectangle"
        static let editMode = "slider.horizontal.3"
        static let cropMode = "crop.rotate"
        static let maskMode = "circle.hexagongrid"
        static let imageDetails = "info.circle"
    }
}
