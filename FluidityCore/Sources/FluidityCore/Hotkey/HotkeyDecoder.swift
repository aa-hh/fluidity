/// One keyboard event, as read from the event tap.
public struct RawKeyEvent: Equatable, Sendable {
    public enum Kind: Sendable { case keyDown, keyUp, flagsChanged }

    public var kind: Kind
    public var keyCode: UInt16
    public var flags: KeyModifiers
    public var isRepeat: Bool

    public init(kind: Kind, keyCode: UInt16, flags: KeyModifiers = [], isRepeat: Bool = false) {
        self.kind = kind
        self.keyCode = keyCode
        self.flags = flags
        self.isRepeat = isRepeat
    }
}

/// What to do with one keyboard event.
public enum HotkeyDecision: Equatable, Sendable {
    /// The dictation key went down; `DictationController` decides tap versus hold.
    case keyDown
    case keyUp
    /// The paste-again shortcut was pressed.
    case pasteAgain
    /// Escape while recording.
    case cancel
    /// Swallowed with nothing to report, such as a key repeat of the dictation key.
    case ignore
    case passThrough

    /// Whether the event should be kept from the focused app. Modifier changes always reach it,
    /// so apps never see a modifier stuck down.
    public func swallows(_ event: RawKeyEvent) -> Bool {
        self != .passThrough && event.kind != .flagsChanged
    }
}

/// Turns keyboard events into hotkey decisions for the chosen key and the paste-again shortcut.
public struct HotkeyDecoder: Sendable {
    public var key: KeyChoice
    public var pasteAgainKey: KeyChoice?
    public var isRecording = false

    private var keyHeld = false
    private var pasteAgainHeld = false
    private var escapeHeld = false

    public init(key: KeyChoice, pasteAgainKey: KeyChoice? = nil) {
        self.key = key
        self.pasteAgainKey = pasteAgainKey
    }

    public mutating func decode(_ event: RawKeyEvent) -> HotkeyDecision {
        if let decision = Self.step(Self.edge(of: key, in: event), held: &keyHeld, onDown: .keyDown, onUp: .keyUp) {
            return decision
        }
        if let pasteAgainKey,
           let decision = Self.step(Self.edge(of: pasteAgainKey, in: event), held: &pasteAgainHeld, onDown: .pasteAgain, onUp: .ignore) {
            return decision
        }
        if event.keyCode == KeyNames.escape {
            if event.kind == .keyDown, isRecording {
                escapeHeld = true
                return event.isRepeat ? .ignore : .cancel
            }
            if event.kind == .keyUp, escapeHeld {
                escapeHeld = false
                return .ignore
            }
        }
        return .passThrough
    }

    /// Nil when the event does not concern this key, so later checks still see it.
    private static func step(_ edge: Edge?, held: inout Bool, onDown: HotkeyDecision, onUp: HotkeyDecision) -> HotkeyDecision? {
        switch edge {
        case .down?:
            if held { return .ignore }
            held = true
            return onDown
        case .repeatDown?:
            return held ? .ignore : nil
        case .up?:
            guard held else { return nil }
            held = false
            return onUp
        case nil:
            return nil
        }
    }

    private enum Edge { case down, repeatDown, up }

    private static func edge(of choice: KeyChoice, in event: RawKeyEvent) -> Edge? {
        guard event.keyCode == choice.keyCode else { return nil }
        if let modifier = ModifierKey.byCode[choice.keyCode] {
            guard event.kind == .flagsChanged else { return nil }
            return event.flags.contains(modifier.flag) ? .down : .up
        }
        switch event.kind {
        case .keyDown where event.flags.intersection(.shortcut) == choice.modifiers:
            return event.isRepeat ? .repeatDown : .down
        case .keyUp:
            return .up
        default:
            return nil
        }
    }
}
