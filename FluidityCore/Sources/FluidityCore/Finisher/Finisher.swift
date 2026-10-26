import Foundation

/// Matches the cleaned text's spacing and capitals to the text around the cursor before the paste.
public struct Finisher: Sendable {
    /// Returns `text` finished for the cursor position. `before == nil` means the field could not be read, so `text` comes back unchanged.
    public static func finish(
        _ text: String,
        before: String?,
        after: String?,
        selectedText: String?,
        wordList: Set<String>
    ) -> String {
        guard let before, !text.isEmpty else { return text }
        let after = after ?? ""
        let words = Set(wordList.map { $0.lowercased() })
        var result = text

        // Rule 3: lower-case the first letter mid-sentence.
        let trimmedBefore = before.reversed().drop { $0 == " " || $0 == "\t" }
        if let last = trimmedBefore.first, !".!?\n".contains(last),
           let first = result.split(separator: " ").first,
           !keepsCapital(first, words) {
            result = lowercasingFirst(result)
        }

        // Rule 4: drop the final sentence mark when the text after continues the sentence.
        if let next = after.first, next.isLowercase || next.isPunctuation,
           let last = result.last, ".!?".contains(last) {
            result.removeLast()
        }

        // Rule 5: a one-word result keeps its capital only if it is on the word list.
        let parts = result.split(separator: " ")
        if parts.count == 1, !keepsCapital(parts[0], words) {
            result = lowercasingFirst(result)
        }

        // Rule 6 decides spacing when a selection is replaced; otherwise rules 1 and 2.
        let leading: Bool
        let trailing: Bool
        if let selectedText, !selectedText.isEmpty {
            leading = selectedText.first == " "
            trailing = selectedText.last == " "
        } else {
            leading = before.last.map { $0 != " " && !$0.isNewline } ?? false
            trailing = after.first.map { $0.isLetter || $0.isNumber } ?? false
        }
        if leading, result.first != " " { result = " " + result }
        if trailing, result.last != " " { result += " " }
        return result
    }

    private static let iForms: Set<String> = ["i", "i'm", "i'll", "i've", "i'd"]

    private static func keepsCapital(_ word: Substring, _ words: Set<String>) -> Bool {
        let bare = word.trimmingCharacters(in: .punctuationCharacters.subtracting(["'"])).lowercased()
        return iForms.contains(bare) || words.contains(bare)
    }

    private static func lowercasingFirst(_ s: String) -> String {
        guard let first = s.first else { return s }
        return first.lowercased() + s.dropFirst()
    }
}
