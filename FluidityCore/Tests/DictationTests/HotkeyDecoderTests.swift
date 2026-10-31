import FluidityCore
import Testing

private let rightOption = KeyChoice(keyCode: 61)
private let commandSpace = KeyChoice(keyCode: 49, modifiers: .command)
private let pasteAgain = KeyChoice(keyCode: 9, modifiers: [.control, .option])

private func flags(_ code: UInt16, _ flags: KeyModifiers) -> RawKeyEvent {
    RawKeyEvent(kind: .flagsChanged, keyCode: code, flags: flags)
}
private func down(_ code: UInt16, _ flags: KeyModifiers = [], repeat isRepeat: Bool = false) -> RawKeyEvent {
    RawKeyEvent(kind: .keyDown, keyCode: code, flags: flags, isRepeat: isRepeat)
}
private func up(_ code: UInt16, _ flags: KeyModifiers = []) -> RawKeyEvent {
    RawKeyEvent(kind: .keyUp, keyCode: code, flags: flags)
}

struct DecoderCase: CustomTestStringConvertible, Sendable {
    let name: String
    let key: KeyChoice
    var recording = false
    let events: [RawKeyEvent]
    let expected: [HotkeyDecision]
    var testDescription: String { name }
}

private let decoderCases: [DecoderCase] = [
    DecoderCase(
        name: "right Option alone goes down and up from flag changes",
        key: rightOption,
        events: [flags(61, [.option, .rightOption]), flags(61, [])],
        expected: [.keyDown, .keyUp]
    ),
    DecoderCase(
        name: "left Option does not trigger a right Option choice",
        key: rightOption,
        events: [flags(58, [.option, .leftOption]), flags(58, [])],
        expected: [.passThrough, .passThrough]
    ),
    DecoderCase(
        name: "releasing right Option while left Option stays down is still key up",
        key: rightOption,
        events: [flags(58, [.option, .leftOption]), flags(61, [.option, .leftOption, .rightOption]), flags(61, [.option, .leftOption])],
        expected: [.passThrough, .keyDown, .keyUp]
    ),
    DecoderCase(
        name: "left Command alone",
        key: KeyChoice(keyCode: 55),
        events: [flags(54, [.command, .rightCommand]), flags(54, []), flags(55, [.command, .leftCommand]), flags(55, [])],
        expected: [.passThrough, .passThrough, .keyDown, .keyUp]
    ),
    DecoderCase(
        name: "Fn alone",
        key: KeyChoice(keyCode: 63),
        events: [flags(63, .function), flags(63, [])],
        expected: [.keyDown, .keyUp]
    ),
    DecoderCase(
        name: "ordinary key with its modifiers, repeats ignored, up after modifier released",
        key: commandSpace,
        events: [down(49, [.command, .leftCommand]), down(49, [.command, .leftCommand], repeat: true), up(49)],
        expected: [.keyDown, .ignore, .keyUp]
    ),
    DecoderCase(
        name: "held ordinary key keeps its repeats after the modifier is let go",
        key: commandSpace,
        events: [down(49, .command), down(49, [], repeat: true), up(49)],
        expected: [.keyDown, .ignore, .keyUp]
    ),
    DecoderCase(
        name: "held paste-again key keeps its repeats after the modifiers are let go",
        key: rightOption,
        events: [down(9, [.control, .option]), down(9, [], repeat: true), up(9)],
        expected: [.pasteAgain, .ignore, .ignore]
    ),
    DecoderCase(
        name: "ordinary key with the wrong modifiers passes through",
        key: commandSpace,
        events: [down(49), up(49), down(49, [.command, .shift]), up(49, [.command, .shift])],
        expected: [.passThrough, .passThrough, .passThrough, .passThrough]
    ),
    DecoderCase(
        name: "Fn and side bits do not count as required modifiers",
        key: commandSpace,
        events: [down(49, [.command, .rightCommand, .function]), up(49)],
        expected: [.keyDown, .keyUp]
    ),
    DecoderCase(
        name: "Escape while recording cancels and swallows its repeat and key up",
        key: rightOption,
        recording: true,
        events: [down(53), down(53, repeat: true), up(53)],
        expected: [.cancel, .ignore, .ignore]
    ),
    DecoderCase(
        name: "Escape while not recording passes through",
        key: rightOption,
        events: [down(53), up(53)],
        expected: [.passThrough, .passThrough]
    ),
    DecoderCase(
        name: "paste-again shortcut reports once and swallows its key up",
        key: rightOption,
        events: [down(9, [.control, .option]), down(9, [.control, .option], repeat: true), up(9, [.control, .option])],
        expected: [.pasteAgain, .ignore, .ignore]
    ),
    DecoderCase(
        name: "other keys pass through",
        key: rightOption,
        events: [down(0), up(0), down(9, .command), up(9, .command)],
        expected: [.passThrough, .passThrough, .passThrough, .passThrough]
    ),
]

