import ApplicationServices
import Foundation

/// What `FocusedField.read()` found in the focused text field.
public struct FieldReading: Equatable, Sendable {
    /// Up to 500 characters before the cursor, never starting mid-word.
    public var textBeforeCursor: String
    public var selectedText: String
    /// Up to 500 characters after the selection, never ending mid-word.
    public var textAfterCursor: String
    /// Start of the selection, in UTF-16 units.
    public var cursorOffset: Int
    /// Length of the whole field, in UTF-16 units.
    public var characterCount: Int
    /// Bundle identifier of the app that owns the field.
    public var app: String?
    /// A password field: every text property is empty and the counts are zero.
    public var isSecure: Bool

    public init(
        textBeforeCursor: String, selectedText: String, textAfterCursor: String,
        cursorOffset: Int, characterCount: Int, app: String?, isSecure: Bool
    ) {
        self.textBeforeCursor = textBeforeCursor
        self.selectedText = selectedText
        self.textAfterCursor = textAfterCursor
        self.cursorOffset = cursorOffset
        self.characterCount = characterCount
        self.app = app
        self.isSecure = isSecure
    }
}

/// Why the focused text field could not be read.
public enum FieldReadError: Error, Equatable, Sendable {
    case noFocusedElement
    case noTextValue
    case attributeReadFailed(code: Int32)
    /// Fluidity lacks Accessibility permission, or the app does not answer.
    case appNotAccessible(code: Int32)
}

/// Reads the focused text field through Accessibility. It never writes to the field.
public struct FocusedField: Sendable {
    public static let contextLimit = 500

    private let systemWide: any AccessibilityElement

    public init(systemWide: any AccessibilityElement = AXUIElementAccessibility.systemWide()) {
        self.systemWide = systemWide
    }

    /// Call when dictation starts: asks the focused app to expose its text. Apps that are not Electron refuse, harmlessly.
    public func prepare() {
        guard let app = try? systemWide.focusedApplication() else { return }
        try? app.setManualAccessibility(true)
    }

    /// True when the focused field is a password field, or when that cannot be determined.
    public var isSecure: Bool {
        do {
            guard let element = try systemWide.focusedElement() else { return false }
            return try element.subrole() == kAXSecureTextFieldSubrole
        } catch {
            return true
        }
    }

    public func read() -> Result<FieldReading, FieldReadError> {
        do throws(AccessibilityError) {
            guard let element = try systemWide.focusedElement() else { return .failure(.noFocusedElement) }
            let app = (try? element.owningApplication())?.bundleIdentifier()
            if try element.subrole() == kAXSecureTextFieldSubrole {
                return .success(FieldReading(
                    textBeforeCursor: "", selectedText: "", textAfterCursor: "",
                    cursorOffset: 0, characterCount: 0, app: app, isSecure: true
                ))
            }
            guard let value = try element.value() else { return .failure(.noTextValue) }
            let length = (value as NSString).length
            // A field that reports no selection is treated as having the cursor at the end.
            let selection = try element.selectedTextRange() ?? NSRange(location: length, length: 0)
            let parts = Self.split(value, selection: selection)
            return .success(FieldReading(
                textBeforeCursor: parts.before, selectedText: parts.selected, textAfterCursor: parts.after,
                cursorOffset: min(max(selection.location, 0), length),
                characterCount: try element.numberOfCharacters() ?? length,
                app: app, isSecure: false
            ))
        } catch {
            let notAccessible: Set<Int32> = [
                AXError.apiDisabled.rawValue, AXError.cannotComplete.rawValue, AXError.notImplemented.rawValue,
            ]
            return .failure(notAccessible.contains(error.code)
                ? .appNotAccessible(code: error.code)
                : .attributeReadFailed(code: error.code))
        }
    }

    /// Splits `value` around `selection` (UTF-16 units, clamped to the text) and cuts the text on each side
    /// to `limit` characters at a word boundary. A single word longer than `limit` is kept, truncated.
    public static func split(
        _ value: String, selection: NSRange, limit: Int = contextLimit
    ) -> (before: String, selected: String, after: String) {
        let text = value as NSString
        let start = min(max(selection.location, 0), text.length)
        let end = start + min(max(selection.length, 0), text.length - start)
        return (
            cutBefore(text.substring(to: start), limit: limit),
            text.substring(with: NSRange(location: start, length: end - start)),
            cutAfter(text.substring(from: end), limit: limit)
        )
    }

    private static func isBoundary(_ character: Character) -> Bool {
        character.isWhitespace || character.isPunctuation
    }

    private static func cutBefore(_ text: String, limit: Int) -> String {
        guard text.count > limit else { return text }
        let window = text.suffix(limit)
        guard let previous = text[..<window.startIndex].last, let first = window.first,
              !isBoundary(previous), !isBoundary(first),
              let boundary = window.firstIndex(where: isBoundary)
        else { return String(window) }
        return String(window[boundary...])
    }

    private static func cutAfter(_ text: String, limit: Int) -> String {
        guard text.count > limit else { return text }
        let window = text.prefix(limit)
        guard let last = window.last, !isBoundary(last), !isBoundary(text[window.endIndex]),
              let boundary = window.lastIndex(where: isBoundary)
        else { return String(window) }
        return String(window[...boundary])
    }
}
