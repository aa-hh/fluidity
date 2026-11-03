import Foundation

/// Whether a dictation's recording is on the Mac for the History page.
public enum RecordingStatus: Codable, Equatable, Sendable {
    case saved
    /// Deleted when it passed the Keep recordings period, which it names.
    case expired(Retention)
}

/// One dictation on the History page.
public struct HistoryItem: Equatable, Sendable {
    public var record: DictationRecord
    /// Nil when no recording was saved, or the user deleted it.
    public var recording: RecordingStatus?

    public init(record: DictationRecord, recording: RecordingStatus? = nil) {
        self.record = record
        self.recording = recording
    }
}

extension HistoryItem {
    /// The items whose raw transcript or pasted text holds `query`, ignoring case and accents; all of them for none.
    public static func search(_ items: [HistoryItem], for query: String) -> [HistoryItem] {
        let query = query.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return items }
        return items.filter {
            $0.record.rawTranscript.localizedStandardContains(query) || ($0.record.pastedText ?? "").localizedStandardContains(query)
        }
    }

    /// The item to choose once `id` is deleted: the next one down, or the one above at the end.
    public static func neighbour(of id: UUID, in items: [HistoryItem]) -> UUID? {
        guard let index = items.firstIndex(where: { $0.record.id == id }) else { return nil }
        let next = items.indices.contains(index + 1) ? index + 1 : index - 1
        return items.indices.contains(next) ? items[next].record.id : nil
    }

    /// Runs of items that started on the same calendar day, in the order given.
    public static func byDay(_ items: [HistoryItem], calendar: Calendar = .current) -> [(day: Date, items: [HistoryItem])] {
        var days: [(day: Date, items: [HistoryItem])] = []
        for item in items {
            let day = calendar.startOfDay(for: item.record.startedAt)
            if day == days.last?.day {
                days[days.count - 1].items.append(item)
            } else {
                days.append((day, [item]))
            }
        }
        return days
    }
}

extension HistoryItem: Codable {
    // Flat beside the record's own keys, so history files written as plain records still read.
    private enum Keys: String, CodingKey { case recording }

    public init(from decoder: any Decoder) throws {
        record = try DictationRecord(from: decoder)
        recording = try decoder.container(keyedBy: Keys.self).decodeIfPresent(RecordingStatus.self, forKey: .recording)
    }

    public func encode(to encoder: any Encoder) throws {
        try record.encode(to: encoder)
        var container = encoder.container(keyedBy: Keys.self)
        try container.encodeIfPresent(recording, forKey: .recording)
    }
}

/// What the History group's Space used row reports.
public struct HistoryUsage: Equatable, Sendable {
    public var textBytes: Int
    public var recordingBytes: Int
    public var recordingCount: Int
    public var dictationCount: Int
    /// The user's pace, from the oldest dictation kept to the newest; nil until those are a day apart.
    public var dictationsPerYear: Double?

    public init(textBytes: Int = 0, recordingBytes: Int = 0, recordingCount: Int = 0, dictationCount: Int = 0,
                dictationsPerYear: Double? = nil) {
        self.textBytes = textBytes
        self.recordingBytes = recordingBytes
        self.recordingCount = recordingCount
        self.dictationCount = dictationCount
        self.dictationsPerYear = dictationsPerYear
    }
}

