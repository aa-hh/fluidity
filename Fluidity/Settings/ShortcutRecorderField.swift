import FluidityCore
import SwiftUI

/// The 160 × 28 pt shortcut recorder. Click, Space or Return starts recording; the next
/// key pressed is taken through `ShortcutRecorder`, which refuses keys that can't work.
struct ShortcutRecorderField: View {
    let model: SettingsModel
    let slot: ShortcutSlot
    /// What VoiceOver calls the control, such as "Dictation key".
    let name: String

    private var key: KeyChoice? { slot == .dictation ? model.dictationKey : model.pasteAgainKey }
    private var isRecording: Bool { model.recordingSlot == slot }

    var body: some View {
        HStack(spacing: 4) {
            Button {
                isRecording ? model.endRecording() : model.beginRecording(slot)
            } label: {
                Group {
                    if isRecording {
                        Text("Type a shortcut…").font(GlassTheme.label).foregroundStyle(GlassTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                    } else if let key {
                        KeyCap(text: key.description).frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("Record Shortcut").font(GlassTheme.label).foregroundStyle(GlassTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxHeight: .infinity)
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(name)
            .accessibilityValue(isRecording ? "Recording. Press the key to use." : key?.description ?? "Not set")
            .accessibilityHint(isRecording ? "" : "Records a new shortcut")

            if slot == .pasteAgain, key != nil, !isRecording {
                Button { model.clearPasteAgainKey() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(GlassTheme.textPrimary)
                        .frame(width: 18, height: 18)
                        .background(GlassTheme.hover, in: Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear \(name)")
            }
        }
        .padding(.horizontal, 5)
        .frame(width: 160)
        .glassFieldChrome(isFocused: isRecording, isError: model.shortcutProblem?.slot == slot)
        .onDisappear { if isRecording { model.endRecording() } }
    }
}
