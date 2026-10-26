import Foundation
import Synchronization
import os

private let log = Logger(subsystem: "com.fluidity.app", category: "audio")

/// `AudioCapturing` over `AudioCapture`.
///
/// `AudioCapture.events` is not forwarded: the controller has no input for them. It times the
/// recording limits itself and shows mic silent after 5 s without new words.
public struct AudioCaptureAdapter: AudioCapturing {
    private let capture: AudioCapture
    private let willStart: @Sendable () async -> Void
    private let onChunk: (@Sendable ([Float]) -> Void)?

    /// `willStart` runs at the start of every dictation, before the microphone starts.
    /// `onChunk` receives each chunk of the recording as it arrives, for the pill.
    public init(
        capture: AudioCapture,
        willStart: @escaping @Sendable () async -> Void = {},
        onChunk: (@Sendable ([Float]) -> Void)? = nil
    ) {
        self.capture = capture
        self.willStart = willStart
        self.onChunk = onChunk
    }

    public func start() async throws -> AsyncStream<[Float]> {
        log.notice("adapter start: running willStart")
        await willStart()
        log.notice("adapter start: willStart done, starting capture")
        let chunks = try capture.start()
        guard let onChunk else { return chunks }
        let (stream, sink) = AsyncStream.makeStream(of: [Float].self)
        let relay = Task {
            for await chunk in chunks {
                onChunk(chunk)
                sink.yield(chunk)
            }
            sink.finish()
        }
        sink.onTermination = { _ in relay.cancel() }
        return stream
    }

    public func stop() async -> DictationController.Recording {
        let recording = await capture.stop()
        log.notice("adapter stop: \(recording.samples.count, privacy: .public) samples")
        return DictationController.Recording(samples: recording.samples, sampleRate: Double(AudioCapture.sampleRate))
    }
}

/// `Transcribing` over `Transcriber`.
///
/// `RawTranscript.transcriptionTime` is not passed on: the controller times the final pass itself.
public final class TranscriberAdapter: Transcribing {
    private let transcriber: Transcriber
    private let wordList: @Sendable () -> [String]
    private let lastPreview = Mutex<Task<Void, Never>?>(nil)

    public init(transcriber: Transcriber, wordList: @escaping @Sendable () -> [String]) {
        self.transcriber = transcriber
        self.wordList = wordList
    }

    /// Feeds `audio` to the transcriber and relays its live preview. When the caller stops reading,
    /// the transcriber's preview is cancelled too, so the speech model stops running preview passes.
    public func preview(_ audio: AsyncStream<[Float]>) -> AsyncStream<String> {
        let (stream, sink) = AsyncStream.makeStream(of: String.self, bufferingPolicy: .bufferingNewest(1))
        let transcriber = self.transcriber
        let task: Task<Void, Never> = lastPreview.withLock { last in
            let task = Task { [previous = last] in
                // The previous preview's cancel must not land after this one's start.
                await previous?.value
                let previews = await transcriber.startRecording()
                await withDiscardingTaskGroup { group in
                    group.addTask {
                        for await chunk in audio { await transcriber.append(chunk: chunk) }
                    }
                    for await text in previews { sink.yield(text) }
                    group.cancelAll()
                }
                // `finish` takes the recording as an argument, so this cannot touch a final pass.
                await transcriber.cancel()
                sink.finish()
            }
            last = task
            return task
        }
        sink.onTermination = { _ in task.cancel() }
        return stream
    }

    public func transcribe(_ recording: DictationController.Recording) async throws -> DictationController.Transcript {
        let raw = try await transcriber.finish(recording: recording.samples, wordList: wordList())
        return DictationController.Transcript(
            text: raw.text, wordTimings: raw.wordTimings, wordListRecheck: raw.wordListRecheckTime)
    }
}
