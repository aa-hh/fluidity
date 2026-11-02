import Carbon.HIToolbox
import CoreGraphics

/// `KeySender` that posts ⌘V as four `CGEvent`s.
@MainActor
public final class CGEventKeySender: KeySender {
    public init() {}

    public func sendPaste() {
        let source = CGEventSource(stateID: .hidSystemState)
        let command = CGKeyCode(kVK_Command)
        let v = Self.keyCodeTypingV()
        // Command is pressed and released as its own key; a flag on V alone can leave Command reported as held.
        let presses: [(CGKeyCode, Bool, CGEventFlags)] = [
            (command, true, .maskCommand),
            (v, true, .maskCommand),
            (v, false, .maskCommand),
            (command, false, []),
        ]
        for (key, down, flags) in presses {
            let event = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: down)
            event?.flags = flags
            event?.post(tap: .cghidEventTap)
        }
    }

    /// The key that types "v" in the current keyboard layout.
    /// Falls back to key code 9, the V key on a US layout, when the layout has no Unicode data or no key types "v".
    private static func keyCodeTypingV() -> CGKeyCode {
        let fallback = CGKeyCode(kVK_ANSI_V)
        guard
            let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue(),
            let raw = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
        else { return fallback }
        let layoutData = Unmanaged<CFData>.fromOpaque(raw).takeUnretainedValue() as Data
        return layoutData.withUnsafeBytes { bytes in
            guard let layout = bytes.bindMemory(to: UCKeyboardLayout.self).baseAddress else { return fallback }
            for code in 0..<128 {
                var deadKeyState: UInt32 = 0
                var length = 0
                var characters = [UniChar](repeating: 0, count: 4)
                let status = UCKeyTranslate(
                    layout,
                    UInt16(code),
                    UInt16(kUCKeyActionDisplay),
                    0,
                    UInt32(LMGetKbdType()),
                    OptionBits(kUCKeyTranslateNoDeadKeysBit),
                    &deadKeyState,
                    characters.count,
                    &length,
                    &characters
                )
                if status == noErr, length == 1, characters[0] == UniChar(UInt8(ascii: "v")) {
                    return CGKeyCode(code)
                }
            }
            return fallback
        }
    }
}
