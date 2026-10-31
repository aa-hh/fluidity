import Foundation

/// The scripted dictation the General pane's preview plays: words heard one by one, a pause,
/// processing when cleanup is on, then the paste.
public enum SpeechPreview {
    public static let rawSentence = "um so I think we should uh move the meeting to Thursday"
    public static let cleanedSentence = "I think we should move the meeting to Thursday."

    public static func pastedText(cleanupOn: Bool) -> String {
        cleanupOn ? cleanedSentence : rawSentence
    }

    public enum Phase: Equatable {
        case listening(wordsHeard: Int)
        case processing
        case pasted
    }

    /// Milliseconds between words, after the last word, and spent processing (cleanup only).
    private static let wordPace = 220
    private static let hold = 400
    private static let processing = 1000
    private static let wordCount = rawSentence.split(separator: " ").count

    public static func phase(at elapsed: Duration, cleanupOn: Bool, reduceMotion: Bool) -> Phase {
        if reduceMotion { return .pasted }
        let (seconds, attoseconds) = elapsed.components
        let ms = Int(seconds) * 1000 + Int(attoseconds / 1_000_000_000_000_000)
        let listeningEnds = (wordCount - 1) * wordPace + hold
        if ms < listeningEnds { return .listening(wordsHeard: min(ms / wordPace + 1, wordCount)) }
        if cleanupOn, ms < listeningEnds + processing { return .processing }
        return .pasted
    }
}
