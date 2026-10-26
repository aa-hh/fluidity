import FluidityCore
import FluidityTestSupport
import Foundation

/// Answers "heard <sample count>"; `hold()` parks every pass until `release()`.
final class FakeSpeechEngine: SpeechEngine, @unchecked Sendable {
    let started: AsyncStream<Int>
    private let startedContinuation: AsyncStream<Int>.Continuation
    private let work: @Sendable () async -> Void
    private let lock = NSLock()
    private var holding = false
    private var held: [CheckedContinuation<Void, Never>] = []
    private var running = 0
    private var lengths: [Int] = []
    private var most = 0
    private var loaded = true
    private var failsToLoad = false
    private var wasUnloaded = false

    init(work: @escaping @Sendable () async -> Void = {}) {
        (started, startedContinuation) = AsyncStream.makeStream(of: Int.self)
        self.work = work
    }

    var audioLengths: [Int] { lock.withLock { lengths } }
    var mostAtOnce: Int { lock.withLock { most } }
    /// When set, `load` throws.
    var loadFails: Bool {
        get { lock.withLock { failsToLoad } }
        set { lock.withLock { failsToLoad = newValue } }
    }
    var unloaded: Bool { lock.withLock { wasUnloaded } }

    func hold() { lock.withLock { holding = true } }

    func release() {
        let waiting = lock.withLock {
            holding = false
            defer { held = [] }
            return held
        }
        for continuation in waiting { continuation.resume() }
    }

    /// Stays unloaded while held, like a slow first load of the real model.
    func load(progress: @escaping @Sendable (Double) -> Void) async throws {
        if loadFails { throw FluidAudioEngine.EngineError.notLoaded }
        lock.withLock { loaded = false }
        await parkWhileHeld()
        lock.withLock { loaded = true }
    }

    func transcribe(_ audio: [Float]) async throws -> Transcript {
        guard lock.withLock({ loaded }) else { throw FluidAudioEngine.EngineError.notLoaded }
        lock.withLock {
            lengths.append(audio.count)
            running += 1
            most = max(most, running)
        }
        startedContinuation.yield(audio.count)
        await parkWhileHeld()
        await work()
        lock.withLock { running -= 1 }
        return Transcript(text: "heard \(audio.count)", wordTimings: [])
    }

    func unload() async { lock.withLock { wasUnloaded = true } }

    private func parkWhileHeld() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let parked = lock.withLock {
                if holding { held.append(continuation) }
                return holding
            }
            if !parked { continuation.resume() }
        }
    }
}

final class FakeVoiceDetector: VoiceDetecting, @unchecked Sendable {
    let checked: AsyncStream<Void>
    private let checkedContinuation: AsyncStream<Void>.Continuation
    private let lock = NSLock()
    private var heard: Bool

    init(speech: Bool) {
        (checked, checkedContinuation) = AsyncStream.makeStream(of: Void.self)
        heard = speech
    }

    var speech: Bool {
        get { lock.withLock { heard } }
        set { lock.withLock { heard = newValue } }
    }

    func hasSpeech(in audio: [Float]) async throws -> Bool {
        defer { checkedContinuation.yield() }
        return speech
    }
}

/// The candidate check costs 4 ms and the recheck 170 ms on the clock; the recheck answers the word list.
final class FakeRechecker: WordListRechecking, @unchecked Sendable {
    private let candidates: Bool
    private let clock: ManualClock

    init(candidates: Bool, clock: ManualClock) {
        self.candidates = candidates
        self.clock = clock
    }

    func hasCandidates(in transcript: Transcript, wordList: [String]) async -> Bool {
        await clock.advance(by: .milliseconds(4))
        return candidates
    }

    func recheck(_ transcript: Transcript, audio: [Float], wordList: [String]) async -> Transcript {
        await clock.advance(by: .milliseconds(170))
        return Transcript(text: wordList.joined(separator: " "), wordTimings: transcript.wordTimings)
    }
}

/// Records every chunk it is fed and each stream call; `partial` sends text as the engine's live words.
final class FakeStreamingEngine: StreamingSpeechEngine, @unchecked Sendable {
    private let lock = NSLock()
    private let result: String
    private var partialSink: (@Sendable (String) -> Void)?
    private var chunks: [[Float]] = []
    private var calls: [String] = []
    private var holdingFeeds = false
    private var heldFeeds: [CheckedContinuation<Void, Never>] = []
    private var holdingCancels = false
    private var heldCancels: [CheckedContinuation<Void, Never>] = []

    init(result: String = "streamed") {
        self.result = result
    }

    var fedChunks: [[Float]] { lock.withLock { chunks } }
    /// "start", "finish", "cancel" and "transcribe", in the order they reached the engine.
    var streamCalls: [String] { lock.withLock { calls } }

    func partial(_ text: String) { lock.withLock { partialSink }?(text) }

    /// Parks every feed after recording its chunk, until `releaseFeeds`, like a slow model.
    func holdFeeds() { lock.withLock { holdingFeeds = true } }

    func releaseFeeds() {
        let waiting = lock.withLock {
            holdingFeeds = false
            defer { heldFeeds = [] }
            return heldFeeds
        }
        for continuation in waiting { continuation.resume() }
    }

    /// Parks every cancel until `releaseCancels`; "cancel" is recorded when it ends.
    func holdCancels() { lock.withLock { holdingCancels = true } }

    func releaseCancels() {
        let waiting = lock.withLock {
            holdingCancels = false
            defer { heldCancels = [] }
            return heldCancels
        }
        for continuation in waiting { continuation.resume() }
    }

    func load(progress: @escaping @Sendable (Double) -> Void) async throws {}
    func unload() async {}

    func transcribe(_ audio: [Float]) async throws -> Transcript {
        lock.withLock { calls.append("transcribe") }
        return Transcript(text: result, wordTimings: [])
    }

    func startStream(partial: @escaping @Sendable (String) -> Void) async throws {
        lock.withLock {
            calls.append("start")
            partialSink = partial
        }
    }

    func feed(_ chunk: [Float]) async throws {
        lock.withLock { chunks.append(chunk) }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let parked = lock.withLock {
                if holdingFeeds { heldFeeds.append(continuation) }
                return holdingFeeds
            }
            if !parked { continuation.resume() }
        }
    }

    func finishStream() async throws -> Transcript {
        lock.withLock { calls.append("finish") }
        return Transcript(text: result, wordTimings: [])
    }

    func cancelStream() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let parked = lock.withLock {
                if holdingCancels { heldCancels.append(continuation) }
                return holdingCancels
            }
            if !parked { continuation.resume() }
        }
        lock.withLock { calls.append("cancel") }
    }
}
