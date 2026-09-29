import SwiftUI
import PhotosUI

struct HomeScreenSettingsView: View {

    // ── Persisted state via AppStorage (app group suite so AppIntents can read it) ──
    private static let suite = UserDefaults(suiteName: "group.com.yourapp.todowallpaper") ?? .standard

    @AppStorage(AppSettings.Keys.homeScreenWallpaperType, store: HomeScreenSettingsView.suite)
    private var typeRaw: String = HomeScreenWallpaperType.matchLockScreen.rawValue

    @AppStorage(AppSettings.Keys.homeScreenSolidColorHex, store: HomeScreenSettingsView.suite)
    private var solidColorHex: String = "000000"

    // ── Local state ──
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var previewImage: UIImage?       // loaded from disk or picker
    @State private var pickerColor: Color = .black  // drives the ColorPicker
    @State private var isSavingPhoto = false

    private var selectedType: Binding<HomeScreenWallpaperType> {
        Binding(
            get: { HomeScreenWallpaperType(rawValue: typeRaw) ?? .matchLockScreen },
            set: { typeRaw = $0.rawValue }
        )
    }

    var body: some View {
        Form {
            // ── Type picker ──
            Section {
                Picker("Home Screen Wallpaper", selection: selectedType) {
                    ForEach(HomeScreenWallpaperType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } header: {
                Text("Home Screen Style")
            } footer: {
                Text("Applied to your Home Screen when you run the Shortcut.")
            }

            // ── Solid color picker ──
            if selectedType.wrappedValue == .solidColor {
                Section("Color") {
                    ColorPicker("Background color", selection: $pickerColor, supportsOpacity: false)
                        .onChange(of: pickerColor) { _, newColor in
                            solidColorHex = newColor.toHex() ?? "000000"
                            AppSettings.shared.homeScreenSolidColorHex = solidColorHex
                        }

                    // Preview swatch
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: solidColorHex))
                        .frame(height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                }
            }

            // ── Custom photo picker ──
            if selectedType.wrappedValue == .customPhoto {
                Section("Photo") {
                    PhotosPicker(
                        selection: $selectedPhotoItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label(
                            previewImage == nil ? "Choose from Photos" : "Change Photo",
                            systemImage: "photo.on.rectangle"
                        )
                    }
                    .onChange(of: selectedPhotoItem) { _, item in
                        Task { await loadPickedPhoto(item) }
                    }

                    // Preview thumbnail
                    if let image = previewImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.secondary.opacity(0.1))
                            .frame(height: 160)
                            .overlay(
                                Text("No photo selected")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            )
                    }

                    if isSavingPhoto {
                        HStack {
                            ProgressView()
                            Text("Saving photo…")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Home Screen")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadSavedState() }
    }

    // MARK: - Helpers

    private func loadSavedState() {
        // Restore color picker from saved hex
        pickerColor = Color(hex: solidColorHex)

        // Restore photo preview from disk
        previewImage = AppSettings.shared.loadCustomHomeScreenPhoto()
    }

    private func loadPickedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        isSavingPhoto = true

        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {

            // Scale down to wallpaper canvas size to save space
            let scaled = scaleImage(image, to: CGSize(
                width:  HomeScreenWallpaperView.canvasWidth  * 3,
                height: HomeScreenWallpaperView.canvasHeight * 3
            ))

            try? AppSettings.shared.saveCustomHomeScreenPhoto(scaled)
            await MainActor.run { previewImage = scaled }
        }

        await MainActor.run { isSavingPhoto = false }
    }

    private func scaleImage(_ image: UIImage, to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - Color → Hex

extension Color {
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components,
              components.count >= 3 else { return nil }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "%02X%02X%02X", r, g, b)
    }
}
