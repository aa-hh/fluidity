import AppKit
import FluidityCore
import SwiftUI

/// The Speech model pane: models on this Mac as a radio group, the rest with a Download
/// symbol button, each row's More menu holding Compare and Delete.
struct SpeechModelPane: View {
    let model: SettingsModel
    @FocusState private var focus: PaneFocus?
    /// The failure note shows only for a failure that happened while the pane was open.
    @State private var shownFailure: String?
    /// The model a confirmed delete is waiting on, and what to announce once it is gone; a failed delete never
    /// leaves the Mac, so its failure note speaks instead.
    @State private var pendingDelete: (id: SpeechModelID, announcement: String)?

    var body: some View {
        let onMac = SpeechModel.all.filter { isListedOnMac($0.id) }
        let available = SpeechModel.all.filter { !isListedOnMac($0.id) }
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "On this Mac", description: "Models you can use now. Switching takes under a second.")
                ModelTable {
                    ForEach(Array(onMac.enumerated()), id: \.element.id) { index, entry in
                        if index > 0 { GlassRule() }
                        row(entry, onMac: true)
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("On this Mac")
                // A failed delete leaves its model here, so its note shows under this table.
                if let failure = model.downloadFailure, failureKey == shownFailure, isOnMac(failure.0) {
                    failureNote(failure.0, failure.1)
                }
                if let failure = model.switchFailure {
                    switchFailureNote(failure)
                }
                if let ready = model.readyModel, isOnMac(ready) {
                    readyLine(ready)
                }
            }
            if !available.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(title: "Available to download", description: "Download a model before you choose it.")
                    ModelTable {
                        ForEach(Array(available.enumerated()), id: \.element.id) { index, entry in
                            if index > 0 { GlassRule() }
                            row(entry, onMac: false)
                        }
                    }
                    if let failure = model.downloadFailure, failureKey == shownFailure, !isOnMac(failure.0) {
                        failureNote(failure.0, failure.1)
                    }
                }
            }
            Button("Compare Models…") { model.onCompare(model.speechModel, compareDefaultRight) }
                .buttonStyle(.glassSecondary)
            Text("Measured on an Apple M1. * Compared with the final text of \(name(.parakeetTDTv2)). Your speech never leaves this Mac, whichever model you pick.")
                .font(GlassTheme.small)
                .foregroundStyle(GlassTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 4)
        }
        .onChange(of: model.modelStates) {
            guard let pending = pendingDelete, state(pending.id) == .notInstalled else { return }
            pendingDelete = nil
            AccessibilityNotification.Announcement(pending.announcement).post()
        }
        .onChange(of: failureKey) { _, key in
            shownFailure = key
            pendingDelete = nil
            if let failure = model.downloadFailure {
                AccessibilityNotification.Announcement(failureText(failure.0, failure.1)).post()
            }
        }
        .onChange(of: model.switchFailure) { _, failure in
            if let failure { AccessibilityNotification.Announcement(switchFailureText(failure)).post() }
        }
        .onChange(of: model.readyModel) { _, ready in
            if let ready { AccessibilityNotification.Announcement("\(name(ready)) is ready").post() }
        }
    }

    // MARK: Rows

    private func row(_ entry: SpeechModel, onMac: Bool) -> some View {
        ModelRow(
            entry: entry,
            state: state(entry.id),
            isSelected: onMac && entry.id == model.speechModel,
            showsRadio: onMac,
            downloadingAtLaunch: onMac && !isOnMac(entry.id) && model.isPreparingModel,
            focus: $focus,
            menu: { menuItems(entry) },
            select: { select(entry.id) },
            step: { step(by: $0) },
            download: {
                model.onDownloadModel(entry.id)
                focus = .action(entry.id)
            },
            cancel: {
                model.onCancelDownload(entry.id)
                focus = .action(entry.id)
            },
            deleteKey: { if canDelete(entry), deleteRefusal(entry) == nil { confirmDelete(entry) } })
    }

    @ViewBuilder
    private func menuItems(_ entry: SpeechModel) -> some View {
        let inUse = model.speechModel
        Button("Compare with \(name(inUse))…") { model.onCompare(inUse, entry.id) }
            .disabled(entry.id == inUse)
        if canDelete(entry) {
            Button("Delete Model…") { confirmDelete(entry) }
                .disabled(deleteRefusal(entry) != nil)
        }
        if let reason = deleteRefusal(entry) {
            Divider()
            Text(reason)
        }
    }

    /// Delete appears for every model on this Mac; a download in progress is cancelled instead.
    private func canDelete(_ entry: SpeechModel) -> Bool { isOnMac(entry.id) }

    /// Why Delete is dimmed, in the menu's last line; nil when it can run.
    private func deleteRefusal(_ entry: SpeechModel) -> String? {
        if entry.id == model.speechModel {
            return "\(entry.name) is in use, so it can't be compared with itself or deleted. Choose another model first."
        }
        if model.modelsInUse.contains(entry.id) {
            return "\(entry.name) is still in use until the switch to \(name(model.speechModel)) finishes."
        }
        if state(entry.id) == .partOfMacOS { return "Part of macOS, so it can't be deleted." }
        if model.modelsInCompare.contains(entry.id) { return "Close the compare window to delete \(entry.name)." }
        return nil
    }

    private func confirmDelete(_ entry: SpeechModel) {
        guard let window = NSApp.keyWindow else { return }
        let size = sizeText(entry)
        let alert = NSAlert()
        alert.messageText = "Delete \(entry.name)?"
        alert.informativeText = "This frees \(size). You can download it again."
        alert.addButton(withTitle: "Cancel")
        let delete = alert.addButton(withTitle: "Delete")
        delete.hasDestructiveAction = true
        delete.keyEquivalent = ""
        let onDelete = model.onDeleteModel
        alert.beginSheetModal(for: window) { response in
            guard response == .alertSecondButtonReturn else { return }
            MainActor.assumeIsolated {
                pendingDelete = (entry.id, "\(entry.name) deleted. \(size.prefix(1).uppercased())\(size.dropFirst()) freed.")
                onDelete(entry.id)
                focus = .action(entry.id)
            }
        }
    }

    // MARK: Radio group

    private func select(_ id: SpeechModelID) {
        guard id != model.speechModel else { return }
        model.changeSpeechModel(id)
        model.onClearReadyModel()
        focus = .radio(id)
    }

    /// The arrow keys move the choice between the models on this Mac.
    private func step(by offset: Int) -> KeyPress.Result {
        let ids = SpeechModel.all.map(\.id).filter(isListedOnMac)
        guard let index = ids.firstIndex(of: model.speechModel) else { return .ignored }
        let next = index + offset
        guard ids.indices.contains(next) else { return .handled }
        select(ids[next])
        return .handled
    }

    // MARK: Notes under the tables

    private func readyLine(_ id: SpeechModelID) -> some View {
        HStack(spacing: 12) {
            Text("\(name(id)) is ready.").font(GlassTheme.body).foregroundStyle(GlassTheme.textPrimary)
            Button("Use Now") { select(id) }.buttonStyle(.glassSecondary)
        }
        .padding(.horizontal, 4)
    }

    private func failureNote(_ id: SpeechModelID, _ failure: DownloadFailure) -> some View {
        HStack(spacing: 8) {
            StatusIcon(kind: .attention)
            Text(failureText(id, failure))
                .font(GlassTheme.body)
                .foregroundStyle(GlassTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            if case .notEnoughSpace = failure {
                Button("Open Storage Settings…") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.settings.Storage") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.glassSecondary)
            }
            if !isOnMac(id) {
                Button("Try Again") { model.onDownloadModel(id) }.buttonStyle(.glassSecondary)
            }
        }
        .padding(.horizontal, 4)
    }

    private func switchFailureNote(_ failure: ModelCoordinator.SwitchFailure) -> some View {
        HStack(spacing: 8) {
            StatusIcon(kind: .attention)
            Text(switchFailureText(failure))
                .font(GlassTheme.body)
                .foregroundStyle(GlassTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 4)
    }

    private func switchFailureText(_ failure: ModelCoordinator.SwitchFailure) -> String {
        "Couldn't switch to \(name(failure.model)): \(failure.message). \(name(model.speechModel)) is still in use."
    }

    private func failureText(_ id: SpeechModelID, _ failure: DownloadFailure) -> String {
        let entry = SpeechModel.model(id)
        switch failure {
        case .offline:
            return "Couldn't download \(entry.name) because this Mac is offline. \(name(model.speechModel)) is still in use."
        case .notEnoughSpace(_, let available):
            return "Not enough space for \(entry.name): it needs \(sizeText(entry)) and this Mac has \(Self.megabytes(available)) free."
        case .other(let description) where isOnMac(id):
            return "Couldn't delete \(entry.name): \(description)."
        case .other(let description):
            return "Couldn't download \(entry.name): \(description). \(name(model.speechModel)) is still in use."
        }
    }

    // MARK: Helpers

    /// Compare Models… opens with the model in use on the left and Apple Speech on the right.
    private var compareDefaultRight: SpeechModelID {
        model.speechModel == .appleBuiltIn ? .parakeetTDTv2 : .appleBuiltIn
    }

    private var failureKey: String? {
        model.downloadFailure.map { "\($0.0.rawValue) \($0.1)" }
    }

    private func state(_ id: SpeechModelID) -> ModelState { model.modelStates[id] ?? .notInstalled }

    private func isOnMac(_ id: SpeechModelID) -> Bool {
        switch state(id) {
        case .installed, .partOfMacOS: true
        case .notInstalled, .downloading: false
        }
    }

    /// A model in use is listed on this Mac even before its files are: the first launch's load downloads it.
    private func isListedOnMac(_ id: SpeechModelID) -> Bool { isOnMac(id) || model.modelsInUse.contains(id) }

    private func name(_ id: SpeechModelID) -> String { SpeechModel.model(id).name }

    /// "443 MB" or "about 565 MB".
    private func sizeText(_ entry: SpeechModel) -> String {
        guard case .download(let bytes, let approximate, _) = entry.install else { return "" }
        return (approximate ? "about " : "") + Self.megabytes(bytes)
    }

    static func megabytes(_ bytes: Int64, unit: Bool = true) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = .useMB
        formatter.countStyle = .file
        formatter.includesUnit = unit
        return formatter.string(fromByteCount: bytes)
    }
}

