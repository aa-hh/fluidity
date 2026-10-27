import FluidityCore
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
}
