import RilloCore
import SwiftUI

/// The History page: search, the dictations by day on the left, and the chosen one on the right with its
/// recording and its raw transcript beside its pasted text, one sentence per row.
struct HistoryPane: View {
    let model: HistoryModel
    let settings: SettingsModel
    @State private var player = HistoryPlayer()

    var body: some View {
        VStack(spacing: 0) {
            header
            GlassRule()
            if model.items.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nothing dictated yet.").font(GlassTheme.label).foregroundStyle(GlassTheme.textPrimary)
                    Text("Hold \(settings.dictationKey.description) and speak. Every dictation shows here.")
                        .font(GlassTheme.detail).foregroundStyle(GlassTheme.textSecondary)
                }
                .accessibilityElement(children: .combine)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(spacing: 0) {
                    HistoryList(model: model, player: player)
                        .frame(width: 241)
                    Rectangle().fill(GlassTheme.lineRule).frame(width: 1).accessibilityHidden(true)
                    if let item = model.selected {
                        HistoryDetail(item: item, model: model, settings: settings, player: player)
                            .id(item.record.id)
                    } else {
                        Spacer().frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .task(id: PlayerSource(item: model.selected)) {
            let item = model.selected
            let url = item?.recording == .saved ? item.map { model.recordingURL($0.record.id) } : nil
            if let item { await player.load(url, record: item.record) } else { player.stop() }
        }
        .onDisappear { player.stop() }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text("History")
                .font(GlassTheme.title)
                .foregroundStyle(GlassTheme.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Button("History Settings…") { settings.showHistorySettings() }
                .buttonStyle(.glassQuiet)
                .accessibilityHint("Opens General settings, History")
            SearchField(text: Binding(get: { model.query }, set: { model.query = $0 }))
                .frame(width: 238)
        }
        .padding(.leading, 20)
        .padding(.trailing, 16)
        .padding(.top, 18)
        .padding(.bottom, 12)
    }
}

/// What the player loads: the chosen dictation and whether its recording is saved.
private struct PlayerSource: Equatable {
    let id: UUID?
    let recording: RecordingStatus?

    init(item: HistoryItem?) {
        id = item?.record.id
        recording = item?.recording
    }
}

private struct SearchField: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass").font(.system(size: 11)).foregroundStyle(GlassTheme.textSecondary)
            TextField("Search dictations", text: $text)
                .textFieldStyle(.plain)
                .font(GlassTheme.body)
                .foregroundStyle(GlassTheme.textPrimary)
                .focused($isFocused)
                .accessibilityLabel("Search dictations")
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(GlassTheme.textSecondary)
                        .contentShape(Circle())
                        .glassFocusRing(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 12)
        .glassFieldChrome(isFocused: isFocused)
    }
}

// MARK: - List

private struct HistoryList: View {
    let model: HistoryModel
    let player: HistoryPlayer
    @FocusState private var isFocused: Bool

    var body: some View {
        let shown = model.shown
        let selectedID = model.selected?.record.id
        ScrollViewReader { scroller in
            ScrollView {
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    LazyVStack(alignment: .leading, spacing: 2) {
                        if shown.isEmpty {
                            Text("No dictations match “\(model.query)”.")
                                .font(GlassTheme.detail).foregroundStyle(GlassTheme.textSecondary)
                                .padding(8)
                        }
                        ForEach(Self.days(shown, now: context.date), id: \.title) { day in
                            Text(day.title)
                                .font(GlassTheme.small).foregroundStyle(GlassTheme.textSecondary)
                                .padding(.horizontal, 10)
                                .padding(.top, 8)
                                .padding(.bottom, 2)
                                .accessibilityAddTraits(.isHeader)
                            ForEach(day.items, id: \.record.id) { item in
                                HistoryListRow(item: item, now: context.date, isSelected: item.record.id == selectedID) {
                                    model.selection = item.record.id
                                    isFocused = true
                                }
                                .id(item.record.id)
                            }
                        }
                    }
                    .padding(8)
                }
            }
            .focusable()
            .focused($isFocused)
            // The list takes arrow keys and Space as a whole, so the ring goes round it, not a row.
            .overlay {
                if isFocused {
                    RoundedRectangle(cornerRadius: GlassTheme.innerRadius, style: .continuous)
                        .strokeBorder(GlassTheme.focusRing, lineWidth: 2)
                        .padding(3)
                        .allowsHitTesting(false)
                }
            }
            .onKeyPress(.downArrow) { move(by: 1, in: shown, scroller: scroller) }
            .onKeyPress(.upArrow) { move(by: -1, in: shown, scroller: scroller) }
            .onKeyPress(.space) {
                player.toggle()
                return .handled
            }
            .onDeleteCommand { if let selectedID { model.delete(selectedID) } }
        }
    }

    private func move(by step: Int, in shown: [HistoryItem], scroller: ScrollViewProxy) -> KeyPress.Result {
        guard let index = shown.firstIndex(where: { $0.record.id == model.selected?.record.id }),
              shown.indices.contains(index + step) else { return .ignored }
        let id = shown[index + step].record.id
        model.selection = id
        scroller.scrollTo(id)
        return .handled
    }

    /// "Today", "Yesterday", then "Monday 2 November", newest first.
    private static func days(_ items: [HistoryItem], now: Date) -> [(title: String, items: [HistoryItem])] {
        HistoryItem.byDay(items).map { (dayTitle($0.day, now: now), $0.items) }
    }

    private static func dayTitle(_ day: Date, now: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDate(day, inSameDayAs: now) { return "Today" }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now), calendar.isDate(day, inSameDayAs: yesterday) {
            return "Yesterday"
        }
        let sameYear = calendar.isDate(day, equalTo: now, toGranularity: .year)
        return day.formatted(sameYear ? .dateTime.weekday(.wide).day().month(.wide) : .dateTime.day().month(.wide).year())
    }
}

