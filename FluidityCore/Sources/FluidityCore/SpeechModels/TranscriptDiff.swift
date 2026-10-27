import Foundation

/// The words two transcripts of one recording disagree on, found by a word-level longest common subsequence.
public enum TranscriptDiff {
    /// One run of words that differ: what the left transcript says there and what the right one says.
    /// Either side is empty when the other inserted words. The ranges index each transcript's words,
    /// split on whitespace, so a view can mark them in the full text.
    public struct Difference: Equatable, Sendable {
        public var left: String
        public var right: String
        public var leftWords: Range<Int>
        public var rightWords: Range<Int>

        public init(left: String, right: String, leftWords: Range<Int>, rightWords: Range<Int>) {
            self.left = left
            self.right = right
            self.leftWords = leftWords
            self.rightWords = rightWords
        }
    }

    public static func words(_ text: String) -> [String] {
        text.split(whereSeparator: \.isWhitespace).map(String.init)
    }

    public static func differences(_ left: String, _ right: String) -> [Difference] {
        let a = words(left), b = words(right)
        // lengths[i][j] = longest common subsequence of a[i...] and b[j...].
        var lengths = [[Int]](repeating: [Int](repeating: 0, count: b.count + 1), count: a.count + 1)
        for i in stride(from: a.count - 1, through: 0, by: -1) {
            for j in stride(from: b.count - 1, through: 0, by: -1) {
                lengths[i][j] = a[i] == b[j] ? lengths[i + 1][j + 1] + 1 : max(lengths[i + 1][j], lengths[i][j + 1])
            }
        }
        var result: [Difference] = []
        var i = 0, j = 0, start = (left: 0, right: 0)
        func closeRun() {
            guard i > start.left || j > start.right else { return }
            result.append(Difference(
                left: a[start.left..<i].joined(separator: " "), right: b[start.right..<j].joined(separator: " "),
                leftWords: start.left..<i, rightWords: start.right..<j))
        }
        while i < a.count || j < b.count {
            if i < a.count, j < b.count, a[i] == b[j] {
                closeRun()
                i += 1
                j += 1
                start = (i, j)
            } else if j == b.count || (i < a.count && lengths[i + 1][j] >= lengths[i][j + 1]) {
                i += 1
            } else {
                j += 1
            }
        }
        closeRun()
        return result
    }
}
