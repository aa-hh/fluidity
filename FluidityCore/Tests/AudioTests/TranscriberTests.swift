import FluidityCore
import FluidityTestSupport
import Foundation
import Testing

@Suite(.timeLimit(.minutes(1)))
struct TranscriberTests {
    let clock = ManualClock()
    let oneSecond = [Float](repeating: 0, count: 16_000)

    func makeTranscriber(
        engine: FakeSpeechEngine,
        speech: Bool = true,
        candidates: Bool = false
    ) -> (Transcriber, FakeVoiceDetector) {
        let voice = FakeVoiceDetector(speech: speech)
        let transcriber = Transcriber(
            engine: engine,
            voiceDetector: voice,
            rechecker: FakeRechecker(candidates: candidates, clock: clock),
            clock: clock
        )
        return (transcriber, voice)
    }

    /// Lets every task that is ready run, so a tick that should not start a pass has had its chance to.
    func settle() async {
        for _ in 0..<100 { await Task.yield() }
    }

    func advance(by duration: Duration) async {
        await settle()
        await clock.advance(by: duration)
    }

    @Test func noPreviewRunsBeforeSpeechIsHeard() async {
        // Dropping the voice-detection check from the preview pass turns this red.
        let engine = FakeSpeechEngine()
        let (transcriber, voice) = makeTranscriber(engine: engine, speech: false)
        var checks = voice.checked.makeAsyncIterator()
        var previews = await transcriber.startRecording().makeAsyncIterator()
        await transcriber.append(chunk: oneSecond)

        for _ in 0..<3 {
            await advance(by: .seconds(1))
            _ = await checks.next()
        }
        await settle()
        #expect(engine.audioLengths.isEmpty)

        voice.speech = true
        await advance(by: .seconds(1))
        #expect(await previews.next() == "heard 16000")
    }

    @Test func previewsRunAboutOnceASecondOnTheWholeRecordingSoFar() async {
        // Ticking faster than once a second, or transcribing only the newest chunk, turns this red.
        let engine = FakeSpeechEngine()
        let (transcriber, _) = makeTranscriber(engine: engine)
        var previews = await transcriber.startRecording().makeAsyncIterator()
        await transcriber.append(chunk: oneSecond)

        await advance(by: .milliseconds(500))
        await settle()
        #expect(engine.audioLengths.isEmpty)
        await advance(by: .milliseconds(500))
        #expect(await previews.next() == "heard 16000")

        await transcriber.append(chunk: oneSecond)
        await advance(by: .seconds(1))
        #expect(await previews.next() == "heard 32000")
        #expect(engine.audioLengths == [16_000, 32_000])
    }

    @Test func aSlowPassMakesTheNextTickSkip() async {
        // Starting a pass on a tick while the previous pass is still running turns this red.
        let engine = FakeSpeechEngine()
        let (transcriber, _) = makeTranscriber(engine: engine)
        var started = engine.started.makeAsyncIterator()
        var previews = await transcriber.startRecording().makeAsyncIterator()
        await transcriber.append(chunk: oneSecond)
        engine.hold()

        await advance(by: .seconds(1))
        _ = await started.next()
        await advance(by: .seconds(1))
        await settle()
        #expect(engine.audioLengths.count == 1)

        engine.release()
        #expect(await previews.next() == "heard 16000")
        await advance(by: .seconds(1))
        _ = await started.next()
        #expect(engine.audioLengths.count == 2)
        #expect(engine.mostAtOnce == 1)
    }

    @Test func theFinalPassWaitsForTheRunningPreviewThenUsesTheWholeRecording() async throws {
        // Starting the final pass before the running preview ends, or on the preview's audio, turns this red.
        let engine = FakeSpeechEngine()
        let (transcriber, _) = makeTranscriber(engine: engine)
        var started = engine.started.makeAsyncIterator()
        var previews = await transcriber.startRecording().makeAsyncIterator()
        await transcriber.append(chunk: oneSecond)
        engine.hold()
        await advance(by: .seconds(1))
        _ = await started.next()

        let withTail = oneSecond + [Float](repeating: 0, count: 3_200)
        let finishing = Task { try await transcriber.finish(recording: withTail) }
        await settle()
        #expect(engine.audioLengths == [16_000])

        engine.release()
        let raw = try await finishing.value
        #expect(raw.text == "heard 19200")
        #expect(engine.mostAtOnce == 1)
        #expect(await previews.next() == nil)
    }

    @Test(arguments: [
        ([String](), true, false),
        (["Fluidity"], false, false),
        (["Fluidity"], true, true),
    ])
    func theRecheckRunsOnlyWithAWordListAndACandidate(wordList: [String], candidates: Bool, rechecks: Bool) async throws {
        // Skipping the candidate check or the empty-list check, or timing the wrong stage, turns this red.
        let engine = FakeSpeechEngine(work: { [clock] in await clock.advance(by: .milliseconds(120)) })
        let (transcriber, _) = makeTranscriber(engine: engine, candidates: candidates)

        let raw = try await transcriber.finish(recording: oneSecond, wordList: wordList)

        #expect(raw.text == (rechecks ? "Fluidity" : "heard 16000"))
        #expect(abs(raw.transcriptionTime - 0.12) < 1e-9)
        if rechecks {
            #expect(abs((raw.wordListRecheckTime ?? 0) - 0.174) < 1e-9)
        } else {
            #expect(raw.wordListRecheckTime == nil)
        }
    }

    @Test func cancelEndsThePreviewAndStopsPasses() async {
        // Leaving the preview ticker running after cancel turns this red.
        let engine = FakeSpeechEngine()
        let (transcriber, _) = makeTranscriber(engine: engine)
        var previews = await transcriber.startRecording().makeAsyncIterator()
        await transcriber.append(chunk: oneSecond)
        await advance(by: .seconds(1))
        #expect(await previews.next() == "heard 16000")

        await transcriber.cancel()
        #expect(await previews.next() == nil)
        await advance(by: .seconds(2))
        await settle()
        #expect(engine.audioLengths == [16_000])
    }
}

extension TranscriberTests {
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

        init(work: @escaping @Sendable () async -> Void = {}) {
            (started, startedContinuation) = AsyncStream.makeStream(of: Int.self)
            self.work = work
        }

        var audioLengths: [Int] { lock.withLock { lengths } }
        var mostAtOnce: Int { lock.withLock { most } }

        func hold() { lock.withLock { holding = true } }

        func release() {
            let waiting = lock.withLock {
                holding = false
                defer { held = [] }
                return held
            }
            for continuation in waiting { continuation.resume() }
        }

        func load(progress: @escaping @Sendable (Double) -> Void) async throws {}

        func transcribe(_ audio: [Float]) async throws -> Transcript {
            lock.withLock {
                lengths.append(audio.count)
                running += 1
                most = max(most, running)
            }
            startedContinuation.yield(audio.count)
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                let parked = lock.withLock {
                    if holding { held.append(continuation) }
                    return holding
                }
                if !parked { continuation.resume() }
            }
            await work()
            lock.withLock { running -= 1 }
            return Transcript(text: "heard \(audio.count)", wordTimings: [])
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
}
