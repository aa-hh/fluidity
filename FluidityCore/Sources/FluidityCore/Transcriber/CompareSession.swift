import Foundation

/// Two models transcribing the same speech at once, for the compare window: one shared recording fans out
/// to one `Transcriber` per column. Nothing is pasted or saved.
@MainActor
@Observable
public final class CompareSession {
    public enum Phase: Equatable, Sendable { case idle, listening, finishing, finished }
    public enum Column: Hashable, Sendable { case left, right }

    public struct CompareResult: Sendable {
        public var leftFinal: RawTranscript
        public var rightFinal: RawTranscript
        public var differences: [TranscriptDiff.Difference]
    }

    public private(set) var left: SpeechModelID = .parakeetTDTv2
    public private(set) var right: SpeechModelID = .appleBuiltIn
    public private(set) var phase: Phase = .idle
    /// Each column's newest live words while listening, or while the live words are replayed.
    public private(set) var liveText: [Column: String] = [:]
    public private(set) var result: CompareResult?
    /// The last finished recording, 16 kHz mono, for Play Recording.
    public private(set) var recording: [Float] = []
    public private(set) var isReplaying = false
    /// Whether both columns can transcribe now; `start` does nothing while it says no. The app shell sets it.
    @ObservationIgnored public var canStart: () -> Bool = { true }

    private let audio: any AudioCapturing
    private let makeTranscriber: (SpeechModelID) -> Transcriber
    private let clock: any Clock<Duration>
    private var transcribers: (left: Transcriber, right: Transcriber)?
    /// The microphone's start; nil when it failed. Stopping waits for it, or the shared capture would stay on.
    private var starting: Task<AsyncStream<[Float]>?, Never>?
    /// Feeds the microphone's chunks to both transcribers until the recording ends.
    private var feeding: Task<Void, Never>?
    /// The last discard's stop of the microphone, which the next start waits for.
    private var discarding: Task<Void, Never>?
    /// Each column's live words with when they arrived, measured from the start of the recording.
    private var partials: [Column: [(at: Duration, text: String)]] = [:]
    private var elapsed: @Sendable () -> Duration = { .zero }
    private var replay: Task<Void, Never>?

    public init(
        audio: any AudioCapturing,
        makeTranscriber: @escaping (SpeechModelID) -> Transcriber,
        clock: any Clock<Duration> = ContinuousClock()
    ) {
        self.audio = audio
        self.makeTranscriber = makeTranscriber
        self.clock = clock
    }

    /// Ignored when the other column already holds `model`, or while a recording runs.
    public func choose(left model: SpeechModelID) {
        guard model != right, phase != .listening, phase != .finishing else { return }
        left = model
        clearResult()
    }

    public func choose(right model: SpeechModelID) {
        guard model != left, phase != .listening, phase != .finishing else { return }
        right = model
        clearResult()
    }

    /// Sets both columns at once, so a swapped pair is not refused halfway; ignored when the two are equal.
    public func choose(left newLeft: SpeechModelID, right newRight: SpeechModelID) {
        guard newLeft != newRight, phase != .listening, phase != .finishing else { return }
        left = newLeft
        right = newRight
        clearResult()
    }

    /// Starts recording into both columns.
    public func start() {
        guard phase == .idle || phase == .finished, canStart() else { return }
        stopReplay()
        result = nil
        recording = []
        liveText = [.left: "", .right: ""]
        partials = [.left: [], .right: []]
        let pair = (left: makeTranscriber(left), right: makeTranscriber(right))
        transcribers = pair
        elapsed = clock.stopwatch()
        phase = .listening
        let audio = audio, discarded = discarding
        let starting = Task { () -> AsyncStream<[Float]>? in
            await discarded?.value
            return try? await audio.start()
        }
        self.starting = starting
        feeding = Task {
            guard let chunks = await starting.value else {
                if phase == .listening { phase = .idle }
                return
            }
            let leftPreview = await pair.left.startRecording()
            let rightPreview = await pair.right.startRecording()
            Task { for await text in leftPreview { self.receive(text, in: .left) } }
            Task { for await text in rightPreview { self.receive(text, in: .right) } }
            for await chunk in chunks {
                await pair.left.append(chunk: chunk)
                await pair.right.append(chunk: chunk)
            }
        }
    }

    /// Ends the recording and runs both final passes.
    public func stop() async {
        guard phase == .listening, let pair = transcribers else { return }
        phase = .finishing
        guard await starting?.value != nil else {
            transcribers = nil
            phase = .idle
            return
        }
        let samples = await audio.stop().samples
        await feeding?.value
        async let leftFinal = pair.left.finish(recording: samples)
        async let rightFinal = pair.right.finish(recording: samples)
        do {
            let (a, b) = try await (leftFinal, rightFinal)
            result = CompareResult(leftFinal: a, rightFinal: b, differences: TranscriptDiff.differences(a.text, b.text))
            recording = samples
            phase = .finished
        } catch {
            phase = .idle
        }
        transcribers = nil
    }

    /// Ends the recording and drops it; nothing is transcribed.
    public func discard() {
        guard phase == .listening, let pair = transcribers else { return }
        transcribers = nil
        liveText = [:]
        phase = .idle
        let feeding = feeding, starting = starting, audio = audio
        discarding = Task {
            if await starting?.value != nil { _ = await audio.stop() }
            await feeding?.value
            await pair.left.cancel()
            await pair.right.cancel()
        }
    }

    /// Waits until the last discard has stopped the microphone and both engines have ended their streams.
    public func discarded() async {
        await discarding?.value
    }

    /// The dictation key while the compare window is open: a press starts or stops, Escape while listening
    /// discards. Key up is ignored, so holding the key does not end the recording on release.
    public func handle(_ decision: HotkeyDecision) {
        switch decision {
        case .keyDown:
            if phase == .listening {
                Task { await stop() }
            } else {
                start()
            }
        case .cancel:
            discard()
        case .keyUp, .pasteAgain, .ignore, .passThrough:
            break
        }
    }

    /// Plays each column's live words again at half speed, from empty, on the times they first arrived.
    public func replayLiveWords() {
        guard phase == .finished else { return }
        stopReplay()
        isReplaying = true
        liveText = [.left: "", .right: ""]
        let columns = partials
        replay = Task {
            let runs = columns.map { column, words in Task { await self.replay(words, in: column) } }
            await withTaskCancellationHandler {
                for run in runs { await run.value }
            } onCancel: {
                for run in runs { run.cancel() }
            }
            if !Task.isCancelled { isReplaying = false }
        }
    }

    private func replay(_ words: [(at: Duration, text: String)], in column: Column) async {
        var shown = Duration.zero
        for word in words {
            do { try await clock.sleep(for: (word.at - shown) * 2) } catch { return }
            shown = word.at
            liveText[column] = word.text
        }
    }

    private func receive(_ text: String, in column: Column) {
        guard phase == .listening else { return }
        liveText[column] = text
        partials[column, default: []].append((elapsed(), text))
    }

    private func clearResult() {
        stopReplay()
        result = nil
        if phase == .finished { phase = .idle }
    }

    private func stopReplay() {
        replay?.cancel()
        replay = nil
        isReplaying = false
    }
}

private extension Clock where Duration == Swift.Duration {
    /// Time since this call, read later without knowing the clock's instant type.
    func stopwatch() -> @Sendable () -> Swift.Duration {
        let start = now
        return { start.duration(to: self.now) }
    }
}
