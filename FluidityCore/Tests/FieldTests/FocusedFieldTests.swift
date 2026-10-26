import ApplicationServices
import FluidityCore
import Foundation
import Testing

struct FocusedFieldSplitTests {
    struct Case: Sendable, CustomStringConvertible {
        let name: String
        let value: String
        let selection: NSRange
        let before: String
        let selected: String
        let after: String
        var description: String { name }
    }

    // Fails if the cut drops whole words it should keep, keeps a partial word, or misplaces the selection.
    @Test(arguments: [
        Case(name: "short field", value: "hello there", selection: NSRange(location: 5, length: 0),
             before: "hello", selected: "", after: " there"),
        Case(name: "cursor at start", value: "one two", selection: NSRange(location: 0, length: 0),
             before: "", selected: "", after: "one two"),
        Case(name: "cursor at end", value: "one two", selection: NSRange(location: 7, length: 0),
             before: "one two", selected: "", after: ""),
        Case(name: "selection present", value: "one two three", selection: NSRange(location: 4, length: 3),
             before: "one ", selected: "two", after: " three"),
        Case(name: "exactly the limit", value: "abcde fghij", selection: NSRange(location: 10, length: 0),
             before: "abcde fghi", selected: "", after: "j"),
        Case(name: "long before drops the partial first word", value: "alpha betas gamma",
             selection: NSRange(location: 17, length: 0), before: " gamma", selected: "", after: ""),
        Case(name: "long after drops the partial last word", value: "alpha betas gamma",
             selection: NSRange(location: 0, length: 0), before: "", selected: "", after: "alpha "),
        Case(name: "window already starts on a word", value: "xx alpha beta",
             selection: NSRange(location: 13, length: 0), before: "alpha beta", selected: "", after: ""),
        Case(name: "newline is a boundary", value: "intro\nsecond",
             selection: NSRange(location: 12, length: 0), before: "\nsecond", selected: "", after: ""),
        Case(name: "punctuation is a boundary", value: "alphaxy,betagam",
             selection: NSRange(location: 15, length: 0), before: ",betagam", selected: "", after: ""),
        Case(name: "one huge word is truncated, not emptied", value: "abcdefghijklmnop",
             selection: NSRange(location: 16, length: 0), before: "ghijklmnop", selected: "", after: ""),
        Case(name: "selection past the end is clamped", value: "abc", selection: NSRange(location: 2, length: 99),
             before: "ab", selected: "c", after: ""),
    ])
    func split(_ c: Case) {
        let parts = FocusedField.split(c.value, selection: c.selection, limit: 10)
        #expect(parts.before == c.before)
        #expect(parts.selected == c.selected)
        #expect(parts.after == c.after)
    }

    // Fails if the default window stops being 500 characters on each side.
    @Test func defaultLimitIsFiveHundredCharacters() {
        let words = String(repeating: "word ", count: 200)
        let parts = FocusedField.split(words + "|" + words, selection: NSRange(location: 1000, length: 1))
        #expect(parts.before.count == 500)
        #expect(parts.after.count == 500)
    }

    // Fails if offsets are counted in Swift characters instead of the UTF-16 units Accessibility reports.
    @Test func selectionIsInUTF16Units() {
        let parts = FocusedField.split("👍 ok then", selection: NSRange(location: 3, length: 2))
        #expect(parts.before == "👍 ")
        #expect(parts.selected == "ok")
    }
}

struct FocusedFieldReadTests {
    private func field(value: String?, subrole: String? = nil) -> (FocusedField, FakeAccessibilityElement) {
        let app = FakeAccessibilityElement()
        app.bundleID = "com.anthropic.claudefordesktop"
        let element = FakeAccessibilityElement()
        element.valueAnswer = value
        element.subroleAnswer = subrole
        element.application = app
        let system = FakeAccessibilityElement()
        system.focused = element
        system.application = app
        return (FocusedField(systemWide: system), element)
    }

    // Fails if a read stops reporting the cursor, count or owning app alongside the text.
    @Test func readsTextAroundTheCursor() throws {
        let (focused, element) = field(value: "hello brave world")
        element.rangeAnswer = NSRange(location: 6, length: 5)
        element.countAnswer = 17
        let reading = try focused.read().get()
        #expect(reading == FieldReading(
            textBeforeCursor: "hello ", selectedText: "brave", textAfterCursor: " world",
            cursorOffset: 6, characterCount: 17, app: "com.anthropic.claudefordesktop", isSecure: false
        ))
    }

    // Fails if a field without a selection range is not read as having the cursor at the end.
    @Test func missingSelectionPutsCursorAtEnd() throws {
        let (focused, _) = field(value: "abc")
        let reading = try focused.read().get()
        #expect(reading.textBeforeCursor == "abc")
        #expect(reading.cursorOffset == 3)
        #expect(reading.characterCount == 3)
    }

    // Fails if any text, offset or length from a password field leaks into the reading.
    @Test func secureFieldReturnsNoText() throws {
        let (focused, element) = field(value: "hunter2", subrole: kAXSecureTextFieldSubrole)
        element.rangeAnswer = NSRange(location: 7, length: 0)
        let reading = try focused.read().get()
        #expect(reading == FieldReading(
            textBeforeCursor: "", selectedText: "", textAfterCursor: "",
            cursorOffset: 0, characterCount: 0, app: "com.anthropic.claudefordesktop", isSecure: true
        ))
        #expect(focused.isSecure)
    }

    // Fails if isSecure reports a readable field when it cannot tell.
    @Test func isSecureWhenSubroleUnreadable() {
        let (focused, element) = field(value: "x")
        #expect(!focused.isSecure)
        element.failure = AccessibilityError(code: AXError.failure.rawValue)
        #expect(focused.isSecure)
    }

    // Fails if a failure reason is lost or reported as a different one.
    @Test func eachErrorReason() {
        let system = FakeAccessibilityElement()
        #expect(FocusedField(systemWide: system).read() == .failure(.noFocusedElement))

        let (noValue, _) = field(value: nil)
        #expect(noValue.read() == .failure(.noTextValue))

        let (failing, element) = field(value: "x")
        element.failure = AccessibilityError(code: AXError.illegalArgument.rawValue)
        #expect(failing.read() == .failure(.attributeReadFailed(code: AXError.illegalArgument.rawValue)))

        system.failure = AccessibilityError(code: AXError.apiDisabled.rawValue)
        #expect(FocusedField(systemWide: system).read() == .failure(.appNotAccessible(code: AXError.apiDisabled.rawValue)))
    }

    // Fails if prepare stops asking the focused app to expose its text.
    @Test func prepareTurnsOnManualAccessibility() {
        let app = FakeAccessibilityElement()
        let system = FakeAccessibilityElement()
        system.application = app
        FocusedField(systemWide: system).prepare()
        #expect(app.manualAccessibility == true)
    }
}
