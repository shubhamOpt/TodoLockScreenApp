import AppIntents
import SwiftData
import EventKit
import SwiftUI
import UniformTypeIdentifiers

struct GenerateTodoWallpaperIntent: AppIntent {

    static var title: LocalizedStringResource = "Generate Todo Wallpaper"
    static var description = IntentDescription(
        "Renders your todo list and today's calendar events as a Lock Screen wallpaper.",
        categoryName: "Todo Wallpaper"
    )

    @Parameter(title: "Include completed todos")
    var includeCompleted: Bool?

    @Parameter(title: "Style")
    var style: WallpaperStyleParam?

    @Parameter(title: "Include calendar events")
    var includeCalendarEvents: Bool?

    @MainActor
    func perform() async throws -> some ReturnsValue<IntentFile> {
        let showCompleted = includeCompleted      ?? false
        let resolvedStyle = style                 ?? .dark
        let showCalendar  = includeCalendarEvents ?? true

        // Todos
        let container = try ModelContainer(for: TodoItem.self)
        let allTodos  = try container.mainContext.fetch(
            FetchDescriptor<TodoItem>(sortBy: [SortDescriptor(\.sortOrder)])
        )
        let filtered = showCompleted ? allTodos : allTodos.filter { !$0.isCompleted }

        // Calendar
        var events: [CalendarEvent] = []
        if showCalendar { events = await fetchTodayEvents() }

        guard !filtered.isEmpty || !events.isEmpty else {
            throw GenerateWallpaperError.noContent
        }

        let settings = AppSettings.shared
        let isPhotoMode = settings.lockscreenBackgroundType == .customPhoto
        let photo = isPhotoMode ? settings.loadLockscreenPhoto() : nil

        let fileURL = try WallpaperExporter.saveToSharedContainer(
            todos:           filtered,
            calendarEvents:  events,
            style:           resolvedStyle.toWallpaperStyle(),
            backgroundPhoto: photo,
            cardStyle:       settings.lockscreenCardStyle
        )

        return .result(value: IntentFile(
            fileURL: fileURL,
            filename: "todo-wallpaper.jpg",
            type: .jpeg
        ))
    }

    private func fetchTodayEvents() async -> [CalendarEvent] {
        let store = EKEventStore()
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else { return [] }
        let cal   = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end   = cal.date(byAdding: .day, value: 1, to: start)!
        return store.events(matching: store.predicateForEvents(withStart: start, end: end, calendars: nil))
            .sorted { $0.startDate < $1.startDate }
            .map { e in
                let hex = colorToHex(e.calendar.cgColor) ?? "4A90E2"
                return CalendarEvent(id: e.eventIdentifier ?? UUID().uuidString,
                                     title: e.title ?? "Untitled",
                                     startDate: e.startDate, endDate: e.endDate,
                                     isAllDay: e.isAllDay, calendarColor: hex)
            }
    }

    private func colorToHex(_ cgColor: CGColor?) -> String? {
        guard let c = cgColor?.components, (cgColor?.numberOfComponents ?? 0) >= 3 else { return nil }
        return String(format: "%02X%02X%02X", Int(c[0]*255), Int(c[1]*255), Int(c[2]*255))
    }
}

enum GenerateWallpaperError: LocalizedError {
    case noContent
    var errorDescription: String? { "No todos or events to display." }
}

enum WallpaperStyleParam: String, AppEnum {
    case dark, light, gradient, midnight
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Wallpaper Style"
    static var caseDisplayRepresentations: [WallpaperStyleParam: DisplayRepresentation] = [
        .dark: "Dark", .light: "Light", .gradient: "Gradient", .midnight: "Midnight",
    ]
    func toWallpaperStyle() -> WallpaperStyle {
        switch self {
        case .dark: return .dark; case .light: return .light
        case .gradient: return .gradient; case .midnight: return .midnight
        }
    }
}
