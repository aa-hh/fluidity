import FluidAudio
import Foundation
import OSLog

/// Parakeet TDT v2 for every pass and Silero voice detection, from FluidAudio.
public actor FluidAudioEngine: SpeechEngine, VoiceDetecting {
    public enum EngineError: Error {
        case notLoaded
    }

    private var asr: AsrManager?
    private var vad: VadManager?
    private let asrLoads = SingleFlight()
    private let vadLoads = SingleFlight()

    public init() {}

    /// Loads Silero then Parakeet TDT v2, reporting TDT v2's download alone from 0 to 1, not its compile;
    /// FluidAudio caches the models under Application Support, so only the first launch downloads them.
    public func load(progress: @escaping @Sendable (Double) -> Void) async throws {
        try await vadLoads.run { try await self.loadVAD { _ in } }
        try await asrLoads.run { try await self.loadASR(progress: progress) }
        progress(1)
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
        let asr = AsrManager()
        try await asr.initialize(models: models)
        self.asr = asr
    }

    /// Loads Silero, which every speech model needs for the voice check.
    public func loadVoiceDetector() async throws {
        try await vadLoads.run { try await self.loadVAD { _ in } }
    }

    private func loadVAD(progress: @escaping @Sendable (Double) -> Void) async throws {
        guard vad == nil else { return }
        vad = try await VadManager(progressHandler: { progress($0.fractionCompleted) })
    }

    /// Drops Parakeet TDT v2 only; Silero stays, since every speech model uses it.
    public func unload() async {
        asr = nil
    }

    public func transcribe(_ audio: [Float]) async throws -> Transcript {
        guard let asr else { throw EngineError.notLoaded }
        return Transcript(try await asr.transcribe(audio))
    }

    public func hasSpeech(in audio: [Float]) async throws -> Bool {
        guard let vad else { throw EngineError.notLoaded }
        return try await vad.process(audio).contains { $0.isVoiceActive }
    }
}

extension Transcript {
    /// A FluidAudio Parakeet result, with word timings joined from its token timings.
    init(_ result: ASRResult) {
        var words: [WordTiming] = []
        for token in result.tokenTimings ?? [] where !token.token.isEmpty && token.token != "<blank>" && token.token != "<pad>" {
            if isWordBoundary(token.token) || words.isEmpty {
                let word = stripWordBoundaryPrefix(token.token)
                words.append(WordTiming(word: word, start: token.startTime, end: token.endTime))
            } else {
                words[words.count - 1].word += token.token
                words[words.count - 1].end = token.endTime
            }
        }
        for index in words.indices { words[index].word = words[index].word.trimmingCharacters(in: .whitespaces) }
        self.init(text: result.text, wordTimings: words.filter { !$0.word.isEmpty })
    }
}
