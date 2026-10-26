import Foundation

/// Decides whether a cleanup reply is safe to paste. The thresholds are starting values to
/// tune from saved fallbacks.
enum OutputCheck {
    static let minimumKnownShare = 0.85
    static let lengthRatio = 0.5...1.5
    static let lengthCheckMinimumWords = 8
    static let answerOpeners = [["sure"], ["here's"], ["i", "can't"]]

    static func fallbackReason(cleaned: String, rawTranscript: String, wordList: [String]) -> FallbackReason? {
        let replyWords = words(cleaned)
        let transcriptWords = words(rawTranscript)

        // Cleanup writes spoken numbers as digits, so words with digits are not counted.
        let checked = replyWords.filter { !$0.contains(where: \.isNumber) }
        let known = Set(transcriptWords + wordList.flatMap(words))
        if !checked.isEmpty, Double(checked.filter(known.contains).count) / Double(checked.count) < minimumKnownShare {
            return .wordsNotInTranscript
        }

        if transcriptWords.count >= lengthCheckMinimumWords,
           !lengthRatio.contains(Double(replyWords.count) / Double(transcriptWords.count)) {
            return .lengthOutOfRange
        }

        if answerOpeners.contains(where: { replyWords.starts(with: $0) && !transcriptWords.starts(with: $0) }) {
            return .answeredInstead
        }
        return nil
    }

    /// Lower-cased words with punctuation removed; apostrophes inside a word are kept.
    static func words(_ text: String) -> [String] {
        text.lowercased()
            .replacingOccurrences(of: "\u{2019}", with: "'")
            .split { !($0.isLetter || $0.isNumber || $0 == "'") }
            .map { $0.trimmingCharacters(in: ["'"]) }
            .filter { !$0.isEmpty }
    }
}
