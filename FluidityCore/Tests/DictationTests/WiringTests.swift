import FluidityCore
import FluidityTestSupport
import Foundation
import Synchronization
import Testing

// MARK: Cleanup

struct CleanupMappingCase: Sendable, CustomTestStringConvertible {
    let name: String
    let result: CleanupResult
    let expected: DictationController.CleanupResult
    var testDescription: String { name }
}

@Test(arguments: [
    CleanupMappingCase(
        name: "cleaned", result: CleanupResult(cleanedText: "Hi.", fallbackReason: nil, duration: 0.2),
        expected: .cleaned("Hi.")),
    CleanupMappingCase(
        name: "reply failed the output check",
        result: CleanupResult(cleanedText: "Sure, here it is.", fallbackReason: .answeredInstead, duration: 0.2),
        expected: .fallback(.answeredInstead)),
    CleanupMappingCase(
        name: "offline", result: CleanupResult(cleanedText: nil, fallbackReason: .offline, duration: 0),
        expected: .fallback(.offline)),
])
func cleanupResultMapsToPasteChoice(_ row: CleanupMappingCase) async {
    // Reading the cleaned text before the fallback reason turns the failed-check row red: that reply would be pasted.
    let adapter = CleanupAdapter(isOn: { true }, clean: { _ in row.result })
    #expect(await adapter.clean("hi") == row.expected)
}

// MARK: Paste

@MainActor
private final class FakeFocus: FocusChecking {
    var focus: FocusIdentity?
    init(_ focus: FocusIdentity?) { self.focus = focus }
    func currentFocus() -> FocusIdentity? { focus }
}

private let notesField = FocusIdentity(processID: 7, element: 1)

struct PasteMappingCase: Sendable, CustomTestStringConvertible {
    let result: PasteResult
    let expected: DictationController.PasteOutcome
    var testDescription: String { "\(result)" }
}

@MainActor
@Test(arguments: [
    PasteMappingCase(result: .landed(.milliseconds(40)), expected: .landed),
    PasteMappingCase(result: .failed(.nothingAskedForText), expected: .nowhereToPaste),
    PasteMappingCase(result: .failed(.focusMoved), expected: .nowhereToPaste),
    PasteMappingCase(result: .failed(.clipboardUnavailable), expected: .nowhereToPaste),
])
func pasteResultMapsToOutcome(_ row: PasteMappingCase) async {
    // Counting any result other than a landed paste as landed turns its row red.
    let focus = FakeFocus(notesField)
    let adapter = PasteAdapter(focusChecking: focus) { _, _ in row.result }
    adapter.captureFocus()
    #expect(await adapter.paste("hi") == row.expected)
}

@MainActor
@Test func pasteComparesAgainstFocusFromDictationStart() async {
    // Capturing the focus at paste time instead of at dictation start turns this red.
    let focus = FakeFocus(notesField)
    let compared = Mutex<FocusIdentity?>(nil)
    let adapter = PasteAdapter(focusChecking: focus) { _, start in
        compared.withLock { $0 = start }
        return .landed(.zero)
    }
    adapter.captureFocus()
    focus.focus = FocusIdentity(processID: 9, element: 2)
    _ = await adapter.paste("hi")
    #expect(compared.withLock { $0 } == notesField)
}

@MainActor
@Test func noFocusAtDictationStartIsNowhereToPaste() async {
    // Pasting when no app had focus at dictation start turns this red.
    let adapter = PasteAdapter(focusChecking: FakeFocus(nil)) { _, _ in .landed(.zero) }
    adapter.captureFocus()
    #expect(await adapter.paste("hi") == .nowhereToPaste)
}

struct PasteAgainCase: Sendable, CustomTestStringConvertible {
    let name: String
    let record: DictationRecord
    let expected: String
    var testDescription: String { name }
}

private func record(pasted: String? = nil, cleaned: String? = nil, fallback: FallbackReason? = nil) -> DictationRecord {
    DictationRecord(
        id: UUID(), startedAt: Date(), rawTranscript: "um hi there", cleanedText: cleaned, pastedText: pasted,
        fallbackReason: fallback, modelVersion: "m", wordListVersion: "w")
}

