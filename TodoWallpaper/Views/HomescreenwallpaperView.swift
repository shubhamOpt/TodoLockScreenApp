import SwiftUI

// MARK: - Home Screen Wallpaper View

/// Rendered by ImageRenderer for the home screen.
/// Shows either the style background, a solid color, or a custom photo.
struct HomeScreenWallpaperView: View {

    let type: HomeScreenWallpaperType
    let style: WallpaperStyle          // used when type == .matchLockScreen
    let solidColorHex: String          // used when type == .solidColor
    let customPhoto: UIImage?          // used when type == .customPhoto

    static let canvasWidth:  CGFloat = 393
    static let canvasHeight: CGFloat = 852

    var body: some View {
        ZStack {
            switch type {
            case .matchLockScreen:
                style.background.ignoresSafeArea()

            case .solidColor:
                Color(hex: solidColorHex).ignoresSafeArea()

            case .customPhoto:
                if let photo = customPhoto {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                } else {
                    Color.black.ignoresSafeArea()
                }
            }
        }
        .frame(width: Self.canvasWidth, height: Self.canvasHeight)
    }
}
