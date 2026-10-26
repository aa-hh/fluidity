import AppKit
import FluidityCore
import SwiftUI

/// The menu bar popover, 280 pt wide: status row, the last dictations, Settings and Quit.
/// It draws its own Glass shell, so its host should give it a clear background.
struct PopoverView: View {
    let model: PopoverModel
    let settings: SettingsModel
    @FocusState private var focusedRecord: UUID?
    @State private var copiedRecord: UUID?

    var body: some View {
        VStack(spacing: 0) {
            statusRow
            GlassRule()
            if model.records.isEmpty {
                emptyHistory
            } else {
                history
            }
            GlassRule()
            VStack(spacing: 0) {
                MenuRow(title: "Settings…", shortcut: "⌘,") { model.onOpenSettings(nil) }
                    .keyboardShortcut(",", modifiers: .command)
                MenuRow(title: "Quit Fluidity", shortcut: "⌘Q", action: model.onQuit)
                    .keyboardShortcut("q", modifiers: .command)
            }
            .padding(6)
        }
        .frame(width: 280)
        .glassShell(isLive: settings.isMicLive)
        .focusEffectDisabled()
        .task(id: copiedRecord) {
            guard copiedRecord != nil else { return }
            try? await Task.sleep(for: GlassTheme.hold)
            copiedRecord = nil
        }
    }

    // MARK: Status

    private var statusRow: some View {
        let status = settings.status
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                StatusDot(tone: status.tone)
                Text(status.title).font(GlassTheme.label).foregroundStyle(GlassTheme.textPrimary)
                Spacer(minLength: 8)
                if let hint {
                    Text(hint).font(GlassTheme.small).foregroundStyle(GlassTheme.textSecondary).lineLimit(1)
                }
            }
            .frame(minHeight: 22)
            if let detail = status.detail {
                Text(detail).font(GlassTheme.detail).foregroundStyle(GlassTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 16)
                    .padding(.top, -6)
            }
            if status.offersFixButton, let title = status.fixButtonTitle, let fix = status.fix {
                Button(title) {
                    switch fix {
                    case .permission(let permission): settings.onOpenPrivacySettings(permission)
                    case .cleanup: model.onOpenSettings(.cleanup)
                    }
                }
                .buttonStyle(.glassSecondary)
                .padding(.leading, 16)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(minHeight: 38)
        .accessibilityElement(children: .contain)
    }

    private var hint: String? {
        let key = settings.dictationKey.description
        if settings.menuBarState == .recording {
            return settings.recordingMode == .handsFree ? "Tap \(key) to stop" : "Let go to paste"
        }
        return settings.status.showsKey ? "Tap or hold \(key)" : nil
    }

    // MARK: History

    private var emptyHistory: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Nothing dictated yet.").font(GlassTheme.label).foregroundStyle(GlassTheme.textPrimary)
            Text("Hold \(settings.dictationKey.description) and speak. Your last \(DictationStore.historyLimit) dictations show here.")
                .font(GlassTheme.detail).foregroundStyle(GlassTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var history: some View {
        ScrollView {
            TimelineView(.periodic(from: .now, by: 60)) { context in
                LazyVStack(spacing: 0) {
                    ForEach(model.records, id: \.id) { record in
                        HistoryRow(
                            record: record,
                            now: context.date,
                            isFocused: focusedRecord == record.id,
                            isCopied: copiedRecord == record.id,
                            paste: { model.onPasteAgain(record) },
                            copy: { copy(record) })
                            .focused($focusedRecord, equals: record.id)
                            .onKeyPress(.downArrow) { moveFocus(from: record, by: 1) }
                            .onKeyPress(.upArrow) { moveFocus(from: record, by: -1) }
                            .onKeyPress(.return) { model.onPasteAgain(record); return .handled }
                            .onCopyCommand { copy(record); return [] }
                    }
                }
                .padding(6)
            }
        }
        .frame(maxHeight: 400)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func copy(_ record: DictationRecord) {
        model.onCopy(record)
        copiedRecord = record.id
        AccessibilityNotification.Announcement("Copied").post()
    }

    private func moveFocus(from record: DictationRecord, by step: Int) -> KeyPress.Result {
        guard let index = model.records.firstIndex(where: { $0.id == record.id }),
              model.records.indices.contains(index + step) else { return .ignored }
        focusedRecord = model.records[index + step].id
        return .handled
    }
}

/// One past dictation. The whole row pastes it again; Copy is always visible, so no
/// action needs a hover.
private struct HistoryRow: View {
    let record: DictationRecord
    let now: Date
    let isFocused: Bool
    let isCopied: Bool
    let paste: () -> Void
    let copy: () -> Void
    @State private var isHovering = false

    private var text: String { record.pastedText ?? record.rawTranscript }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Button(action: paste) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(text)
                        .font(GlassTheme.transcript)
                        .lineSpacing(4)
                        .foregroundStyle(GlassTheme.textPrimary)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    // One line, so the row never changes height.
                    Text(meta)
                        .font(GlassTheme.detail)
                        .foregroundStyle(GlassTheme.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if let note {
                        Text(note).font(GlassTheme.small).foregroundStyle(GlassTheme.textSecondary)
                    }
                }
                .contentShape(Rectangle())
                .glassFocusRing(RoundedRectangle(cornerRadius: GlassTheme.innerRadius, style: .continuous))
            }
            .buttonStyle(.plain)
            .help("Click to paste")
            .accessibilityLabel("Paste again: \(text), \(meta)")
            .accessibilityAction(named: "Copy", copy)

            Button(action: copy) {
                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    .foregroundStyle(isCopied ? GlassTheme.stateDone : GlassTheme.textPrimary)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
                    .glassFocusRing(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isCopied ? "Copied" : "Copy")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isFocused ? GlassTheme.selected : isHovering ? GlassTheme.hover : .clear)
        }
        .onHover { isHovering = $0 }
        .animation(GlassTheme.snap, value: isHovering)
    }

    /// "Notes · 4 min. ago": the app it went to and when.
    private var meta: String {
        let elapsed = now.timeIntervalSince(record.startedAt)
        let when = elapsed < 60 ? "just now" : Self.relative.localizedString(for: record.startedAt, relativeTo: now)
        return [Self.appName(record.app), when].compactMap { $0 }.joined(separator: " · ")
    }

    private var note: String? {
        if !record.pasteLanded { return "Not pasted" }
        guard let reason = record.fallbackReason else { return nil }
        let why = switch reason {
        case .slow: "cleanup too slow"
        case .offline: "offline"
        case .unparseable, .cutOff, .wordsNotInTranscript, .lengthOutOfRange, .answeredInstead: "cleanup didn't pass its check"
        }
        return "Raw transcript · \(why)"
    }

    private static let relative: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()

    private static func appName(_ bundleID: String?) -> String? {
        guard let bundleID, let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return nil
        }
        let name = FileManager.default.displayName(atPath: url.path(percentEncoded: false))
        return name.hasSuffix(".app") ? String(name.dropLast(4)) : name
    }
}

/// Settings and Quit: 28 pt capsule rows with the shortcut at the right.
private struct MenuRow: View {
    let title: String
    let shortcut: String
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title).font(GlassTheme.label).foregroundStyle(GlassTheme.textPrimary)
                Spacer()
                Text(shortcut).font(GlassTheme.small).foregroundStyle(GlassTheme.textSecondary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 10)
            .frame(height: GlassTheme.controlHeight)
            .background { if isHovering { Capsule().fill(GlassTheme.selected) } }
            .contentShape(Capsule())
            .glassFocusRing(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