private struct HistoryListRow: View {
    let item: HistoryItem
    let now: Date
    let isSelected: Bool
    let select: () -> Void
    @State private var isHovering = false

    var body: some View {
        let record = item.record
        Button(action: select) {
            VStack(alignment: .leading, spacing: 2) {
                Text(record.textToPasteAgain)
                    .font(GlassTheme.transcript)
                    .foregroundStyle(GlassTheme.textPrimary)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text([record.appName, record.startedAt.historyTime(now: now)].compactMap { $0 }.joined(separator: " · "))
                    .font(GlassTheme.small).foregroundStyle(GlassTheme.textSecondary).lineLimit(1)
                if let note = record.pasteNote {
                    Text(note).font(GlassTheme.small).foregroundStyle(GlassTheme.textSecondary).lineLimit(1)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background {
                RoundedRectangle(cornerRadius: GlassTheme.innerRadius, style: .continuous)
                    .fill(isSelected ? GlassTheme.selected : isHovering ? GlassTheme.hover : .clear)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focusable(false)
        .onHover { isHovering = $0 }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

@MainActor
private extension Date {
    /// "just now" or "2 min. ago" today, "Yesterday 17:40" or "2 Nov 17:40" before.
    func historyTime(now: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDate(self, inSameDayAs: now) {
            return now.timeIntervalSince(self) < 60 ? "just now" : Self.relative.localizedString(for: self, relativeTo: now)
        }
        return historyDay(now: now)
    }

    /// "Today 14:02", "Yesterday 17:40", "2 Nov 17:40".
    func historyDay(now: Date) -> String {
        let calendar = Calendar.current
        let time = formatted(date: .omitted, time: .shortened)
        if calendar.isDate(self, inSameDayAs: now) { return "Today \(time)" }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now), calendar.isDate(self, inSameDayAs: yesterday) {
            return "Yesterday \(time)"
        }
        return "\(formatted(.dateTime.day().month(.abbreviated))) \(time)"
    }

    private static let relative: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()
}

// MARK: - Detail

private struct HistoryDetail: View {
    let item: HistoryItem
    let model: HistoryModel
    let settings: SettingsModel
    let player: HistoryPlayer
    @State private var comparison: HistoryComparison?
    @State private var hoveredChange: Int?
    @State private var copied: MarkedWordsText.Side?

    private var record: DictationRecord { item.record }
    private var pasted: String { record.textToPasteAgain }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                titleRow
                recordingRow
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .bottom, spacing: 16) {
                        columnHeader("Raw transcript", detail: "What the speech model heard", side: .raw, text: record.rawTranscript)
                        columnHeader("Pasted text", detail: pastedDetail, side: .pasted, text: pasted)
                    }
                    if let comparison { rows(comparison) }
                }
                if comparison?.rows.contains(where: { $0.raw.contains { $0.change != nil } || $0.pasted.contains { $0.change != nil } }) == true {
                    Text("Red, struck through: words cleanup removed from the raw transcript. Green, underlined: words cleanup added or rewrote in the pasted text. Each row holds one sentence.")
                        .font(GlassTheme.small).foregroundStyle(GlassTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollBounceBehavior(.basedOnSize)
        .task {
            let raw = record.rawTranscript, pasted = pasted
            // razor: the word alignment is quadratic in words; fine for dictations of a few thousand words.
            comparison = await Task.detached { HistoryComparison(raw: raw, pasted: pasted) }.value
        }
        .task(id: copied) {
            guard copied != nil else { return }
            try? await Task.sleep(for: GlassTheme.hold)
            copied = nil
        }
    }

    private var titleRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text([record.appName, record.startedAt.historyDay(now: .now)].compactMap { $0 }.joined(separator: " · "))
                    .font(GlassTheme.label).foregroundStyle(GlassTheme.textPrimary)
                Text(pasteSummary).font(GlassTheme.small).foregroundStyle(GlassTheme.textSecondary)
            }
            .accessibilityElement(children: .combine)
            Spacer()
            Button { model.delete(record.id) } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundStyle(GlassTheme.textPrimary)
                    .frame(width: 28, height: 28)
                    .contentShape(Circle())
                    .glassFocusRing(Circle())
            }
            .buttonStyle(.plain)
            .help("Delete this dictation and its recording")
            .accessibilityLabel("Delete dictation")
        }
    }

