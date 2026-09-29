import SwiftUI
import Photos
import PhotosUI

struct WallpaperPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    let todos: [TodoItem]
    let calendarEvents: [CalendarEvent]

    // ── Style mode ──
    @State private var selectedStyle: WallpaperStyle = .dark
    @State private var showCompleted = false
    @State private var showCalendarOnWallpaper = true

    // ── Photo mode ──
    @State private var backgroundType: WallpaperBackgroundType = .style
    @State private var selectedCardStyle: CardStyle = .darkBlur
    @State private var lockscreenPhoto: UIImage? = nil
    @State private var pickerItem: PhotosPickerItem?
    @State private var isLoadingPhoto = false

    // ── Export ──
    @State private var isGenerating = false
    @State private var savedSuccessfully = false
    @State private var exportError: String?
    @State private var showingShortcutHelp = false

    private let previewScale: CGFloat = 0.48

    var filteredTodos: [TodoItem] {
        showCompleted ? todos : todos.filter { !$0.isCompleted }
    }
    var wallpaperEvents: [CalendarEvent] {
        showCalendarOnWallpaper ? calendarEvents : []
    }
    var isPhotoMode: Bool { backgroundType == .customPhoto }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    phonePreview
                    controls
                        .padding(.horizontal)
                    Divider().padding(.horizontal)
                    actionButtons
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                }
                .padding(.top, 24)
            }
            .navigationTitle("Wallpaper Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .alert("Saved to Photos!", isPresented: $savedSuccessfully) {
            Button("OK") {}
        } message: {
            Text("Set it as your Lock Screen in Photos, or use the Shortcuts integration.")
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(exportError ?? "Unknown error")
        }
        .sheet(isPresented: $showingShortcutHelp) {
            ShortcutInstructionsView()
        }
        .onAppear { loadSavedState() }
    }

    // MARK: - Phone Frame

    private var phonePreview: some View {
        let pw = WallpaperView.canvasWidth  * previewScale
        let ph = WallpaperView.canvasHeight * previewScale

        return ZStack {
            RoundedRectangle(cornerRadius: 36 * previewScale)
                .fill(Color(hex: "1C1C1E"))
                .frame(width: pw + 14, height: ph + 20)
                .shadow(color: .black.opacity(0.4), radius: 20, y: 8)

            WallpaperView(
                todos:           filteredTodos,
                calendarEvents:  wallpaperEvents,
                style:           selectedStyle,
                backgroundPhoto: isPhotoMode ? lockscreenPhoto : nil,
                cardStyle:       selectedCardStyle
            )
            .scaleEffect(previewScale)
            .frame(width: pw, height: ph)
            .clipShape(RoundedRectangle(cornerRadius: 30 * previewScale))

            // Loading overlay while photo loads
            if isLoadingPhoto {
                RoundedRectangle(cornerRadius: 30 * previewScale)
                    .fill(Color.black.opacity(0.4))
                    .frame(width: pw, height: ph)
                ProgressView().tint(.white)
            }

            // Dynamic Island
            RoundedRectangle(cornerRadius: 12 * previewScale)
                .fill(Color(hex: "1C1C1E"))
                .frame(width: 80 * previewScale, height: 24 * previewScale)
                .offset(y: -(ph / 2) + 20 * previewScale)
        }
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 20) {

            // ── Background type segmented ──
            VStack(alignment: .leading, spacing: 8) {
                Text("Background")
                    .font(.footnote).foregroundStyle(.secondary)
                    .textCase(.uppercase).tracking(0.5)

                Picker("Background", selection: $backgroundType) {
                    ForEach(WallpaperBackgroundType.allCases) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: backgroundType) { _, newVal in
                    AppSettings.shared.lockscreenBackgroundType = newVal
                }
            }

            // ── Style picker (style mode) ──
            if !isPhotoMode {
                stylePicker
            }

            // ── Photo picker + card style (photo mode) ──
            if isPhotoMode {
                photoSection
                cardStylePicker
            }

            // ── Shared toggles ──
            Toggle(isOn: $showCompleted) {
                Text("Show completed todos")
            }
            .tint(.green)

            Toggle(isOn: $showCalendarOnWallpaper) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Show calendar events")
                    Text(calendarEvents.isEmpty ? "No events today" : "\(calendarEvents.count) event\(calendarEvents.count == 1 ? "" : "s") today")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .tint(.blue)
            .disabled(calendarEvents.isEmpty)
        }
    }

    // MARK: - Style Picker

    private var stylePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Style")
                .font(.footnote).foregroundStyle(.secondary)
                .textCase(.uppercase).tracking(0.5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(WallpaperStyle.allCases) { style in
                        styleChip(style)
                    }
                }
            }
        }
    }

    private func styleChip(_ style: WallpaperStyle) -> some View {
        let isSelected = selectedStyle == style
        return Button {
            withAnimation(.spring(response: 0.3)) { selectedStyle = style }
        } label: {
            Text(style.label)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.12), in: Capsule())
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Photo")
                .font(.footnote).foregroundStyle(.secondary)
                .textCase(.uppercase).tracking(0.5)

            PhotosPicker(
                selection: $pickerItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                ZStack {
                    if let photo = lockscreenPhoto {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.accentColor, lineWidth: 2)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.secondary.opacity(0.1))
                            .frame(height: 120)
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.title2)
                                        .foregroundStyle(.secondary)
                                    Text("Tap to choose a photo")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            )
                    }
                }
            }
            .onChange(of: pickerItem) { _, item in
                Task { await loadPickedPhoto(item) }
            }
        }
    }

    // MARK: - Card Style Picker

    private var cardStylePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Card style")
                .font(.footnote).foregroundStyle(.secondary)
                .textCase(.uppercase).tracking(0.5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(CardStyle.allCases) { cs in
                        let isSelected = selectedCardStyle == cs
                        Button {
                            withAnimation(.spring(response: 0.3)) { selectedCardStyle = cs }
                            AppSettings.shared.lockscreenCardStyle = cs
                        } label: {
                            HStack(spacing: 6) {
                                // Color swatch
                                Circle()
                                    .fill(cs.fillColor)
                                    .frame(width: 12, height: 12)
                                    .overlay(Circle().strokeBorder(Color.secondary.opacity(0.3), lineWidth: 0.5))
                                Text(cs.rawValue)
                                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                            }
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.12), in: Capsule())
                            .foregroundStyle(isSelected ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button { saveToPhotos() } label: {
                HStack {
                    if isGenerating { ProgressView().tint(.white) }
                    else { Image(systemName: "photo.badge.arrow.down.fill") }
                    Text(isGenerating ? "Saving…" : "Save to Photos")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isGenerating || (isPhotoMode && lockscreenPhoto == nil) || (filteredTodos.isEmpty && wallpaperEvents.isEmpty))

            Button { showingShortcutHelp = true } label: {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Auto-update via Shortcuts")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.bordered)

        }
    }

    // MARK: - Helpers

    private func loadSavedState() {
        backgroundType    = AppSettings.shared.lockscreenBackgroundType
        selectedCardStyle = AppSettings.shared.lockscreenCardStyle
        lockscreenPhoto   = AppSettings.shared.loadLockscreenPhoto()
    }

    private func loadPickedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        isLoadingPhoto = true

        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            let scaled = scaleImage(image, to: CGSize(
                width:  WallpaperView.canvasWidth  * 3,
                height: WallpaperView.canvasHeight * 3
            ))
            try? AppSettings.shared.saveLockscreenPhoto(scaled)
            await MainActor.run { lockscreenPhoto = scaled }
        }
        await MainActor.run { isLoadingPhoto = false }
    }

    private func scaleImage(_ image: UIImage, to size: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    private func saveToPhotos() {
        isGenerating = true
        Task {
            do {
                try await WallpaperExporter.saveToPhotos(
                    todos:          filteredTodos,
                    calendarEvents: wallpaperEvents,
                    style:          selectedStyle,
                    backgroundPhoto: isPhotoMode ? lockscreenPhoto : nil,
                    cardStyle:      selectedCardStyle
                )
                await MainActor.run { isGenerating = false; savedSuccessfully = true }
            } catch {
                await MainActor.run { isGenerating = false; exportError = error.localizedDescription }
            }
        }
    }
}
