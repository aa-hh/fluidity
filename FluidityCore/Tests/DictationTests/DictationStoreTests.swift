import AVFoundation
import Foundation
import FluidityCore
import Testing

/// A temporary folder holding the drive root, the holding root and the history file of one store.
private struct Folders {
    let base = FileManager.default.temporaryDirectory.appending(path: "DictationStoreTests-\(UUID().uuidString)")
    var drive: URL { base.appending(path: "drive") }
    var holding: URL { base.appending(path: "holding") }
    var history: URL { base.appending(path: "history.json") }

    func store(mounts: any MountObserving = NoMounts()) -> DictationStore {
        DictationStore(driveRoot: drive, holdingRoot: holding, historyURL: history, mounts: mounts)
    }

    func mountDrive() throws { try FileManager.default.createDirectory(at: drive, withIntermediateDirectories: true) }

    func names(in url: URL) -> [String] {
        ((try? FileManager.default.contentsOfDirectory(atPath: url.path)) ?? []).sorted()
    }

    func lines(_ url: URL) throws -> [DictationRecord] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try String(decoding: Data(contentsOf: url), as: UTF8.self)
            .split(separator: "\n")
            .map { try decoder.decode(DictationRecord.self, from: Data($0.utf8)) }
    }
}

private struct NoMounts: MountObserving {
    func mounts() -> AsyncStream<Void> { AsyncStream { $0.finish() } }
}

/// Delivers one mount, running `beforeMount` only when the store asks for the event, then ends.
private struct OneMount: MountObserving {
    let beforeMount: @Sendable () throws -> Void

    private actor Once {
        var fired = false
        func fire() -> Bool { defer { fired = true }; return !fired }
    }

    func mounts() -> AsyncStream<Void> {
        let once = Once()
        let beforeMount = beforeMount
        return AsyncStream {
            guard await once.fire() else { return nil }
            try? beforeMount()
            return ()
        }
    }
}

// 2026-10-22T23:04:28Z, a whole second so the ISO 8601 round trip is exact.
private let startedAt = Date(timeIntervalSince1970: 1_792_710_268)

private func record(_ offset: TimeInterval = 0, id: UUID = UUID()) -> DictationRecord {
    DictationRecord(
        id: id, startedAt: startedAt.addingTimeInterval(offset), app: "com.apple.TextEdit",
        rawTranscript: "hello world \(offset)", pastedText: "Hello world.",
        wordTimings: [WordTiming(word: "hello", start: 0, end: 0.4)],
        modelVersion: "parakeet-v2", wordListVersion: "1"
    )
}

private let tone: [Float] = (0..<16_000).map { sinf(Float($0) * 0.1) * 0.5 }

// Turns red if save names the audio file or day file differently, writes anything but 16 kHz mono FLAC,
// or writes other than exactly one line.
@Test func saveWritesFLACAndOneLineOnTheDrive() async throws {
    let folders = Folders()
    try folders.mountDrive()
    let id = try #require(UUID(uuidString: "DA258D55-0000-4000-8000-000000000000"))
    let saved = record(id: id)

    try await folders.store().save(record: saved, audio: tone)

    #expect(folders.names(in: folders.drive) == ["2026-10-22.jsonl", "2026-10-22T23-04-28Z_DA258D55.flac"])
    #expect(try folders.lines(folders.drive.appending(path: "2026-10-22.jsonl")) == [saved])
    let audio = try AVAudioFile(forReading: folders.drive.appending(path: "2026-10-22T23-04-28Z_DA258D55.flac"))
    #expect(audio.fileFormat.settings[AVFormatIDKey] as? UInt32 == kAudioFormatFLAC)
    #expect(audio.fileFormat.sampleRate == 16_000)
    #expect(audio.fileFormat.channelCount == 1)
    #expect(audio.length == AVAudioFramePosition(tone.count))
    #expect(!FileManager.default.fileExists(atPath: folders.holding.path))
}

// Turns red if audio shorter than one FLAC block is written unpadded, which leaves an unreadable 42-byte file.
@Test(arguments: [0, 1_600])
func shortAudioIsPaddedToAReadableFLAC(sampleCount: Int) async throws {
    let folders = Folders()
    try folders.mountDrive()

    try await folders.store().save(record: record(), audio: Array(tone.prefix(sampleCount)))

    let name = try #require(folders.names(in: folders.drive).first { $0.hasSuffix(".flac") })
    #expect(try AVAudioFile(forReading: folders.drive.appending(path: name)).length == 4_608)
}

