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

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GlassPanel {
                GlassRow(title: "Cleanup", detail: switchDetail) {
                    Toggle("Cleanup", isOn: Binding(
                        get: { model.isCleanupActive },
                        set: { model.changeCleanupEnabled($0) }))
                        .toggleStyle(GlassToggleStyle())
                        .labelsHidden()
                        .disabled(model.cleanupKey == .noKey)
                }
                GlassRule()
                keyRow
                GlassRule()
                rulesRow
            }
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                Text("Text goes to Cerebras's US servers, which keep nothing.")
            }
            .font(GlassTheme.detail)
            .foregroundStyle(GlassTheme.textSecondary)
            .padding(.horizontal, 4)
            .accessibilityElement(children: .combine)
        }
        .onAppear { draftKey = model.apiKey }
        .onChange(of: model.apiKey) { _, saved in if !keyFieldFocused { draftKey = saved } }
        .onChange(of: model.cleanupRules) { _, rules in
            if rules != model.defaultCleanupRules { rulesBeforeRestore = nil }
        }
    }

    private var switchDetail: String {
        switch model.cleanupKey {
        case .noKey: "Add a Cerebras key below to turn cleanup on."
        case _ where !model.isCleanupEnabled: "Off. Fluidity pastes the raw transcript."
        case .checking: "Checking your key…"
        case .refused: "On, but paused until Cerebras accepts a key."
        case .offline: "On, but paused while you're offline."
        case .accepted: "Removes filler words and resolves self-corrections before pasting."
        }
    }

    // MARK: API key

    private var keyRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Cerebras API key").font(GlassTheme.label).foregroundStyle(GlassTheme.textPrimary)
                Text("Cleanup turns on as soon as a key works. Stored in your Keychain.")
                    .font(GlassTheme.detail).foregroundStyle(GlassTheme.textSecondary)
            }
            .accessibilityElement(children: .combine)
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
            .onChange(of: keyFieldFocused) { _, focused in if !focused { submitKey() } }
            keyMessage
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
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

    private func submitKey() {
        let key = draftKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard key != model.apiKey else { return }
        model.submitAPIKey(key)
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
