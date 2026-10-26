import AppKit
import FluidityCore
import Observation

/// The popover's history and actions. Status, the key and cleanup state come from `SettingsModel`.
@MainActor
@Observable
final class PopoverModel {
    /// Newest first, as `DictationStore.recent()` returns them.
    var records: [DictationRecord] = []

    /// Clicking a row, or Return on it: paste that dictation again.
    var onPasteAgain: (DictationRecord) -> Void = { _ in }
    var onCopy: (DictationRecord) -> Void = { _ in }
    /// Open the settings window, at a pane when the status row asks for one.
    var onOpenSettings: (SettingsPane?) -> Void = { _ in }
    var onQuit: () -> Void = { NSApp.terminate(nil) }
}