@Test(arguments: [
    PasteAgainCase(name: "pasted", record: record(pasted: "Hi there.", cleaned: "Hi there."), expected: "Hi there."),
    PasteAgainCase(name: "nowhere to paste, cleaned", record: record(cleaned: "Hi there."), expected: "Hi there."),
    PasteAgainCase(
        name: "nowhere to paste, failed check", record: record(cleaned: "Sure!", fallback: .answeredInstead),
        expected: "um hi there"),
    PasteAgainCase(name: "nowhere to paste, no cleanup", record: record(), expected: "um hi there"),
])
func pasteAgainPicksTheTextThatWasOrWouldHaveBeenPasted(_ row: PasteAgainCase) {
    // Using cleaned text whose fallback reason is set turns the failed-check row red.
    #expect(row.record.textToPasteAgain == row.expected)
}

// MARK: Edit watching

private typealias Reading = (value: String, cursor: Int, hasFocus: Bool, isSecure: Bool)

/// Returns its scripted readings one per read and repeats the last one.
private final class ScriptedField: WatchedField, @unchecked Sendable {
    private let lock = NSLock()
    private var script: [Reading?]
    private var count = 0
    let notifications = AsyncStream<FieldChange> { _ in }

    init(_ script: [Reading?]) { self.script = script }

    var reads: Int { lock.withLock { count } }

    func read() -> Reading? {
        lock.withLock {
            count += 1
            return script.count > 1 ? script.removeFirst() : script[0]
        }
    }
}

private let before = "Dear Sam, "
private let after = " Thanks."
private let pasted = "the meeting is at noon"
private let mailContext = DictationController.FieldContext(
    textBeforeCursor: before, selectedText: "", textAfterCursor: after, isSecure: false, app: "com.apple.mail")

private func showing(_ middle: String, secure: Bool = false) -> Reading {
    (before + middle + after, (before + middle).utf16.count, true, secure)
}

private let landedReading = showing(pasted)
private let correctedReading = showing("the meeting is at one")

private func until(_ condition: () -> Bool, sourceLocation: SourceLocation = #_sourceLocation) async {
    let ceiling = ContinuousClock.now + .seconds(10)
    while !condition() {
        if ContinuousClock.now > ceiling {
            Issue.record("condition never held", sourceLocation: sourceLocation)
            return
        }
        await Task.yield()
    }
}

struct WatchMappingCase: Sendable, CustomTestStringConvertible {
    let name: String
    let script: [(value: String, cursor: Int, hasFocus: Bool, isSecure: Bool)?]?
    let expected: DictationController.WatchStop
    var testDescription: String { name }
}

@Test(.timeLimit(.minutes(1)), arguments: [
    WatchMappingCase(
        name: "field cleared", script: [landedReading, correctedReading, ("", 0, true, false)],
        expected: .init(reason: .fieldCleared, finalText: "the meeting is at one")),
    WatchMappingCase(
        name: "became a password field", script: [landedReading, showing("", secure: true)],
        expected: .init(reason: .surroundingTextLost, finalText: nil)),
    WatchMappingCase(
        name: "no field to watch", script: nil, expected: .init(reason: .surroundingTextLost, finalText: nil)),
])
func watchOutcomeMapsToStop(_ row: WatchMappingCase) async {
    // Dropping the watcher's final text or stop reason, or saving text from a password field, turns a row red.
    let clock = ManualClock()
    let field = row.script.map(ScriptedField.init)
    let adapter = EditWatchAdapter(watcher: EditWatcher(clock: clock), context: { mailContext }, makeField: { field })
    let watch = Task { await adapter.watch(pastedText: pasted) }
    let done = Mutex(false)
    let result = Task {
        let stop = await watch.value
        done.withLock { $0 = true }
        return stop
    }
    for _ in 0..<40 where !done.withLock({ $0 }) {
        await clock.advance(by: .milliseconds(50))
    }
    #expect(await result.value == row.expected)
}

@Test(.timeLimit(.minutes(1)))
func cancelledWatchReturnsFinalTextSoFar() async {
    // Letting the caller's cancellation reach `EditWatcher.watch`, which then returns nil, turns this red.
    let clock = ManualClock()
    let field = ScriptedField([landedReading, correctedReading])
    let adapter = EditWatchAdapter(watcher: EditWatcher(clock: clock), context: { mailContext }, makeField: { field })
    let watch = Task { await adapter.watch(pastedText: pasted) }
    await until { field.reads >= 1 }
    await clock.advance(by: .milliseconds(50))
    await until { field.reads >= 2 }
    watch.cancel()
    #expect(await watch.value == .init(reason: .newDictation, finalText: "the meeting is at one"))
}

// MARK: Transcriber

private final class CountingEngine: SpeechEngine, VoiceDetecting, WordListRechecking {
    private let state = Mutex((passes: 0, wordList: [String]?.none))
    static let timings = [WordTiming(word: "hello", start: 0, end: 0.4)]

