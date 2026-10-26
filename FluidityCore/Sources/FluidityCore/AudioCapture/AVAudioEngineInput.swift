@preconcurrency import AVFoundation
import FluidAudio
import Foundation
import os

private let log = Logger(subsystem: "com.fluidity.app", category: "audio")

private final class TapTally: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0
    func next() -> Int { lock.withLock { count += 1; return count } }
}

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
        log.notice("input start: \(format.sampleRate, privacy: .public) Hz, \(format.channelCount, privacy: .public) ch")
        guard format.sampleRate > 0, format.channelCount > 0 else {
            log.error("input start: no input device (format \(format.sampleRate, privacy: .public) Hz)")
            throw Failure.noInputDevice
        }

        let converter = converter
        let tally = TapTally()
        node.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, _ in
            let n = tally.next()
            do {
                let samples = try converter.resampleBuffer(buffer)
                if n <= 60 ? n % 10 == 0 || n == 1 : n % 100 == 0 {
                    var peak: Float = 0
                    if let ch = buffer.floatChannelData?[0] {
                        for i in 0..<Int(buffer.frameLength) where abs(ch[i]) > peak { peak = abs(ch[i]) }
                    }
                    let outPeak = samples.reduce(Float(0)) { max($0, abs($1)) }
                    log.notice("tap buffer \(n, privacy: .public): \(buffer.frameLength, privacy: .public) frames -> \(samples.count, privacy: .public) samples, inPeak=\(peak, privacy: .public) outPeak=\(outPeak, privacy: .public)")
                }
                guard !samples.isEmpty else { return }
                handler(.samples(samples))
            } catch {
                if n <= 3 || n % 200 == 0 {
                    log.error("tap buffer \(n, privacy: .public): resample failed: \(String(describing: error), privacy: .public)")
                }
            }
        }
        let observer = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange, object: engine, queue: nil
        ) { [weak self] _ in
            log.error("configuration change: engine running=\(engine.isRunning, privacy: .public); stopping input")
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
            log.notice("engine started, running=\(engine.isRunning, privacy: .public)")
        } catch {
            log.error("engine.start failed: \(String(describing: error), privacy: .public)")
            stop()
            throw error
        }
    }

    public func stop() {
        let (engine, observer) = lock.withLock {
            defer { self.engine = nil; self.observer = nil }
            return (self.engine, self.observer)
        }
        log.notice("input stop: engine \(engine == nil ? "absent" : "present", privacy: .public)")
        if let observer { NotificationCenter.default.removeObserver(observer) }
        engine?.inputNode.removeTap(onBus: 0)
        engine?.stop()
    }
}
