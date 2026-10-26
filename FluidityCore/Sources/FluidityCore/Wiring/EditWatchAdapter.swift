import ApplicationServices
import Foundation
import Synchronization

/// `EditWatching` over `EditWatcher`.
///
/// `EditWatcher.watch` returns nil when its task is cancelled, losing the final text, so the watch
/// runs in a task of its own and a cancelled caller ends it with `endForNewDictation()` instead.
public struct EditWatchAdapter: EditWatching {
    private let watcher: EditWatcher
    private let context: @Sendable () -> DictationController.FieldContext?
    private let makeField: @Sendable () async -> (any WatchedField)?

    /// `context` is the field as read just before the paste; `makeField` returns the focused field
    /// after the paste, a fresh one per watch.
    public init(
        watcher: EditWatcher,
        context: @escaping @Sendable () -> DictationController.FieldContext?,
        makeField: @escaping @Sendable () async -> (any WatchedField)? = EditWatchAdapter.focusedField
    ) {
        self.watcher = watcher
        self.context = context
        self.makeField = makeField
    }

    /// When nothing could be watched, or the field turned into a password field, the stop reason is
    /// `.surroundingTextLost` with no final text: none of the other reasons fit, and nothing is recorded.
    public func watch(pastedText: String) async -> DictationController.WatchStop {
        let nothingWatched = DictationController.WatchStop(reason: .surroundingTextLost, finalText: nil)
        guard let context = context(), let field = await makeField() else { return nothingWatched }
        let watcher = self.watcher
        let cancelled = Mutex(false)
        let endIfCancelled: @Sendable () -> Void = {
            if cancelled.withLock({ $0 }) { Task { await watcher.endForNewDictation() } }
        }
        let relay = CancellingField(field: field, beforeRead: endIfCancelled)
        let watch = Task {
            await watcher.watch(
                pastedText: pastedText, in: relay,
                textBefore: context.textBeforeCursor, textAfter: context.textAfterCursor)
        }
        let outcome = await withTaskCancellationHandler {
            await watch.value
        } onCancel: {
            cancelled.withLock { $0 = true }
            endIfCancelled()
        }
        guard let outcome else { return nothingWatched }
        return DictationController.WatchStop(reason: outcome.stopReason, finalText: outcome.finalText)
    }

    /// The focused text field, read through Accessibility.
    public static func focusedField() async -> (any WatchedField)? {
        await MainActor.run {
            var focused: CFTypeRef?
            guard AXUIElementCopyAttributeValue(
                AXUIElementCreateSystemWide(), kAXFocusedUIElementAttribute as CFString, &focused) == .success,
                let focused, CFGetTypeID(focused) == AXUIElementGetTypeID()
            else { return nil }
            let element = focused as! AXUIElement
            var pid: pid_t = 0
            guard AXUIElementGetPid(element, &pid) == .success else { return nil }
            return AccessibilityWatchedField(element: element, pid: pid)
        }
    }
}

/// Passes reads through, first repeating a cancelled caller's end request. `EditWatcher` drops an
/// end request that reaches it before the watch has started, and every watch reads the field
/// once it has started.
private struct CancellingField: WatchedField {
    let field: any WatchedField
    let beforeRead: @Sendable () -> Void

    var notifications: AsyncStream<FieldChange> { field.notifications }

    func read() -> (value: String, cursor: Int, hasFocus: Bool, isSecure: Bool)? {
        beforeRead()
        return field.read()
    }
}
