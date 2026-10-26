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
                MenuRow(title: "Settings…", shortcut: "⌘ ,") { model.onOpenSettings(nil) }
                    .keyboardShortcut(",", modifiers: .command)
                MenuRow(title: "Quit Fluidity", shortcut: "⌘ Q", action: model.onQuit)
                    .keyboardShortcut("q", modifiers: .command)
            }
            .padding(6)
        }
        .padding(1)
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
        let fixTitle = status.offersFixButton && status.fix != nil ? status.fixButtonTitle : nil
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                StatusDot(tone: status.tone)
                Text(status.title).font(GlassTheme.label).foregroundStyle(GlassTheme.textPrimary)
                Spacer(minLength: 8)
                if let hint {
                    Text(hint).font(GlassTheme.small).foregroundStyle(GlassTheme.textSecondary).lineLimit(1)
                }
            }
            .frame(height: 16)
            if status.detail != nil || fixTitle != nil {
                VStack(alignment: .leading, spacing: 8) {
                    if let detail = status.detail {
                        Text(detail).font(GlassTheme.detail).foregroundStyle(GlassTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let fixTitle, let fix = status.fix {
                        Button(fixTitle) {
                            switch fix {
                            case .permission(let permission): settings.onOpenPrivacySettings(permission)
                            case .cleanup: model.onOpenSettings(.cleanup)
                            }
                        }
                        .buttonStyle(.glassSecondary)
                    }
                }
                .padding(.leading, 16)
                .padding(.bottom, 2)
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 12)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
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
                LazyVStack(spacing: 2) {
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
        // Five two-line rows show; the rest scroll.
        .frame(maxHeight: 376)
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
                    // 13 pt on a 17 pt line: the font's own line is 16 pt.
                    Text(text)
                        .font(GlassTheme.transcript)
                        .lineSpacing(1)
                        .padding(.vertical, 0.5)
                        .foregroundStyle(GlassTheme.textPrimary)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    // One line, so the row never changes height.
                    HStack(spacing: 8) {
                        Text(isCopied ? "Copied" : meta)
                            .font(GlassTheme.detail)
                            .foregroundStyle(isCopied ? GlassTheme.textPrimary : GlassTheme.textSecondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if isFocused && !isCopied {
                            Text("Return to paste").font(GlassTheme.small).foregroundStyle(GlassTheme.textSecondary)
                                .accessibilityHidden(true)
                        }
                    }
                    .frame(height: 16)
                    if let note, !isCopied {
                        Text(note).font(GlassTheme.small).foregroundStyle(GlassTheme.textSecondary)
                            .frame(height: 14)
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
                Group {
                    if isCopied {
                        StatusIcon(kind: .done)
                    } else {
                        CopyGlyph()
                            .stroke(GlassTheme.textPrimary, style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))
                            .frame(width: 16, height: 16)
                    }
                }
                .frame(width: 28, height: 28)
                .contentShape(Circle())
                .glassFocusRing(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isCopied ? "Copied" : "Copy")
        }
        .padding(.leading, 10)
        .padding(.trailing, 6)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: GlassTheme.innerRadius, style: .continuous)
                .fill(isFocused || isCopied ? GlassTheme.selected : isHovering ? GlassTheme.hover : .clear)
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

/// The design library's `Icon/Copy`: two overlapping rounded squares, drawn in a 16 pt box.
private struct CopyGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 16
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * s, y: rect.minY + y * s) }
        var path = Path(roundedRect: CGRect(origin: p(2.5, 5), size: CGSize(width: 8 * s, height: 8.5 * s)), cornerRadius: 2 * s)
        path.move(to: p(5.5, 2.5))
        path.addLine(to: p(11.5, 2.5))
        path.addCurve(to: p(13.5, 4.5), control1: p(12.83, 2.5), control2: p(13.5, 3.17))
        path.addLine(to: p(13.5, 10.5))
        return path
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
