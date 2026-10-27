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
    private let supportLoads = SingleFlight()

    public init() {}

    /// FluidAudio caches the models under Application Support, so only the first launch downloads them.
    public func load(progress: @escaping @Sendable (Double) -> Void) async throws {
        // Silero takes 0.05 of the bar and TDT v2 the rest.
        try await vadLoads.run { try await self.loadVAD { progress(0.05 * $0) } }
        try await asrLoads.run { try await self.loadASR(progress: progress) }
        progress(1)
        // CTC 110M only feeds the word-list recheck, which skips until it lands, so dictation does not wait for
        // its Neural Engine compile (about 25 s whenever macOS has purged the saved one).
        Task {
            do {
                try await self.loadSupport { _ in }
            } catch {
                log.error("CTC 110M load failed: \(String(describing: error), privacy: .public)")
            }
        }
    }

    private func loadASR(progress: @escaping @Sendable (Double) -> Void) async throws {
        guard asr == nil else { return }
        let models = try await AsrModels.downloadAndLoad(version: .v2) { progress(0.05 + 0.95 * $0.fractionCompleted) }
        asr = AsrManager(config: .default, models: models)
    }

    /// Loads only Silero and CTC 110M, which every speech model needs for the voice check and the word-list recheck.
    public func loadSupport(progress: @escaping @Sendable (Double) -> Void) async throws {
        try await supportLoads.run { try await self.loadSupportOnce(progress: progress) }
    }

    private func loadSupportOnce(progress: @escaping @Sendable (Double) -> Void) async throws {
        try await vadLoads.run { try await self.loadVAD { progress(0.25 * $0) } }
        if ctc == nil {
            ctc = try await CtcModels.downloadAndLoad()
        }
        progress(1)
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
        guard let session = try? await VocabularyBoostingSession(
            vocabulary: vocabulary,
            ctcModels: ctc,
            config: VocabularyRescorer.Config(spotterRescueEnabled: false)
        ) else { return nil }
        boosting = (wordList, session)
        return session
    }
}
