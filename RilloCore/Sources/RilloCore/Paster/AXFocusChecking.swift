import AppKit
import ApplicationServices

/// `FocusChecking` through Accessibility: the frontmost app's process and its focused element.
@MainActor
public final class AXFocusChecking: FocusChecking {
    public init() {}

    public func currentFocus() -> FocusIdentity? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        let pid = app.processIdentifier
        var focused: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(
            AXUIElementCreateApplication(pid),
            kAXFocusedUIElementAttribute as CFString,
            &focused
        )
        // Equal elements hash equally, so the hash stands in for the element.
        let element = status == .success ? focused.map { Int(bitPattern: CFHash($0)) } : nil
        return FocusIdentity(processID: pid, element: element)
    }
}
