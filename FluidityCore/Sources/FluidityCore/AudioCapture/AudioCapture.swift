import Foundation
import Synchronization
import os

private let log = Logger(subsystem: "com.fluidity.app", category: "audio")

/// One dictation's audio: 16 kHz mono Float32, from the silent lead-in to the end of the tail.
public struct AudioRecording: Equatable, Sendable {
    public var samples: [Float]
    public var duration: TimeInterval { Double(samples.count) / Double(AudioCapture.sampleRate) }

    public init(samples: [Float]) { self.samples = samples }
}

public enum AudioCaptureEvent: Equatable, Sendable {
    /// The microphone has delivered only all-zero buffers for 5 s of this recording.
    case silentFor5s
    /// The recording has reached 19 minutes.
    case limitNear
    /// The recording reached 20 minutes and has ended; call `stop()` to collect it.
    case limitReached
    /// The device changed, went away or stopped delivering audio; the recording has ended with what it had. Call `stop()` to collect it.
    case inputLost
}

public enum AudioCaptureError: Error, Equatable {
    /// `start()` was called before the previous recording was collected with `stop()`.
    case alreadyRecording
}

/// Records dictations from an `AudioInput`: 300 ms of silent lead-in, a 200 ms tail, a 19/20 minute limit
/// and a dead-microphone check. The input runs only from `start()` until the recording is collected.
/// Sample counts decide the tail and limits; the clock decides only how long the tail may take.
public final class AudioCapture: Sendable {
    public static let sampleRate = 16_000
    /// Silence before the first audio, so the speech model has a lead-in before the first word.
    /// Audio from before the key press would need the microphone open all the time.
    static let leadInSamples = sampleRate * 3 / 10
    static let tailSamples = sampleRate / 5
    static let silenceSamples = sampleRate * 5
    static let limitNearSamples = sampleRate * 60 * 19
    static let limitSamples = sampleRate * 60 * 20
    /// If the tail's audio has not arrived by then, stop returns what it has.
    static let tailCeiling = Duration.seconds(1)

    /// Silence, limit and lost-input warnings, for as long as this object lives.
    public let events: AsyncStream<AudioCaptureEvent>

    private let input: any AudioInput
    private let clock: any Clock<Duration>
    private let eventSink: AsyncStream<AudioCaptureEvent>.Continuation
    /// Held across `input.start()` and `input.stop()`, which must never run under `state`'s lock.
    private let control = Mutex(())
    private let state = Mutex(State())

    private struct Recording {
        var samples: [Float]
        let chunks: AsyncStream<[Float]>.Continuation
        var zeroRun = 0
        var silenceReported = false
        var limitNearReported = false
        var ended = false
        var tailEnd: Int?
        var stopWaiter: CheckedContinuation<Void, Never>?
        var firstAudioLogged = false
    }

    private struct State {
        var running = false
        var inputGeneration = 0
        var recording: Recording?
    }

    public init(input: any AudioInput, clock: any Clock<Duration> = ContinuousClock()) {
        self.input = input
        self.clock = clock
        (events, eventSink) = AsyncStream.makeStream()
    }

    /// Starts the input and a recording, and returns its audio as it arrives, beginning with the silent lead-in.
    /// The stream finishes when the recording ends.
    public func start() throws -> AsyncStream<[Float]> {
        try control.withLock { _ throws(any Error) in
            let (stream, chunks) = AsyncStream<[Float]>.makeStream()
            let generation = try state.withLock { s throws(AudioCaptureError) -> Int in
                guard s.recording == nil else { throw .alreadyRecording }
                let leadIn = [Float](repeating: 0, count: Self.leadInSamples)
                chunks.yield(leadIn)
                s.recording = Recording(samples: leadIn, chunks: chunks)
                s.running = true
                s.inputGeneration += 1
                return s.inputGeneration
            }
            log.notice("capture start")
            do {
                try input.start { [weak self] event in self?.receive(event, generation: generation) }
            } catch {
                log.error("capture start: input.start threw \(String(describing: error), privacy: .public)")
                state.withLock { s in
                    s.running = false
                    s.recording = nil
                }
                chunks.finish()
                throw error
            }
            return stream
        }
    }

