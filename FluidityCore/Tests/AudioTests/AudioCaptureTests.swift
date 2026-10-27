import FluidityCore
import FluidityTestSupport
import Testing

private let rate = AudioCapture.sampleRate
/// The 300 ms of silence every recording starts with.
private let leadIn = [Float](repeating: 0, count: rate * 3 / 10)

/// `count` samples with distinct non-zero values, so a misplaced sample shows up in a comparison.
private func ramp(_ count: Int, from first: Int = 1) -> [Float] {
    (first..<(first + count)).map { Float($0) }
}

private func collect(_ stream: AsyncStream<[Float]>) async -> [Float] {
    var all: [Float] = []
    for await chunk in stream { all += chunk }
    return all
}

/// The events of one recording, up to the one that ended it.
private func eventsUntilRecordingEnds(_ capture: AudioCapture) async -> [AudioCaptureEvent] {
    var seen: [AudioCaptureEvent] = []
    for await event in capture.events {
        seen.append(event)
        if event == .inputLost || event == .limitReached { break }
    }
    return seen
}

/// Calls `stop()`, then delivers `tail` while it waits.
private func stop(_ capture: AudioCapture, _ input: FakeAudioInput, tail: [Float]) async -> AudioRecording {
    let stopping = Task.immediate { await capture.stop() }
    input.deliver(tail)
    return await stopping.value
}

@Suite(.timeLimit(.minutes(1)))
struct AudioCaptureTests {
    let input = FakeAudioInput()
    let clock = ManualClock()
    let capture: AudioCapture

    init() { capture = AudioCapture(input: input, clock: clock) }

    @Test func eachRecordingRunsTheInputOnlyUntilStopAndBeginsWith300msOfSilence() async throws {
        // Turns red if the lead-in changes length, stop() leaves the microphone running, or the next
        // recording does not restart the input.
        _ = try capture.start()
        input.deliver(ramp(rate))
        _ = await stop(capture, input, tail: ramp(rate / 5))
        #expect(input.stops == 1)

        let chunks = try capture.start()
        #expect(input.starts == 2)
        let body = ramp(rate, from: 200_000)
        input.deliver(body)
        let tail = ramp(rate / 5, from: 300_000)
        let recording = await stop(capture, input, tail: tail)

        #expect(recording.samples == leadIn + body + tail)
        #expect(await collect(chunks) == recording.samples)
        #expect(input.stops == 2)
    }

    @Test func stopKeepsExactly200msOfAudioAfterRelease() async throws {
        // Turns red if the tail is longer or shorter than 3,200 samples, or audio after it is kept.
        _ = try capture.start()
        let body = ramp(rate)
        input.deliver(body)
        let afterRelease = ramp(rate / 2, from: 100_000)
        let recording = await stop(capture, input, tail: afterRelease)

        #expect(recording.samples == leadIn + body + afterRelease.prefix(rate / 5))
    }

    @Test func stopReturnsWhatItHasWhenTheTailNeverArrives() async throws {
        // Turns red if stop() waits forever for tail audio from an input that went quiet.
        _ = try capture.start()
        let body = ramp(rate)
        input.deliver(body)
        let stopping = Task.immediate { await capture.stop() }
        await clock.advance(by: .seconds(1))

        #expect(await stopping.value.samples == leadIn + body)
    }

    enum Feed: Sendable, CustomTestStringConvertible {
        case zeros(seconds: Double)
        case sound(seconds: Double)
        var testDescription: String {
            switch self {
            case .zeros(let s): "\(s) s silent"
            case .sound(let s): "\(s) s sound"
            }
        }
    }

    @Test(arguments: [
        ([Feed.zeros(seconds: 5)], [AudioCaptureEvent.silentFor5s]),
        ([.zeros(seconds: 4.9)], []),
        ([.zeros(seconds: 12)], [.silentFor5s]),
        ([.zeros(seconds: 4), .sound(seconds: 0.1), .zeros(seconds: 4)], []),
        ([.zeros(seconds: 5), .sound(seconds: 0.1), .zeros(seconds: 5)], [.silentFor5s, .silentFor5s]),
    ])
    func silenceIsReportedOncePerSilentStretch(feeds: [Feed], expected: [AudioCaptureEvent]) async throws {
        // Turns red if the 5 s threshold moves, the report repeats within one stretch, or audio does not reset it.
        _ = try capture.start()
        for feed in feeds {
            switch feed {
            case .zeros(let seconds):
                for _ in 0..<Int(seconds * 10) { input.deliver([Float](repeating: 0, count: rate / 10)) }
            case .sound(let seconds):
                for _ in 0..<Int(seconds * 10) { input.deliver([Float](repeating: 0.1, count: rate / 10)) }
            }
        }
        input.lose()

        #expect(await eventsUntilRecordingEnds(capture) == expected + [.inputLost])
    }

    @Test(arguments: [
        (1139, [AudioCaptureEvent.inputLost], 1139 * rate + leadIn.count),
        (1140, [.limitNear, .inputLost], 1140 * rate + leadIn.count),
        (1260, [.limitNear, .limitReached], 1200 * rate),
    ])
    func longRecordingsWarnAt19MinutesAndEndAt20(seconds: Int, expected: [AudioCaptureEvent], kept: Int) async throws {
        // Turns red if the warning or the limit moves, or audio past 20 minutes (lead-in included) is kept.
        _ = try capture.start()
        let second = [Float](repeating: 0.1, count: rate)
        for _ in 0..<seconds { input.deliver(second) }
        input.lose()

        #expect(await eventsUntilRecordingEnds(capture) == expected)
        #expect(await capture.stop().samples.count == kept)
    }

    @Test func lostInputKeepsTheRecordingSoFarAndTheNextStartRestartsTheInput() async throws {
        // Turns red if a device change drops the recording, makes stop() wait for a tail, or stops an input
        // that already stopped itself.
        let chunks = try capture.start()
        let body = ramp(rate)
        input.deliver(body)
        input.lose()

        #expect(await collect(chunks) == leadIn + body)
        #expect(await capture.stop().samples == leadIn + body)
        #expect(input.stops == 0)
        _ = try capture.start()
        #expect(input.starts == 2)
    }
}
