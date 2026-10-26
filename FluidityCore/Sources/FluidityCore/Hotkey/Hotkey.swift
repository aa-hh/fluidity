import CoreGraphics

/// Owns the keyboard event tap: feeds every key event through `HotkeyDecoder`,
/// swallows only what the decoder says, and reports decisions on `decisions`.
@MainActor
public final class Hotkey {
    public enum StartError: Error {
        /// The tap could not be created, usually because Accessibility permission is missing.
        case tapUnavailable
    }

    /// Every decision except `.passThrough` and `.ignore`.
    public let decisions: AsyncStream<HotkeyDecision>
    private let continuation: AsyncStream<HotkeyDecision>.Continuation
    private var decoder: HotkeyDecoder
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?

    public init(key: KeyChoice, pasteAgainKey: KeyChoice?) {
        decoder = HotkeyDecoder(key: key, pasteAgainKey: pasteAgainKey)
        (decisions, continuation) = AsyncStream.makeStream()
    }

    isolated deinit {
        stop()
        continuation.finish()
    }

    /// Escape is swallowed only while this is true.
    public var isRecording: Bool {
        get { decoder.isRecording }
        set { decoder.isRecording = newValue }
    }

    public func setKeys(_ key: KeyChoice, pasteAgainKey: KeyChoice?) {
        if let decision = decoder.setKeys(key, pasteAgainKey: pasteAgainKey) { continuation.yield(decision) }
    }

    public func start() throws(StartError) {
        guard tap == nil else { return }
        let mask: CGEventMask = [CGEventType.keyDown, .keyUp, .flagsChanged]
            .reduce(0) { $0 | (1 << $1.rawValue) }
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: hotkeyTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { throw .tapUnavailable }
        let source = CFMachPortCreateRunLoopSource(nil, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        self.tap = tap
        self.source = source
    }

    public func stop() {
        if let tap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        tap = nil
        source = nil
    }

    /// Returns true when the event should be swallowed.
    fileprivate func handle(type: CGEventType, event raw: RawKeyEvent?) -> Bool {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return false
        }
        guard let raw else { return false }
        let decision = decoder.decode(raw)
        if decision.isReported { continuation.yield(decision) }
        return decision.swallows(raw)
    }
}

private func hotkeyTapCallback(
    proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else { return Unmanaged.passUnretained(event) }
    let hotkey = Unmanaged<Hotkey>.fromOpaque(userInfo).takeUnretainedValue()
    let kind: RawKeyEvent.Kind? = switch type {
    case .keyDown: .keyDown
    case .keyUp: .keyUp
    case .flagsChanged: .flagsChanged
    default: nil
    }
    let raw = kind.map {
        RawKeyEvent(
            kind: $0,
            keyCode: UInt16(truncatingIfNeeded: event.getIntegerValueField(.keyboardEventKeycode)),
            flags: KeyModifiers(rawValue: event.flags.rawValue),
            isRepeat: event.getIntegerValueField(.keyboardEventAutorepeat) != 0
        )
    }
    // The tap's run loop source is on the main run loop, so the callback runs on the main thread.
    let swallow = MainActor.assumeIsolated { hotkey.handle(type: type, event: raw) }
    return swallow ? nil : Unmanaged.passUnretained(event)
}