    @ViewBuilder private var recordingRow: some View {
        switch item.recording {
        case .saved:
            if player.failed {
                recordingLine("Recording can't be played. The file is missing or can't be read.")
            } else {
                HistoryPlayerBar(player: player)
            }
        case .expired(let period):
            recordingLine("Recording deleted after \(period.title.lowercased())")
        case nil:
            if !model.saveRecordings {
                Text("Recordings are off. [Turn on Save recordings in General](rillo://history-settings) to play dictations back.")
                    .font(GlassTheme.small).foregroundStyle(GlassTheme.textSecondary)
                    .tint(GlassTheme.textPrimary)
                    .environment(\.openURL, OpenURLAction { _ in
                        settings.showHistorySettings()
                        return .handled
                    })
                    .frame(minHeight: 28, alignment: .leading)
            }
        }
    }

    private func recordingLine(_ text: String) -> some View {
        Text(text).font(GlassTheme.small).foregroundStyle(GlassTheme.textSecondary)
            .frame(minHeight: 28, alignment: .leading)
    }

    private func columnHeader(_ title: String, detail: String, side: MarkedWordsText.Side, text: String) -> some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                Text(title).font(GlassTheme.label).foregroundStyle(GlassTheme.textPrimary)
                Text(detail).font(GlassTheme.small).foregroundStyle(GlassTheme.textSecondary)
            }
            .accessibilityElement(children: .combine)
            Spacer()
            Button(copied == side ? "Copied" : "Copy") {
                model.copy(text)
                copied = side
            }
            .buttonStyle(.glassSecondary)
            .accessibilityLabel(copied == side ? "Copied" : "Copy \(title.lowercased())")
        }
        .frame(maxWidth: .infinity)
    }

    private func rows(_ comparison: HistoryComparison) -> some View {
        GlassPanel {
            ForEach(Array(comparison.rows.enumerated()), id: \.offset) { number, row in
                if number > 0 { GlassRule() }
                HStack(alignment: .top, spacing: 0) {
                    MarkedWordsText(
                        words: row.raw, side: .raw, hoveredChange: hoveredChange,
                        heardWord: player.heardWord, onHover: { hoveredChange = $0 },
                        onClickWord: item.recording == .saved && player.isLoaded ? { player.play(fromWord: $0) } : nil)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    Rectangle().fill(GlassTheme.lineRule).frame(width: 1).accessibilityHidden(true)
                    MarkedWordsText(words: row.pasted, side: .pasted, hoveredChange: hoveredChange, onHover: { hoveredChange = $0 })
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Sentence \(number + 1) of \(comparison.rows.count)")
            }
        }
    }

    /// "Pasted the cleaned text", or why it was the raw transcript, or that nothing landed.
    private var pasteSummary: String {
        if !record.pasteLanded { return "Not pasted" }
        if record.cleanedText != nil && record.fallbackReason == nil { return "Pasted the cleaned text" }
        return record.pasteNote.map { $0.replacing("Raw transcript", with: "Pasted the raw transcript") }
            ?? "Pasted the raw transcript"
    }

    private var pastedDetail: String {
        guard record.pasteLanded else { return "Not pasted" }
        return record.appName.map { "Pasted into \($0)" } ?? "Pasted"
    }
}
