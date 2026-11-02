import ApplicationServices
import Foundation

/// A `WatchedField` over one Accessibility element. Create one per watch.
public final class AccessibilityWatchedField: WatchedField, @unchecked Sendable {
    private let element: AXUIElement
    private let changes: AsyncStream<FieldChange>.Continuation
    public let notifications: AsyncStream<FieldChange>

    /// `pid` is the process that owns `element`. If the observer cannot be created,
    /// `notifications` ends at once and the watcher relies on its timed reads.
    public init(element: AXUIElement, pid: pid_t) {
        self.element = element
        (notifications, changes) = AsyncStream.makeStream(of: FieldChange.self)
        AXUIElementSetMessagingTimeout(element, 0.25)

        var created: AXObserver?
        let callback: AXObserverCallback = { _, _, name, refcon in
            guard let refcon else { return }
            let relay = Unmanaged<Relay>.fromOpaque(refcon).takeUnretainedValue()
            switch name as String {
            case kAXValueChangedNotification: relay.changes.yield(.valueChanged)
            case kAXSelectedTextChangedNotification: relay.changes.yield(.selectionChanged)
            default: relay.changes.yield(.focusChanged)
            }
        }
        guard AXObserverCreate(pid, callback, &created) == .success, let observer = created else {
            changes.finish()
            return
        }
        let relay = Relay(changes: changes, observer: observer)
        let refcon = Unmanaged.passUnretained(relay).toOpaque()
        AXObserverAddNotification(observer, element, kAXValueChangedNotification as CFString, refcon)
        AXObserverAddNotification(observer, element, kAXSelectedTextChangedNotification as CFString, refcon)
        AXObserverAddNotification(
            observer, AXUIElementCreateApplication(pid), kAXFocusedUIElementChangedNotification as CFString, refcon
        )
        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)
        // The relay stays alive until the source is off the main run loop, where its callbacks run.
        changes.onTermination = { _ in DispatchQueue.main.async { relay.stop() } }
    }

    deinit {
        changes.finish()
    }

    public func read() -> (value: String, cursor: Int, hasFocus: Bool, isSecure: Bool)? {
        let focused = attribute(kAXFocusedUIElementAttribute, of: AXUIElementCreateSystemWide())
        let hasFocus = focused.map { CFEqual($0, element) } ?? false
        if attribute(kAXSubroleAttribute) as? String == kAXSecureTextFieldSubrole {
            return ("", 0, hasFocus, true)
        }
        guard let value = attribute(kAXValueAttribute) as? String,
              let selection = attribute(kAXSelectedTextRangeAttribute),
              CFGetTypeID(selection) == AXValueGetTypeID()
        else { return nil }
        var range = CFRange()
        guard AXValueGetValue(selection as! AXValue, .cfRange, &range) else { return nil }
        return (value, range.location, hasFocus, false)
    }

    private func attribute(_ name: String, of target: AXUIElement? = nil) -> CFTypeRef? {
        var result: CFTypeRef?
        guard AXUIElementCopyAttributeValue(target ?? element, name as CFString, &result) == .success else { return nil }
        return result
    }

    private final class Relay: @unchecked Sendable {
        let changes: AsyncStream<FieldChange>.Continuation
        private var observer: AXObserver?

        init(changes: AsyncStream<FieldChange>.Continuation, observer: AXObserver) {
            self.changes = changes
            self.observer = observer
        }

        func stop() {
            guard let observer else { return }
            CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)
            self.observer = nil
        }
    }
}
