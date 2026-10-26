import FluidityCore
import FluidityTestSupport
import Foundation
import Testing

/// A microphone the test feeds by hand; `stop` ends the chunk stream and returns every sample sent.
/// `holdStart()` parks the next start until `releaseStart()`, like a microphone slow to start.
final class FakeMicrophone: AudioCapturing, @unchecked Sendable {
    private let lock = NSLock()
    private var sink: AsyncStream<[Float]>.Continuation?
    private var samples: [Float] = []
    private var holding = false
    private var heldStart: CheckedContinuation<Void, Never>?
    private var stopCount = 0

    var isStarted: Bool { lock.withLock { sink != nil } }
    var isStarting: Bool { lock.withLock { heldStart != nil } }
    var stops: Int { lock.withLock { stopCount } }

    func holdStart() { lock.withLock { holding = true } }

    func releaseStart() {
        lock.withLock {
            holding = false
            defer { heldStart = nil }
            return heldStart
        }?.resume()
    }

    func start() async throws -> AsyncStream<[Float]> {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let parked = lock.withLock {
                if holding { heldStart = continuation }
                return holding
            }
            if !parked { continuation.resume() }
        }
        let (stream, sink) = AsyncStream.makeStream(of: [Float].self)
        lock.withLock {
            self.sink = sink
            samples = []
        }
        return stream
    }

    func send(_ chunk: [Float]) {
        lock.withLock {
            samples.append(contentsOf: chunk)
            return sink
        }?.yield(chunk)
    }

    func stop() async -> DictationController.Recording {
        let (sink, samples) = lock.withLock {
            defer {
                self.sink = nil
                stopCount += 1
            }
            return (self.sink, self.samples)
        }
        sink?.finish()
        return DictationController.Recording(samples: samples, sampleRate: 16_000)
    }
}

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct CompareSessionTests {
    let clock = ManualClock()
    let microphone = FakeMicrophone()
    let leftEngine = FakeStreamingEngine(result: "move the standup to 10:30")
    let rightEngine = FakeStreamingEngine(result: "move the stand-up to 10:30")

    func makeSession() -> CompareSession {
        let engines: [SpeechModelID: FakeStreamingEngine] = [.parakeetTDTv2: leftEngine, .appleBuiltIn: rightEngine]
        return CompareSession(
            audio: microphone,
            makeTranscriber: { [clock] model in
                Transcriber(
                    engine: engines[model]!, model: model, voiceDetector: FakeVoiceDetector(speech: true),
                    rechecker: FakeRechecker(candidates: false, clock: clock), clock: clock)
            },
            clock: clock)
    }

    /// Lets ready tasks run until `condition` holds, with a generous ceiling.
    func until(_ condition: () -> Bool) async {
        for _ in 0..<10_000 where !condition() { await Task.yield() }
    }

    /// Lets every ready task run, so a sleep about to start is parked before the clock moves.
    func settle() async {
        for _ in 0..<100 { await Task.yield() }
    }

    /// Starts listening and waits until both engines have started their streams.
    func startListening(_ session: CompareSession) async {
        session.start()
        await until { leftEngine.streamCalls.contains("start") && rightEngine.streamCalls.contains("start") }
    }

    @Test func bothColumnsHearEveryChunkAndStopDiffsTheFinals() async {
        // Feeding a chunk to only one transcriber, or diffing anything but the two finals, turns this red.
        let session = makeSession()
        await startListening(session)
        microphone.send([1, 2])
        microphone.send([3])
        await until { leftEngine.fedChunks.count == 2 && rightEngine.fedChunks.count == 2 }
        await session.stop()

        #expect(leftEngine.fedChunks.flatMap { $0 } == [1, 2, 3])
        #expect(rightEngine.fedChunks.flatMap { $0 } == [1, 2, 3])
        #expect(session.phase == .finished)
        #expect(session.result?.leftFinal.text == "move the standup to 10:30")
        #expect(session.result?.rightFinal.model == .appleBuiltIn)
        #expect(session.result?.differences.map(\.left) == ["standup"])
        #expect(session.recording == [1, 2, 3])
    }

    @Test func dictationKeyTogglesListeningAndIgnoresKeyUp() async {
        // Stopping on key up, as dictation's hold does, or not toggling on key down, turns this red.
        let session = makeSession()
        session.handle(.keyDown)
        #expect(session.phase == .listening)
        session.handle(.keyUp)
        #expect(session.phase == .listening)
        await until { microphone.isStarted }
        session.handle(.keyDown)
        await until { session.phase == .finished }
        #expect(session.phase == .finished)
    }

    @Test func escapeWhileListeningDiscards() async {
        // Running the final passes on Escape, instead of dropping the recording, turns this red.
        let session = makeSession()
        await startListening(session)
        session.handle(.cancel)
        #expect(session.phase == .idle)
        await until { leftEngine.streamCalls.contains("cancel") && rightEngine.streamCalls.contains("cancel") }
        #expect(!leftEngine.streamCalls.contains("finish"))
        #expect(session.result == nil)
    }

    @Test func theDictationKeyStartsOnlyWhenBothColumnsAreReady() async {
        // Letting key down start the microphone while a column's model is missing or still loading turns this red.
        let session = makeSession()
        var ready = false
        session.canStart = { ready }
        session.handle(.keyDown)
        await settle()
        #expect(session.phase == .idle)
        #expect(!microphone.isStarted && !microphone.isStarting)

        ready = true
        session.handle(.keyDown)
        #expect(session.phase == .listening)
        await until { microphone.isStarted }
        #expect(microphone.isStarted)
    }

    @Test func aStartAfterADiscardWaitsForTheEnginesToEndTheOldStream() async {
        // Returning from `Transcriber.cancel` before the engine's cancel has run lets the old stream's cancel land
        // on the new stream of the same engine, which turns this red.
        let session = makeSession()
        await startListening(session)
        leftEngine.holdCancels()
        session.discard()
        session.start()
        await settle()
        #expect(leftEngine.streamCalls == ["start"])

        leftEngine.releaseCancels()
        await until { leftEngine.streamCalls.count == 3 }
        #expect(leftEngine.streamCalls == ["start", "cancel", "start"])
    }

    enum EarlyEnd: Sendable, CaseIterable { case stop, escape, close }

    // Turns red if Stop, Escape or closing the window stops the microphone before its start returns,
    // which leaves the shared capture recording and every later dictation refused.
    @Test(arguments: EarlyEnd.allCases)
    func endingBeforeTheMicrophoneStartsLeavesItStopped(_ end: EarlyEnd) async {
        let session = makeSession()
        microphone.holdStart()
        session.start()
        await until { microphone.isStarting }
        let ending: Task<Void, Never>
        switch end {
        case .stop: ending = Task { await session.stop() }
        case .escape: session.handle(.cancel); ending = Task {}
        case .close: session.discard(); ending = Task {}
        }
        await settle()
        microphone.releaseStart()
        await ending.value
        await until { microphone.stops == 1 }
        #expect(microphone.stops == 1)
        #expect(!microphone.isStarted)
        #expect(session.phase == (end == .stop ? .finished : .idle))
    }

    @Test func replayShowsLiveWordsAtHalfSpeed() async {
        // Replaying at the recorded offsets, not twice them, turns this red.
        let session = makeSession()
        await startListening(session)
        await clock.advance(by: .milliseconds(100))
        leftEngine.partial("move")
        await until { session.liveText[.left] == "move" }
        await clock.advance(by: .milliseconds(200))
        leftEngine.partial("move the")
        await until { session.liveText[.left] == "move the" }
        await session.stop()

        session.replayLiveWords()
        #expect(session.liveText[.left] == "")
        await settle()
        await clock.advance(by: .milliseconds(199))
        #expect(session.liveText[.left] == "")
        await clock.advance(by: .milliseconds(1))
        await until { session.liveText[.left] == "move" }
        #expect(session.liveText[.left] == "move")
        await settle()
        await clock.advance(by: .milliseconds(399))
        #expect(session.liveText[.left] == "move")
        await clock.advance(by: .milliseconds(1))
        await until { session.liveText[.left] == "move the" }
        #expect(session.liveText[.left] == "move the")
    }
}
