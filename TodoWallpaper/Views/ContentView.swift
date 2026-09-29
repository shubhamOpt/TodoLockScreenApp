import Combine
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.sortOrder) private var todos: [TodoItem]
    @StateObject private var calendarManager = CalendarManager()

    @AppStorage(AppSettings.Keys.showCalendarEvents,
                store: UserDefaults(suiteName: "group.com.yourapp.todowallpaper") ?? .standard)
    private var showCalendarEvents: Bool = true

    @State private var showingAddTodo          = false
    @State private var showingWallpaperPreview = false
    @State private var showingSettings         = false

    var body: some View {
        NavigationStack {
            TodoListView(
                todos: todos,
                calendarEvents: showCalendarEvents ? calendarManager.events : [],
                calendarStatus: calendarManager.authorizationStatus,
                onRequestCalendarAccess: { Task { await calendarManager.requestAccess() } },
                onDelete: deleteTodos,
                onToggle: toggleTodo,
                onMove: moveTodos
            )
            .navigationTitle("My Todos")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showingWallpaperPreview = true } label: {
                        Image(systemName: "lock.iphone")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAddTodo = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTodo) {
            AddTodoView { title in addTodo(title: title) }
        }
        .sheet(isPresented: $showingWallpaperPreview) {
            WallpaperPreviewView(
                todos: todos,
                calendarEvents: calendarManager.events
            )
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .task {
            await calendarManager.requestAccess()
            runAutoRemove()
        }
        .onReceive(
            Timer.publish(every: 900, on: .main, in: .common).autoconnect()
        ) { _ in
            Task { await calendarManager.fetchTodayEvents() }
            runAutoRemove()
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
        ) { _ in
            Task { await calendarManager.fetchTodayEvents() }
            runAutoRemove()
        }
    }

    // MARK: - Todo Actions

    private func addTodo(title: String) {
        let item = TodoItem(title: title, sortOrder: todos.count)
        modelContext.insert(item)
    }

    private func deleteTodos(at offsets: IndexSet) {
        for index in offsets { modelContext.delete(todos[index]) }
    }

    private func toggleTodo(_ todo: TodoItem) {
        todo.toggleCompletion()
        if AppSettings.shared.autoRemoveDelay == .immediately && todo.isCompleted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                if let index = todos.firstIndex(where: { $0.id == todo.id }) {
                    modelContext.delete(todos[index])
                }
            }
        }
    }

    private func moveTodos(from source: IndexSet, to destination: Int) {
        var reordered = todos
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, item) in reordered.enumerated() { item.sortOrder = index }
    }

    private func runAutoRemove() {
        guard AppSettings.shared.autoRemoveDelay != .never,
              AppSettings.shared.autoRemoveDelay != .immediately else { return }
        for todo in todos where todo.shouldAutoRemove() { modelContext.delete(todo) }
    }
}
