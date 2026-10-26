import Foundation

/// `Pasting` over `Paster`. Holds the focus captured when the dictation started, which the paste
/// compares against so text never lands in a field the user moved to.
///
/// `Paster.paste` returns only after the old clipboard is restored, about 300 ms after the text
/// landed, so the pasted pill shows that much late. `Paster` does not report the landing on its own.
@MainActor
public final class PasteAdapter: Pasting {
    private let focusChecking: any FocusChecking
    private let pasteText: @MainActor (String, FocusIdentity) async -> PasteResult
    private var focusAtStart: FocusIdentity?
    private var pasting = false

    public convenience init(paster: Paster, focusChecking: any FocusChecking) {
        self.init(focusChecking: focusChecking) { await paster.paste($0, focusAtStart: $1) }
    }

    public init(
        focusChecking: any FocusChecking,
        paste: @escaping @MainActor (String, FocusIdentity) async -> PasteResult
    ) {
        self.focusChecking = focusChecking
        pasteText = paste
    }

    /// Call at the start of every dictation.
    public func captureFocus() {
        focusAtStart = focusChecking.currentFocus()
    }

    public func paste(_ text: String) async -> DictationController.PasteOutcome {
        guard let focusAtStart, let result = await pasteOnce(text, focus: focusAtStart) else { return .nowhereToPaste }
        switch result {
        case .landed:
            return .landed
        // Focus that moved since the dictation started also counts as nowhere to paste:
        // the field the user dictated into is gone.
        case .failed(.focusMoved), .failed(.nothingAskedForText), .failed(.clipboardUnavailable):
            return .nowhereToPaste
        }
    }

    /// Pastes `text` into whatever has focus now. Nil when another paste is still running.
    @discardableResult
    public func pasteAgain(_ text: String) async -> PasteResult? {
        guard let focus = focusChecking.currentFocus() else { return .failed(.focusMoved) }
        return await pasteOnce(text, focus: focus)
    }

    /// Two pastes at once would save our own text as the user's clipboard.
    private func pasteOnce(_ text: String, focus: FocusIdentity) async -> PasteResult? {
        guard !pasting else { return nil }
        pasting = true
        defer { pasting = false }
        return await pasteText(text, focus)
    }
}

extension DictationRecord {
    /// What the paste-again key pastes: the pasted text, or, when the paste found nowhere to land,
    /// the cleaned text or raw transcript it would have come from.
    public var textToPasteAgain: String {
        pastedText ?? (fallbackReason == nil ? cleanedText : nil) ?? rawTranscript
    }
}
