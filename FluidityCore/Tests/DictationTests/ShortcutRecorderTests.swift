import FluidityCore
import Testing

private final class FakeShortcutStore: ShortcutStoring {
    var dictationKey = KeyChoice(keyCode: 61)
    var pasteAgainKey: KeyChoice? = KeyChoice(keyCode: 9, modifiers: [.control, .option])
}

struct RecorderCase: CustomTestStringConvertible, Sendable {
    let name: String
    let events: [RawKeyEvent]
    let expected: ShortcutRecording
    var testDescription: String { name }
}

private let recorderCases: [RecorderCase] = [
    RecorderCase(
        name: "left Command alone, captured on release",
        events: [.init(kind: .flagsChanged, keyCode: 55, flags: [.command, .leftCommand]), .init(kind: .flagsChanged, keyCode: 55)],
        expected: .accepted(KeyChoice(keyCode: 55))
    ),
    RecorderCase(
        name: "right Command alone",
        events: [.init(kind: .flagsChanged, keyCode: 54, flags: [.command, .rightCommand]), .init(kind: .flagsChanged, keyCode: 54)],
        expected: .accepted(KeyChoice(keyCode: 54))
    ),
    RecorderCase(
        name: "modifier then key gives the ordinary key with that modifier",
        events: [.init(kind: .flagsChanged, keyCode: 55, flags: [.command, .leftCommand]), .init(kind: .keyDown, keyCode: 49, flags: [.command, .leftCommand])],
        expected: .accepted(KeyChoice(keyCode: 49, modifiers: .command))
    ),
    RecorderCase(
        name: "bare function key",
        events: [.init(kind: .keyDown, keyCode: 96, flags: .function)],
        expected: .accepted(KeyChoice(keyCode: 96))
    ),
    RecorderCase(
        name: "Escape alone",
        events: [.init(kind: .keyDown, keyCode: 53)],
        expected: .rejected(.escape)
    ),
    RecorderCase(
        name: "Return alone",
        events: [.init(kind: .keyDown, keyCode: 36)],
        expected: .rejected(.returnOrTab)
    ),
    RecorderCase(
        name: "Tab alone",
        events: [.init(kind: .keyDown, keyCode: 48)],
        expected: .rejected(.returnOrTab)
    ),
    RecorderCase(
        name: "bare letter",
        events: [.init(kind: .keyDown, keyCode: 0)],
        expected: .rejected(.typingKeyWithoutModifier)
    ),
    RecorderCase(
        name: "digit with Shift only",
        events: [.init(kind: .keyDown, keyCode: 18, flags: [.shift, .leftShift])],
        expected: .rejected(.typingKeyWithoutModifier)
    ),
    RecorderCase(
        name: "same as the paste-again shortcut",
        events: [.init(kind: .keyDown, keyCode: 9, flags: [.control, .option])],
        expected: .rejected(.sameAsOtherShortcut)
    ),
]

// Turns red if the recorder accepts a key that can't work, rejects one that can, or confuses left and right.
@Test(arguments: recorderCases)
func recorderAcceptsOrRejectsTheNextKey(_ testCase: RecorderCase) {
    let store = FakeShortcutStore()
    var recorder = ShortcutRecorder(store: store)
    recorder.arm(for: .dictation)
    let results = testCase.events.map { recorder.record($0) }
    #expect(results.dropLast().allSatisfy { $0 == nil })
    #expect(results.last == testCase.expected)
    if case .accepted(let choice) = testCase.expected {
        #expect(store.dictationKey == choice)
    } else {
        #expect(store.dictationKey == KeyChoice(keyCode: 61))
    }
}

// Turns red if the paste-again slot saves to the wrong setting or is not checked against the dictation key.
@Test func pasteAgainSlotSavesItsOwnSettingAndRejectsTheDictationKey() {
    let store = FakeShortcutStore()
    var recorder = ShortcutRecorder(store: store)
    recorder.arm(for: .pasteAgain)
    #expect(recorder.record(.init(kind: .flagsChanged, keyCode: 61, flags: [.option, .rightOption])) == nil)
    #expect(recorder.record(.init(kind: .flagsChanged, keyCode: 61)) == .rejected(.sameAsOtherShortcut))
    #expect(recorder.record(.init(kind: .keyDown, keyCode: 35, flags: .command)) == .accepted(KeyChoice(keyCode: 35, modifiers: .command)))
    #expect(store.pasteAgainKey == KeyChoice(keyCode: 35, modifiers: .command))
    #expect(recorder.slot == nil)
}

// Turns red if an unarmed recorder captures keys.
@Test func unarmedRecorderIgnoresKeys() {
    var recorder = ShortcutRecorder(store: FakeShortcutStore())
    #expect(recorder.record(.init(kind: .keyDown, keyCode: 49, flags: .command)) == nil)
}

// Turns red if the settings text for a key changes shape or names the wrong side.
@Test(arguments: [
    (KeyChoice(keyCode: 61), "⌥ Right Option"),
    (KeyChoice(keyCode: 58), "⌥ Left Option"),
    (KeyChoice(keyCode: 54), "⌘ Right Command"),
    (KeyChoice(keyCode: 56), "⇧ Left Shift"),
    (KeyChoice(keyCode: 62), "⌃ Right Control"),
    (KeyChoice(keyCode: 63), "Fn"),
    (KeyChoice(keyCode: 49, modifiers: .command), "⌘ Space"),
    (KeyChoice(keyCode: 0, modifiers: [.command, .shift, .control, .option]), "⌃⌥⇧⌘ A"),
    (KeyChoice(keyCode: 96), "F5"),
])
func keyChoiceDescription(_ choice: KeyChoice, _ text: String) {
    #expect(choice.description == text)
}

// Turns red if a modifier choice loses its side or keeps stray modifier flags.
@Test func modifierChoiceKnowsItsSideAndDropsFlags() {
    let choice = KeyChoice(keyCode: 60, modifiers: .command)
    #expect(choice.isModifier)
    #expect(choice.side == .right)
    #expect(choice.modifiers.isEmpty)
    #expect(KeyChoice(keyCode: 49, modifiers: [.command, .leftCommand, .function]).modifiers == .command)
}
