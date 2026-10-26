/// Modifier flags with the same bit values as `CGEventFlags` and `NSEvent.ModifierFlags`,
/// including the bits that tell the left and right keys apart.
public struct KeyModifiers: OptionSet, Codable, Hashable, Sendable {
    public let rawValue: UInt64
    public init(rawValue: UInt64) { self.rawValue = rawValue }

    public static let shift = KeyModifiers(rawValue: 0x20000)
    public static let control = KeyModifiers(rawValue: 0x40000)
    public static let option = KeyModifiers(rawValue: 0x80000)
    public static let command = KeyModifiers(rawValue: 0x100000)
    public static let function = KeyModifiers(rawValue: 0x800000)

    public static let leftControl = KeyModifiers(rawValue: 0x1)
    public static let leftShift = KeyModifiers(rawValue: 0x2)
    public static let rightShift = KeyModifiers(rawValue: 0x4)
    public static let leftCommand = KeyModifiers(rawValue: 0x8)
    public static let rightCommand = KeyModifiers(rawValue: 0x10)
    public static let leftOption = KeyModifiers(rawValue: 0x20)
    public static let rightOption = KeyModifiers(rawValue: 0x40)
    public static let rightControl = KeyModifiers(rawValue: 0x2000)

    /// The modifiers an ordinary-key shortcut can require; sides and Fn are ignored.
    public static let shortcut: KeyModifiers = [.control, .option, .shift, .command]
}

public enum KeySide: String, Codable, Sendable {
    case left, right
}

/// The key chosen for a shortcut: a modifier key on its own, or an ordinary key with required modifiers.
public struct KeyChoice: Codable, Equatable, Sendable {
    public var keyCode: UInt16
    /// Required modifiers for an ordinary key; empty for a modifier key.
    public var modifiers: KeyModifiers

    public init(keyCode: UInt16, modifiers: KeyModifiers = []) {
        self.keyCode = keyCode
        self.modifiers = ModifierKey.byCode[keyCode] == nil ? modifiers.intersection(.shortcut) : []
    }

    public var isModifier: Bool { ModifierKey.byCode[keyCode] != nil }
    public var side: KeySide? { ModifierKey.byCode[keyCode]?.side }

    /// Text for the settings screen, such as "⌥ Right Option" or "⌘ Space".
    public var description: String {
        if let key = ModifierKey.byCode[keyCode] {
            return key.symbol.isEmpty ? key.name : "\(key.symbol) \(key.name)"
        }
        let symbols = [(KeyModifiers.control, "⌃"), (.option, "⌥"), (.shift, "⇧"), (.command, "⌘")]
            .filter { modifiers.contains($0.0) }.map(\.1).joined()
        let name = KeyNames.byCode[keyCode] ?? "Key \(keyCode)"
        return symbols.isEmpty ? name : "\(symbols) \(name)"
    }
}

/// A modifier key, told apart from its other side by key code.
struct ModifierKey {
    let name: String
    let symbol: String
    let side: KeySide?
    /// The flag that is set while this key is down.
    let flag: KeyModifiers

    static let byCode: [UInt16: ModifierKey] = [
        55: ModifierKey(name: "Left Command", symbol: "⌘", side: .left, flag: .leftCommand),
        54: ModifierKey(name: "Right Command", symbol: "⌘", side: .right, flag: .rightCommand),
        58: ModifierKey(name: "Left Option", symbol: "⌥", side: .left, flag: .leftOption),
        61: ModifierKey(name: "Right Option", symbol: "⌥", side: .right, flag: .rightOption),
        56: ModifierKey(name: "Left Shift", symbol: "⇧", side: .left, flag: .leftShift),
        60: ModifierKey(name: "Right Shift", symbol: "⇧", side: .right, flag: .rightShift),
        59: ModifierKey(name: "Left Control", symbol: "⌃", side: .left, flag: .leftControl),
        62: ModifierKey(name: "Right Control", symbol: "⌃", side: .right, flag: .rightControl),
        63: ModifierKey(name: "Fn", symbol: "", side: nil, flag: .function),
    ]
}

enum KeyNames {
    static let escape: UInt16 = 53
    static let returnKey: UInt16 = 36
    static let tab: UInt16 = 48

    // razor: names follow the US key layout; other layouts need UCKeyTranslate to name keys as printed.
    /// Keys that type a character when pressed with no modifier.
    static let typing: [UInt16: String] = [
        0: "A", 11: "B", 8: "C", 2: "D", 14: "E", 3: "F", 5: "G", 4: "H", 34: "I", 38: "J",
        40: "K", 37: "L", 46: "M", 45: "N", 31: "O", 35: "P", 12: "Q", 15: "R", 1: "S", 17: "T",
        32: "U", 9: "V", 13: "W", 7: "X", 16: "Y", 6: "Z",
        29: "0", 18: "1", 19: "2", 20: "3", 21: "4", 23: "5", 22: "6", 26: "7", 28: "8", 25: "9",
        27: "-", 24: "=", 33: "[", 30: "]", 42: "\\", 41: ";", 39: "'", 43: ",", 47: ".", 44: "/",
        50: "`", 49: "Space",
    ]

    static let byCode: [UInt16: String] = typing.merging([
        36: "Return", 48: "Tab", 51: "Delete", 53: "Escape", 117: "Forward Delete",
        115: "Home", 119: "End", 116: "Page Up", 121: "Page Down",
        123: "←", 124: "→", 125: "↓", 126: "↑",
        122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6", 98: "F7", 100: "F8",
        101: "F9", 109: "F10", 103: "F11", 111: "F12", 105: "F13", 107: "F14", 113: "F15",
        106: "F16", 64: "F17", 79: "F18", 80: "F19", 90: "F20",
    ]) { first, _ in first }
}
