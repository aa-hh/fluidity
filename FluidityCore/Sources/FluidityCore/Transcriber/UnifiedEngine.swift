import AVFoundation
import FluidAudio
import Foundation

/// Parakeet Unified 0.6B at its 320 ms tier, from FluidAudio, fed chunk by chunk.
public actor UnifiedEngine: StreamingSpeechEngine {
    public enum EngineError: Error {
        case notLoaded
    }

    private var manager: StreamingUnifiedAsrManager?

    public init() {}

    /// FluidAudio caches the model under Application Support, so only the first load downloads it.
    public func load(progress: @escaping @Sendable (Double) -> Void) async throws {
        if manager != nil {
            progress(1)
            return
        }
        let manager = StreamingUnifiedAsrManager(config: StreamingModelVariant.parakeetUnified320ms.unifiedConfig!)
        try await manager.loadModels(to: nil, progressHandler: { progress($0.fractionCompleted) })
        // One second of near-silence warms the model, so the first dictation is not slowed by it.
        try await manager.appendAudio(pcm([Float](repeating: 0.001, count: 16000)))
        _ = try await manager.finish()
        try await manager.reset()
        self.manager = manager
        progress(1)
    }

    public func unload() async {
        await manager?.cleanup()
        manager = nil
    }

    public func startStream(partial: @escaping @Sendable (String) -> Void) async throws {
        guard let manager else { throw EngineError.notLoaded }
        try await manager.reset()
        await manager.setPartialTranscriptCallback(partial)
    }

    public func feed(_ chunk: [Float]) async throws {
        guard let manager else { throw EngineError.notLoaded }
        try await manager.appendAudio(pcm(chunk))
        try await manager.processBufferedAudio()
    }

    public func finishStream() async throws -> Transcript {
        guard let manager else { throw EngineError.notLoaded }
        let text = try await manager.finish()
        // Word and token timings drain the same buffer, so the words are built from the one read of the tokens.
        let tokens = await manager.consumeTokenTimings()
        let words = buildWordTimings(from: tokens).map {
            WordTiming(word: $0.word, start: $0.startTime, end: $0.endTime)
        }
        return Transcript(text: text, wordTimings: words, tokenTimings: tokens)
    }

    public func cancelStream() async {
        try? await manager?.reset()
    }

    public func transcribe(_ audio: [Float]) async throws -> Transcript {
        try await startStream { _ in }
        try await feed(audio)
        return try await finishStream()
    }
}

private let format16k = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false)!

/// Wraps 16 kHz mono samples in the buffer FluidAudio's streaming managers take.
private func pcm(_ samples: [Float]) -> AVAudioPCMBuffer {
    let buffer = AVAudioPCMBuffer(pcmFormat: format16k, frameCapacity: AVAudioFrameCount(samples.count))!
    buffer.frameLength = AVAudioFrameCount(samples.count)
    samples.withUnsafeBufferPointer { buffer.floatChannelData![0].update(from: $0.baseAddress!, count: samples.count) }
    return buffer
}
