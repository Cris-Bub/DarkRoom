import SwiftUI

enum DarkRoomDesign {
    enum Spacing {
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let viewerPadding: CGFloat = 28
    }

    enum Typography {
        static let panelHeader: Font = .headline
        static let emptyStateTitle: Font = .headline
        static let emptyStateMessage: Font = .caption
        static let viewerPlaceholder: Font = .title3
    }

    enum Icon {
        static let emptyLibrary = "photo.on.rectangle"
    }
}
