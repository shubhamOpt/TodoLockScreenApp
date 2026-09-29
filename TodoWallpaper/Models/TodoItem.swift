import SwiftData
import Foundation

@Model
class TodoItem {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var completedAt: Date?   // tracked for auto-removal
    var createdAt: Date
    var sortOrder: Int

    init(title: String, sortOrder: Int = 0) {
        self.id          = UUID()
        self.title       = title
        self.isCompleted = false
        self.completedAt = nil
        self.createdAt   = Date()
        self.sortOrder   = sortOrder
    }

    /// Marks the item complete and records the timestamp,
    /// or clears the timestamp when un-completing.
    func toggleCompletion() {
        isCompleted = !isCompleted
        completedAt = isCompleted ? Date() : nil
    }

    /// Returns true if this item should be auto-removed
    /// based on the current AppSettings delay.
    func shouldAutoRemove() -> Bool {
        guard isCompleted,
              let completedAt,
              let interval = AppSettings.shared.autoRemoveDelay.interval
        else { return false }
        return Date().timeIntervalSince(completedAt) >= interval
    }
}
