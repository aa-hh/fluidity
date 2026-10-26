import FluidityCore
import FluidityTestSupport
import Foundation
import Synchronization
import Testing

/// Stands in for every part `DictationController` talks to. Each test sets the state it needs.
final class FakeParts: AudioCapturing, Transcribing, CleaningUp, FieldReading, Finishing, Pasting,
    EditWatching, DictationStoring, PermissionChecking {
    struct Failure: Error {}

    struct FinalTextUpdate: Equatable {
        var finalText: String?
        var reason: WatchStopReason
        var id: UUID
    }

    struct State {
        var microphoneGranted = true
        var accessibilityGranted = true
        var audioStartFails = false
        var audioStarts = 0
        var audioStops = 0
        var previews = 0
        var previewSink: AsyncStream<String>.Continuation?
        /// Nil makes the final pass fail.
        var rawTranscript: String? = "hello world"
        var transcribeHangs = false
        var transcribeCalls = 0
        var cleanupOn = true
        /// Nil makes cleanup never answer.
        var cleanupResult: DictationController.CleanupResult? = .cleaned("Hello, world.")
        var cleanCalls = 0
        var field: DictationController.FieldContext? = FakeParts.mailField
        var pasteOutcome: DictationController.PasteOutcome = .landed
        var pasted: [String] = []
        var watched: [String] = []
        var watchEnd: CheckedContinuation<DictationController.WatchStop, Never>?
        var saved: [DictationRecord] = []
        var finalTexts: [FinalTextUpdate] = []
        var cancelledRecordings = 0
    }

    static let mailField = DictationController.FieldContext(
        textBeforeCursor: "Dear Sam, ", selectedText: "", textAfterCursor: " Thanks.", isSecure: false, app: "com.apple.mail")
    static let recording = DictationController.Recording(samples: [0.1, 0.2], sampleRate: 16_000)
    static let wordTimings = [WordTiming(word: "hello", start: 0, end: 0.4), WordTiming(word: "world", start: 0.5, end: 0.9)]

    let state: Mutex<State>
    private let clock: ManualClock

    init(clock: ManualClock, _ setUp: (inout State) -> Void) {
        var initial = State()
        setUp(&initial)
        state = Mutex(initial)
        self.clock = clock
    }

    var snapshot: State { state.withLock { $0 } }

    /// Sends live preview text, as the speech model would while recording.
    func say(_ text: String) {
        state.withLock { $0.previewSink }?.yield(text)
    }

    /// Ends the current watch as the field watcher would on its own.
    func endWatch(_ reason: WatchStopReason) {
        let waiting = state.withLock { s in
            defer { s.watchEnd = nil }
            return s.watchEnd
        }
        waiting?.resume(returning: .init(reason: reason, finalText: "edited"))
    }

    func start() async throws -> AsyncStream<[Float]> {
        let fails = state.withLock { s in
            if !s.audioStartFails { s.audioStarts += 1 }
            return s.audioStartFails
        }
        if fails { throw Failure() }
        return AsyncStream { _ in }
    }

    func stop() async -> DictationController.Recording {
        state.withLock { $0.audioStops += 1 }
        return Self.recording
    }

    func preview(_ audio: AsyncStream<[Float]>) -> AsyncStream<String> {
        let (stream, sink) = AsyncStream.makeStream(of: String.self)
        state.withLock { s in
            s.previewSink = sink
            s.previews += 1
        }
        return stream
    }

    func transcribe(_ recording: DictationController.Recording) async throws -> DictationController.Transcript {
        let (text, hangs) = state.withLock { s in
            s.transcribeCalls += 1
            return (s.rawTranscript, s.transcribeHangs)
        }
        if hangs { try await clock.sleep(for: .seconds(3600)) }
        guard let text else { throw Failure() }
        return .init(text: text, wordTimings: Self.wordTimings)
    }

    var isOn: Bool { state.withLock { $0.cleanupOn } }

    func clean(_ rawTranscript: String) async -> DictationController.CleanupResult {
        let result = state.withLock { s in
            s.cleanCalls += 1
            return s.cleanupResult
        }
        if let result { return result }
        try? await clock.sleep(for: .seconds(3600))
        return .fallback(.offline)
    }

    func read() async -> DictationController.FieldContext? { state.withLock { $0.field } }

    func finish(_ text: String, in field: DictationController.FieldContext?) -> String { text.uppercased() }

    func paste(_ text: String) async -> DictationController.PasteOutcome {
        state.withLock { s in
            s.pasted.append(text)
            return s.pasteOutcome
        }
    }

    func watch(pastedText: String) async -> DictationController.WatchStop {
        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                let cancelled = state.withLock { s in
                    s.watched.append(pastedText)
                    // Checked under the lock so a cancel that lands before the continuation is stored is not lost.
                    if Task.isCancelled { return true }
                    s.watchEnd = continuation
                    return false
                }
                if cancelled { continuation.resume(returning: .init(reason: .focusLost, finalText: "edited")) }
            }
        } onCancel: {
            // Answers with a reason other than `.newDictation`, so the controller has to supply that one itself.
            endWatch(.focusLost)
        }
    }

    func save(_ record: DictationRecord, recording: DictationController.Recording) async {
        state.withLock { $0.saved.append(record) }
    }

    func updateFinalText(_ finalText: String?, reason: WatchStopReason, for id: UUID) async {
        state.withLock { $0.finalTexts.append(.init(finalText: finalText, reason: reason, id: id)) }
    }

    func dictationCancelled(_ recording: DictationController.Recording) async {
        state.withLock { $0.cancelledRecordings += 1 }
    }

    var microphoneGranted: Bool { state.withLock { $0.microphoneGranted } }
    var accessibilityGranted: Bool { state.withLock { $0.accessibilityGranted } }
}

