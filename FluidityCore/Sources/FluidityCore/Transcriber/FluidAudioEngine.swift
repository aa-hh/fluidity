import FluidAudio
import Foundation

/// Parakeet TDT v2 for every pass, Silero voice detection, and the Parakeet CTC 110M word-list recheck, from FluidAudio.
public actor FluidAudioEngine: SpeechEngine, VoiceDetecting, WordListRechecking {
    public enum EngineError: Error {
        case notLoaded
    }

    private var asr: AsrManager?
    private var vad: VadManager?
    private var ctc: CtcModels?
    private var boosting: (wordList: [String], session: VocabularyBoostingSession)?

    public init() {}

    /// FluidAudio caches the models under Application Support, so only the first launch downloads them.
    public func load(progress: @escaping @Sendable (Double) -> Void) async throws {
        // Silero takes 0.05 of the bar, CTC 0.15 and TDT v2 the last 0.8.
        try await loadSupport { progress(0.2 * $0) }
        if asr == nil {
            let models = try await AsrModels.downloadAndLoad(version: .v2) { progress(0.2 + 0.8 * $0.fractionCompleted) }
            asr = AsrManager(config: .default, models: models)
        }
        progress(1)
    }

    /// Loads only Silero and CTC 110M, which every speech model needs for the voice check and the word-list recheck.
    public func loadSupport(progress: @escaping @Sendable (Double) -> Void) async throws {
        if vad == nil {
            vad = try await VadManager(progressHandler: { progress(0.25 * $0.fractionCompleted) })
        }
        if ctc == nil {
            ctc = try await CtcModels.downloadAndLoad()
        }
        progress(1)
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
