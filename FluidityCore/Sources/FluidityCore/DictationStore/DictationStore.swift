import AVFoundation
import Foundation

public enum DictationStoreError: Error, Equatable {
    case recordNotFound(UUID)
    /// A held audio file's copy on the drive came out a different size; the held file is kept.
    case copyIncomplete(fileName: String)
    case audioBufferUnavailable
}

/// Saves each dictation as a 16 kHz mono FLAC file plus one JSONL line, on the Space drive,
/// or under `holdingRoot` until the drive mounts.
///
/// Files are named `<UTC timestamp>_<first 8 hex of the id>.flac`, for example
/// `2026-10-22T23-04-28Z_DA258D55.flac`, as the recordings already on the drive are. Lines go to one file
/// per UTC day, `2026-10-22.jsonl`, so rewriting a line for the final text reads one day, not every dictation.
public actor DictationStore {
    public static let defaultDriveRoot = URL(filePath: "/Volumes/Space/fluidity-data", directoryHint: .isDirectory)
    public static let defaultHoldingRoot = URL.applicationSupportDirectory
        .appending(path: "Fluidity/holding", directoryHint: .isDirectory)
    public static let defaultHistoryURL = URL.applicationSupportDirectory.appending(path: "Fluidity/history.json")
    public static let historyLimit = 20

    private let driveRoot: URL
    private let holdingRoot: URL
    private let historyURL: URL
    private let mounts: any MountObserving
    private let files = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        driveRoot: URL = DictationStore.defaultDriveRoot,
        holdingRoot: URL = DictationStore.defaultHoldingRoot,
        historyURL: URL = DictationStore.defaultHistoryURL,
        mounts: any MountObserving = WorkspaceMountObserver()
    ) {
        self.driveRoot = driveRoot
        self.holdingRoot = holdingRoot
        self.historyURL = historyURL
        self.mounts = mounts
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .withoutEscapingSlashes
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    /// Writes the audio and the record's line. Call it only for dictations into non-secure fields:
    /// the controller skips secure fields, and this store saves whatever it is given.
    public func save(record: DictationRecord, audio: [Float]) throws {
        let wroteToDrive = isDriveMounted && (try? write(record, audio: audio, under: driveRoot)) != nil
        if !wroteToDrive {
            try files.createDirectory(at: holdingRoot, withIntermediateDirectories: true)
            try write(record, audio: audio, under: holdingRoot)
        }
        // The dictation is already saved; a history failure must not make the caller save it again.
        try? updateHistory { $0.insert(record, at: 0) }
    }

    /// Sets the final text and why watching stopped on the saved record, rewriting its line in place.
    public func updateFinalText(id: UUID, finalText: String?, stopReason: WatchStopReason?) throws {
        let change = { (record: inout DictationRecord) in
            record.finalText = finalText
            record.watchStopReason = stopReason
        }
        // Both roots, because an interrupted move leaves the line on the drive and held, and the next move
        // copies the held line over the drive's.
        let roots = isDriveMounted ? [driveRoot, holdingRoot] : [holdingRoot]
        var updated: DictationRecord?
        for root in roots {
            var found: DictationRecord?
            for url in lineFiles(in: root) where found == nil {
                found = try rewrite(id: id, in: url, change)
            }
            updated = found ?? updated
        }
        if updated == nil, var record = readHistory().first(where: { $0.id == id }) {
            // The line is on a drive that is not mounted. A held copy replaces it when the drive mounts.
            change(&record)
            try files.createDirectory(at: holdingRoot, withIntermediateDirectories: true)
            try append(line(for: record), to: holdingRoot.appending(path: dayFileName(for: record)))
            updated = record
        }
        guard let updated else { throw DictationStoreError.recordNotFound(id) }
        try? updateHistory { history in
            if let index = history.firstIndex(where: { $0.id == id }) { history[index] = updated }
        }
    }

    /// The most recent saved dictations, newest first, for the popover.
    public func recent(limit: Int = DictationStore.historyLimit) -> [DictationRecord] {
        Array(readHistory().prefix(limit))
    }

    /// Moves held dictations to the drive now and after every volume mount, until the stream ends or the task is cancelled.
    public func watchMounts() async {
        let events = mounts.mounts()
        // A failed move leaves the files held, and the next mount tries again.
        try? moveHeldDictations()
        for await _ in events {
            try? moveHeldDictations()
        }
    }

    /// Moves every held audio file and line to the drive, if it is mounted. Running it again after an
    /// interruption duplicates nothing: a held line replaces the drive line with the same id.
    public func moveHeldDictations() throws {
        guard isDriveMounted else { return }
        let held = (try? files.contentsOfDirectory(at: holdingRoot, includingPropertiesForKeys: nil)) ?? []
        for source in held where source.pathExtension == "flac" {
            let target = driveRoot.appending(path: source.lastPathComponent)
            if size(of: target) != size(of: source) {
                try? files.removeItem(at: target)
                try files.copyItem(at: source, to: target)
                guard size(of: target) == size(of: source) else {
                    throw DictationStoreError.copyIncomplete(fileName: source.lastPathComponent)
                }
            }
            try files.removeItem(at: source)
        }
        for source in held where source.pathExtension == "jsonl" {
            let target = driveRoot.appending(path: source.lastPathComponent)
            var lines = readLines(target)
            var ids = lines.map(lineID)
            for line in readLines(source) {
                if let id = lineID(line), let index = ids.firstIndex(of: id) {
                    lines[index] = line
                } else if !lines.contains(line) {
                    lines.append(line)
                    ids.append(lineID(line))
                }
            }
            try writeLines(lines, to: target)
            try files.removeItem(at: source)
        }
    }

    // MARK: - Files

    /// Never create `driveRoot`: when the drive is unmounted that would put a folder at the same path on the startup disk.
    private var isDriveMounted: Bool {
        var isDirectory: ObjCBool = false
        return files.fileExists(atPath: driveRoot.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    private func write(_ record: DictationRecord, audio: [Float], under root: URL) throws {
        try writeFLAC(audio, to: root.appending(path: audioFileName(for: record)))
        try append(line(for: record), to: root.appending(path: dayFileName(for: record)))
    }

    /// macOS's FLAC encoder writes an unreadable file from fewer samples than one 4608-sample block.
    static let shortestFLAC = 4_608

    private func writeFLAC(_ audio: [Float], to url: URL) throws {
        let samples = audio + repeatElement(0, count: max(0, Self.shortestFLAC - audio.count))
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatFLAC,
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
        ]
        let file = try AVAudioFile(forWriting: url, settings: settings, commonFormat: .pcmFormatFloat32, interleaved: false)
        defer { file.close() }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(samples.count)),
              let channel = buffer.floatChannelData?[0]
        else { throw DictationStoreError.audioBufferUnavailable }
        samples.withUnsafeBufferPointer { channel.update(from: $0.baseAddress!, count: samples.count) }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        try file.write(from: buffer)
    }

    private func audioFileName(for record: DictationRecord) -> String {
        let stamp = record.startedAt.formatted(.iso8601).replacing(":", with: "-")
        return "\(stamp)_\(record.id.uuidString.prefix(8)).flac"
    }

    private func dayFileName(for record: DictationRecord) -> String {
        "\(record.startedAt.formatted(.iso8601).prefix(10)).jsonl"
    }

    /// Day files, newest first; their names sort by date.
    private func lineFiles(in root: URL) -> [URL] {
        let all = (try? files.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? []
        return all.filter { $0.pathExtension == "jsonl" }.sorted { $0.lastPathComponent > $1.lastPathComponent }
    }

    private func line(for record: DictationRecord) throws -> String {
        String(decoding: try encoder.encode(record), as: UTF8.self)
    }

    private func append(_ line: String, to url: URL) throws {
        if !files.fileExists(atPath: url.path) {
            files.createFile(atPath: url.path, contents: nil)
        }
        let handle = try FileHandle(forWritingTo: url)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: Data((line + "\n").utf8))
    }

    /// Replaces the line whose id matches with `change` applied, and returns the changed record; nil when no line matches.
    private func rewrite(id: UUID, in url: URL, _ change: (inout DictationRecord) -> Void) throws -> DictationRecord? {
        var lines = readLines(url)
        guard let index = lines.firstIndex(where: { lineID($0) == id }) else { return nil }
        var record = try decoder.decode(DictationRecord.self, from: Data(lines[index].utf8))
        change(&record)
        lines[index] = try line(for: record)
        try writeLines(lines, to: url)
        return record
    }

    private func readLines(_ url: URL) -> [String] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        return String(decoding: data, as: UTF8.self).split(separator: "\n").map(String.init)
    }

    private func writeLines(_ lines: [String], to url: URL) throws {
        try Data(lines.map { $0 + "\n" }.joined().utf8).write(to: url, options: .atomic)
    }

    private struct LineID: Decodable { let id: UUID }

    /// Nil for a line cut short by an interrupted write; such lines are kept as they are.
    private func lineID(_ line: String) -> UUID? {
        try? decoder.decode(LineID.self, from: Data(line.utf8)).id
    }

    private func size(of url: URL) -> Int? {
        (try? files.attributesOfItem(atPath: url.path))?[.size] as? Int
    }

    // MARK: - History

    private func readHistory() -> [DictationRecord] {
        guard let data = try? Data(contentsOf: historyURL) else { return [] }
        return (try? decoder.decode([DictationRecord].self, from: data)) ?? []
    }

    private func updateHistory(_ change: (inout [DictationRecord]) -> Void) throws {
        var history = readHistory()
        change(&history)
        try files.createDirectory(at: historyURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try encoder.encode(Array(history.prefix(Self.historyLimit))).write(to: historyURL, options: .atomic)
    }
}
