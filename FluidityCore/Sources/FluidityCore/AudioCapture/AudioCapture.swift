import Foundation
import Synchronization
import os

private let log = Logger(subsystem: "com.fluidity.app", category: "audio")

/// One dictation's audio: 16 kHz mono Float32, from the pre-roll to the end of the tail.
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
    /// The device changed or the engine stopped; the recording has ended with what it had. Call `stop()` to collect it.
    case inputLost
}

public enum AudioCaptureError: Error, Equatable {
    /// `start()` was called before the previous recording was collected with `stop()` or dropped with `cancel()`.
    case alreadyRecording
}

/// Records dictations from an `AudioInput`: 300 ms of pre-roll, a 200 ms tail, a 19/20 minute limit,
/// a dead-microphone check, and an engine that stays running for 3 minutes after each dictation.
/// Sample counts decide the pre-roll, tail and limits; the clock decides only the warm period and how long the tail may take.
public final class AudioCapture: Sendable {
    public static let sampleRate = 16_000
    static let preRollSamples = sampleRate * 3 / 10
    static let tailSamples = sampleRate / 5
    static let silenceSamples = sampleRate * 5
    static let limitNearSamples = sampleRate * 60 * 19
    static let limitSamples = sampleRate * 60 * 20
    static let warmPeriod = Duration.seconds(180)
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
        var preRoll: [Float] = []
        var recording: Recording?
        var warmTimer: Task<Void, Never>?
        var warmGeneration = 0
    }

    public init(input: any AudioInput, clock: any Clock<Duration> = ContinuousClock()) {
        self.input = input
        self.clock = clock
        (events, eventSink) = AsyncStream.makeStream()
    }

    /// Whether the engine is running, so the microphone is in use.
    public var isWarm: Bool { state.withLock { $0.running } }

    /// Starts a recording and returns its audio as it arrives, beginning with the pre-roll when the engine is warm.
    /// The stream finishes when the recording ends.
    public func start() throws -> AsyncStream<[Float]> {
        try control.withLock { _ throws(any Error) in
            let (stream, chunks) = AsyncStream<[Float]>.makeStream()
            let generation = try state.withLock { s throws(AudioCaptureError) -> Int? in
                guard s.recording == nil else { throw .alreadyRecording }
                s.warmTimer?.cancel()
                s.warmTimer = nil
                s.warmGeneration += 1
                if !s.preRoll.isEmpty { chunks.yield(s.preRoll) }
                s.recording = Recording(samples: s.preRoll, chunks: chunks)
                guard !s.running else { return nil }
                s.running = true
                s.inputGeneration += 1
                return s.inputGeneration
            }
            log.notice("capture start: startingInput=\(generation != nil, privacy: .public)")
            guard let generation else { return stream }
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

    /// Ends the recording after 200 ms more audio and returns all of it. Returns at once if the recording
    /// already ended on a limit or lost input, and returns an empty recording if none was started.
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
        let recording = state.withLock { s in
            guard let r = s.recording, r.ended else { return AudioRecording(samples: []) }
            s.recording = nil
            return AudioRecording(samples: r.samples)
        }
        log.notice("capture stop: returning \(recording.samples.count, privacy: .public) samples (ceiling task used=\(ceiling != nil, privacy: .public))")
        return recording
    }

    /// Drops the recording without returning it.
    public func cancel() {
        state.withLock { s in
            endRecording(&s)
            s.recording = nil
        }
    }

    private func receive(_ event: AudioInputEvent, generation: Int) {
        state.withLock { s in
            guard s.running, s.inputGeneration == generation else { return }
            switch event {
            case .lost:
                let had = s.recording?.samples.count ?? -1
                log.error("capture: input lost; recording had \(had, privacy: .public) samples")
                s.running = false
                s.preRoll = []
                if let r = s.recording, !r.ended {
                    eventSink.yield(.inputLost)
                    endRecording(&s)
                }
            case .samples(let samples):
                s.preRoll.append(contentsOf: samples)
                if s.preRoll.count > Self.preRollSamples {
                    s.preRoll.removeFirst(s.preRoll.count - Self.preRollSamples)
                }
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
            let zero = samples.allSatisfy { $0 == 0 }, held = r.samples.count
            log.notice("capture: first audio for this recording, \(samples.count, privacy: .public) samples, allZero=\(zero, privacy: .public), preRollHeld=\(held, privacy: .public)")
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

    /// Ends the recording in place, keeping its samples for `stop()`, and starts the warm period.
    private func endRecording(_ s: inout State) {
        guard var r = s.recording, !r.ended else { return }
        r.ended = true
        r.chunks.finish()
        r.stopWaiter?.resume()
        r.stopWaiter = nil
        s.recording = r
        guard s.running else { return }
        s.warmGeneration += 1
        let generation = s.warmGeneration
        s.warmTimer?.cancel()
        s.warmTimer = after(Self.warmPeriod) { [weak self] in self?.coolDown(generation) }
    }

    private func coolDown(_ generation: Int) {
        control.withLock { _ in
            let stopInput = state.withLock { s in
                guard s.running, s.warmGeneration == generation, s.recording?.ended ?? true else { return false }
                s.running = false
                s.preRoll = []
                s.warmTimer = nil
                return true
            }
            if stopInput { log.notice("capture: warm period over, stopping input"); input.stop() }
        }
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