    /// Ends the recording after 200 ms more audio, stops the input and returns all of it. Returns at once if the
    /// recording already ended on a limit or lost input, and returns an empty recording if none was started.
    nonisolated(nonsending) public func stop() async -> AudioRecording {
        // Marks the release point before the first suspension, so audio arriving after this call is the tail.
        let ceiling: Task<Void, Never>? = state.withLock { s in
            guard let r = s.recording, !r.ended, r.tailEnd == nil else { return nil }
            s.recording?.tailEnd = r.samples.count + Self.tailSamples
            return after(Self.tailCeiling) { [weak self] in
                self?.state.withLock { s in self?.endRecording(&s) }
            }
        }
        if let ceiling {
            await withCheckedContinuation { continuation in
                state.withLock { s in
                    if let r = s.recording, !r.ended {
                        s.recording?.stopWaiter = continuation
                    } else {
                        continuation.resume()
                    }
                }
            }
            ceiling.cancel()
        }
        // One `control` hold for clearing and stopping, so a `start()` cannot land between them
        // and have its new input stopped.
        let recording = control.withLock { _ in
            let (recording, stopInput) = state.withLock { s in
                guard let r = s.recording, r.ended else { return (AudioRecording(samples: []), false) }
                defer { s.running = false; s.recording = nil }
                return (AudioRecording(samples: r.samples), s.running)
            }
            if stopInput { log.notice("capture: stopping input"); input.stop() }
            return recording
        }
        log.notice("capture stop: returning \(recording.samples.count, privacy: .public) samples (ceiling task used=\(ceiling != nil, privacy: .public))")
        return recording
    }

    private func receive(_ event: AudioInputEvent, generation: Int) {
        state.withLock { s in
            guard s.running, s.inputGeneration == generation else { return }
            switch event {
            case .lost:
                let had = s.recording?.samples.count ?? -1
                log.error("capture: input lost; recording had \(had, privacy: .public) samples")
                s.running = false
                if let r = s.recording, !r.ended {
                    eventSink.yield(.inputLost)
                    endRecording(&s)
                }
            case .samples(let samples):
                record(samples, into: &s)
            }
        }
    }

    private func record(_ samples: [Float], into s: inout State) {
        guard var r = s.recording, !r.ended else { return }
        // Drops the second reference so appending does not copy every sample recorded so far.
        s.recording = nil
        if !r.firstAudioLogged {
            r.firstAudioLogged = true
            let zero = samples.allSatisfy { $0 == 0 }
            log.notice("capture: first audio for this recording, \(samples.count, privacy: .public) samples, allZero=\(zero, privacy: .public)")
        }
        if samples.allSatisfy({ $0 == 0 }) {
            r.zeroRun += samples.count
            if r.zeroRun >= Self.silenceSamples, !r.silenceReported {
                r.silenceReported = true
                log.error("capture: 5 s of all-zero audio")
                eventSink.yield(.silentFor5s)
            }
        } else {
            r.zeroRun = 0
            r.silenceReported = false
        }

        let end = min(r.tailEnd ?? .max, Self.limitSamples)
        let kept = Array(samples.prefix(end - r.samples.count))
        if !kept.isEmpty {
            r.samples += kept
            r.chunks.yield(kept)
        }
        if r.samples.count >= Self.limitNearSamples, !r.limitNearReported {
            r.limitNearReported = true
            eventSink.yield(.limitNear)
        }
        s.recording = r
        if let tailEnd = r.tailEnd, r.samples.count >= tailEnd {
            endRecording(&s)
        } else if r.samples.count >= Self.limitSamples {
            eventSink.yield(.limitReached)
            endRecording(&s)
        }
    }

    /// Ends the recording in place, keeping its samples for `stop()`.
    private func endRecording(_ s: inout State) {
        guard var r = s.recording, !r.ended else { return }
        r.ended = true
        r.chunks.finish()
        r.stopWaiter?.resume()
        r.stopWaiter = nil
        s.recording = r
    }

    private func after(_ delay: Duration, _ action: @escaping @Sendable () -> Void) -> Task<Void, Never> {
        clock.task(after: delay, action)
    }
}

extension Clock where Duration == Swift.Duration {
    /// Fixes the deadline now, not when the task first runs, so a test's clock advance cannot slip past it.
    fileprivate func task(after delay: Duration, _ action: @escaping @Sendable () -> Void) -> Task<Void, Never> {
        let deadline = now.advanced(by: delay)
        return Task {
            do {
                try await sleep(until: deadline, tolerance: nil)
                action()
            } catch {}
        }
    }
}
