import Foundation
import Synchronization

/// `CleaningUp` over `CleanupClient`, with the rules and word list from `Settings`.
public struct CleanupAdapter: CleaningUp {
    private let cleanupOn: @Sendable () -> Bool
    private let cleanText: @Sendable (String) async -> CleanupResult
    private let warm: @Sendable () async -> Void

    public init(client: CleanupClient, settings: Settings) {
        self.init(
            isOn: { settings.isCleanupOn },
            clean: { await client.clean(rawTranscript: $0, rules: settings.cleanupRules, wordList: settings.wordList) },
            warmUp: { await client.warmUp() }
        )
    }

    public init(
        isOn: @escaping @Sendable () -> Bool,
        clean: @escaping @Sendable (String) async -> CleanupResult,
        warmUp: @escaping @Sendable () async -> Void = {}
    ) {
        cleanupOn = isOn
        cleanText = clean
        warm = warmUp
    }

    public var isOn: Bool { cleanupOn() }

    /// Opens the cleanup connection in the background; call when recording starts.
    public func warmUp() {
        guard isOn else { return }
        Task { [warm] in await warm() }
    }

    /// The fallback reason wins over any text: a reply that failed the output check still carries
    /// its text so it can be saved, but it must never be pasted. The controller's result has no
    /// room for that text, so it is not saved.
    public func clean(_ rawTranscript: String) async -> DictationController.CleanupResult {
        let result = await cleanText(rawTranscript)
        if let reason = result.fallbackReason { return .fallback(reason) }
        guard let cleaned = result.cleanedText else { return .fallback(.unparseable) }
        return .cleaned(cleaned)
    }
}

/// `FieldContextReading` over `FocusedField`. Keeps the last reading for the edit watcher, which
/// needs the text on either side of the cursor from before the paste.
public final class FieldContextAdapter: FieldContextReading {
    private let field: FocusedField
    private let last = Mutex<DictationController.FieldContext?>(nil)

    public init(field: FocusedField) {
        self.field = field
    }

    /// Call at the start of every dictation.
    public func prepare() {
        field.prepare()
    }

    /// Nil only when nothing has focus. A field that could not be read counts as a password field,
    /// so its dictation is neither saved nor watched.
    public func read() async -> DictationController.FieldContext? {
        let context: DictationController.FieldContext? = switch field.read() {
        case .success(let reading):
            DictationController.FieldContext(
                textBeforeCursor: reading.textBeforeCursor, selectedText: reading.selectedText,
                textAfterCursor: reading.textAfterCursor, isSecure: reading.isSecure, app: reading.app)
        case .failure(.noFocusedElement):
            nil
        case .failure(.noTextValue), .failure(.attributeReadFailed), .failure(.appNotAccessible):
            DictationController.FieldContext(
                textBeforeCursor: "", selectedText: "", textAfterCursor: "", isSecure: true, app: nil)
        }
        last.withLock { $0 = context }
        return context
    }

    /// What the last `read()` found; nil when nothing had focus.
    public var lastRead: DictationController.FieldContext? { last.withLock { $0 } }
}

/// `Finishing` over `Finisher`, with the word list from `Settings`.
public struct FinisherAdapter: Finishing {
    private let wordList: @Sendable () -> [String]

    public init(wordList: @escaping @Sendable () -> [String]) {
        self.wordList = wordList
    }

    public func finish(_ text: String, in field: DictationController.FieldContext?) -> String {
        Finisher.finish(
            text, before: field?.textBeforeCursor, after: field?.textAfterCursor,
            selectedText: field?.selectedText, wordList: Set(wordList()))
    }
}
