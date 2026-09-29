import SwiftUI

// MARK: - Auto-Remove Delay

enum AutoRemoveDelay: String, CaseIterable, Identifiable {
    case never        = "Never"
    case immediately  = "Immediately"
    case oneHour      = "After 1 hour"
    case sixHours     = "After 6 hours"
    case oneDay       = "After 24 hours"

    var id: String { rawValue }

    var interval: TimeInterval? {
        switch self {
        case .never:       return nil
        case .immediately: return 0
        case .oneHour:     return 3_600
        case .sixHours:    return 21_600
        case .oneDay:      return 86_400
        }
    }
}

// MARK: - Home Screen Wallpaper Type

enum HomeScreenWallpaperType: String, CaseIterable, Identifiable {
    case matchLockScreen = "Match Lock Screen"
    case solidColor      = "Solid Color"
    case customPhoto     = "Custom Photo"

    var id: String { rawValue }
}

// MARK: - AppSettings

final class AppSettings {
    static let shared = AppSettings()
    private init() {}

    private let defaults = UserDefaults(suiteName: "group.com.yourapp.todowallpaper")
                        ?? UserDefaults.standard

    // MARK: Keys

    enum Keys {
        static let autoRemoveDelay           = "autoRemoveDelay"
        static let showCalendarEvents        = "showCalendarEvents"
        static let homeScreenWallpaperType   = "homeScreenWallpaperType"
        static let homeScreenSolidColorHex   = "homeScreenSolidColorHex"
        static let lockscreenBackgroundType  = "lockscreenBackgroundType"
        static let lockscreenCardStyle       = "lockscreenCardStyle"
    }

    // MARK: - Todo settings

    var autoRemoveDelay: AutoRemoveDelay {
        get {
            let raw = defaults.string(forKey: Keys.autoRemoveDelay) ?? AutoRemoveDelay.oneHour.rawValue
            return AutoRemoveDelay(rawValue: raw) ?? .oneHour
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.autoRemoveDelay) }
    }

    var showCalendarEvents: Bool {
        get { defaults.object(forKey: Keys.showCalendarEvents) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.showCalendarEvents) }
    }

    // MARK: - Home screen settings

    var homeScreenWallpaperType: HomeScreenWallpaperType {
        get {
            let raw = defaults.string(forKey: Keys.homeScreenWallpaperType)
                   ?? HomeScreenWallpaperType.matchLockScreen.rawValue
            return HomeScreenWallpaperType(rawValue: raw) ?? .matchLockScreen
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.homeScreenWallpaperType) }
    }

    var homeScreenSolidColorHex: String {
        get { defaults.string(forKey: Keys.homeScreenSolidColorHex) ?? "000000" }
        set { defaults.set(newValue, forKey: Keys.homeScreenSolidColorHex) }
    }

    static func homeScreenPhotoURL() -> URL {
        let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.yourapp.todowallpaper"
        ) ?? FileManager.default.temporaryDirectory
        return container.appendingPathComponent("home-screen-custom-photo.jpg")
    }

    func saveCustomHomeScreenPhoto(_ image: UIImage) throws {
        guard let data = image.jpegData(compressionQuality: 0.95) else { return }
        try data.write(to: AppSettings.homeScreenPhotoURL(), options: .atomic)
    }

    func loadCustomHomeScreenPhoto() -> UIImage? {
        let url = AppSettings.homeScreenPhotoURL()
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    // MARK: - Lockscreen settings

    var lockscreenBackgroundType: WallpaperBackgroundType {
        get {
            let raw = defaults.string(forKey: Keys.lockscreenBackgroundType)
                   ?? WallpaperBackgroundType.style.rawValue
            return WallpaperBackgroundType(rawValue: raw) ?? .style
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.lockscreenBackgroundType) }
    }

    var lockscreenCardStyle: CardStyle {
        get {
            let raw = defaults.string(forKey: Keys.lockscreenCardStyle)
                   ?? CardStyle.darkBlur.rawValue
            return CardStyle(rawValue: raw) ?? .darkBlur
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.lockscreenCardStyle) }
    }

    static func lockscreenPhotoURL() -> URL {
        let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.yourapp.todowallpaper"
        ) ?? FileManager.default.temporaryDirectory
        return container.appendingPathComponent("lockscreen-custom-photo.jpg")
    }

    func saveLockscreenPhoto(_ image: UIImage) throws {
        guard let data = image.jpegData(compressionQuality: 0.92) else { return }
        try data.write(to: AppSettings.lockscreenPhotoURL(), options: .atomic)
    }

    func loadLockscreenPhoto() -> UIImage? {
        let url = AppSettings.lockscreenPhotoURL()
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}