/// Where keyboard focus moves after a change: a row's radio, or its Download or Cancel spot.
private enum PaneFocus: Hashable {
    case radio(SpeechModelID)
    case action(SpeechModelID)
}

// MARK: - Table

/// Column widths shared by both tables, so names and figures line up.
private enum ModelColumns {
    static let leading: CGFloat = 16
    static let firstWord: CGFloat = 76
    static let updates: CGFloat = 76
    static let liveVsFinal: CGFloat = 84
    static let symbolButton: CGFloat = 28
    static let gap: CGFloat = 8
    static let trailing: CGFloat = symbolButton * 2 + gap
    static let rowHeight: CGFloat = 48
    static let headerHeight: CGFloat = 28
}

/// A raised panel with the column header row, then the rows.
private struct ModelTable<Rows: View>: View {
    @ViewBuilder var rows: Rows

    var body: some View {
        GlassPanel {
            ModelTableHeader()
            GlassRule()
            rows
        }
    }
}

private struct ModelTableHeader: View {
    @State private var showsInfo = false

    var body: some View {
        HStack(spacing: ModelColumns.gap) {
            Color.clear.frame(width: ModelColumns.leading, height: 1)
            label("Model").frame(maxWidth: .infinity, alignment: .leading)
            label("First word").frame(width: ModelColumns.firstWord, alignment: .leading)
            label("Updates every").frame(width: ModelColumns.updates, alignment: .leading)
            HStack(spacing: 4) {
                label("Live vs final")
                Button { showsInfo.toggle() } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11))
                        .foregroundStyle(GlassTheme.textSecondary)
                        .frame(width: 14, height: 14)
                        .contentShape(Circle())
                        .glassFocusRing(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("What Live vs final means")
                .popover(isPresented: $showsInfo, arrowEdge: .bottom) { LiveVsFinalInfo() }
            }
            .frame(width: ModelColumns.liveVsFinal, alignment: .leading)
            Color.clear.frame(width: ModelColumns.trailing, height: 1)
        }
        .padding(.horizontal, 12)
        .frame(height: ModelColumns.headerHeight)
    }

    private func label(_ text: String) -> some View {
        Text(text).font(GlassTheme.small).foregroundStyle(GlassTheme.textSecondary).lineLimit(1)
    }
}