/// A controller wired to `FakeParts` and a `ManualClock`, with the key presses tests repeat.
@MainActor
struct ControllerHarness {
    let clock = ManualClock()
    let parts: FakeParts
    let controller: DictationController

    init(_ setUp: (inout FakeParts.State) -> Void = { _ in }) {
        parts = FakeParts(clock: clock, setUp)
        controller = DictationController(
            audio: parts, transcriber: parts, cleanup: parts, field: parts, finisher: parts, paster: parts,
            watcher: parts, store: parts, permissions: parts,
            modelVersion: "parakeet-v2", wordListVersion: "words-1", clock: clock)
    }

    func advance(_ duration: Duration) async { await clock.advance(by: duration) }

    /// Polls until the condition holds. The real-time ceiling only stops a broken test from hanging.
    func until(_ condition: () -> Bool, sourceLocation: SourceLocation = #_sourceLocation) async {
        let ceiling = ContinuousClock.now + .seconds(10)
        while !condition() {
            if ContinuousClock.now > ceiling {
                Issue.record("condition never held", sourceLocation: sourceLocation)
                return
            }
            await Task.yield()
        }
    }

    /// Gives running work a chance to act before a test checks that something did not happen.
    func settle() async {
        for _ in 0..<1000 { await Task.yield() }
    }

    /// Presses the key and waits until recording has started.
    func pressAndHold() async {
        let previews = parts.snapshot.previews
        controller.keyDown()
        await until { parts.snapshot.previews == previews + 1 }
    }

    /// Holds the key for a second, releases it and lets the 200 ms after release pass.
    func dictate() async {
        await pressAndHold()
        await release()
    }

    /// Releases the key a second after it went down and lets the 200 ms after release pass.
    func release() async {
        await advance(.seconds(1))
        controller.keyUp()
        await advance(.milliseconds(200))
    }

    func untilDone() async {
        await until { [.ready, .watching].contains(controller.phase) }
    }
}
