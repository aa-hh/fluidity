import FluidAudio
import Foundation

/// The speech model that turns 16 kHz mono audio into text.
public protocol SpeechEngine: Sendable {
    /// Downloads the models the first time, then loads them; `progress` runs from 0 to 1.
    func load(progress: @escaping @Sendable (Double) -> Void) async throws
    func transcribe(_ audio: [Float]) async throws -> Transcript
    /// Frees the model's memory; the next `load` loads it again.
    func unload() async
}

/// A speech engine that listens as audio arrives and reports its own partial text, instead of re-running whole passes.
public protocol StreamingSpeechEngine: SpeechEngine {
    func startStream(partial: @escaping @Sendable (String) -> Void) async throws
    func feed(_ chunk: [Float]) async throws
    func finishStream() async throws -> Transcript
    func cancelStream() async
}

/// Voice detection over 16 kHz mono audio.
public protocol VoiceDetecting: Sendable {
    /// Whether any speech has been heard in this audio.
    func hasSpeech(in audio: [Float]) async throws -> Bool
}

/// The word-list recheck: swaps in terms from the user's word list where the audio supports them.
public protocol WordListRechecking: Sendable {
    /// A cheap check for whether any word in the transcript could be a word-list term.
    func hasCandidates(in transcript: Transcript, wordList: [String]) async -> Bool
    func recheck(_ transcript: Transcript, audio: [Float], wordList: [String]) async -> Transcript
}

/// One pass of the speech model over a recording.
public struct Transcript: Sendable {
    public var text: String
    public var wordTimings: [WordTiming]
    /// The speech model's own token timings, which the word-list recheck needs.
    var tokenTimings: [TokenTiming]

    public init(text: String, wordTimings: [WordTiming]) {
        self.init(text: text, wordTimings: wordTimings, tokenTimings: [])
    }

    init(text: String, wordTimings: [WordTiming], tokenTimings: [TokenTiming]) {
        self.text = text
        self.wordTimings = wordTimings
        self.tokenTimings = tokenTimings
    }
}

/// The raw transcript of a finished recording, with what each stage cost.
public struct RawTranscript: Sendable {
    public var text: String
    public var wordTimings: [WordTiming]
    /// Seconds the final pass took.
    public var transcriptionTime: TimeInterval
    /// Seconds the candidate check and the recheck took together; nil when the recheck did not run.
    public var wordListRecheckTime: TimeInterval?
    /// The model the final pass ran on.
    public var model: SpeechModelID
}