/// The info popover after "Live vs final": what the column measures, with one example.
private struct LiveVsFinalInfo: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Live text and final text").font(GlassTheme.label)
            paragraph("While you talk, Fluidity shows the words it has heard so far. That is the live text. When you let go, the model settles on the final text, and that is what gets pasted.")
            VStack(alignment: .leading, spacing: 6) {
                example("Live", Text("send the notes to \(Text("Anna").underline()) by friday"))
                    .accessibilityLabel("Live: send the notes to Anna, changed to Hannah, by friday")
                example("Final", Text("Send the notes to \(Text("Hannah").underline()) by Friday."))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(GlassTheme.selected, in: RoundedRectangle(cornerRadius: 8))
            paragraph("The column counts how many live words change in the final text: 1.6% is about 2 words in 100. Lower means what you read while talking is closer to what gets pasted. It does not measure the final text itself.")
            paragraph("Parakeet Unified also rewrites words already on screen less often: in 14% of its updates, against 36% for Parakeet TDT v2.")
            Text("Measured on an Apple M1.").font(GlassTheme.small).foregroundStyle(GlassTheme.textSecondary)
        }
        .foregroundStyle(GlassTheme.textPrimary)
        .frame(width: 266, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func paragraph(_ text: String) -> some View {
        Text(text).font(GlassTheme.detail).fixedSize(horizontal: false, vertical: true)
    }

    private func example(_ label: String, _ words: Text) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label).font(GlassTheme.small).foregroundStyle(GlassTheme.textSecondary).frame(width: 30, alignment: .leading)
            words.font(GlassTheme.detail).fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Row

