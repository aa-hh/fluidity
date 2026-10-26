@preconcurrency import AVFoundation
import FluidAudio
import Foundation

/// The real microphone: an input node tap converted to 16 kHz mono with FluidAudio's `AudioConverter`.
public final class AVAudioEngineInput: AudioInput, @unchecked Sendable {
    public enum Failure: Error { case noInputDevice }

    private let lock = NSLock()
    private var engine: AVAudioEngine?
    private var observer: (any NSObjectProtocol)?
    private let converter = AudioConverter()

    public init() {}

    public func start(_ handler: @escaping @Sendable (AudioInputEvent) -> Void) throws {
        let engine = AVAudioEngine()
        let node = engine.inputNode
        // The model and retraining both get raw audio: no echo cancellation, noise suppression or gain control.
        try node.setVoiceProcessingEnabled(false)
        let format = node.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else { throw Failure.noInputDevice }

        let converter = converter
        node.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, _ in
            guard let samples = try? converter.resampleBuffer(buffer), !samples.isEmpty else { return }
            handler(.samples(samples))
        }
        let observer = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange, object: engine, queue: nil
        ) { [weak self] _ in
            self?.stop()
            handler(.lost)
        }
        lock.withLock {
            self.engine = engine
            self.observer = observer
        }
        engine.prepare()
        do {
            try engine.start()
        } catch {
            stop()
            throw error
        }
    }

    public func stop() {
        let (engine, observer) = lock.withLock {
            defer { self.engine = nil; self.observer = nil }
            return (self.engine, self.observer)
        }
        if let observer { NotificationCenter.default.removeObserver(observer) }
        engine?.inputNode.removeTap(onBus: 0)
        engine?.stop()
    }
}
