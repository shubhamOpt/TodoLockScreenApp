import SwiftUI

// MARK: - Wallpaper Background Type

enum WallpaperBackgroundType: String, CaseIterable, Identifiable {
    case style       = "Style"
    case customPhoto = "Custom Photo"

    var id: String { rawValue }
}

// MARK: - Card Style (translucent overlay on custom photo)

enum CardStyle: String, CaseIterable, Identifiable {
    case darkBlur   = "Dark"
    case lightBlur  = "Light"
    case tinted     = "Tinted"
    case ultraDark  = "Ultra Dark"

    var id: String { rawValue }

    var fillColor: Color {
        switch self {
        case .darkBlur:  return Color.black.opacity(0.55)
        case .lightBlur: return Color.white.opacity(0.55)
        case .tinted:    return Color(hex: "1A1050").opacity(0.72)
        case .ultraDark: return Color.black.opacity(0.82)
        }
    }

    var strokeColor: Color {
        switch self {
        case .lightBlur: return Color.white.opacity(0.4)
        default:         return Color.white.opacity(0.12)
        }
    }

    var primaryTextColor: Color {
        switch self {
        case .lightBlur: return Color(hex: "111111")
        default:         return .white
        }
    }

    var secondaryTextColor: Color {
        switch self {
        case .lightBlur: return Color(hex: "444444")
        default:         return Color.white.opacity(0.55)
        }
    }

    var accentColor: Color {
        switch self {
        case .lightBlur: return Color(hex: "3A3A3A")
        case .tinted:    return Color(hex: "A78BFA")
        default:         return Color.white.opacity(0.9)
        }
    }

    var checkmarkColor: Color {
        switch self {
        case .lightBlur: return Color(hex: "22C55E")
        case .tinted:    return Color(hex: "A78BFA")
        default:         return Color(hex: "4ADE80")
        }
    }

    var dividerColor: Color {
        switch self {
        case .lightBlur: return Color.black.opacity(0.1)
        default:         return Color.white.opacity(0.12)
        }
    }
}
