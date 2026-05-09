import SwiftUI

enum ViewerBackground: String, CaseIterable, Identifiable {
    case black
    case darkGray
    case mediumGray
    case lightGray
    case white

    var id: String {
        rawValue
    }

    var label: String {
        switch self {
        case .black:
            "Black"
        case .darkGray:
            "Dark Gray"
        case .mediumGray:
            "Medium Gray"
        case .lightGray:
            "Light Gray"
        case .white:
            "White"
        }
    }

    var color: Color {
        switch self {
        case .black:
            Color.black
        case .darkGray:
            Color(white: 0.13)
        case .mediumGray:
            Color(white: 0.42)
        case .lightGray:
            Color(white: 0.78)
        case .white:
            Color.white
        }
    }
}