    var passes: Int { state.withLock { $0.passes } }
    var wordList: [String]? { state.withLock { $0.wordList } }

    func load(progress: @escaping @Sendable (Double) -> Void) async throws {}
    func unload() async {}

    func transcribe(_ audio: [Float]) async throws -> Transcript {
        state.withLock { $0.passes += 1 }
        return Transcript(text: "hello", wordTimings: Self.timings)
    }

    func hasSpeech(in audio: [Float]) async throws -> Bool { true }

    func hasCandidates(in transcript: Transcript, wordList: [String]) async -> Bool {
        state.withLock { $0.wordList = wordList }
        return true
    }

    func recheck(_ transcript: Transcript, audio: [Float], wordList: [String]) async -> Transcript { transcript }
}

private func settle() async {
    for _ in 0..<1000 { await Task.yield() }
}

@Test(.timeLimit(.minutes(1)))
func previewPassesStopWhenThePreviewIsNoLongerRead() async {
    // Leaving the transcriber's preview running after the controller stops reading it, as on Escape, turns this red.
    let clock = ManualClock()
    let engine = CountingEngine()
    let transcriber = Transcriber(engine: engine, voiceDetector: engine, rechecker: engine, clock: clock)
    let adapter = TranscriberAdapter(transcriber: transcriber, wordList: { [] })
    let (audio, microphone) = AsyncStream.makeStream(of: [Float].self)
    let previews = adapter.preview(audio)
    let heard = Mutex<[String]>([])
    let reader = Task { for await text in previews { heard.withLock { $0.append(text) } } }
    microphone.yield([Float](repeating: 0.1, count: 16_000))
    await settle()
    await clock.advance(by: .seconds(1))
    await until { heard.withLock { $0 } == ["hello"] }

    reader.cancel()
    await settle()
    let passes = engine.passes
    for _ in 0..<3 {
        await clock.advance(by: .seconds(1))
        await settle()
    }
    #expect(engine.passes == passes)
}

/// Records every call on the stream in the order it reached the engine.
private final class StreamCallsEngine: StreamingSpeechEngine, VoiceDetecting, WordListRechecking {
    private let state = Mutex<[String]>([])
    var calls: [String] { state.withLock { $0 } }
    private func record(_ call: String) { state.withLock { $0.append(call) } }

    func load(progress: @escaping @Sendable (Double) -> Void) async throws {}
    func unload() async {}
    func transcribe(_ audio: [Float]) async throws -> Transcript {
        record("transcribe")
        return Transcript(text: "whole", wordTimings: [])
    }
    func startStream(partial: @escaping @Sendable (String) -> Void) async throws { record("start") }
    func feed(_ chunk: [Float]) async throws { record("feed \(chunk.count)") }
    func finishStream() async throws -> Transcript {
        record("finish")
        return Transcript(text: "streamed", wordTimings: [])
    }
    func cancelStream() async { record("cancel") }
    func hasSpeech(in audio: [Float]) async throws -> Bool { true }
    func hasCandidates(in transcript: Transcript, wordList: [String]) async -> Bool { false }
    func recheck(_ transcript: Transcript, audio: [Float], wordList: [String]) async -> Transcript { transcript }
}

/// Streams two samples through the adapter's preview, then stops reading it, as the controller does on release and on Escape.
private func streamThenStopReading(_ engine: StreamCallsEngine) async -> TranscriberAdapter {
    let transcriber = Transcriber(
        engine: engine, model: .parakeetUnified, voiceDetector: engine, rechecker: engine, clock: ManualClock())
    let adapter = TranscriberAdapter(transcriber: transcriber, wordList: { [] })
    let (audio, microphone) = AsyncStream.makeStream(of: [Float].self)
    let previews = adapter.preview(audio)
    let reader = Task { for await _ in previews {} }
    microphone.yield([0.1, 0.2])
    await until { engine.calls == ["start", "feed 2"] }
    reader.cancel()
    await settle()
    return adapter
}

@Test(.timeLimit(.minutes(1)))
func releaseFinishesTheLiveStream() async throws {
    // Cancelling the stream when the preview stops being read, so the final pass re-runs the whole recording, turns this red.
    let engine = StreamCallsEngine()
    let adapter = await streamThenStopReading(engine)
    let transcript = try await adapter.transcribe(.init(samples: [0.1, 0.2, 0.3], sampleRate: 16_000))
    #expect(transcript.text == "streamed")
    #expect(engine.calls == ["start", "feed 2", "feed 1", "finish"])
}

