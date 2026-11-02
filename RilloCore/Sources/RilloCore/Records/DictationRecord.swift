import Foundation

/// Everything saved about one dictation; every part reads or fills it.
public struct DictationRecord: Codable, Equatable, Sendable {
    public var id: UUID
    public var startedAt: Date
    /// Bundle identifier of the app that had focus.
    public var app: String?
    /// The speech model's output, before cleanup.
    public var rawTranscript: String
    /// Cleanup's output, when cleanup returned in time.
    public var cleanedText: String?
    /// What was pasted: the cleaned text, or the raw transcript after a fallback.
    public var pastedText: String?
    /// The pasted part of the field, with the user's edits, when watching stopped.
    public var finalText: String?
    public var wordTimings: [WordTiming]
    public var textBeforeCursor: String?
    public var selectedText: String?
    public var textAfterCursor: String?
    /// Whether the paste reached the text field.
    public var pasteLanded: Bool
    /// Why the raw transcript was pasted instead of the cleaned text, if it was.
    public var fallbackReason: FallbackReason?
    public var watchStopReason: WatchStopReason?
    public var timings: StageTimings
    public var modelVersion: String
    public var wordListVersion: String

    public init(
        id: UUID,
        startedAt: Date,
        app: String? = nil,
        rawTranscript: String,
        cleanedText: String? = nil,
        pastedText: String? = nil,
        finalText: String? = nil,
        wordTimings: [WordTiming] = [],
        textBeforeCursor: String? = nil,
        selectedText: String? = nil,
        textAfterCursor: String? = nil,
        pasteLanded: Bool = false,
        fallbackReason: FallbackReason? = nil,
        watchStopReason: WatchStopReason? = nil,
        timings: StageTimings = StageTimings(),
        modelVersion: String,
        wordListVersion: String
    ) {
        self.id = id
        self.startedAt = startedAt
        self.app = app
        self.rawTranscript = rawTranscript
        self.cleanedText = cleanedText
        self.pastedText = pastedText
        self.finalText = finalText
        self.wordTimings = wordTimings
        self.textBeforeCursor = textBeforeCursor
        self.selectedText = selectedText
        self.textAfterCursor = textAfterCursor
        self.pasteLanded = pasteLanded
        self.fallbackReason = fallbackReason
        self.watchStopReason = watchStopReason
        self.timings = timings
        self.modelVersion = modelVersion
        self.wordListVersion = wordListVersion
    }
}

/// One word of the raw transcript and when it was spoken, in seconds from the start of the audio.
public struct WordTiming: Codable, Equatable, Sendable {
    public var word: String
    public var start: TimeInterval
    public var end: TimeInterval

    public init(word: String, start: TimeInterval, end: TimeInterval) {
        self.word = word
        self.start = start
        self.end = end
    }
}

/// Seconds each stage took; nil for a stage that did not run.
public struct StageTimings: Codable, Equatable, Sendable {
    public var transcription: TimeInterval?
    public var wordListRecheck: TimeInterval?
    public var cleanup: TimeInterval?
    public var finishing: TimeInterval?
    public var paste: TimeInterval?

    public init(
        transcription: TimeInterval? = nil,
        wordListRecheck: TimeInterval? = nil,
        cleanup: TimeInterval? = nil,
        finishing: TimeInterval? = nil,
        paste: TimeInterval? = nil
    ) {
        self.transcription = transcription
        self.wordListRecheck = wordListRecheck
        self.cleanup = cleanup
        self.finishing = finishing
        self.paste = paste
    }
}

/// Why a dictation fell back to pasting the raw transcript.
public enum FallbackReason: String, Codable, Equatable, Sendable {
    case slow, offline, unparseable, cutOff, wordsNotInTranscript, lengthOutOfRange, answeredInstead
}

/// Why the app stopped watching the text field for the final text.
public enum WatchStopReason: String, Codable, Equatable, Sendable {
    case fieldCleared, focusLost, newDictation, timeLimit, surroundingTextLost
}