/// One 48 pt model row: the radio (On this Mac) or an empty slot, name and size, three figures,
/// then the Download or Cancel symbol button and the More button.
private struct ModelRow<MenuItems: View>: View {
    let entry: SpeechModel
    let state: ModelState
    let isSelected: Bool
    let showsRadio: Bool
    /// The launch load is downloading this model, outside the Download button.
    let downloadingAtLaunch: Bool
    let focus: FocusState<PaneFocus?>.Binding
    @ViewBuilder let menu: () -> MenuItems
    let select: () -> Void
    let step: (Int) -> KeyPress.Result
    let download: () -> Void
    let cancel: () -> Void
    let deleteKey: () -> Void
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: ModelColumns.gap) {
            HStack(spacing: ModelColumns.gap) {
                leadingSlot
                nameBlock.frame(maxWidth: .infinity, alignment: .leading)
                figure(entry.figures.map { "\($0.firstWordMs) ms" })
                    .frame(width: ModelColumns.firstWord, alignment: .leading)
                figure(entry.figures.map { "\($0.updateEveryMs) ms" })
                    .frame(width: ModelColumns.updates, alignment: .leading)
                figure(entry.figures.map {
                    String(format: "%.1f%%", $0.liveVsFinalPercent) + (entry.id == .parakeetTDTv2 ? "" : " *")
                })
                .frame(width: ModelColumns.liveVsFinal, alignment: .leading)
            }
            .contentShape(Rectangle())
            .onTapGesture { if showsRadio { select() } }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(spokenSummary)
            .accessibilityValue(progressValue)
            .accessibilityAddTraits(rowTraits)
            .accessibilityAction { if showsRadio { select() } }
            HStack(spacing: ModelColumns.gap) {
                actionButton
                MoreButton(name: entry.name, menu: menu, deleteKey: deleteKey)
            }
            .frame(width: ModelColumns.trailing, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .frame(height: ModelColumns.rowHeight)
        .background { if isHovering { GlassTheme.hover } }
        .onHover { isHovering = $0 }
        .contextMenu { menu() }
    }

    private var rowTraits: AccessibilityTraits {
        guard showsRadio else { return [] }
        return isSelected ? [.isButton, .isSelected] : [.isButton]
    }

    @ViewBuilder
    private var leadingSlot: some View {
        if showsRadio {
            Button(action: select) { RadioMark(isSelected: isSelected) }
                .buttonStyle(.plain)
                .focusable(isSelected)
                .focused(focus, equals: .radio(entry.id))
                .onKeyPress(.downArrow) { step(1) }
                .onKeyPress(.upArrow) { step(-1) }
        } else {
            Color.clear.frame(width: ModelColumns.leading, height: ModelColumns.leading)
        }
    }

    private var nameBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.name).font(GlassTheme.label).foregroundStyle(GlassTheme.textPrimary).lineLimit(1)
            if case .downloading(let done, let total) = state {
                HStack(spacing: 8) {
                    ProgressTrack(fraction: total > 0 ? Double(done) / Double(total) : 0)
                    Text("\(SpeechModelPane.megabytes(done, unit: false)) of \(SpeechModelPane.megabytes(total))")
                        .font(GlassTheme.small).foregroundStyle(GlassTheme.textSecondary).lineLimit(1)
                }
                .frame(height: 14)
            } else if downloadingAtLaunch {
                Text("Downloading…")
                    .font(GlassTheme.small).foregroundStyle(GlassTheme.textSecondary).lineLimit(1)
                    .frame(height: 14)
            } else {
                Text("\(entry.language) · \(sizeLine)")
                    .font(GlassTheme.small).foregroundStyle(GlassTheme.textSecondary).lineLimit(1)
                    .frame(height: 14)
            }
        }
    }

    @ViewBuilder
    private func figure(_ text: String?) -> some View {
        if let text {
            Text(text).font(GlassTheme.body).foregroundStyle(GlassTheme.textPrimary).lineLimit(1)
        } else {
            Text("Not measured").font(GlassTheme.small).foregroundStyle(GlassTheme.textSecondary).lineLimit(1)
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        switch state {
        case .notInstalled where !showsRadio:
            SymbolButton(symbol: "arrow.down.circle", label: "Download \(entry.name), \(sizeLine)",
                         tooltip: "Download (\(sizeLine))", action: download)
                .focused(focus, equals: .action(entry.id))
        case .downloading:
            SymbolButton(symbol: "xmark.circle", label: "Cancel download of \(entry.name)",
                         tooltip: "Cancel Download", action: cancel)
                .focused(focus, equals: .action(entry.id))
        case .notInstalled, .installed, .partOfMacOS:
            // A model listed on this Mac before its files are is in use, and its download already runs.
            Color.clear.frame(width: ModelColumns.symbolButton, height: ModelColumns.symbolButton)
        }
    }

    /// "443 MB", "about 565 MB" or "in macOS".
    private var sizeLine: String {
        switch entry.install {
        case .partOfMacOS: "in macOS"
        case .download(let bytes, let approximate, _): (approximate ? "about " : "") + SpeechModelPane.megabytes(bytes)
        }
    }

    private var spokenSummary: String {
        let figures: String
        if let f = entry.figures {
            figures = "first word \(f.firstWordMs) milliseconds, updates every \(f.updateEveryMs) milliseconds, "
                + "live versus final \(String(format: "%.1f", f.liveVsFinalPercent)) percent"
        } else {
            figures = "first word, updates every and live versus final not measured"
        }
        return "\(entry.name), \(entry.language), \(sizeLine), \(figures)"
    }

    private var progressValue: String {
        if downloadingAtLaunch { return "Downloading" }
        guard case .downloading(let done, let total) = state, total > 0 else { return "" }
        return "Downloading, \(Int(Double(done) / Double(total) * 100)) percent"
    }
}