/// Runs the live preview while recording and the final pass on release, one pass at a time on one engine.
public actor Transcriber {
    /// The pause after each preview pass, or each voice check, before the next one.
    static let previewGap: Duration = .milliseconds(250)

    private var engine: any SpeechEngine
    private var model: SpeechModelID
    private let voiceDetector: any VoiceDetecting
    private let rechecker: any WordListRechecking
    private let clock: any Clock<Duration>

    private var recording: [Float] = []
    private var recordingNumber = 0
    private var speechHeard = false
    private var preview: AsyncStream<String>.Continuation?
    private var ticker: Task<Void, Never>?
    /// The preview pass on the engine, possibly left over from a recording that already ended.
    private var runningPass: Task<Void, Never>?
    /// Set while a final pass or its recheck is on the engine; a new recording's preview passes wait until it clears.
    private var finalPassRunning = false
    /// The model load `prepare` started. The final pass waits for it, so a dictation made just after launch is not lost.
    private var loading: Task<Void, any Error>?
    /// The streaming engine the current recording is fed to, until `finish` or `cancel` takes it.
    private var stream: (any StreamingSpeechEngine)?
    /// The chain of `startStream`, `feed` and `cancelStream` calls, so they reach the engine in order.
    private var feeder: Task<Void, Never>?
    /// Samples of the recording the feeder chain has been given.
    private var fedSamples = 0
    /// Bumped by each `switchEngine`, so an older switch still waiting gives up.
    private var switchNumber = 0
    private var switchWaiters: [CheckedContinuation<Void, Never>] = []

    public init(
        engine: any SpeechEngine,
        model: SpeechModelID = .parakeetTDTv2,
        voiceDetector: any VoiceDetecting,
        rechecker: any WordListRechecking,
        clock: any Clock<Duration> = ContinuousClock()
    ) {
        self.engine = engine
        self.model = model
        self.voiceDetector = voiceDetector
        self.rechecker = rechecker
        self.clock = clock
    }

    /// Loads the models, downloading them on first launch; `progress` runs from 0 to 1.
    public func prepare(progress: @escaping @Sendable (Double) -> Void = { _ in }) async throws {
        let load = Task { [engine] in try await engine.load(progress: progress) }
        loading = load
        try await load.value
    }

    /// Loads `newEngine`, waits until no recording or final pass is running, then dictates with it from the next
    /// recording on. Returns the engine it replaced, still loaded. A newer switch makes this one throw
    /// `CancellationError`; a failed load throws and keeps the current engine.
    public func switchEngine(to newEngine: any SpeechEngine, model newModel: SpeechModelID) async throws -> any SpeechEngine {
        switchNumber += 1
        let number = switchNumber
        wakeSwitches()
        try await newEngine.load(progress: { _ in })
        while preview != nil || finalPassRunning || runningPass != nil {
            guard number == switchNumber else { throw CancellationError() }
            await withCheckedContinuation { switchWaiters.append($0) }
        }
        guard number == switchNumber else { throw CancellationError() }
        let old = engine
        engine = newEngine
        model = newModel
        return old
    }

    /// Starts a recording and returns its live preview, which ends on `finish` or `cancel`.
    @discardableResult
    public func startRecording() -> AsyncStream<String> {
        endPreviews()
        recording = []
        speechHeard = false
        recordingNumber += 1
        let (stream, continuation) = AsyncStream.makeStream(of: String.self, bufferingPolicy: .bufferingNewest(1))
        preview = continuation
        if let streaming = engine as? any StreamingSpeechEngine {
            // Streaming engines report their own partials and need no voice check.
            self.stream = streaming
            fedSamples = 0
            let previous = feeder
            feeder = Task {
                await previous?.value
                try? await streaming.startStream { continuation.yield($0) }
            }
            return stream
        }
        let ticker = Task { [weak self, clock] in
            while true {
                do { try await clock.sleep(for: Self.previewGap) } catch { return }
                guard let self else { return }
                await self.step()
            }
        }
        self.ticker = ticker
        // Stops the passes as soon as nobody reads the preview, without waiting for `cancel` to reach this actor.
        continuation.onTermination = { _ in ticker.cancel() }
        return stream
    }

    /// Adds 16 kHz mono audio to the recording the live preview reads.
    public func append(chunk: [Float]) {
        recording.append(contentsOf: chunk)
        guard let stream else { return }
        let previous = feeder
        feeder = Task {
            await previous?.value
            try? await stream.feed(chunk)
            fedSamples += chunk.count
        }
    }

    /// Ends the live preview and runs the final pass on `recording`, which includes the tail after release.
    public func finish(recording: [Float], wordList: [String] = []) async throws -> RawTranscript {
        endPreviews()
        // Set before the first wait, so a switch cannot swap the engine under this final pass.
        finalPassRunning = true
        defer {
            finalPassRunning = false
            wakeSwitches()
        }
        _ = await loading?.result
        while let pass = runningPass { await pass.value }

        let streaming = stream
        stream = nil
        var transcript = Transcript(text: "", wordTimings: [])
        let transcriptionTime = try await clock.measure {
            if let streaming {
                await feeder?.value
                if fedSamples < recording.count { try await streaming.feed(Array(recording[fedSamples...])) }
                transcript = try await streaming.finishStream()
            } else {
                transcript = try await engine.transcribe(recording)
            }
        }

        var wordListRecheckTime: TimeInterval?
        if !wordList.isEmpty {
            var rechecked = false
            let elapsed = await clock.measure {
                guard await rechecker.hasCandidates(in: transcript, wordList: wordList) else { return }
                transcript = await rechecker.recheck(transcript, audio: recording, wordList: wordList)
                rechecked = true
            }
            if rechecked { wordListRecheckTime = elapsed.seconds }
        }

        return RawTranscript(
            text: transcript.text,
            wordTimings: transcript.wordTimings,
            transcriptionTime: transcriptionTime.seconds,
            wordListRecheckTime: wordListRecheckTime,
            model: model
        )
    }

    /// Stops the live preview and drops the recording; nothing is transcribed.
    public func cancel() {
        endPreviews()
        recording = []
        if let streaming = stream {
            stream = nil
            let previous = feeder
            feeder = Task {
                await previous?.value
                await streaming.cancelStream()
            }
        }
        wakeSwitches()
    }

    /// Lets every waiting switch check again whether the engine is free.
    private func wakeSwitches() {
        let waiting = switchWaiters
        switchWaiters = []
        for waiter in waiting { waiter.resume() }
    }

    private func endPreviews() {
        ticker?.cancel()
        ticker = nil
        preview?.finish()
        preview = nil
    }

    /// One preview iteration: waits for a pass left over from an earlier recording, then runs and awaits one pass.
    private func step() async {
        if let leftover = runningPass { await leftover.value }
        guard !Task.isCancelled, runningPass == nil, !finalPassRunning, let preview else { return }
        let audio = recording
        let number = recordingNumber
        let pass = Task { await previewPass(on: audio, recordingNumber: number, preview: preview) }
        runningPass = pass
        await pass.value
    }

    private func previewPass(on audio: [Float], recordingNumber number: Int, preview: AsyncStream<String>.Continuation) async {
        defer {
            runningPass = nil
            wakeSwitches()
        }
        if !speechHeard {
            guard (try? await voiceDetector.hasSpeech(in: audio)) == true else { return }
            if number == recordingNumber { speechHeard = true }
        }
        // A failed preview pass is dropped; the next pass tries again.
        if let text = try? await engine.transcribe(audio).text {
            preview.yield(text)
        }
    }
}

extension Duration {
    var seconds: TimeInterval {
        let (seconds, attoseconds) = components
        return TimeInterval(seconds) + TimeInterval(attoseconds) * 1e-18
    }
}
