import Foundation

// The parts the controller talks to, each cut down to the calls it makes.
// The values they exchange are nested in `DictationController` so they cannot
// clash with the parts' own types in this module.

/// The microphone.
public protocol AudioCapturing: Sendable {
    /// Starts recording; the stream carries audio as it arrives, for the live preview.
    func start() async throws -> AsyncStream<[Float]>
    /// Stops recording and returns everything recorded since `start`.
    func stop() async -> DictationController.Recording
}

/// The speech model.
public protocol Transcribing: Sendable {
    /// Live preview text for the audio so far; each element replaces the one before.
    func preview(_ audio: AsyncStream<[Float]>) -> AsyncStream<String>
    /// The final pass over the whole recording.
    func transcribe(_ recording: DictationController.Recording) async throws -> DictationController.Transcript
}

/// Cleanup of the raw transcript.
public protocol CleaningUp: Sendable {
    /// False when cleanup is switched off or has no key.
    var isOn: Bool { get }
    func clean(_ rawTranscript: String) async -> DictationController.CleanupResult
}

/// The focused text field.
public protocol FieldContextReading: Sendable {
    /// Nil when no text field can be read.
    func read() async -> DictationController.FieldContext?
}

/// The spacing and capitals rules applied before pasting.
public protocol Finishing: Sendable {
    func finish(_ text: String, in field: DictationController.FieldContext?) -> String
}

public protocol Pasting: Sendable {
    func paste(_ text: String) async -> DictationController.PasteOutcome
}

/// Watches the field after a paste for the final text.
public protocol EditWatching: Sendable {
    /// Returns when watching stops. When the calling task is cancelled, because a
    /// new dictation started, it returns at once with the final text read so far.
    func watch(pastedText: String) async -> DictationController.WatchStop
}

public protocol DictationStoring: Sendable {
    func save(_ record: DictationRecord, recording: DictationController.Recording) async
    /// Can be called from a cancelled task; the write must still happen.
    func updateFinalText(_ finalText: String?, reason: WatchStopReason, for id: UUID) async
    /// Receives the audio of a cancelled dictation, which by default is not kept.
    func dictationCancelled(_ recording: DictationController.Recording) async
}

extension DictationStoring {
    public func dictationCancelled(_ recording: DictationController.Recording) async {}
}

public protocol PermissionChecking: Sendable {
    var microphoneGranted: Bool { get }
    var accessibilityGranted: Bool { get }
}

extension DictationController {
    /// Where a dictation is, from key down to the end of watching.
    public enum Phase: Equatable, Sendable {
        case ready
        case recording(RecordingMode)
        /// The 200 ms of audio after release, then the final pass.
        case finishing
        case cleaning
        case pasting
        case watching
    }

    public enum RecordingMode: Equatable, Sendable {
        /// Started by a tap; stops at the next key press.
        case handsFree
        /// Stops when the key is released.
        case held
    }

    public enum Permission: Equatable, Sendable {
        case microphone, accessibility
    }

    /// Mono audio of one dictation.
    public struct Recording: Equatable, Sendable {
        public var samples: [Float]
        public var sampleRate: Double

        public init(samples: [Float], sampleRate: Double) {
            self.samples = samples
            self.sampleRate = sampleRate
        }
    }

    /// The final pass's raw transcript.
    public struct Transcript: Equatable, Sendable {
        public var text: String
        public var wordTimings: [WordTiming]

        public init(text: String, wordTimings: [WordTiming] = []) {
            self.text = text
            self.wordTimings = wordTimings
        }
    }

    public enum CleanupResult: Equatable, Sendable {
        case cleaned(String)
        case fallback(FallbackReason)
    }

    public struct FieldContext: Equatable, Sendable {
        public var textBeforeCursor: String
        public var selectedText: String
        public var textAfterCursor: String
        /// A password field: nothing is saved and nothing is watched.
        public var isSecure: Bool
        /// Bundle identifier of the app that has focus.
        public var app: String?

        public init(textBeforeCursor: String, selectedText: String, textAfterCursor: String, isSecure: Bool, app: String?) {
            self.textBeforeCursor = textBeforeCursor
            self.selectedText = selectedText
            self.textAfterCursor = textAfterCursor
            self.isSecure = isSecure
            self.app = app
        }
    }

    public enum PasteOutcome: Equatable, Sendable {
        case landed, nowhereToPaste
    }

    public struct WatchStop: Equatable, Sendable {
        public var reason: WatchStopReason
        public var finalText: String?

        public init(reason: WatchStopReason, finalText: String?) {
            self.reason = reason
            self.finalText = finalText
        }
    }
}
