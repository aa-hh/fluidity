/// Where the chosen shortcuts are saved; `Settings` conforms in the app.
public protocol ShortcutStoring: AnyObject {
    var dictationKey: KeyChoice { get set }
    var pasteAgainKey: KeyChoice? { get set }
}

public enum ShortcutSlot: Sendable {
    case dictation, pasteAgain
}

public enum ShortcutRejection: Equatable, Sendable {
    case escape
    case returnOrTab
    /// A key that types a character, pressed with no modifier or with Shift only.
    case typingKeyWithoutModifier
    case sameAsOtherShortcut
}

public enum ShortcutRecording: Equatable, Sendable {
    case accepted(KeyChoice)
    case rejected(ShortcutRejection)
}

/// Captures the next key or modifier for a shortcut, rejects keys that can't work, and saves the rest.
public struct ShortcutRecorder {
    public let store: any ShortcutStoring
    public private(set) var slot: ShortcutSlot?
    /// The last modifier pressed while armed; it becomes the choice if released before any other key.
    private var pendingModifier: UInt16?

    public init(store: any ShortcutStoring) {
        self.store = store
    }

    public mutating func arm(for slot: ShortcutSlot) {
        self.slot = slot
        pendingModifier = nil
    }

    public mutating func disarm() {
        slot = nil
        pendingModifier = nil
    }

    /// Returns nil while the press is still incomplete or the recorder is not armed.
    /// The recorder disarms itself after accepting.
    public mutating func record(_ event: RawKeyEvent) -> ShortcutRecording? {
        guard let slot else { return nil }
        let choice: KeyChoice
        switch event.kind {
        case .flagsChanged:
            guard let modifier = ModifierKey.byCode[event.keyCode] else { return nil }
            if event.flags.contains(modifier.flag) {
                pendingModifier = event.keyCode
                return nil
            }
            guard let pending = pendingModifier else { return nil }
            choice = KeyChoice(keyCode: pending)
        case .keyDown:
            choice = KeyChoice(keyCode: event.keyCode, modifiers: event.flags)
        case .keyUp:
            return nil
        }
        pendingModifier = nil
        if let rejection = Self.rejection(for: choice, other: slot == .dictation ? store.pasteAgainKey : store.dictationKey) {
            return .rejected(rejection)
        }
        switch slot {
        case .dictation: store.dictationKey = choice
        case .pasteAgain: store.pasteAgainKey = choice
        }
        self.slot = nil
        return .accepted(choice)
    }

    private static func rejection(for choice: KeyChoice, other: KeyChoice?) -> ShortcutRejection? {
        if choice.keyCode == other?.keyCode && choice.modifiers == other?.modifiers { return .sameAsOtherShortcut }
        if choice.isModifier { return nil }
        if choice.keyCode == KeyNames.escape && choice.modifiers.isEmpty { return .escape }
        if [KeyNames.returnKey, KeyNames.tab].contains(choice.keyCode) && choice.modifiers.isEmpty { return .returnOrTab }
        if KeyNames.typing[choice.keyCode] != nil && choice.modifiers.subtracting(.shift).isEmpty {
            return .typingKeyWithoutModifier
        }
        return nil
    }
}
