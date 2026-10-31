import FluidityCore
import SwiftUI

struct GeneralPane: View {
    let model: SettingsModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Dictation", description: "One key starts dictation, anywhere on your Mac.")
            GlassPanel {
                GlassRow(title: "Dictation key", error: problem(for: .dictation), detail: Self.tapAndHold) {
                    ShortcutRecorderField(model: model, slot: .dictation, name: "Dictation key")
                }
                GlassRule()
                GlassRow(title: "Paste last transcript", error: problem(for: .pasteAgain),
                         detail: "Pastes your newest dictation into the app that has focus.") {
                    ShortcutRecorderField(model: model, slot: .pasteAgain, name: "Paste last transcript")
                }
                GlassRule()
                GlassRow(title: "Microphone",
                         detail: "Automatic uses your Mac's own microphone instead of Bluetooth headphones, so they keep full sound quality.") {
                    MicrophoneMenu(model: model) {
                        HStack(spacing: 8) {
                            Text(model.chosenMicrophoneName)
                            Image(systemName: "chevron.up.chevron.down").font(.system(size: 10, weight: .semibold))
                        }
                    }
                    .menuStyle(.button)
                    .buttonStyle(.glassSecondary)
                    .fixedSize()
                }
                GlassRule()
                GlassRow(title: "Live words", detail: "Shows what you say as you speak, before cleanup.") {
                    Menu {
                        Picker("Live words", selection: Binding(get: { model.liveWords }, set: { model.changeLiveWords($0) })) {
                            ForEach(LiveWords.allCases, id: \.self) { Text(Self.label(for: $0)).tag($0) }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    } label: {
                        HStack(spacing: 8) {
                            Text(Self.label(for: model.liveWords))
                            Image(systemName: "chevron.up.chevron.down").font(.system(size: 10, weight: .semibold))
                        }
                    }
                    .menuIndicator(.hidden)
                    .menuStyle(.button)
                    .buttonStyle(.glassSecondary)
                    .fixedSize()
                    .accessibilityLabel("Live words")
                    .accessibilityValue(Self.label(for: model.liveWords))
                }
                GlassRule()
                GlassRow(title: "Launch at login", detail: "Opens Fluidity in the menu bar when you log in.") {
                    Toggle("Launch at login", isOn: Binding(get: { model.launchAtLogin }, set: { model.changeLaunchAtLogin($0) }))
                        .toggleStyle(GlassToggleStyle())
                        .labelsHidden()
                }
            }
        }
    }

    /// The two help lines that explain tap versus hold.
    static let tapAndHold = "Tap: keeps listening until you tap again.\nHold: talk, let go to paste. Escape cancels."

    private static func label(for words: LiveWords) -> String {
        switch words {
        case .off: "Off"
        case .inPill: "In the pill"
        case .above: "Bubble above"
        }
    }

    private func problem(for slot: ShortcutSlot) -> String? {
        model.shortcutProblem?.slot == slot ? model.shortcutProblem?.message : nil
    }
}

