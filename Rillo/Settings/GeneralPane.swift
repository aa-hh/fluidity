import RilloCore
import SwiftUI

struct GeneralPane: View {
    /// The History group, which the History page scrolls to.
    static let historyGroupID = "history"

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
                    GlassRow(title: "Launch at login", detail: "Opens Rillo in the menu bar when you log in.") {
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
            HistoryGroup(model: model)
                .id(Self.historyGroupID)
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
                        get: { model.isCleanupSwitchOn },
                        set: { model.changeCleanupEnabled($0) }))
                        .toggleStyle(GlassToggleStyle())
                        .labelsHidden()
                        .disabled(model.isCleanupSwitchLocked)
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

/// What Rillo keeps for the History page: how long, whether recordings are saved, and the space it takes.
private struct HistoryGroup: View {
    let model: SettingsModel
    @State private var confirmsDeleteRecordings = false
    @State private var confirmsDeleteAll = false

    var body: some View {
        let usage = model.historyUsage
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "History", description: "What Rillo keeps on this Mac for the History page.")
            GlassPanel {
                GlassRow(title: "Keep history", detail: keepHistoryDetail(usage)) {
                    RetentionMenu(label: "Keep history", choices: Retention.historyChoices, selection: model.keepHistory,
                                  limit: nil) { model.changeRetention(.history, to: $0) }
                }
                GlassRule()
                GlassRow(title: "Save recordings", detail: "Keeps the sound of each dictation so you can play it back.") {
                    Toggle("Save recordings", isOn: Binding(get: { model.saveRecordings }, set: { model.changeSaveRecordings($0) }))
                        .toggleStyle(GlassToggleStyle())
                        .labelsHidden()
                }
                GlassRule()
                GlassRow(title: "Keep recordings", detail: keepRecordingsDetail(usage)) {
                    RetentionMenu(label: "Keep recordings", choices: Retention.recordingChoices, selection: model.keepRecordings,
                                  limit: model.keepHistory) { model.changeRetention(.recordings, to: $0) }
                        .disabled(!model.saveRecordings)
                }
                GlassRule()
                GlassRow(title: "Space used", detail: spaceUsed(usage)) {
                    HStack(spacing: 8) {
                        Button("Delete Recordings…") { confirmsDeleteRecordings = true }
                            .buttonStyle(.glassSecondary)
                            .disabled(usage.recordingCount == 0)
                        Button("Delete All History…") { confirmsDeleteAll = true }
                            .buttonStyle(.glassSecondary)
                            .disabled(usage.dictationCount == 0)
                    }
                }
            }
        }
        // Only the buttons answer: the binding may be cleared before a button's action runs.
        .alert(retentionTitle, isPresented: Binding(get: { model.retentionQuestion != nil }, set: { _ in })) {
            Button("Delete \(model.retentionQuestion?.count.formatted() ?? "")", role: .destructive) {
                model.answerRetentionQuestion(keepOlder: false)
            }
            Button("Keep", role: .cancel) { model.answerRetentionQuestion(keepOlder: true) }
                .keyboardShortcut(.defaultAction)
        } message: {
            Text("Keep them, or delete them now? The new setting applies to \(model.retentionQuestion?.kind == .recordings ? "recordings" : "dictations") from now on.")
        }
        .alert("Delete all \(usage.recordingCount.formatted()) \(usage.recordingCount == 1 ? "recording" : "recordings")?",
               isPresented: $confirmsDeleteRecordings) {
            Button("Delete", role: .destructive) { model.onDeleteRecordings() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This frees \(Self.bytes(usage.recordingBytes)). The dictations' text stays.")
        }
        .alert("Delete all \(usage.dictationCount.formatted()) \(usage.dictationCount == 1 ? "dictation" : "dictations")?",
               isPresented: $confirmsDeleteAll) {
            Button("Delete All", role: .destructive) { model.onDeleteAllHistory() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(deleteAllMessage(usage))
        }
    }

    /// "900 dictations are older than 3 months".
    private var retentionTitle: String {
        guard let question = model.retentionQuestion else { return "" }
        let noun = question.kind == .history ? "dictation" : "recording"
        let count = question.count
        return "\(count.formatted()) \(noun)\(count == 1 ? " is" : "s are") older than \(question.period.title.lowercased())"
    }

    private func keepHistoryDetail(_ usage: HistoryUsage) -> String {
        let base = "Raw transcript and pasted text of each dictation."
        guard let perYear = Self.perYear(usage.textBytes, count: usage.dictationCount, usage) else { return base }
        return "\(base) About \(Self.bytes(perYear)) a year at your pace."
    }

    private func keepRecordingsDetail(_ usage: HistoryUsage) -> String {
        guard model.saveRecordings else {
            let note = "Turn on Save recordings to choose."
            guard usage.recordingCount > 0, model.keepRecordings != .forever else { return note }
            return "\(note) Saved ones are still deleted at \(model.keepRecordings.title.lowercased())."
        }
        guard usage.recordingCount > 0 else { return "How long each recording stays on this Mac." }
        let each = "About \(Self.bytes(usage.recordingBytes / usage.recordingCount)) each."
        guard let perYear = Self.perYear(usage.recordingBytes, count: usage.recordingCount, usage) else { return each }
        return "\(each) Forever uses about \(Self.bytes(perYear)) a year at your pace."
    }

    private func spaceUsed(_ usage: HistoryUsage) -> String {
        let text = "Text \(Self.bytes(usage.textBytes))"
        return usage.recordingCount > 0 ? "\(text), recordings \(Self.bytes(usage.recordingBytes))." : "\(text)."
    }

    private func deleteAllMessage(_ usage: HistoryUsage) -> String {
        let what = usage.recordingBytes > 0
            ? "Their text and \(Self.bytes(usage.recordingBytes)) of recordings are deleted from this Mac."
            : "Their text is deleted from this Mac."
        let shared = model.isContributor ? " Dictations you've already shared for training aren't affected." : ""
        return "\(what) This can't be undone.\(shared)"
    }

    /// Bytes a year of `bytes` spread over `count` items, at the user's dictations a year.
    private static func perYear(_ bytes: Int, count: Int, _ usage: HistoryUsage) -> Int? {
        guard count > 0, let pace = usage.dictationsPerYear else { return nil }
        return Int(Double(bytes) / Double(count) * pace)
    }

    private static func bytes(_ count: Int) -> String {
        count.formatted(.byteCount(style: .file))
    }
}

/// A pop-up of retention periods. Periods longer than `limit` are greyed under a "Longer than Keep history" heading.
private struct RetentionMenu: View {
    let label: String
    let choices: [Retention]
    let selection: Retention
    let limit: Retention?
    let choose: (Retention) -> Void

    var body: some View {
        let tooLong = choices.filter { limit.map($0.isLonger) ?? false }
        Menu {
            if !tooLong.isEmpty {
                Section("Longer than Keep history") {
                    ForEach(tooLong, id: \.self) { Button($0.title) {}.disabled(true) }
                }
            }
            ForEach(choices.filter { !tooLong.contains($0) }, id: \.self) { choice in
                Toggle(choice.title, isOn: Binding(get: { selection == choice }, set: { if $0 { choose(choice) } }))
            }
        } label: {
            HStack(spacing: 8) {
                Text(selection.title)
                Image(systemName: "chevron.up.chevron.down").font(.system(size: 10, weight: .semibold))
            }
        }
        .menuIndicator(.hidden)
        .menuStyle(.button)
        .buttonStyle(.glassSecondary)
        .fixedSize()
        .accessibilityLabel(label)
        .accessibilityValue(selection.title)
    }
}