/// The 16 pt radio circle, filled when selected.
private struct RadioMark: View {
    let isSelected: Bool

    var body: some View {
        ZStack {
            if isSelected {
                Circle().fill(GlassTheme.actionPrimary)
                Circle().fill(GlassTheme.actionOnPrimary).frame(width: 6, height: 6)
            } else {
                Circle().fill(GlassTheme.raised)
                Circle().strokeBorder(GlassTheme.lineStrong, lineWidth: 1)
            }
        }
        .frame(width: ModelColumns.leading, height: ModelColumns.leading)
        .contentShape(Circle())
        .glassFocusRing(Circle())
    }
}

/// The download progress under the model name: a 48 × 4 pt bar.
private struct ProgressTrack: View {
    let fraction: Double

    var body: some View {
        Capsule().fill(GlassTheme.selected)
            .frame(width: 48, height: 4)
            .overlay(alignment: .leading) {
                Capsule().fill(GlassTheme.textSecondary).frame(width: 48 * min(max(fraction, 0), 1), height: 4)
            }
            .accessibilityHidden(true)
    }
}

/// A 28 pt circle button holding one SF Symbol, with a spoken label and a hover tooltip.
private struct SymbolButton: View {
    let symbol: String
    let label: String
    let tooltip: String
    let action: () -> Void

    var body: some View {
        Button(action: action) { SymbolCircle(symbol: symbol) }
            .buttonStyle(.plain)
            .help(tooltip)
            .accessibilityLabel(label)
    }
}

private struct SymbolCircle: View {
    let symbol: String
    @State private var isHovering = false

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 15))
            .foregroundStyle(GlassTheme.textPrimary)
            .frame(width: ModelColumns.symbolButton, height: ModelColumns.symbolButton)
            .background { if isHovering { Circle().fill(GlassTheme.hover) } }
            .contentShape(Circle())
            .glassFocusRing(Circle())
            .onHover { isHovering = $0 }
    }
}

/// The row's More (⋯) button; the Delete key on it runs the row's delete.
private struct MoreButton<MenuItems: View>: View {
    let name: String
    @ViewBuilder let menu: () -> MenuItems
    let deleteKey: () -> Void

    var body: some View {
        Menu { menu() } label: { SymbolCircle(symbol: "ellipsis.circle") }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .fixedSize()
            .frame(width: ModelColumns.symbolButton, height: ModelColumns.symbolButton)
            .accessibilityLabel("More for \(name)")
            .onKeyPress(keys: [.delete, .deleteForward]) { _ in
                deleteKey()
                return .handled
            }
    }
}
