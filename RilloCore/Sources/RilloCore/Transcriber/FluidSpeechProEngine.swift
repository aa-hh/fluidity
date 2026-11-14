import FluidAudio
import Foundation

/// Fluid Speech Pro, from FluidVoice-Labs, run through Fluid Voice's FluidAudio. It loads from the folder its
/// download filled and never downloads: `ModelDownloads` does that.
public actor FluidSpeechProEngine: SpeechEngine {
    public enum EngineError: Error {
        case notLoaded
    }

    private let folder: URL
    private var asr: AsrManager?
    private let loads = SingleFlight()

    public init(folder: URL) {
        self.folder = folder
    }

    public func load(progress: @escaping @Sendable (Double) -> Void) async throws {
        try await loads.run { try await self.loadOnce() }
        progress(1)
    }

    private func loadOnce() async throws {
        guard asr == nil else { return }
        let models = try await AsrModels.load(from: folder, version: .fluidParakeetPro)
        let asr = AsrManager()
        try await asr.initialize(models: models)
        self.asr = asr
    }

    public func unload() async {
        asr = nil
    }

    public func transcribe(_ audio: [Float]) async throws -> Transcript {
        guard let asr else { throw EngineError.notLoaded }
        return Transcript(try await asr.transcribe(audio))
    }
}
