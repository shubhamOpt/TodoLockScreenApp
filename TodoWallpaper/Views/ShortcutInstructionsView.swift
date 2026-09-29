import SwiftUI

struct ShortcutInstructionsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Set up a one-tap Shortcut (or daily automation) to regenerate and apply your todo wallpaper without opening the app.")
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                }

                Section("One-Time Shortcut Setup") {
                    ForEach(oneTimeSteps, id: \.number) { step in
                        StepRow(step: step)
                    }
                }

                Section("Optional: Auto-Update Every Morning") {
                    ForEach(automationSteps, id: \.number) { step in
                        StepRow(step: step)
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Tip", systemImage: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                            .fontWeight(.semibold)
                        Text("You can also trigger the shortcut from the Shortcuts widget on your Home Screen for quick one-tap updates.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Shortcuts Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Steps

    private var oneTimeSteps: [SetupStep] {[
        SetupStep(number: 1, icon: "plus.app",     text: "Open the **Shortcuts** app and tap **+**"),
        SetupStep(number: 2, icon: "sparkles",     text: "Search for **Generate Todo Wallpaper** and add it (from this app)"),
        SetupStep(number: 3, icon: "photo",        text: "Add the **Set Wallpaper Photo** action"),
        SetupStep(number: 4, icon: "lock.iphone",  text: "In Set Wallpaper, choose **Lock Screen** and disable \"Show Preview\""),
        SetupStep(number: 5, icon: "square.and.arrow.down", text: "Save as **\"Update Todo Wallpaper\"**"),
    ]}

    private var automationSteps: [SetupStep] {[
        SetupStep(number: 1, icon: "clock",        text: "In Shortcuts, go to the **Automation** tab and tap **+**"),
        SetupStep(number: 2, icon: "person",       text: "Choose **Personal Automation**"),
        SetupStep(number: 3, icon: "sunrise",      text: "Pick **Time of Day** → set to your preferred morning time"),
        SetupStep(number: 4, icon: "arrow.triangle.2.circlepath", text: "Add your **\"Update Todo Wallpaper\"** shortcut as the action"),
        SetupStep(number: 5, icon: "checkmark.circle", text: "Save — your wallpaper will now refresh automatically every morning"),
    ]}
}

// MARK: - Supporting Types

struct SetupStep {
    let number: Int
    let icon: String
    let text: String
}

struct StepRow: View {
    let step: SetupStep

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 28, height: 28)
                Text("\(step.number)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.top, 1)

            Text(.init(step.text)) // supports **bold** markdown
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
    }
}
