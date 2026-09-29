import AppIntents
import SwiftUI
import UniformTypeIdentifiers

struct GenerateHomeScreenWallpaperIntent: AppIntent {

    static var title: LocalizedStringResource = "Generate Home Screen Wallpaper"
    static var description = IntentDescription(
        "Generates the Home Screen wallpaper based on your settings — solid color, custom photo, or matching the Lock Screen style.",
        categoryName: "Todo Wallpaper"
    )

    // Style is only used when type is matchLockScreen
    @Parameter(title: "Lock Screen Style")
    var style: WallpaperStyleParam?

    @MainActor
    func perform() async throws -> some ReturnsValue<IntentFile> {
        let settings      = AppSettings.shared
        let resolvedStyle = style ?? .dark
        let type          = settings.homeScreenWallpaperType

        // Build the view based on the saved preference
        let view = HomeScreenWallpaperView(
            type:           type,
            style:          resolvedStyle.toWallpaperStyle(),
            solidColorHex:  settings.homeScreenSolidColorHex,
            customPhoto:    type == .customPhoto ? settings.loadCustomHomeScreenPhoto() : nil
        )

        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0

        guard let raw = renderer.uiImage else {
            throw HomeScreenWallpaperError.renderFailed
        }

        // Flatten to opaque RGB
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        format.scale  = raw.scale
        let opaque = UIGraphicsImageRenderer(size: raw.size, format: format).image { _ in
            raw.draw(at: .zero)
        }

        guard let data = opaque.jpegData(compressionQuality: 0.95) else {
            throw HomeScreenWallpaperError.renderFailed
        }

        let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.yourapp.todowallpaper"
        ) ?? FileManager.default.temporaryDirectory

        let fileURL = containerURL.appendingPathComponent("home-screen-wallpaper.jpg")
        try data.write(to: fileURL, options: .atomic)

        return .result(value: IntentFile(
            fileURL: fileURL,
            filename: "home-screen-wallpaper.jpg",
            type: .jpeg
        ))
    }
}

enum HomeScreenWallpaperError: LocalizedError {
    case renderFailed
    var errorDescription: String? { "Failed to render the Home Screen wallpaper." }
}
