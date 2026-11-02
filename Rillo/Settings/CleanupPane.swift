import RilloCore
import SwiftUI

struct CleanupPane: View {
    let model: SettingsModel
    @Environment(\.undoManager) private var undoManager
    @State private var draftKey = ""
    @State private var showsKey = false
    @FocusState private var keyFieldFocused: Bool
    @FocusState private var rulesFocused: Bool
    /// The rules as they were before Restore Default, while the Undo button is offered.
    @State private var rulesBeforeRestore: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The place whose rows fill the space under the Cloud | Local control. It changes only while that space is
    /// empty, so Cloud's rows and Local's take turns in it and are never on screen together.
    @State private var shownPlace: CleanupPlace = .cloud
    @State private var contentShown = true
    /// Lets a newer switch cancel the rest of an older one.
    @State private var switchCount = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GlassPanel {
                GlassRow(title: "Cleanup", detail: switchDetail) {
                    Toggle("Cleanup", isOn: Binding(
                        get: { model.isCleanupSwitchOn },
                        set: { model.changeCleanupEnabled($0) }))
                        .toggleStyle(GlassToggleStyle())
                        .labelsHidden()
                        .disabled(model.isCleanupSwitchLocked)
                }
                GlassRule()
                GlassRow(title: "Where cleanup runs", detail: "Each keeps its own setup, so switching loses nothing.") {
                    Picker("Where cleanup runs", selection: Binding(get: { model.cleanupPlace }, set: { choose($0) })) {
                        Text("Cloud").tag(CleanupPlace.cloud)
                        Text("Local").tag(CleanupPlace.local)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .fixedSize()
                }
                if shownPlace == .cloud {
                    Group {
                        GlassRule()
                        keyRow
                        GlassRule()
                        rulesRow
                    }
                    .modifier(TakingTurns(shown: contentShown))
                }
            }
            Group {
                if shownPlace == .local {
                    localModels
                    infoLine("This model learned its cleanup style from examples, so it has no rules to edit. It still uses your word list.")
                    infoLine("Text stays on this Mac. Your Cerebras key stays saved for when you switch back.")
                } else {
                    infoLine("Text goes to Cerebras's US servers, which keep nothing.")
                }
            }
            .modifier(TakingTurns(shown: contentShown))
        }
        .onAppear {
            draftKey = model.apiKey
            shownPlace = model.cleanupPlace
        }
        .onChange(of: model.cleanupPlace) { _, place in show(place) }
        .onChange(of: model.apiKey) { _, saved in if !keyFieldFocused { draftKey = saved } }
        .onChange(of: model.cleanupRules) { _, rules in
            if rules != model.defaultCleanupRules { rulesBeforeRestore = nil }
        }
    }

    private var switchDetail: String {
        if model.cleanupPlace == .local {
            return model.isCleanupEnabled
                ? "Download a model below to use local cleanup. Until then Rillo pastes the raw transcript."
                : "Off. Rillo pastes the raw transcript."
        }
        return switch model.cleanupKey {
        case .noKey: "Add a Cerebras key below to turn cleanup on."
        case _ where !model.isCleanupEnabled: "Off. Rillo pastes the raw transcript."
        case .checking: "Checking your key…"
        case .refused: "On, but paused until Cerebras accepts a key."
        case .offline: "On, but paused while you're offline."
        case .accepted: "Removes filler words and resolves self-corrections before pasting."
        }
    }

    // MARK: Cloud or Local

    private func choose(_ place: CleanupPlace) {
        model.changeCleanupPlace(place)
        AccessibilityNotification.Announcement(place == .local ? "Cleanup runs on this Mac" : "Cleanup runs on Cerebras").post()
    }

    /// Fades the shown rows out, swaps them while the space is empty (its height changes at once), then fades the
    /// new rows in. Nothing slides, and nothing above the space moves.
    private func show(_ place: CleanupPlace) {
        switchCount += 1
        let count = switchCount
        withAnimation(reduceMotion ? GlassTheme.snap : .easeIn(duration: 0.1), completionCriteria: .removed) {
            contentShown = false
        } completion: {
            guard count == switchCount else { return }
            var swap = Transaction()
            swap.disablesAnimations = true
            withTransaction(swap) { shownPlace = place }
            withAnimation(reduceMotion ? GlassTheme.snap : .easeOut(duration: 0.15)) { contentShown = true }
        }
    }

    // razor: placeholder rows until the cleanup model list and downloads land (AA-457); Download stays unavailable.
    private var localModels: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Available to download", description: "Download a model before you choose it.")
            GlassPanel {
                localModelRow("Qwen3.5 2B, tuned for dictation")
                GlassRule()
                localModelRow("S1-mini by Superwhisper")
            }
        }
    }

    private func localModelRow(_ name: String) -> some View {
        GlassRow(title: name, detail: "English · 1.4 GB") {
            Button("Download") {}
                .buttonStyle(.glassSecondary)
                .disabled(true)
                .help("Local models can't be downloaded in this build yet.")
        }
    }

    private func infoLine(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "info.circle")
            Text(text).fixedSize(horizontal: false, vertical: true)
        }
        .font(GlassTheme.detail)
        .foregroundStyle(GlassTheme.textSecondary)
        .padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
    }

    // MARK: API key

    private var keyRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Cerebras API key").font(GlassTheme.label).foregroundStyle(GlassTheme.textPrimary)
                Text("Paste your key, then press Save or Return. Stored in your Keychain.")
                    .font(GlassTheme.detail).foregroundStyle(GlassTheme.textSecondary)
            }
            .accessibilityElement(children: .combine)
            HStack(spacing: 8) {
                keyField
                if !(model.cleanupKey == .accepted && trimmedDraft == model.apiKey) {
                    Button("Save", action: submitKey)
                        .buttonStyle(.glassPrimary)
                        .disabled(trimmedDraft == model.apiKey || model.cleanupKey == .checking)
                        .accessibilityLabel("Save key")
                }
            }
            keyMessage
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var keyField: some View {
        HStack(spacing: 6) {
            Group {
                if showsKey {
                    TextField("Paste your Cerebras API key", text: $draftKey)
                } else {
                    SecureField("Paste your Cerebras API key", text: $draftKey)
                }
            }
            .textFieldStyle(.plain)
            .font(GlassTheme.body)
            .foregroundStyle(GlassTheme.textPrimary)
            .focused($keyFieldFocused)
            .onSubmit { submitKey() }
            .accessibilityLabel("Cerebras API key")
            if model.cleanupKey == .accepted {
                Image(systemName: "checkmark").foregroundStyle(GlassTheme.stateDone)
                    .accessibilityHidden(true)
            }
            if !draftKey.isEmpty {
                Button { showsKey.toggle() } label: {
                    Image(systemName: showsKey ? "eye.slash" : "eye")
                        .foregroundStyle(GlassTheme.textPrimary)
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                        .glassFocusRing(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(showsKey ? "Hide key" : "Show key")
            }
        }
        .padding(.horizontal, 12)
        .frame(width: 254)
        .glassFieldChrome(isFocused: keyFieldFocused, isError: model.cleanupKey == .refused)
    }

    @ViewBuilder private var keyMessage: some View {
        switch model.cleanupKey {
        case .noKey: EmptyView()
        case .checking: FieldMessage(kind: .info, text: "Checking the key…")
        case .accepted:
            FieldMessage(kind: .done, text: model.isCleanupEnabled ? "Key accepted · cleanup on" : "Key accepted")
        case .refused:
            FieldMessage(kind: .error, text: "Cerebras didn't accept this key. Copy it again from cloud.cerebras.ai.")
        case .offline: FieldMessage(kind: .info, text: "Offline · the key is checked when you're back online.")
        }
    }

    private var trimmedDraft: String { draftKey.trimmingCharacters(in: .whitespacesAndNewlines) }

    private func submitKey() {
        guard trimmedDraft != model.apiKey else { return }
        model.submitAPIKey(trimmedDraft)
    }

    // MARK: Rules

    private var rulesRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cleanup rules").font(GlassTheme.label).foregroundStyle(GlassTheme.textPrimary)
                    Text(rulesBeforeRestore == nil
                         ? "Sent to Cerebras with every dictation."
                         : "Default rules restored. Command-Z also undoes this.")
                        .font(GlassTheme.detail).foregroundStyle(GlassTheme.textSecondary)
                }
                .accessibilityElement(children: .combine)
                .frame(maxWidth: .infinity, alignment: .leading)
                if let previous = rulesBeforeRestore {
                    Button("Undo") { undoRestore(to: previous) }.buttonStyle(.glassQuiet)
                } else {
                    Button("Restore Default") { restoreDefault() }
                        .buttonStyle(.glassQuiet)
                        .disabled(model.cleanupRules == model.defaultCleanupRules)
                }
            }
            TextEditor(text: Binding(get: { model.cleanupRules }, set: { model.changeCleanupRules($0) }))
                .font(GlassTheme.body)
                .foregroundStyle(GlassTheme.textPrimary)
                .scrollContentBackground(.hidden)
                .focused($rulesFocused)
                .padding(8)
                .frame(height: 140)
                .background(GlassTheme.raised, in: RoundedRectangle(cornerRadius: GlassTheme.innerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: GlassTheme.innerRadius, style: .continuous)
                        .strokeBorder(rulesFocused ? GlassTheme.lineStrong : GlassTheme.lineRule, lineWidth: 1)
                }
                .overlay {
                    if rulesFocused {
                        RoundedRectangle(cornerRadius: GlassTheme.innerRadius + 3, style: .continuous)
                            .strokeBorder(GlassTheme.focusRing, lineWidth: 2).padding(-3)
                    }
                }
                .accessibilityLabel("Cleanup rules")
        }
        .padding(12)
    }

    private func restoreDefault() {
        let previous = model.cleanupRules
        model.changeCleanupRules(model.defaultCleanupRules)
        rulesBeforeRestore = previous
        undoManager?.registerUndo(withTarget: model) { model in
            MainActor.assumeIsolated { model.changeCleanupRules(previous) }
        }
        undoManager?.setActionName("Restore Default")
        AccessibilityNotification.Announcement("Default rules restored").post()
    }

    private func undoRestore(to previous: String) {
        model.changeCleanupRules(previous)
        rulesBeforeRestore = nil
        undoManager?.removeAllActions(withTarget: model)
    }
}

/// Hides one place's rows while the other place takes the space: invisible, untouchable and silent to VoiceOver.
private struct TakingTurns: ViewModifier {
    let shown: Bool

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .allowsHitTesting(shown)
            .accessibilityHidden(!shown)
    }
}
