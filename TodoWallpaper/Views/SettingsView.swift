import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    private static let suite = UserDefaults(suiteName: "group.com.yourapp.todowallpaper") ?? .standard

    @AppStorage(AppSettings.Keys.autoRemoveDelay, store: SettingsView.suite)
    private var autoRemoveRaw: String = AutoRemoveDelay.oneHour.rawValue

    @AppStorage(AppSettings.Keys.showCalendarEvents, store: SettingsView.suite)
    private var showCalendarEvents: Bool = true

    @AppStorage(AppSettings.Keys.homeScreenWallpaperType, store: SettingsView.suite)
    private var homeScreenTypeRaw: String = HomeScreenWallpaperType.matchLockScreen.rawValue

    private var autoRemoveDelay: Binding<AutoRemoveDelay> {
        Binding(
            get: { AutoRemoveDelay(rawValue: autoRemoveRaw) ?? .oneHour },
            set: { autoRemoveRaw = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            Form {

                // ── Todos ──
                Section {
                    Picker("Remove completed todos", selection: autoRemoveDelay) {
                        ForEach(AutoRemoveDelay.allCases) { delay in
                            Text(delay.rawValue).tag(delay)
                        }
                    }
                } header: {
                    Text("Completed Todos")
                } footer: {
                    Text("Completed items are automatically removed after the selected time.")
                }

                // ── Calendar ──
                Section {
                    Toggle("Show today's calendar events", isOn: $showCalendarEvents)
                } header: {
                    Text("Calendar")
                } footer: {
                    Text("Today's events appear in the todo list and on your Lock Screen wallpaper.")
                }

                // ── Home Screen Wallpaper ──
                Section {
                    NavigationLink(destination: HomeScreenSettingsView()) {
                        HStack {
                            Text("Home Screen Wallpaper")
                            Spacer()
                            Text(HomeScreenWallpaperType(rawValue: homeScreenTypeRaw)?.rawValue ?? "")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }
                    }
                } header: {
                    Text("Home Screen")
                }

                // ── About ──
                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Wallpaper size", value: "393 × 852 pt (@3×)")

                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