// Turns red if save writes anywhere but the holding folder while the drive is missing, or creates the drive folder.
@Test func saveHoldsTheDictationWhileTheDriveIsMissing() async throws {
    let folders = Folders()
    let saved = record()

    try await folders.store().save(record: saved, audio: tone)

    #expect(folders.names(in: folders.holding).count == 2)
    #expect(try folders.lines(folders.holding.appending(path: "2026-10-22.jsonl")) == [saved])
    #expect(!FileManager.default.fileExists(atPath: folders.drive.path))
}

// Turns red if a mount does not move held dictations, or if a move that was interrupted after copying
// and is then run twice leaves a duplicate line or a held file behind.
@Test func heldDictationsMoveOnMountWithoutLossOrDuplicates() async throws {
    let folders = Folders()
    let first = record(), second = record(5)
    let store = folders.store(mounts: OneMount {
        // The drive mounts holding a copy of everything, as if an earlier move stopped before deleting.
        try folders.mountDrive()
        for name in folders.names(in: folders.holding) {
            try FileManager.default.copyItem(at: folders.holding.appending(path: name), to: folders.drive.appending(path: name))
        }
    })
    try await store.save(record: first, audio: tone)
    try await store.save(record: second, audio: tone)

    await store.watchMounts()
    try await store.moveHeldDictations()

    #expect(folders.names(in: folders.holding).isEmpty)
    #expect(folders.names(in: folders.drive).filter { $0.hasSuffix(".flac") }.count == 2)
    #expect(try folders.lines(folders.drive.appending(path: "2026-10-22.jsonl")) == [first, second])
}

// Turns red if updateFinalText appends a line instead of replacing one, changes another record,
// or leaves the popover history stale.
@Test func updateFinalTextRewritesOnlyThatLine() async throws {
    let folders = Folders()
    try folders.mountDrive()
    let store = folders.store()
    let records = [record(0), record(1), record(2)]
    for saved in records { try await store.save(record: saved, audio: []) }

    try await store.updateFinalText(id: records[1].id, finalText: "Hello, world.", stopReason: .focusLost)

    var expected = records
    expected[1].finalText = "Hello, world."
    expected[1].watchStopReason = .focusLost
    #expect(try folders.lines(folders.drive.appending(path: "2026-10-22.jsonl")) == expected)
    #expect(await store.recent() == expected.reversed())
}

// Turns red if a final text that arrives while the drive is unmounted is lost, or lands as a second line.
@Test func finalTextWrittenWhileTheDriveIsUnmountedReplacesTheDriveLine() async throws {
    let folders = Folders()
    try folders.mountDrive()
    let store = folders.store()
    let saved = record()
    try await store.save(record: saved, audio: tone)
    let unmounted = folders.base.appending(path: "unmounted")
    try FileManager.default.moveItem(at: folders.drive, to: unmounted)

    try await store.updateFinalText(id: saved.id, finalText: "Hello there.", stopReason: .timeLimit)
    try FileManager.default.moveItem(at: unmounted, to: folders.drive)
    try await store.moveHeldDictations()

    let lines = try folders.lines(folders.drive.appending(path: "2026-10-22.jsonl"))
    #expect(lines.map(\.finalText) == ["Hello there."])
    #expect(lines.map(\.watchStopReason) == [.timeLimit])
}

// Turns red if updateFinalText silently does nothing for a dictation that was never saved.
@Test func updateFinalTextRefusesAnUnknownDictation() async throws {
    let folders = Folders()
    try folders.mountDrive()
    let id = UUID()

    await #expect(throws: DictationStoreError.recordNotFound(id)) {
        try await folders.store().updateFinalText(id: id, finalText: "x", stopReason: .fieldCleared)
    }
}

// Turns red if the history keeps more than 20, orders oldest first, or lives only in memory.
@Test func recentReturnsTheLastTwentyNewestFirstAfterARestart() async throws {
    let folders = Folders()
    try folders.mountDrive()
    let records = (0..<25).map { record(TimeInterval($0)) }
    let first = folders.store()
    for saved in records { try await first.save(record: saved, audio: []) }

    let restarted = folders.store()

    #expect(await restarted.recent() == Array(records.reversed().prefix(20)))
}