// Turns red if decoding confuses left and right modifiers, misreads required modifiers, mishandles Escape or the paste-again shortcut, or reports repeats.
@Test(arguments: decoderCases)
func decoderTurnsEventsIntoDecisions(_ testCase: DecoderCase) {
    var decoder = HotkeyDecoder(key: testCase.key, pasteAgainKey: pasteAgain)
    decoder.isRecording = testCase.recording
    #expect(testCase.events.map { decoder.decode($0) } == testCase.expected)
}

// Turns red if a dictation key that shares a key code with the paste-again shortcut hides the paste-again key up.
@Test func pasteAgainSharingTheDictationKeyCodeStillSwallowsItsKeyUp() {
    var decoder = HotkeyDecoder(key: commandSpace, pasteAgainKey: KeyChoice(keyCode: 49, modifiers: .option))
    #expect([down(49, .option), up(49, .option)].map { decoder.decode($0) } == [.pasteAgain, .ignore])
}

// Turns red if the decoder stops passing through Fluidity's own events: a paste-again V held while the paste sends ⌘V swallows that ⌘V.
@Test func ownPastePassesThroughWhilePasteAgainIsHeld() {
    var decoder = HotkeyDecoder(key: rightOption, pasteAgainKey: KeyChoice(keyCode: 9, modifiers: [.command, .shift]))
    #expect(decoder.decode(down(9, [.command, .shift])) == .pasteAgain)
    let own = [RawKeyEvent(kind: .keyDown, keyCode: 9, flags: .command, isOwn: true), RawKeyEvent(kind: .keyUp, keyCode: 9, flags: .command, isOwn: true)]
    #expect(own.map { decoder.decode($0) } == [.passThrough, .passThrough])
    #expect(decoder.decode(up(9, [.command, .shift])) == .ignore)
}

// Turns red if a modifier change is ever swallowed, or a pass-through key event is swallowed.
@Test func onlyReportedKeyEventsAreSwallowed() {
    #expect(HotkeyDecision.keyDown.swallows(down(49)))
    #expect(HotkeyDecision.ignore.swallows(up(53)))
    #expect(!HotkeyDecision.keyDown.swallows(flags(61, .rightOption)))
    #expect(!HotkeyDecision.passThrough.swallows(down(0)))
}

// Turns red if a held Escape's repeats reach the focused app once the cancel has stopped recording.
@Test func heldEscapeRepeatsStaySwallowedAfterCancel() {
    var decoder = HotkeyDecoder(key: rightOption)
    decoder.isRecording = true
    #expect(decoder.decode(down(53)) == .cancel)
    decoder.isRecording = false
    #expect([down(53, repeat: true), up(53), down(53)].map { decoder.decode($0) } == [.ignore, .ignore, .passThrough])
}

// Turns red if changing the shortcuts drops the recording state or loses the key up of a held dictation key.
@Test func changingKeysKeepsRecordingAndReleasesAHeldKey() {
    var decoder = HotkeyDecoder(key: rightOption, pasteAgainKey: pasteAgain)
    decoder.isRecording = true
    #expect(decoder.decode(flags(61, [.option, .rightOption])) == .keyDown)
    #expect(decoder.setKeys(rightOption, pasteAgainKey: nil) == nil)
    #expect(decoder.setKeys(commandSpace, pasteAgainKey: nil) == .keyUp)
    #expect(decoder.decode(down(53)) == .cancel)
    #expect([down(49, .command), up(49)].map { decoder.decode($0) } == [.keyDown, .keyUp])
}
