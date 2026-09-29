import Combine
import EventKit
import SwiftUI

@MainActor
class CalendarManager: ObservableObject {
    private let store = EKEventStore()

    @Published var events: [CalendarEvent] = []
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined

    // MARK: - Authorization

    func requestAccess() async {
        let status = EKEventStore.authorizationStatus(for: .event)
        if status == .fullAccess {
            authorizationStatus = .fullAccess
            await fetchTodayEvents()
            return
        }

        do {
            let granted = try await store.requestFullAccessToEvents()
            authorizationStatus = granted ? .fullAccess : .denied
            if granted { await fetchTodayEvents() }
        } catch {
            authorizationStatus = .denied
        }
    }

    // MARK: - Fetch

    func fetchTodayEvents() async {
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else { return }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay   = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = store.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: nil
        )

        let ekEvents = store.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }

        events = ekEvents.map { e in
            let hex = colorToHex(e.calendar.cgColor) ?? "4A90E2"
            return CalendarEvent(
                id:            e.eventIdentifier ?? UUID().uuidString,
                title:         e.title ?? "Untitled",
                startDate:     e.startDate,
                endDate:       e.endDate,
                isAllDay:      e.isAllDay,
                calendarColor: hex
            )
        }
    }

    // MARK: - Helpers

    private func colorToHex(_ cgColor: CGColor?) -> String? {
        guard let cgColor,
              let components = cgColor.components,
              cgColor.numberOfComponents >= 3 else { return nil }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "%02X%02X%02X", r, g, b)
    }
}
