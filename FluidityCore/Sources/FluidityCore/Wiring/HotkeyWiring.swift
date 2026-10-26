import Foundation

extension KeyChoice {
    /// The dictation key until the user picks another.
    public static let rightOption = KeyChoice(keyCode: 61)
}

/// Both shortcuts are saved together in `Settings.shortcut`.
extension Settings: ShortcutStoring {
    private struct Shortcuts: Codable {
        var dictationKey: KeyChoice
        var pasteAgainKey: KeyChoice?
    }

    public var dictationKey: KeyChoice {
        get { shortcut(as: Shortcuts.self)?.dictationKey ?? .rightOption }
        set { try? setShortcut(Shortcuts(dictationKey: newValue, pasteAgainKey: pasteAgainKey)) }
    }

    public var pasteAgainKey: KeyChoice? {
        get { shortcut(as: Shortcuts.self)?.pasteAgainKey }
        set { try? setShortcut(Shortcuts(dictationKey: dictationKey, pasteAgainKey: newValue)) }
    }
}

extension DictationController.Phase {
    /// Whether Escape cancels the dictation now, so `Hotkey.isRecording` must be true.
    public var takesEscape: Bool {
        switch self {
        case .recording, .finishing, .cleaning: true
        case .ready, .pasting, .watching: false
        }
    }
}

extension DictationController {
    /// Acts on one hotkey decision. `pasteAgain` runs only between dictations.
    public func handle(_ decision: HotkeyDecision, pasteAgain: () -> Void) {
        switch decision {
        case .keyDown: keyDown()
        case .keyUp: keyUp()
        case .cancel: escapePressed()
        case .pasteAgain: if !phase.isDictating { pasteAgain() }
        case .ignore, .passThrough: break
        }
    }
}