/// Every dictation the History page shows, newest first, kept until a retention rule or the user deletes it, and
/// their recordings. Separate from the training data `DictationStore` writes: nothing here touches that.
// razor: one JSON file, rewritten whole on each change (about 6.5 MB after 1,800 dictations); move to
// per-day files or SQLite if saves get slow.
public actor HistoryStore {
    public static let defaultFolder = URL.applicationSupportDirectory.appending(path: "Rillo", directoryHint: .isDirectory)

    private let historyURL: URL
    private let recordingsFolder: URL
    private let files = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var loaded: [HistoryItem]?
    /// The history file was there but did not read (damaged, or from a newer build); it is moved aside, not overwritten.
    private var unreadable = false

    public init(folder: URL = HistoryStore.defaultFolder) {
        historyURL = folder.appending(path: "history.json")
        recordingsFolder = folder.appending(path: "recordings", directoryHint: .isDirectory)
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .withoutEscapingSlashes
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    public nonisolated func recordingURL(for id: UUID) -> URL {
        recordingsFolder.appending(path: "\(id.uuidString).flac")
    }

    /// Newest first.
    public func items() -> [HistoryItem] {
        if let loaded { return loaded }
        guard files.fileExists(atPath: historyURL.path) else {
            loaded = []
            return []
        }
        let read = (try? Data(contentsOf: historyURL)).flatMap { try? decoder.decode([HistoryItem].self, from: $0) }
        unreadable = read == nil
        let items = read ?? []
        loaded = items
        return items
    }

    /// Adds a dictation, with its recording when `audio` is given. A recording that fails to write leaves the text saved.
    public func add(_ record: DictationRecord, audio: [Float]?) throws {
        var item = HistoryItem(record: record)
        if let audio {
            try? files.createDirectory(at: recordingsFolder, withIntermediateDirectories: true)
            if (try? DictationStore.writeFLAC(audio, to: recordingURL(for: record.id))) != nil { item.recording = .saved }
        }
        try change { $0.insert(item, at: 0) }
    }

    /// Replaces the saved record with the same id; does nothing when there is none.
    public func replace(_ record: DictationRecord) throws {
        try change { items in
            if let index = items.firstIndex(where: { $0.record.id == record.id }) { items[index].record = record }
        }
    }

    /// Deletes the dictations and their recordings.
    public func delete(_ ids: Set<UUID>) throws {
        for id in ids { try? files.removeItem(at: recordingURL(for: id)) }
        try change { $0.removeAll { ids.contains($0.record.id) } }
    }

    public func deleteAll() throws {
        try? files.removeItem(at: recordingsFolder)
        try change { $0.removeAll() }
    }

    /// Deletes every recording; the dictations' text stays.
    public func deleteRecordings() throws {
        try? files.removeItem(at: recordingsFolder)
        try change { items in
            for index in items.indices { items[index].recording = nil }
        }
    }

    /// Dictations that started before `cutoff`, for the sheet that asks whether to keep them.
    public func count(olderThan cutoff: Date) -> Int {
        items().count { $0.record.startedAt < cutoff }
    }

    /// Saved recordings, all of them or those of dictations that started before `cutoff`.
    public func recordingCount(olderThan cutoff: Date? = nil) -> Int {
        items().count { item in item.recording == .saved && cutoff.map { item.record.startedAt < $0 } ?? true }
    }

    /// Deletes dictations and recordings past their periods, except those exempted when a period was shortened.
    public func purge(_ rules: RetentionRules, now: Date) throws {
        func isPast(_ item: HistoryItem, _ period: Retention, exemptBefore: Date?) -> Bool {
            guard let cutoff = period.cutoff(now: now) else { return false }
            let started = item.record.startedAt
            return started < cutoff && exemptBefore.map { started >= $0 } ?? true
        }
        let current = items()
        let expiredDictations = Set(current.filter { isPast($0, rules.keepHistory, exemptBefore: rules.historyExemptBefore) }
            .map(\.record.id))
        let expiredRecordings = Set(current.filter {
            $0.recording == .saved && isPast($0, rules.keepRecordings, exemptBefore: rules.recordingsExemptBefore)
        }.map(\.record.id))
        guard !expiredDictations.isEmpty || !expiredRecordings.isEmpty else { return }
        for id in expiredDictations.union(expiredRecordings) { try? files.removeItem(at: recordingURL(for: id)) }
        try change { items in
            items.removeAll { expiredDictations.contains($0.record.id) }
            for index in items.indices where expiredRecordings.contains(items[index].record.id) {
                items[index].recording = .expired(rules.keepRecordings)
            }
        }
    }

    /// Applies `period` and purges, unless it is shorter and leaves items already past it while the user has not yet
    /// answered whether to keep them (`keepOlder` nil): then it reports how many, for the caller to ask. A purge that
    /// cannot write still applies the period; the next purge tries again.
    public func changeRetention(
        _ rules: RetentionRules, _ kind: RetentionKind, to period: Retention, keepOlder: Bool?, now: Date
    ) -> RetentionChange {
        if keepOlder == nil, rules.period(kind).isLonger(than: period), let cutoff = period.cutoff(now: now) {
            let older = kind == .history ? count(olderThan: cutoff) : recordingCount(olderThan: cutoff)
            if older > 0 { return .ask(count: older) }
        }
        let changed = rules.keeping(kind, for: period, now: now, keepOlder: keepOlder ?? true)
        try? purge(changed, now: now)
        return .applied(changed)
    }

    public func usage() -> HistoryUsage {
        let recordings = (try? files.contentsOfDirectory(at: recordingsFolder, includingPropertiesForKeys: nil)) ?? []
        let all = items()
        let span = (all.first?.record.startedAt).map { newest in newest.timeIntervalSince(all.last!.record.startedAt) } ?? 0
        return HistoryUsage(
            textBytes: size(of: historyURL),
            recordingBytes: recordings.reduce(0) { $0 + size(of: $1) },
            recordingCount: recordings.count,
            dictationCount: all.count,
            dictationsPerYear: span >= 86_400 ? Double(all.count) / span * 365 * 86_400 : nil)
    }

    private func size(of url: URL) -> Int {
        (try? files.attributesOfItem(atPath: url.path))?[.size] as? Int ?? 0
    }

    private func change(_ edit: (inout [HistoryItem]) -> Void) throws {
        var current = items()
        edit(&current)
        try files.createDirectory(at: historyURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        if unreadable {
            let stamp = Date.now.formatted(.iso8601).replacing(":", with: "-")
            try files.moveItem(at: historyURL, to: historyURL.deletingLastPathComponent().appending(path: "history-unreadable-\(stamp).json"))
            unreadable = false
        }
        try encoder.encode(current).write(to: historyURL, options: .atomic)
        loaded = current
    }
}
