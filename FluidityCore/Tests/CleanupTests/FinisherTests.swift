import FluidityCore
import Testing

struct FinisherCase: Sendable, CustomTestStringConvertible {
    let name: String
    let before: String?
    let after: String?
    let selected: String?
    let text: String
    let words: Set<String>
    let expected: String
    var testDescription: String { name }
}

// Changing any spacing or capital rule in Finisher.finish turns the matching row red.
let finisherCases: [FinisherCase] = [
    .init(name: "unreadable field pastes unchanged", before: nil, after: "x", selected: nil, text: "Hello there.", words: [], expected: "Hello there."),
    .init(name: "empty text", before: "abc", after: "", selected: nil, text: "", words: [], expected: ""),
    // Rule 1
    .init(name: "1: start of field, no space", before: "", after: "", selected: nil, text: "Hello there.", words: [], expected: "Hello there."),
    .init(name: "1: after a word, space added", before: "Done.", after: "", selected: nil, text: "Next one.", words: [], expected: " Next one."),
    .init(name: "1: after a newline, no space", before: "Done.\n", after: "", selected: nil, text: "Next one.", words: [], expected: "Next one."),
    // Rule 2
    .init(name: "2: letter after, space added", before: "", after: "world", selected: nil, text: "Hello there", words: [], expected: "Hello there "),
    .init(name: "2: digit after, space added", before: "", after: "42", selected: nil, text: "Count to", words: [], expected: "Count to "),
    .init(name: "2: space after, none added", before: "", after: " rest", selected: nil, text: "Go now", words: [], expected: "Go now"),
    // Rule 3
    .init(name: "3: after a comma, lower-cased", before: "Well,", after: "", selected: nil, text: "That works.", words: [], expected: " that works."),
    .init(name: "3: after a full stop, capital kept", before: "Fine. ", after: "", selected: nil, text: "That works.", words: [], expected: "That works."),
    .init(name: "3: word list keeps capital", before: "I met", after: "", selected: nil, text: "Paris today.", words: ["paris"], expected: " Paris today."),
    .init(name: "3: I'm keeps capital", before: "and", after: "", selected: nil, text: "I'm sure.", words: [], expected: " I'm sure."),
    // Rule 4
    .init(name: "4: lower-case after, mark dropped", before: "", after: "and more", selected: nil, text: "It rained.", words: [], expected: "It rained "),
    .init(name: "4: punctuation after, mark dropped", before: "", after: ", then", selected: nil, text: "Stop!", words: ["stop"], expected: "Stop"),
    .init(name: "4: capital after, mark kept", before: "", after: "Then", selected: nil, text: "It rained.", words: [], expected: "It rained. "),
    // Rule 5
    .init(name: "5: single word lower-cased", before: "", after: "", selected: nil, text: "Hello.", words: [], expected: "hello."),
    .init(name: "5: single word on list keeps capital", before: "", after: "", selected: nil, text: "Fluidity.", words: ["Fluidity"], expected: "Fluidity."),
    .init(name: "5: single I keeps capital", before: "", after: "", selected: nil, text: "I", words: [], expected: "I"),
    // Rule 6
    .init(name: "6: selection with spaces both ends", before: "the", after: "dog", selected: " red ", text: "Blue", words: [], expected: " blue "),
    .init(name: "6: selection without spaces", before: "the ", after: " dog", selected: "red", text: "blue", words: [], expected: "blue"),
    // Combined
    .init(name: "insert between two words", before: "I like ", after: "cats", selected: nil, text: "Big fluffy.", words: [], expected: "big fluffy "),
    .init(name: "end of paragraph", before: "First point.", after: "\nNext", selected: nil, text: "Second point.", words: [], expected: " Second point."),
]

@Test(arguments: finisherCases)
func finisherRules(_ c: FinisherCase) {
    #expect(Finisher.finish(c.text, before: c.before, after: c.after, selectedText: c.selected, wordList: c.words) == c.expected)
}
