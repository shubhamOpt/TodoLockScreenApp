import Foundation

struct CalendarEvent: Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let calendarColor: String // hex

    var timeLabel: String {
        if isAllDay { return "All Day" }
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: startDate)
    }
}