@Test(.timeLimit(.minutes(1)))
func escapeCancelsTheLiveStream() async {
    // Leaving the stream open after Escape, or finishing it, turns this red.
    let engine = StreamCallsEngine()
    let adapter = await streamThenStopReading(engine)
    await adapter.cancel()
    await until { engine.calls.last == "cancel" }
    #expect(engine.calls == ["start", "feed 2", "cancel"])
}

@Test func finalPassUsesTheWordListAndKeepsWordTimings() async throws {
    // Not passing the settings word list to the final pass, or dropping its word timings or recheck time, turns this red.
    let engine = CountingEngine()
    let transcriber = Transcriber(engine: engine, voiceDetector: engine, rechecker: engine, clock: ManualClock())
    let adapter = TranscriberAdapter(transcriber: transcriber, wordList: { ["Fluidity"] })
    let transcript = try await adapter.transcribe(.init(samples: [0.1, 0.2], sampleRate: 16_000))
    #expect(transcript == .init(
        text: "hello", modelVersion: "parakeet-tdt-0.6b-v2", wordTimings: CountingEngine.timings, wordListRecheck: 0))
    #expect(engine.wordList == ["Fluidity"])
}

// MARK: Hotkey

private final class MemoryKeychain: KeychainStoring {
    func get() -> String? { nil }
    func set(_ value: String) {}
    func delete() {}
}

@Test func shortcutsAreSavedWithoutOverwritingEachOther() throws {
    // Saving one shortcut by writing only that key into the stored value turns this red.
    let suite = "WiringTests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    let settings = Settings(defaults: defaults, keyStore: MemoryKeychain())
    #expect(settings.dictationKey == .rightOption)

    let f5 = KeyChoice(keyCode: 96)
    let space = KeyChoice(keyCode: 49, modifiers: .option)
    settings.pasteAgainKey = f5
    settings.dictationKey = space
    #expect(settings.dictationKey == space)
    #expect(settings.pasteAgainKey == f5)
}

@Test(arguments: [
    (DictationController.Phase.ready, false),
    (.recording(.held), true),
    (.recording(.handsFree), true),
    (.finishing, true),
    (.cleaning, true),
    (.pasting, false),
    (.watching, false),
])
func escapeIsTakenOnlyWhileItCancels(_ phase: DictationController.Phase, _ takes: Bool) {
    // Swallowing Escape in a phase where `escapePressed` does nothing turns that row red: Escape stops working in other apps.
    #expect(phase.takesEscape == takes)
}

@Test(arguments: [
    (DictationController.Phase.ready, HotkeyDecision.keyDown, true),
    (.ready, .cancel, true),
    (.watching, .keyDown, true),
    (.ready, .pasteAgain, false),
    (.recording(.handsFree), .keyDown, false),
    (.recording(.held), .cancel, false),
    (.finishing, .keyDown, false),
    (.cleaning, .cancel, false),
    (.pasting, .keyDown, false),
])
func compareWindowGetsKeysOnlyBetweenDictations(_ phase: DictationController.Phase, _ decision: HotkeyDecision, _ passes: Bool) {
    // Sending the dictation key or Escape to the compare window while a dictation runs, or paste-again ever, turns that row red.
    #expect(phase.passesToCompare(decision) == passes)
}

@Test(arguments: [
    (DictationController.Phase.ready, CompareSession.Phase?.some(.listening), true),
    (.watching, .some(.listening), true),
    (.ready, .some(.idle), false),
    (.ready, nil, false),
    (.recording(.held), .some(.idle), true),
    (.pasting, .some(.listening), false),
])
func escapeIsTakenForWhicheverOwnsTheKeys(
    _ phase: DictationController.Phase, _ comparing: CompareSession.Phase?, _ takes: Bool
) {
    // Taking Escape from the compare window's phase while a dictation owns the keys, or ignoring a comparison
    // that is listening between dictations, turns that row red.
    #expect(phase.takesEscape(comparing: comparing) == takes)
}

@MainActor
@Test func pasteAgainWaitsUntilNoDictationIsRunning() async {
    // Letting paste-again run while a dictation records turns this red: it would paste over the dictation's own paste.
    let harness = ControllerHarness()
    var pastes = 0
    harness.controller.handle(.pasteAgain) { pastes += 1 }
    #expect(pastes == 1)

    await harness.pressAndHold()
    harness.controller.handle(.pasteAgain) { pastes += 1 }
    #expect(pastes == 1)
}
