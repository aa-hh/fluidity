import FluidityCore
import SwiftUI

struct GeneralPane: View {
    let model: SettingsModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Speech to text")
                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 12) {
                        SpeechModelTile(model: model)
                        CleanupTile(model: model)
                            .frame(maxHeight: .infinity, alignment: .top)
                    }
                    .frame(width: 205)
                    SpeechPreviewPanel(model: model)
                }
                // The preview sets the row's height; the Cleanup tile stretches to meet it.
                .fixedSize(horizontal: false, vertical: true)
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

/// A tile that opens the Speech model pane, showing the chosen model's name.
private struct SpeechModelTile: View {
    let model: SettingsModel
    @State private var isHovering = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: GlassTheme.containerRadius, style: .continuous)
        let name = SpeechModel.model(model.speechModel).name
        Button { model.pane = .speechModel } label: {
            GlassPanel {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Speech model").font(GlassTheme.label).foregroundStyle(GlassTheme.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(GlassTheme.textSecondary)
                    }
                    Text(name).font(GlassTheme.detail).foregroundStyle(GlassTheme.textSecondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .overlay { if isHovering { shape.fill(GlassTheme.hover) } }
            .contentShape(shape)
            .glassFocusRing(shape)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .accessibilityLabel("Speech model")
        .accessibilityValue(name)
    }
}

/// A tile with the same cleanup switch as the Cleanup pane, and a button to that pane.
private struct CleanupTile: View {
    let model: SettingsModel

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Cleanup").font(GlassTheme.label).foregroundStyle(GlassTheme.textPrimary)
                    Spacer()
                    Toggle("Cleanup", isOn: Binding(
                        get: { model.isCleanupActive },
                        set: { model.changeCleanupEnabled($0) }))
                        .toggleStyle(GlassToggleStyle())
                        .labelsHidden()
                        .disabled(model.cleanupKey == .noKey)
                }
                Text("Removes filler words and resolves self-corrections.")
                    .font(GlassTheme.detail)
                    .foregroundStyle(GlassTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Button { model.pane = .cleanup } label: {
                    HStack(spacing: 4) {
                        Text("Key and rules")
                        Image(systemName: "chevron.right").font(.system(size: 10, weight: .semibold))
                    }
                }
                .buttonStyle(.glassQuiet)
                // The quiet style's side padding would push the text in from the title.
                .padding(.leading, -10)
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}
