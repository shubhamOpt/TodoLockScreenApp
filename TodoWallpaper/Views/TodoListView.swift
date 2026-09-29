import SwiftUI
import EventKit

struct TodoListView: View {
    let todos: [TodoItem]
    let calendarEvents: [CalendarEvent]
    let calendarStatus: EKAuthorizationStatus
    let onRequestCalendarAccess: () -> Void
    let onDelete: (IndexSet) -> Void
    let onToggle: (TodoItem) -> Void
    let onMove: (IndexSet, Int) -> Void

    var incompleteTodos: [TodoItem] { todos.filter { !$0.isCompleted } }
    var completedTodos:  [TodoItem] { todos.filter {  $0.isCompleted } }

    var body: some View {
        List {
            // ── Calendar Events Section ──
            if !calendarEvents.isEmpty {
                Section {
                    ForEach(calendarEvents) { event in
                        CalendarEventRow(event: event)
                    }
                } header: {
                    Label("Today's Events", systemImage: "calendar")
                }
            }

            // Calendar permission prompt
            if calendarStatus == .denied {
                Section {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Calendar Access Denied")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Enable in Settings to show today's events.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .foregroundStyle(.orange)
                    }
                }
            } else if calendarStatus == .notDetermined {
                Section {
                    Button {
                        onRequestCalendarAccess()
                    } label: {
                        Label("Show Today's Calendar Events", systemImage: "calendar.badge.plus")
                    }
                }
            }

            // ── Active Todos ──
            Section {
                ForEach(incompleteTodos) { todo in
                    TodoRowView(todo: todo, onToggle: onToggle)
                }
                .onDelete { offsets in
                    let globalOffsets = IndexSet(
                        offsets.compactMap { offset in
                            todos.firstIndex(where: { $0.id == incompleteTodos[offset].id })
                        }
                    )
                    onDelete(globalOffsets)
                }
                .onMove(perform: onMove)
            } header: {
                if !todos.isEmpty {
                    Text("Tasks")
                }
            }

            // ── Completed Todos ──
            if !completedTodos.isEmpty {
                Section {
                    ForEach(completedTodos) { todo in
                        TodoRowView(todo: todo, onToggle: onToggle)
                    }
                    .onDelete { offsets in
                        let globalOffsets = IndexSet(
                            offsets.compactMap { offset in
                                todos.firstIndex(where: { $0.id == completedTodos[offset].id })
                            }
                        )
                        onDelete(globalOffsets)
                    }
                } header: {
                    HStack {
                        Text("Completed")
                        if let delay = AppSettings.shared.autoRemoveDelay.interval, delay > 0 {
                            Spacer()
                            Text("Auto-removing \(AppSettings.shared.autoRemoveDelay.rawValue.lowercased())")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
        .overlay {
            if todos.isEmpty && calendarEvents.isEmpty {
                ContentUnavailableView(
                    "No Todos Yet",
                    systemImage: "checklist",
                    description: Text("Tap + to add your first item")
                )
            }
        }
    }
}

// MARK: - Todo Row

struct TodoRowView: View {
    let todo: TodoItem
    let onToggle: (TodoItem) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button { onToggle(todo) } label: {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(todo.isCompleted ? .green : .secondary)
                    .font(.title3)
                    .animation(.spring(response: 0.3), value: todo.isCompleted)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(todo.title)
                    .strikethrough(todo.isCompleted, color: .secondary)
                    .foregroundStyle(todo.isCompleted ? .secondary : .primary)

                // Show when it'll be removed
                if todo.isCompleted,
                   let completedAt = todo.completedAt,
                   let interval = AppSettings.shared.autoRemoveDelay.interval,
                   interval > 0 {
                    let removeAt = completedAt.addingTimeInterval(interval)
                    Text("Removing at \(removeAt, style: .time)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Calendar Event Row

struct CalendarEventRow: View {
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: 12) {
            // Calendar color indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: event.calendarColor))
                .frame(width: 4, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.body)
                Text(event.timeLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "calendar")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}
