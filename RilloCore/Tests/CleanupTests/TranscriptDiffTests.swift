import RilloCore
import Testing

struct TranscriptDiffTests {
    @Test(arguments: [
        // Reporting matching words as differences turns this red.
        ("tell Priya the build is green", "tell Priya the build is green", [TranscriptDiff.Difference]()),
        // Splitting one changed word into a deletion and an insertion turns this red.
        ("tell Priya the build", "tell Pria the build",
         [.init(left: "Priya", right: "Pria", leftWords: 1..<2, rightWords: 1..<2)]),
        // Losing words only the right transcript has turns this red.
        ("move to 10:30", "move it to 10:30",
         [.init(left: "", right: "it", leftWords: 1..<1, rightWords: 1..<2)]),
        // Losing words only the left transcript has turns this red.
        ("move it to 10:30", "move to 10:30",
         [.init(left: "it", right: "", leftWords: 1..<2, rightWords: 1..<1)]),
    ])
    func differences(left: String, right: String, expected: [TranscriptDiff.Difference]) {
        #expect(TranscriptDiff.differences(left, right) == expected)
    }

    // Turns red if the key is ignored, so "Priya." and "priya" count as a change.
    @Test func keyDecidesWhichWordsMatch() {
        #expect(TranscriptDiff.differences("tell priya", "Tell Priya.", key: { $0.lowercased().filter(\.isLetter) }).isEmpty)
    }
}

struct HistoryComparisonTests {
    private func marked(_ words: [HistoryComparison.Word]) -> String {
        words.map { $0.change == nil ? $0.text : "[\($0.text)]" }.joined(separator: " ")
    }

    // Turns red if a row takes raw words from the wrong sentence, a removal at a sentence start goes to the sentence
    // before it, punctuation or case counts as a change, or a word is lost.
    @Test func rowsLineUpOneSentenceEach() {
        let comparison = HistoryComparison(
            raw: "um so I think we should uh move it to three pm um can someone check",
            pasted: "I think we should move it to 3 PM. Can someone check?")
        #expect(comparison.rows.map { marked($0.raw) } == [
            "[um] [so] I think we should [uh] move it to [three] pm",
            "[um] can someone check",
        ])
        #expect(comparison.rows.map { marked($0.pasted) } == [
            "I think we should move it to [3] PM.",
            "Can someone check?",
        ])
    }

    // Turns red if a rewrite's two sides stop sharing a change, so pointing at one no longer outlines the other,
    // or a removal with no replacement shares a change with one.
    @Test func aRewriteSharesOneChangeAcrossBothSides() throws {
        let row = try #require(HistoryComparison(raw: "um on the twelfth no wait the fourteenth", pasted: "On the 14th.").rows.first)
        let rewritten = Set(row.raw.filter { ["twelfth", "no", "wait", "the", "fourteenth"].contains($0.text) && $0.index > 2 }.map(\.change))
        #expect(rewritten.count == 1 && !rewritten.contains(nil))
        #expect(Set(row.pasted.filter { $0.text == "14th." }.map(\.change)) == rewritten)
        #expect(row.raw.first?.change != nil && !rewritten.contains(row.raw.first?.change))
    }

    // Turns red if a list number such as "2." splits a sentence, or a line break does not.
    @Test(arguments: [
        ("1. Milk\n2. Eggs", ["1. Milk", "2. Eggs"]),
        ("See you soon Thanks", ["See you soon Thanks"]),
        ("Done! Next?\nLast line", ["Done!", "Next?", "Last line"]),
    ])
    func sentences(text: String, expected: [String]) {
        let rows = HistoryComparison(raw: text, pasted: text).rows
        #expect(rows.map { $0.pasted.map(\.text).joined(separator: " ") } == expected)
    }

    // Turns red if timings stop pairing with transcript words in order, or a timing with no matching word
    // takes another word's place.
    @Test func timingsFindTheirTranscriptWords() {
        let timings = ["hello", "there", "world"].enumerated().map { WordTiming(word: $1, start: Double($0), end: Double($0) + 1) }
        #expect(WordTiming.transcriptIndices(timings, in: "Hello there, world.") == [0, 1, 2])
        #expect(WordTiming.transcriptIndices(timings, in: "Hello world.") == [0, nil, 1])
    }
}
