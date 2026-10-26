import AVFoundation
import Foundation
import Speech

/// Apple's built-in speech model, through SpeechAnalyzer and SpeechTranscriber, streamed with volatile results.
public actor AppleSpeechEngine: StreamingSpeechEngine {
    public enum EngineError: Error {
        case unsupported
        case notLoaded
    }

    /// Holds the locale and installed assets; never attached to an analyzer itself.
    private var transcriber: SpeechTranscriber?
    private var analyzer: SpeechAnalyzer?
    private var input: AsyncStream<AnalyzerInput>.Continuation?
    private var converter: AVAudioConverter?
    private var analyzerFormat: AVAudioFormat?
    /// Collects the finalised results of the current stream until the analyzer finishes.
    private var results: Task<[SpeechTranscriber.Result], any Error>?

    private static let inputFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32, sampleRate: 16_000, channels: 1, interleaved: false)!

    public init() {}

    /// Installs the locale's speech assets the first time; macOS keeps them after that.
    public func load(progress: @escaping @Sendable (Double) -> Void) async throws {
        guard transcriber == nil else { return progress(1) }
        // `supportedLocale(equivalentTo:)` picks a different English region from run to run, so try exact matches first.
        let locale: Locale
        if await SpeechTranscriber.supportedLocales.contains(where: { $0.identifier == Locale.current.identifier }) {
            locale = .current
        } else if Locale.current.language.languageCode == .english {
            locale = Locale(identifier: "en_GB")
        } else if let current = await SpeechTranscriber.supportedLocale(equivalentTo: .current) {
            locale = current
        } else if let english = await SpeechTranscriber.supportedLocale(equivalentTo: Locale(identifier: "en_US")) {
            locale = english
        } else {
            throw EngineError.unsupported
        }
        try await AssetInventory.reserve(locale: locale)
        let transcriber = SpeechTranscriber(
            locale: locale,
            transcriptionOptions: [],
            reportingOptions: [.volatileResults],
            attributeOptions: [.audioTimeRange])
        if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            let poll = Task {
                while !Task.isCancelled {
                    progress(request.progress.fractionCompleted)
                    try? await Task.sleep(for: .milliseconds(250))
                }
            }
            defer { poll.cancel() }
            try await request.downloadAndInstall()
        }
        self.transcriber = transcriber
        progress(1)
    }

    public func unload() async {
        transcriber = nil
    }

    public func startStream(partial: @escaping @Sendable (String) -> Void) async throws {
        guard let loaded = transcriber else { throw EngineError.notLoaded }
        // A transcriber can be attached to only one analyzer, so each stream gets its own.
        let transcriber = SpeechTranscriber(
            locale: loaded.selectedLocales[0],
            transcriptionOptions: [],
            reportingOptions: [.volatileResults],
            attributeOptions: [.audioTimeRange])
        let analyzer = SpeechAnalyzer(modules: [transcriber])
        let format = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber]) ?? Self.inputFormat
        converter = format == Self.inputFormat ? nil : AVAudioConverter(from: Self.inputFormat, to: format)
        analyzerFormat = format
        let (stream, continuation) = AsyncStream.makeStream(of: AnalyzerInput.self)
        input = continuation
        let updates = transcriber.results
        results = Task {
            var finals: [SpeechTranscriber.Result] = []
            for try await result in updates {
                var shown = finals.map { String($0.text.characters) }
                if result.isFinal { finals.append(result) }
                shown.append(String(result.text.characters))
                partial(Self.joined(shown))
            }
            return finals
        }
        try await analyzer.start(inputSequence: stream)
        self.analyzer = analyzer
    }

    public func feed(_ chunk: [Float]) async throws {
        guard let input, !chunk.isEmpty, let buffer = convert(chunk) else { return }
        input.yield(AnalyzerInput(buffer: buffer))
    }

    public func finishStream() async throws -> Transcript {
        guard let analyzer, let results else { throw EngineError.notLoaded }
        input?.finish()
        try await analyzer.finalizeAndFinishThroughEndOfInput()
        let finals = try await results.value
        endStream()
        var words: [WordTiming] = []
        for result in finals {
            for run in result.text.runs {
                guard let range = run.audioTimeRange else { continue }
                let word = String(result.text[run.range].characters).trimmingCharacters(in: .whitespaces)
                guard !word.isEmpty else { continue }
                words.append(WordTiming(word: word, start: range.start.seconds, end: range.end.seconds))
            }
        }
        // No token timings: the word-list recheck's candidate check says no, so it is skipped.
        return Transcript(text: Self.joined(finals.map { String($0.text.characters) }), wordTimings: words)
    }

    public func cancelStream() async {
        input?.finish()
        await analyzer?.cancelAndFinishNow()
        results?.cancel()
        endStream()
    }

    public func transcribe(_ audio: [Float]) async throws -> Transcript {
        try await startStream { _ in }
        try await feed(audio)
        return try await finishStream()
    }

    private func endStream() {
        analyzer = nil
        input = nil
        results = nil
        converter = nil
        analyzerFormat = nil
    }

    private static func joined(_ texts: [String]) -> String {
        texts.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }.joined(separator: " ")
    }

    /// 16 kHz mono samples as a buffer in the analyzer's format.
    private func convert(_ samples: [Float]) -> AVAudioPCMBuffer? {
        guard let source = AVAudioPCMBuffer(pcmFormat: Self.inputFormat, frameCapacity: AVAudioFrameCount(samples.count))
        else { return nil }
        source.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { source.floatChannelData![0].update(from: $0.baseAddress!, count: samples.count) }
        guard let converter, let analyzerFormat else { return source }
        let ratio = analyzerFormat.sampleRate / Self.inputFormat.sampleRate
        let capacity = AVAudioFrameCount(Double(samples.count) * ratio) + 1024
        guard let output = AVAudioPCMBuffer(pcmFormat: analyzerFormat, frameCapacity: capacity) else { return nil }
        var given = false
        var error: NSError?
        converter.convert(to: output, error: &error) { _, status in
            if given {
                status.pointee = .noDataNow
                return nil
            }
            given = true
            status.pointee = .haveData
            return source
        }
        return error == nil ? output : nil
    }
}
