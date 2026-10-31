import FluidAudio
import Foundation
import OSLog

private let log = Logger(subsystem: "com.fluidity.app", category: "models")

/// Parakeet TDT v2 for every pass, Silero voice detection, and the Parakeet CTC 110M word-list recheck, from FluidAudio.
public actor FluidAudioEngine: SpeechEngine, VoiceDetecting, WordListRechecking {
    public enum EngineError: Error {
        case notLoaded
    }

    private var asr: AsrManager?
    private var vad: VadManager?
    private var ctc: CtcModels?
    private var boosting: (wordList: [String], session: VocabularyBoostingSession)?
    private let asrLoads = SingleFlight()
    private let vadLoads = SingleFlight()
    private let ctcLoads = SingleFlight()

    public init() {}

    /// Loads Silero then Parakeet TDT v2, reporting TDT v2's download alone from 0 to 1, not its compile;
    /// FluidAudio caches the models under Application Support, so only the first launch downloads them.
    public func load(progress: @escaping @Sendable (Double) -> Void) async throws {
        try await vadLoads.run { try await self.loadVAD { _ in } }
        try await asrLoads.run { try await self.loadASR(progress: progress) }
        progress(1)
        // CTC 110M only feeds the word-list recheck, which skips until it lands, so dictation does not wait for
        // its Neural Engine compile (about 25 s whenever macOS has purged the saved one).
        Task {
            do {
                try await self.loadWordCheck()
            } catch {
                log.error("CTC 110M load failed: \(String(describing: error), privacy: .public)")
            }
        }
    }

    /// FluidAudio counts each model file's download as 0 to 0.5 of its fraction and the compile as 0.5 to 1.
    private static let downloadPhaseWeight = 0.5

    private func loadASR(progress: @escaping @Sendable (Double) -> Void) async throws {
        guard asr == nil else { return }
        // FluidAudio restarts its fraction for every model file, so send the highest download value so far:
        // the first-run window's bar reads it and must never move back.
        let downloaded = OSAllocatedUnfairLock(initialState: 0.0)
        let models = try await AsrModels.downloadAndLoad(version: .v2) { report in
            downloaded.withLock { last in
                switch report.phase {
                case .downloading: last = max(last, min(1, report.fractionCompleted / Self.downloadPhaseWeight))
                case .compiling: last = 1
                case .listing: break
                }
                progress(last)
            }
        }
        asr = AsrManager(config: .default, models: models)
    }

    /// Loads Silero, which every speech model needs for the voice check.
    public func loadVoiceDetector() async throws {
        try await vadLoads.run { try await self.loadVAD { _ in } }
    }

    /// Loads CTC 110M, which every speech model needs for the word-list recheck.
    public func loadWordCheck() async throws {
        try await ctcLoads.run { try await self.loadCTC() }
    }

    private func loadCTC() async throws {
        if ctc == nil { ctc = try await CtcModels.downloadAndLoad() }
    }

    private func loadVAD(progress: @escaping @Sendable (Double) -> Void) async throws {
        guard vad == nil else { return }
        vad = try await VadManager(progressHandler: { progress($0.fractionCompleted) })
    }

    /// Drops Parakeet TDT v2 only; Silero and CTC stay, since every speech model uses them.
    public func unload() async {
        asr = nil
    }

    public func transcribe(_ audio: [Float]) async throws -> Transcript {
        guard let asr else { throw EngineError.notLoaded }
        var decoderState = TdtDecoderState.make(decoderLayers: await asr.decoderLayerCount)
        let result = try await asr.transcribe(audio, decoderState: &decoderState)
        let tokens = result.tokenTimings ?? []
        let words = buildWordTimings(from: tokens).map {
            WordTiming(word: $0.word, start: $0.startTime, end: $0.endTime)
        }
        return Transcript(text: result.text, wordTimings: words, tokenTimings: tokens)
    }

    public func hasSpeech(in audio: [Float]) async throws -> Bool {
        guard let vad else { throw EngineError.notLoaded }
        return try await vad.process(audio).contains { $0.isVoiceActive }
    }

    public func hasCandidates(in transcript: Transcript, wordList: [String]) async -> Bool {
        guard let session = await session(for: wordList) else { return false }
        return session.hasCTCRescoringCandidates(text: transcript.text, tokenTimings: transcript.tokenTimings)
    }

    public func recheck(_ transcript: Transcript, audio: [Float], wordList: [String]) async -> Transcript {
        guard let session = await session(for: wordList),
              let output = await session.rescore(
                  text: transcript.text, tokenTimings: transcript.tokenTimings, audioSamples: audio),
              output.wasModified
        else { return transcript }

        // Word timings follow the new words only when the recheck swapped words one for one.
        var wordTimings = transcript.wordTimings
        let words = output.text.split(separator: " ")
        if words.count == wordTimings.count {
            for index in wordTimings.indices { wordTimings[index].word = String(words[index]) }
        }
        return Transcript(text: output.text, wordTimings: wordTimings, tokenTimings: transcript.tokenTimings)
    }

    /// The boosting session for this word list, rebuilt only when the list changes.
    private func session(for wordList: [String]) async -> VocabularyBoostingSession? {
        if let boosting, boosting.wordList == wordList { return boosting.session }
        guard let ctc else { return nil }
        let vocabulary = CustomVocabularyContext(terms: wordList.map { CustomVocabularyTerm(text: $0) })
        // With spotter rescue on, the candidate check says yes to every list of 10 terms or fewer, and false replacements rise.
        // Terms under 5 tokens get a smaller boost, so a short name ("Sonos") can't replace a word heard right ("sounds").
        guard let session = try? await VocabularyBoostingSession(
            vocabulary: vocabulary,
            ctcModels: ctc,
            config: VocabularyRescorer.Config(shortTermCbwTaperPivot: 5, spotterRescueEnabled: false)
        ) else { return nil }
        boosting = (wordList, session)
        return session
    }
}
