import AppKit
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
    /// The download failure note shows only for a failure that happened while the pane was open.
    @State private var shownFailure: String?
    /// A delete the user confirmed, announced only once its model is gone.
    @State private var pendingDelete: (id: CleanupModelID, announcement: String)?
    @FocusState private var focusedModel: CleanupModelID?

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
                    GlassSegmented(
                        label: "Where cleanup runs",
                        options: [(.cloud, "Cloud"), (.local, "Local")],
                        selection: Binding(get: { model.cleanupPlace }, set: { choose($0) }))
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
                    infoLine("Local models learned their cleanup style from examples, so they have no rules to edit.")
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
        .onChange(of: model.cleanupModelStates) {
            guard let pending = pendingDelete, !isOnMac(pending.id) else { return }
            pendingDelete = nil
            AccessibilityNotification.Announcement(pending.announcement).post()
        }
        .onChange(of: failureKey) { _, key in
            shownFailure = key
            pendingDelete = nil
            if let failure = model.cleanupDownloadFailure {
                AccessibilityNotification.Announcement(failureText(failure.0, failure.1)).post()
            }
        }
    }

    private var switchDetail: String {
        if model.cleanupPlace == .local {
            if !model.isCleanupEnabled { return "Off. Rillo pastes the raw transcript." }
            // razor: says plainly that Local doesn't run yet; drop the second sentence once local cleanup runs.
            if let chosen = model.localCleanupModel {
                let name = CleanupModel.model(chosen).name
                return isOnMac(chosen)
                    ? "\(name) is ready. Local cleanup isn't switched on in this build yet, so Rillo pastes the raw transcript."
                    : "\(name) is no longer on this Mac. Rillo pastes the raw transcript until you choose or download a model, or switch to Cloud."
            }
            if CleanupModel.all.contains(where: { isOnMac($0.id) }) {
                return "Choose a model below to use local cleanup. Until then Rillo pastes the raw transcript."
            }
            return "Download a model below to use local cleanup. Until then Rillo pastes the raw transcript."
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

    // MARK: Local models

    private var localModels: some View {
        let onMac = CleanupModel.all.filter { isOnMac($0.id) }
        let available = CleanupModel.all.filter { !isOnMac($0.id) }
        return VStack(alignment: .leading, spacing: 16) {
            if !onMac.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(title: "On this Mac", description: "Choose the model local cleanup uses.")
                    GlassPanel {
                        ForEach(Array(onMac.enumerated()), id: \.element.id) { index, entry in
                            if index > 0 { GlassRule() }
                            onMacRow(entry, takesFocus: index == 0)
                        }
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("On this Mac")
                    // A failed delete leaves its model here, so its note shows under this table.
                    if let failure = shownCleanupFailure, isOnMac(failure.0) { failureMessage(failure.0, failure.1) }
                }
            }
            if !available.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(title: "Available to download", description: "Download a model before you choose it.")
                    GlassPanel {
                        ForEach(Array(available.enumerated()), id: \.element.id) { index, entry in
                            if index > 0 { GlassRule() }
                            availableRow(entry)
                        }
                    }
                    if let failure = shownCleanupFailure, !isOnMac(failure.0) { failureMessage(failure.0, failure.1) }
                }
            }
            Text("Measured on an Apple M1.")
                .font(GlassTheme.small)
                .foregroundStyle(GlassTheme.textSecondary)
                .padding(.horizontal, 4)
        }
    }

    /// A downloaded model: the radio, its details, "In use" when chosen, and the More menu with Delete.
    private func onMacRow(_ entry: CleanupModel, takesFocus: Bool) -> some View {
        let isChosen = entry.id == model.localCleanupModel
        let noneChosen = !CleanupModel.all.contains { $0.id == model.localCleanupModel && isOnMac($0.id) }
        return GlassRow(title: entry.name, detail: details(entry)) {
            Button { chooseLocalModel(entry.id) } label: { RadioMark(isSelected: isChosen) }
                .buttonStyle(.plain)
                .focusable(isChosen || (noneChosen && takesFocus))
                .focused($focusedModel, equals: entry.id)
                .onKeyPress(.downArrow) { stepLocalModel(by: 1) }
                .onKeyPress(.upArrow) { stepLocalModel(by: -1) }
                .accessibilityLabel(entry.name)
                .accessibilityAddTraits(isChosen ? [.isSelected] : [])
        } trailing: {
            HStack(spacing: 8) {
                if isChosen {
                    Text("In use").font(GlassTheme.small).foregroundStyle(GlassTheme.textSecondary)
                }
                MoreButton(name: entry.name, label: "More options for \(entry.name)") {
                    Button("Delete Model…") { confirmDelete(entry) }
                } deleteKey: {
                    confirmDelete(entry)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { chooseLocalModel(entry.id) }
    }

    /// A model not on this Mac: Download, or while downloading its progress and Cancel.
    private func availableRow(_ entry: CleanupModel) -> some View {
        GlassRow(title: entry.name, detail: details(entry)) {
            if case .downloading(let done, let total) = cleanupState(entry.id) {
                HStack(spacing: 8) {
                    ProgressTrack(fraction: total > 0 ? Double(done) / Double(total) : 0)
                    Text("\(SpeechModelPane.megabytes(done, unit: false)) of \(SpeechModelPane.megabytes(total))")
                        .font(GlassTheme.small).foregroundStyle(GlassTheme.textSecondary).lineLimit(1)
                        .accessibilityLabel("Downloading, \(total > 0 ? Int(Double(done) / Double(total) * 100) : 0) percent")
                    Button("Cancel") {
                        model.onCancelCleanupDownload(entry.id)
                        focusedModel = entry.id
                    }
                    .buttonStyle(.glassSecondary)
                    .focused($focusedModel, equals: entry.id)
                    .accessibilityLabel("Cancel download of \(entry.name)")
                }
            } else {
                Button("Download") {
                    model.onDownloadCleanupModel(entry.id)
                    focusedModel = entry.id
                }
                .buttonStyle(.glassSecondary)
                .focused($focusedModel, equals: entry.id)
                .accessibilityLabel("Download \(entry.name)")
            }
        }
    }

    /// "English · 1.29 GB", then the figures measured on an Apple M1.
    private func details(_ entry: CleanupModel) -> String {
        var figures = [
            entry.secondsPerDictation.map { "About \(String(format: "%.1f", $0)) s per dictation" } ?? "Speed not measured",
            entry.memoryGB.map { "\(String(format: "%.1f", $0)) GB of memory" } ?? "Memory not measured",
        ]
        if !entry.usesWordList { figures.append("Doesn't use your word list") }
        return "English · \(sizeText(entry))\n" + figures.joined(separator: " · ")
    }

    private func sizeText(_ entry: CleanupModel) -> String {
        ByteCountFormatter.string(fromByteCount: entry.totalBytes, countStyle: .file)
    }

    private func chooseLocalModel(_ id: CleanupModelID) {
        guard id != model.localCleanupModel else { return }
        model.changeLocalCleanupModel(id)
        focusedModel = id
    }

    /// The arrow keys move the choice between the models on this Mac.
    private func stepLocalModel(by offset: Int) -> KeyPress.Result {
        let ids = CleanupModel.all.map(\.id).filter(isOnMac)
        guard let chosen = model.localCleanupModel, let index = ids.firstIndex(of: chosen) else {
            if let first = ids.first { chooseLocalModel(first) }
            return .handled
        }
        let next = index + offset
        if ids.indices.contains(next) { chooseLocalModel(ids[next]) }
        return .handled
    }

    private func confirmDelete(_ entry: CleanupModel) {
        guard let window = NSApp.keyWindow else { return }
        let size = sizeText(entry)
        let alert = NSAlert()
        alert.messageText = "Delete \(entry.name)?"
        alert.informativeText = "This frees \(size). You can download it again."
        alert.addButton(withTitle: "Cancel")
        let delete = alert.addButton(withTitle: "Delete")
        delete.hasDestructiveAction = true
        delete.keyEquivalent = ""
        let onDelete = model.onDeleteCleanupModel
        alert.beginSheetModal(for: window) { response in
            guard response == .alertSecondButtonReturn else { return }
            MainActor.assumeIsolated {
                pendingDelete = (entry.id, "\(entry.name) deleted")
                onDelete(entry.id)
            }
        }
    }

    private func failureMessage(_ id: CleanupModelID, _ failure: DownloadFailure) -> some View {
        FieldMessage(kind: .error, text: failureText(id, failure)).padding(.horizontal, 4)
    }

    private func failureText(_ id: CleanupModelID, _ failure: DownloadFailure) -> String {
        switch failure {
        case .offline: "You're offline. Connect and try again."
        case .notEnoughSpace(_, let available):
            "Not enough space: \(CleanupModel.model(id).name) needs \(sizeText(CleanupModel.model(id))) and this Mac has \(SpeechModelPane.megabytes(available)) free."
        case .damaged: "The download was damaged. Try again."
        case .other(let message) where isOnMac(id): "Couldn't delete \(CleanupModel.model(id).name): \(message)."
        case .other(let message): "The download failed: \(message)"
        }
    }

    private var failureKey: String? {
        model.cleanupDownloadFailure.map { "\($0.0.rawValue) \($0.1)" }
    }

    private var shownCleanupFailure: (CleanupModelID, DownloadFailure)? {
        failureKey == shownFailure ? model.cleanupDownloadFailure : nil
    }

    private func cleanupState(_ id: CleanupModelID) -> ModelState { model.cleanupModelStates[id] ?? .notInstalled }

    private func isOnMac(_ id: CleanupModelID) -> Bool { cleanupState(id) == .installed }

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
                Button("Save", action: submitKey)
                    .buttonStyle(.glassPrimary)
                    .disabled(trimmedDraft == model.apiKey || model.cleanupKey == .checking)
                    .accessibilityLabel("Save key")
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
            FieldMessage(kind: .done, text: "Connected")
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
