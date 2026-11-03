import Foundation

/// One dictation's raw transcript beside its pasted text, one pasted sentence per row, with the words cleanup
/// removed or rewrote marked on the raw side and the words it added or rewrote marked on the pasted side.
///
/// Rows come from the same word alignment that finds the changes: each pasted sentence takes the raw words matched
/// to it, and removed words go with the sentence after them, or the last one at the end. Words match ignoring case
/// and punctuation, so "Priya" and "Priya." are the same word.
public struct HistoryComparison: Equatable, Sendable {
    public struct Word: Equatable, Sendable {
        public var text: String
        /// Its position among its own text's words, split on whitespace.
        public var index: Int
        /// The change it belongs to, shared with the other side's words in the same change; nil when unchanged.
        public var change: Int?

        public init(text: String, index: Int, change: Int? = nil) {
            self.text = text
            self.index = index
            self.change = change
        }
    }

    public struct Row: Equatable, Sendable {
        public var raw: [Word]
        public var pasted: [Word]

        public init(raw: [Word], pasted: [Word]) {
            self.raw = raw
            self.pasted = pasted
        }
    }

    public var rows: [Row]

    public init(raw: String, pasted: String) {
        let rawWords = TranscriptDiff.words(raw)
        let pastedSentence = Self.sentenceNumbers(pasted)
        let pastedWords = TranscriptDiff.words(pasted)
        let differences = TranscriptDiff.differences(raw, pasted, key: Self.matchKey)

        var rawChange = [Int?](repeating: nil, count: rawWords.count)
        var pastedChange = [Int?](repeating: nil, count: pastedWords.count)
        // The pasted word each raw word lines up with: its match, or the first word of its replacement.
        var anchor = [Int?](repeating: nil, count: rawWords.count)
        var i = 0, j = 0
        func matchUpTo(_ rawEnd: Int) {
            while i < rawEnd {
                anchor[i] = j
                i += 1
                j += 1
            }
        }
        for (number, difference) in differences.enumerated() {
            matchUpTo(difference.leftWords.lowerBound)
            for k in difference.leftWords {
                rawChange[k] = number
                anchor[k] = difference.rightWords.isEmpty ? nil : difference.rightWords.lowerBound
            }
            for k in difference.rightWords { pastedChange[k] = number }
            i = difference.leftWords.upperBound
            j = difference.rightWords.upperBound
        }
        matchUpTo(rawWords.count)

        let rowCount = max(1, (pastedSentence.last ?? 0) + 1)
        var rows = [Row](repeating: Row(raw: [], pasted: []), count: rowCount)
        for (k, word) in pastedWords.enumerated() {
            rows[pastedSentence[k]].pasted.append(Word(text: word, index: k, change: pastedChange[k]))
        }
        var rawRow = [Int](repeating: rowCount - 1, count: rawWords.count)
        for k in rawWords.indices.reversed() {
            rawRow[k] = anchor[k].map { pastedSentence[$0] } ?? (k + 1 < rawWords.count ? rawRow[k + 1] : rowCount - 1)
        }
        for (k, word) in rawWords.enumerated() {
            rows[rawRow[k]].raw.append(Word(text: word, index: k, change: rawChange[k]))
        }
        self.rows = rows
    }

    /// Lowercased, with punctuation and symbols removed; a word of only punctuation keeps itself.
    static func matchKey(_ word: String) -> String {
        let letters = word.lowercased().unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) }
        return letters.isEmpty ? word : String(String.UnicodeScalarView(letters))
    }

    /// The sentence each word of `text` belongs to. A sentence ends at a line break, or after a word ending in
    /// `.`, `?`, `!` or `…`, closing quotes and brackets aside; a list number such as "2." ends nothing.
    static func sentenceNumbers(_ text: String) -> [Int] {
        var numbers: [Int] = []
        var sentence = 0
        for line in text.split(whereSeparator: \.isNewline) {
            let words = TranscriptDiff.words(String(line))
            guard !words.isEmpty else { continue }
            for word in words {
                numbers.append(sentence)
                let trimmed = word.trimmingCharacters(in: CharacterSet(charactersIn: "\"'”’)]"))
                let isListNumber = trimmed.dropLast().allSatisfy(\.isNumber)
                if let last = trimmed.last, ".?!…".contains(last), !isListNumber { sentence += 1 }
            }
            if numbers.last == sentence { sentence += 1 }
        }
        return numbers
    }
}

extension WordTiming {
    /// The word of `transcript` (split on whitespace) each timing was heard as, nil for one that matches none.
    /// Equal counts pair up in order; otherwise each timing takes the next word that matches it, ignoring case
    /// and punctuation, within a few words.
    public static func transcriptIndices(_ timings: [WordTiming], in transcript: String) -> [Int?] {
        let words = TranscriptDiff.words(transcript)
        if words.count == timings.count { return Array(words.indices) }
        var next = 0
        return timings.map { timing in
            let key = HistoryComparison.matchKey(timing.word)
            let window = next..<min(words.count, next + 4)
            guard let found = window.first(where: { HistoryComparison.matchKey(words[$0]) == key }) else { return nil }
            next = found + 1
            return found
        }
    }
}
