import AppKit
import RilloCore
import Observation

/// The popover's history and actions. Status, the key and cleanup state come from `SettingsModel`.
@MainActor
@Observable
final class PopoverModel {
    /// The popover lists only the newest few; the History page has the rest.
    static let shownCount = 20

    /// Newest first, as `HistoryStore.items()` returns them.
    var records: [DictationRecord] = []

    /// Clicking a row, or Return on it: paste that dictation again.
    var onPasteAgain: (DictationRecord) -> Void = { _ in }
    var onCopy: (DictationRecord) -> Void = { _ in }
    /// Open the settings window, at a pane when the status row asks for one.
    var onOpenSettings: (SettingsPane?) -> Void = { _ in }
    var onQuit: () -> Void = { NSApp.terminate(nil) }
}
