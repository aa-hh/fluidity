import FluidityCore
import FluidityTestSupport
import Foundation
import Testing

@Suite(.timeLimit(.minutes(1)))
struct TranscriberTests {
    let clock = ManualClock()
    let oneSecond = [Float](repeating: 0, count: 16_000)

    func makeTranscriber(
        engine: any SpeechEngine,
        model: SpeechModelID = .parakeetTDTv2,
        speech: Bool = true,
        candidates: Bool = false
    ) -> (Transcriber, FakeVoiceDetector) {
        let voice = FakeVoiceDetector(speech: speech)
        let transcriber = Transcriber(
            engine: engine,
            model: model,
            voiceDetector: voice,
            rechecker: FakeRechecker(candidates: candidates, clock: clock),
            clock: clock
        )
        return (transcriber, voice)
    }

    /// Lets every task that is ready run, so a step that should not start a pass has had its chance to.
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
            await advance(by: .milliseconds(250))
            _ = await checks.next()
        }
        await settle()
        #expect(engine.audioLengths.isEmpty)

        voice.speech = true
        await advance(by: .milliseconds(250))
        #expect(await previews.next() == "heard 16000")
    }

    @Test func passesRunAfterEachGapOnTheWholeRecordingSoFar() async {
        // Starting a pass before the gap has passed, or transcribing only the newest chunk, turns this red.
        let engine = FakeSpeechEngine()
        let (transcriber, _) = makeTranscriber(engine: engine)
        var previews = await transcriber.startRecording().makeAsyncIterator()
        await transcriber.append(chunk: oneSecond)

        await advance(by: .milliseconds(200))
        await settle()
        #expect(engine.audioLengths.isEmpty)
        await advance(by: .milliseconds(50))
        #expect(await previews.next() == "heard 16000")

        await transcriber.append(chunk: oneSecond)
        await advance(by: .milliseconds(250))
        #expect(await previews.next() == "heard 32000")
        #expect(engine.audioLengths == [16_000, 32_000])
    }

    @Test func aSlowPassDelaysTheNextPassInsteadOfOverlappingIt() async {
        // Starting a second pass while the previous one is still running turns this red.
        let engine = FakeSpeechEngine()
        let (transcriber, _) = makeTranscriber(engine: engine)
        var started = engine.started.makeAsyncIterator()
        var previews = await transcriber.startRecording().makeAsyncIterator()
        await transcriber.append(chunk: oneSecond)
        engine.hold()

        await advance(by: .milliseconds(250))
        _ = await started.next()
        await advance(by: .milliseconds(250))
        await settle()
        #expect(engine.audioLengths.count == 1)

        engine.release()
        #expect(await previews.next() == "heard 16000")
        await advance(by: .milliseconds(250))
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
        await advance(by: .milliseconds(250))
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

    @Test func theFinalPassWaitsForTheModelToLoad() async throws {
        // Running the final pass without waiting for `prepare`, so the engine throws not loaded, turns this red.
        let engine = FakeSpeechEngine()
        let (transcriber, _) = makeTranscriber(engine: engine)
        engine.hold()
        let preparing = Task { try await transcriber.prepare() }
        await settle()
        let finishing = Task { try await transcriber.finish(recording: oneSecond) }
        await settle()
        #expect(engine.audioLengths.isEmpty)

        engine.release()
        try await preparing.value
        #expect(try await finishing.value.text == "heard 16000")
    }

    @Test func aNewRecordingWaitsForTheLastFinalPass() async throws {
        // Letting a new recording's preview pass start while the last final pass is on the engine turns this red.
        let engine = FakeSpeechEngine()
        let (transcriber, _) = makeTranscriber(engine: engine)
        var started = engine.started.makeAsyncIterator()
        engine.hold()
        let finishing = Task { try await transcriber.finish(recording: oneSecond) }
        _ = await started.next()

        var previews = await transcriber.startRecording().makeAsyncIterator()
        await transcriber.append(chunk: [Float](repeating: 0, count: 8_000))
        await advance(by: .milliseconds(250))
        await settle()
        #expect(engine.audioLengths == [16_000])

        engine.release()
        _ = try await finishing.value
        await advance(by: .milliseconds(250))
        #expect(await previews.next() == "heard 8000")
        #expect(engine.mostAtOnce == 1)
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
        // Leaving the preview loop running after cancel turns this red.
        let engine = FakeSpeechEngine()
        let (transcriber, _) = makeTranscriber(engine: engine)
        var previews = await transcriber.startRecording().makeAsyncIterator()
        await transcriber.append(chunk: oneSecond)
        await advance(by: .milliseconds(250))
        #expect(await previews.next() == "heard 16000")

        await transcriber.cancel()
        #expect(await previews.next() == nil)
        await advance(by: .seconds(2))
        await settle()
        #expect(engine.audioLengths == [16_000])
    }

    // MARK: Switching engines

    @Test func aSwitchDuringARecordingLandsAfterItsFinalPass() async throws {
        // Swapping the engine before the recording's final pass ends, or not using the new engine and model after it, turns this red.
        let old = FakeSpeechEngine()
        let new = FakeSpeechEngine()
        let (transcriber, _) = makeTranscriber(engine: old)
        _ = await transcriber.startRecording()
        await transcriber.append(chunk: oneSecond)
        let switching = Task { try await transcriber.switchEngine(to: new, model: .parakeetUnified) }
        await settle()

        let first = try await transcriber.finish(recording: oneSecond)
        #expect(first.model == .parakeetTDTv2)
        #expect(old.audioLengths == [16_000])
        let replaced = try await switching.value
        #expect(replaced as AnyObject === old)

        _ = await transcriber.startRecording()
        let second = try await transcriber.finish(recording: [Float](repeating: 0, count: 8_000))
        #expect(second.model == .parakeetUnified)
        #expect(new.audioLengths == [8_000])
        #expect(old.audioLengths == [16_000])
    }

    @Test func aSwitchWhileIdleTakesEffectForTheNextPass() async throws {
        // Leaving the old engine in place after a switch with nothing recording turns this red.
        let old = FakeSpeechEngine()
        let new = FakeSpeechEngine()
        let (transcriber, _) = makeTranscriber(engine: old)
        _ = try await transcriber.switchEngine(to: new, model: .appleBuiltIn)

        let raw = try await transcriber.finish(recording: oneSecond)
        #expect(new.audioLengths == [16_000])
        #expect(old.audioLengths.isEmpty)
        #expect(raw.model == .appleBuiltIn)
    }

    @Test func aFailedLoadKeepsTheCurrentEngine() async throws {
        // Swapping in an engine whose load failed, or swallowing the failure, turns this red.
        let old = FakeSpeechEngine()
        let new = FakeSpeechEngine()
        new.loadFails = true
        let (transcriber, _) = makeTranscriber(engine: old)
        await #expect(throws: (any Error).self) { _ = try await transcriber.switchEngine(to: new, model: .parakeetUnified) }

        let raw = try await transcriber.finish(recording: oneSecond)
        #expect(old.audioLengths == [16_000])
        #expect(raw.model == .parakeetTDTv2)
    }

    @Test func theNewerOfTwoPendingSwitchesWins() async throws {
        // Letting an older pending switch land after a newer one was asked for turns this red.
        let old = FakeSpeechEngine()
        let first = FakeSpeechEngine()
        let second = FakeSpeechEngine()
        let (transcriber, _) = makeTranscriber(engine: old)
        _ = await transcriber.startRecording()
        let firstSwitch = Task { try await transcriber.switchEngine(to: first, model: .appleBuiltIn) }
        await settle()
        let secondSwitch = Task { try await transcriber.switchEngine(to: second, model: .parakeetUnified) }
        await settle()

        _ = try await transcriber.finish(recording: oneSecond)
        await #expect(throws: CancellationError.self) { _ = try await firstSwitch.value }
        _ = try await secondSwitch.value
        let raw = try await transcriber.finish(recording: oneSecond)
        #expect(raw.model == .parakeetUnified)
        #expect(second.audioLengths == [16_000])
        #expect(first.audioLengths.isEmpty)
    }

    // MARK: Streaming engines

    @Test func aStreamingEngineIsFedEveryChunkAndDrivesThePreview() async throws {
        // Dropping or reordering chunks, losing the engine's partials, or running whole passes on a streaming engine turns this red.
        let engine = FakeStreamingEngine()
        let (transcriber, _) = makeTranscriber(engine: engine, model: .parakeetUnified)
        let first = [Float](repeating: 0.1, count: 4)
        let second = [Float](repeating: 0.2, count: 4)
        var previews = await transcriber.startRecording().makeAsyncIterator()
        await transcriber.append(chunk: first)
        await transcriber.append(chunk: second)
        await settle()
        engine.partial("hello")
        #expect(await previews.next() == "hello")

        let raw = try await transcriber.finish(recording: first + second)
        #expect(raw.text == "streamed")
        #expect(engine.fedChunks == [first, second])
        #expect(engine.streamCalls == ["start", "finish"])
    }

    @Test func finishFeedsTheTailBeforeFinishingTheStream() async throws {
        // Finishing the stream without the audio recorded after the last chunk turns this red.
        let engine = FakeStreamingEngine()
        let (transcriber, _) = makeTranscriber(engine: engine, model: .parakeetUnified)
        let chunk = [Float](repeating: 0.1, count: 4)
        let tail = [Float](repeating: 0.3, count: 2)
        _ = await transcriber.startRecording()
        await transcriber.append(chunk: chunk)

        _ = try await transcriber.finish(recording: chunk + tail)
        #expect(engine.fedChunks == [chunk, tail])
        #expect(engine.streamCalls == ["start", "finish"])
    }

    @Test func cancelEndsTheStreamWithoutFinishingIt() async {
        // Finishing the stream on cancel, or never telling the engine, turns this red.
        let engine = FakeStreamingEngine()
        let (transcriber, _) = makeTranscriber(engine: engine, model: .parakeetUnified)
        _ = await transcriber.startRecording()
        await transcriber.append(chunk: oneSecond)
        await transcriber.cancel()
        await settle()
        #expect(engine.streamCalls == ["start", "cancel"])
    }
}
