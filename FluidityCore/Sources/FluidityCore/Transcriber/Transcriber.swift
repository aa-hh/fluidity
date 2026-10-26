import FluidAudio
import Foundation

/// The speech model that turns 16 kHz mono audio into text.
public protocol SpeechEngine: Sendable {
    /// Downloads the models the first time, then loads them; `progress` runs from 0 to 1.
    func load(progress: @escaping @Sendable (Double) -> Void) async throws
    func transcribe(_ audio: [Float]) async throws -> Transcript
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
}

/// Runs the live preview while recording and the final pass on release, one pass at a time on one engine.
public actor Transcriber {
    static let previewInterval: Duration = .seconds(1)

    private let engine: any SpeechEngine
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

    public init(
        engine: any SpeechEngine,
        voiceDetector: any VoiceDetecting,
        rechecker: any WordListRechecking,
        clock: any Clock<Duration> = ContinuousClock()
    ) {
        self.engine = engine
        self.voiceDetector = voiceDetector
        self.rechecker = rechecker
        self.clock = clock
    }

    /// Loads the models, downloading them on first launch; `progress` runs from 0 to 1.
    public func prepare(progress: @escaping @Sendable (Double) -> Void = { _ in }) async throws {
        try await engine.load(progress: progress)
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
        ticker = Task { [weak self, clock] in
            while true {
                do { try await clock.sleep(for: Self.previewInterval) } catch { return }
                guard let self else { return }
                await self.tick()
            }
        }
        return stream
    }

    /// Adds 16 kHz mono audio to the recording the live preview reads.
    public func append(chunk: [Float]) {
        recording.append(contentsOf: chunk)
    }

    /// Ends the live preview and runs the final pass on `recording`, which includes the tail after release.
    public func finish(recording: [Float], wordList: [String] = []) async throws -> RawTranscript {
        endPreviews()
        await runningPass?.value

        var transcript = Transcript(text: "", wordTimings: [])
        let transcriptionTime = try await clock.measure {
            transcript = try await engine.transcribe(recording)
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
            wordListRecheckTime: wordListRecheckTime
        )
    }

    /// Stops the live preview and drops the recording; nothing is transcribed.
    public func cancel() {
        endPreviews()
        recording = []
    }

    private func endPreviews() {
        ticker?.cancel()
        ticker = nil
        preview?.finish()
        preview = nil
    }

    private func tick() {
        guard runningPass == nil, let preview else { return }
        let audio = recording
        let number = recordingNumber
        runningPass = Task { await previewPass(on: audio, recordingNumber: number, preview: preview) }
    }

    private func previewPass(on audio: [Float], recordingNumber number: Int, preview: AsyncStream<String>.Continuation) async {
        defer { runningPass = nil }
        if !speechHeard {
            guard (try? await voiceDetector.hasSpeech(in: audio)) == true else { return }
            if number == recordingNumber { speechHeard = true }
        }
        // A failed preview pass is dropped; the next tick tries again.
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
