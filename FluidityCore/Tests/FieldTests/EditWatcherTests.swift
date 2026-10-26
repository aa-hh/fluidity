import Foundation
import FluidityCore
import FluidityTestSupport
import Testing

private typealias Reading = (value: String, cursor: Int, hasFocus: Bool, isSecure: Bool)

/// A field that returns its scripted readings one per read and repeats the last one.
private final class ScriptedField: WatchedField, @unchecked Sendable {
    private let lock = NSLock()
    private var script: [Reading?]
    private var reads = 0
    private let changes: AsyncStream<FieldChange>.Continuation
    let notifications: AsyncStream<FieldChange>

    init(_ script: [Reading?]) {
        self.script = script
        (notifications, changes) = AsyncStream.makeStream(of: FieldChange.self)
    }

    func read() -> Reading? {
        lock.withLock {
            reads += 1
            return script.count > 1 ? script.removeFirst() : script[0]
        }
    }

    func replaceScript(with script: [Reading?]) {
        lock.withLock { self.script = script }
    }

    /// Yields until the field is read again, giving up after a bounded number of yields.
    func waitForNextRead() async {
        let before = lock.withLock { reads }
        for _ in 0..<10_000 where lock.withLock({ reads }) == before { await Task.yield() }
    }

    func send(_ change: FieldChange) {
        changes.yield(change)
    }
}

private let textBefore = "Dear Sam, "
private let pasted = "the meeting is at noon"
private let textAfter = " Thanks."

/// The field holding `head + tail`, with the cursor between them.
private func showing(_ head: String, _ tail: String = "", focus: Bool = true, secure: Bool = false) -> Reading {
    (head + tail, head.utf16.count, focus, secure)
}

private let landed = showing(textBefore + pasted, textAfter)
private let corrected = showing(textBefore + "the meeting is at one", textAfter)
private let notLanded = showing(textBefore, textAfter)
private let cleared = showing("")

private func startWatch(_ field: ScriptedField, on clock: ManualClock) -> (EditWatcher, Task<WatchOutcome?, Never>) {
    let watcher = EditWatcher(clock: clock)
    let task = Task { await watcher.watch(pastedText: pasted, in: field, textBefore: textBefore, textAfter: textAfter) }
    return (watcher, task)
}

private func advance(_ clock: ManualClock, by total: Duration) async {
    for _ in 0..<Int(total / .milliseconds(50)) { await clock.advance(by: .milliseconds(50)) }
}

/// Runs a watch over `script` past the 60 s limit, so every watch ends.
private func outcome(of script: [Reading?]) async -> WatchOutcome? {
    let clock = ManualClock()
    let (_, task) = startWatch(ScriptedField(script), on: clock)
    await advance(clock, by: .seconds(61))
    return await task.value
}

struct WatchCase: Sendable, CustomTestStringConvertible {
    let testDescription: String
    fileprivate let script: [Reading?]
    let expected: WatchOutcome?
}

@Suite(.timeLimit(.minutes(1)))
struct EditWatcherTests {
    static let stopCases: [WatchCase] = [
        WatchCase(testDescription: "field cleared after a correction", script: [landed, corrected, cleared],
                  expected: WatchOutcome(finalText: "the meeting is at one", stopReason: .fieldCleared)),
        WatchCase(testDescription: "only a newline left", script: [landed, showing("\n")],
                  expected: WatchOutcome(finalText: pasted, stopReason: .fieldCleared)),
        WatchCase(testDescription: "text typed before the paste",
                  script: [landed, showing("Hi all. " + textBefore + pasted, textAfter), cleared],
                  expected: WatchOutcome(finalText: pasted, stopReason: .fieldCleared)),
        WatchCase(testDescription: "focus gone", script: [landed, showing(textBefore + pasted, textAfter, focus: false)],
                  expected: WatchOutcome(finalText: pasted, stopReason: .focusLost)),
        WatchCase(testDescription: "field unreadable", script: [landed, nil],
                  expected: WatchOutcome(finalText: pasted, stopReason: .focusLost)),
        WatchCase(testDescription: "focus back within 250 ms",
                  script: [landed, showing(textBefore + pasted, textAfter, focus: false)]
                      + Array(repeating: landed, count: 10) + [cleared],
                  expected: WatchOutcome(finalText: pasted, stopReason: .fieldCleared)),
        WatchCase(testDescription: "text before the paste deleted after a correction",
                  script: [landed, corrected, showing("the meeting is at one", textAfter)],
                  expected: WatchOutcome(finalText: "the meeting is at one", stopReason: .surroundingTextLost)),
        WatchCase(testDescription: "60 s pass", script: [landed],
                  expected: WatchOutcome(finalText: pasted, stopReason: .timeLimit)),
    ]

    // Reporting the wrong reason, keeping a reading other than the last one with text on both sides,
    // or stopping on a focus loss shorter than 250 ms fails a row.
    @Test(arguments: stopCases)
    func stopsWithTheLastGoodReading(_ watch: WatchCase) async {
        #expect(await outcome(of: watch.script) == watch.expected)
    }

    static let baselineCases: [WatchCase] = [
        WatchCase(testDescription: "paste found on the third read", script: [notLanded, notLanded, landed, cleared],
                  expected: WatchOutcome(finalText: pasted, stopReason: .fieldCleared)),
        WatchCase(testDescription: "paste never found", script: [notLanded],
                  expected: WatchOutcome(finalText: pasted, stopReason: .surroundingTextLost)),
        WatchCase(testDescription: "cursor not at the end of the paste", script: [showing(textBefore, pasted + textAfter)],
                  expected: WatchOutcome(finalText: pasted, stopReason: .surroundingTextLost)),
    ]

    // Giving up on the paste before the third read, waiting on it past 1 s,
    // or accepting it with the cursor elsewhere fails a row.
    @Test(arguments: baselineCases)
    func waitsUpToOneSecondForThePaste(_ watch: WatchCase) async {
        #expect(await outcome(of: watch.script) == watch.expected)
    }

    // Reading a secure field past its first reading, or recording anything from it, fails a row.
    @Test(arguments: [
        [showing(textBefore + pasted, textAfter, secure: true)],
        [landed, showing(textBefore + pasted, textAfter, secure: true)],
    ] as [[Reading?]])
    fileprivate func secureFieldIsNeverRecorded(_ script: [Reading?]) async {
        #expect(await outcome(of: script) == nil)
    }

    // Ignoring endForNewDictation lets this watch run on to the 60 s limit.
    @Test func newDictationEndsTheWatch() async {
        let clock = ManualClock()
        let (watcher, task) = startWatch(ScriptedField([landed]), on: clock)
        await advance(clock, by: .milliseconds(1500))
        await watcher.endForNewDictation()
        await advance(clock, by: .seconds(60))
        #expect(await task.value == WatchOutcome(finalText: pasted, stopReason: .newDictation))
    }

    // Ignoring the field's notifications leaves the correction unread before the next timed read sees the field cleared.
    @Test func notificationReadsTheFieldBetweenTimedReads() async {
        let clock = ManualClock()
        let field = ScriptedField([landed])
        let (_, task) = startWatch(field, on: clock)
        await advance(clock, by: .milliseconds(1200))
        field.replaceScript(with: [corrected])
        field.send(.valueChanged)
        await field.waitForNextRead()
        field.replaceScript(with: [cleared])
        await advance(clock, by: .seconds(61))
        #expect(await task.value == WatchOutcome(finalText: "the meeting is at one", stopReason: .fieldCleared))
    }
}
