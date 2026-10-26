import Foundation
import FluidityCore
import FluidityTestSupport
import Testing

@MainActor
private final class FakePasteboard: Pasteboard {
    var items: [[PasteboardSnapshot.Representation]]
    var changeCount = 0
    var holdsOurItem = false
    var refusesWrites = false
    private var onRequest: (@Sendable () -> Void)?

    init(items: [[PasteboardSnapshot.Representation]]) {
        self.items = items
    }

    func snapshot() -> PasteboardSnapshot { PasteboardSnapshot(items: items) }

    func writeDelayed(_ text: String, onRequest: @escaping @Sendable () -> Void) -> Bool {
        changeCount += 1
        items = []
        guard !refusesWrites else { return false }
        holdsOurItem = true
        self.onRequest = onRequest
        return true
    }

    func restore(_ snapshot: PasteboardSnapshot) {
        changeCount += 1
        items = snapshot.items
        holdsOurItem = false
    }

    /// Another app reads the text, as a text field does on ⌘V.
    func appReadsText() { onRequest?() }

    /// The user copies something else.
    func copy(_ newItems: [[PasteboardSnapshot.Representation]]) {
        changeCount += 1
        items = newItems
        holdsOurItem = false
    }
}

@MainActor
private final class FakeKeySender: KeySender {
    var pastes = 0
    func sendPaste() { pastes += 1 }
}

@MainActor
private final class FakeFocusChecking: FocusChecking {
    var focus: FocusIdentity?
    init(_ focus: FocusIdentity?) { self.focus = focus }
    func currentFocus() -> FocusIdentity? { focus }
}

private let startFocus = FocusIdentity(processID: 42, element: 7)

private let original: [[PasteboardSnapshot.Representation]] = [
    [
        .init(type: "public.rtf", data: Data("{\\rtf1 hi}".utf8)),
        .init(type: "public.utf8-plain-text", data: Data("hi".utf8)),
    ],
    [.init(type: "public.png", data: Data([0x89, 0x50, 0x4E, 0x47]))],
]

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct PasterTests {
    let clock = ManualClock()
    fileprivate let pasteboard = FakePasteboard(items: original)
    fileprivate let keys = FakeKeySender()

    func makePaster(focusNow: FocusIdentity? = startFocus) -> Paster {
        Paster(pasteboard: pasteboard, keySender: keys, focusChecking: FakeFocusChecking(focusNow), clock: clock)
    }

    /// Lets the paste run up to sending ⌘V before the test moves the clock.
    func untilPasteSent() async {
        while keys.pastes == 0 { await Task.yield() }
    }

    @Test func landedPasteRecordsDurationAndRestoresEveryItemAfterTheDelay() async {
        // Fails if the duration is not the time until the read, the restore runs before the delay, or a restore drops an item or type.
        let paster = makePaster()
        let paste = Task { await paster.paste("hello", focusAtStart: startFocus) }
        await untilPasteSent()
        await clock.advance(by: .milliseconds(120))
        pasteboard.appReadsText()
        await clock.advance(by: .milliseconds(299))
        #expect(pasteboard.holdsOurItem)
        await clock.advance(by: .milliseconds(1))

        #expect(await paste.value == .landed(.milliseconds(120)))
        #expect(pasteboard.items == original)
        #expect(keys.pastes == 1)
    }

    @Test func nothingAskingForTheTextFailsWithoutASecondPaste() async {
        // Fails if a paste counts as landed without a read, or if ⌘V is sent again after the time limit.
        let paster = makePaster()
        let paste = Task { await paster.paste("hello", focusAtStart: startFocus) }
        await untilPasteSent()
        await clock.advance(by: .milliseconds(800))
        await clock.advance(by: .milliseconds(300))

        #expect(await paste.value == .failed(.nothingAskedForText))
        #expect(keys.pastes == 1)
        #expect(pasteboard.items == original)
    }

    @Test(arguments: [FocusIdentity(processID: 42, element: 8), FocusIdentity(processID: 43, element: 7), nil] as [FocusIdentity?])
    func movedFocusLeavesTheClipboardUntouched(focusNow: FocusIdentity?) async {
        // Fails if a paste goes ahead, or the clipboard is written, after focus left the field the dictation started in.
        let result = await makePaster(focusNow: focusNow).paste("hello", focusAtStart: startFocus)

        #expect(result == .failed(.focusMoved))
        #expect(pasteboard.changeCount == 0)
        #expect(keys.pastes == 0)
    }

    @Test func aCopyDuringTheDelayIsNotOverwritten() async {
        // Fails if the restore runs without checking that the clipboard still holds our text.
        let copied: [[PasteboardSnapshot.Representation]] = [[.init(type: "public.utf8-plain-text", data: Data("new".utf8))]]
        let paster = makePaster()
        let paste = Task { await paster.paste("hello", focusAtStart: startFocus) }
        await untilPasteSent()
        pasteboard.appReadsText()
        pasteboard.copy(copied)
        await clock.advance(by: .milliseconds(300))

        #expect(await paste.value == .landed(.zero))
        #expect(pasteboard.items == copied)
    }

    @Test func aRefusedWritePutsTheOldClipboardBackAtOnce() async {
        // Fails if a clipboard write that fails leaves the user's clipboard empty, or still sends ⌘V.
        pasteboard.refusesWrites = true
        let result = await makePaster().paste("hello", focusAtStart: startFocus)

        #expect(result == .failed(.clipboardUnavailable))
        #expect(pasteboard.items == original)
        #expect(keys.pastes == 0)
    }
}
