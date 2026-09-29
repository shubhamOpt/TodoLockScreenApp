import SwiftUI
import Photos

@MainActor
enum WallpaperExporter {

    // MARK: - Render

    static func render(
        todos:           [TodoItem],
        calendarEvents:  [CalendarEvent] = [],
        style:           WallpaperStyle,
        backgroundPhoto: UIImage? = nil,
        cardStyle:       CardStyle = .darkBlur
    ) -> UIImage? {
        let view = WallpaperView(
            todos:           todos,
            calendarEvents:  calendarEvents,
            style:           style,
            backgroundPhoto: backgroundPhoto,
            cardStyle:       cardStyle
        )
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0
        guard let raw = renderer.uiImage else { return nil }

        // Flatten to opaque RGB — required for iOS wallpapers
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        format.scale  = raw.scale
        return UIGraphicsImageRenderer(size: raw.size, format: format).image { _ in
            raw.draw(at: .zero)
        }
    }

    // MARK: - Save to Photos

    static func saveToPhotos(
        todos:           [TodoItem],
        calendarEvents:  [CalendarEvent] = [],
        style:           WallpaperStyle,
        backgroundPhoto: UIImage? = nil,
        cardStyle:       CardStyle = .darkBlur
    ) async throws {
        guard let image = render(
            todos: todos, calendarEvents: calendarEvents,
            style: style, backgroundPhoto: backgroundPhoto, cardStyle: cardStyle
        ) else { throw WallpaperError.renderFailed }

        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw WallpaperError.photoPermissionDenied
        }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }

    // MARK: - Save to Shared Container (Shortcuts)

    @discardableResult
    static func saveToSharedContainer(
        todos:           [TodoItem],
        calendarEvents:  [CalendarEvent] = [],
        style:           WallpaperStyle,
        backgroundPhoto: UIImage? = nil,
        cardStyle:       CardStyle = .darkBlur
    ) throws -> URL {
        guard let image = render(
            todos: todos, calendarEvents: calendarEvents,
            style: style, backgroundPhoto: backgroundPhoto, cardStyle: cardStyle
        ),
        let data = image.jpegData(compressionQuality: 0.95) else {
            throw WallpaperError.renderFailed
        }
        let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.yourapp.todowallpaper"
        ) ?? FileManager.default.temporaryDirectory

        let fileURL = containerURL.appendingPathComponent("todo-wallpaper.jpg")
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }
}

// MARK: - Errors

enum WallpaperError: LocalizedError {
    case renderFailed
    case photoPermissionDenied
    var errorDescription: String? {
        switch self {
        case .renderFailed:         return "Failed to render the wallpaper."
        case .photoPermissionDenied: return "Photo library access was denied. Enable it in Settings → Privacy → Photos."
        }
    }
}
