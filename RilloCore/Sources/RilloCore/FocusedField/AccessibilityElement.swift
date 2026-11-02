import AppKit
import ApplicationServices

/// The Accessibility error code from a failed read or write.
public struct AccessibilityError: Error, Equatable, Sendable {
    public let code: Int32

    public init(code: Int32) { self.code = code }
}

/// The few Accessibility reads `FocusedField` needs, so tests can use a fake element.
/// An attribute the element does not have reads as nil; any other failure throws.
public protocol AccessibilityElement: Sendable {
    func subrole() throws(AccessibilityError) -> String?
    func value() throws(AccessibilityError) -> String?
    /// Location and length in UTF-16 units, as Accessibility reports them.
    func selectedTextRange() throws(AccessibilityError) -> NSRange?
    func numberOfCharacters() throws(AccessibilityError) -> Int?
    /// Read on the system-wide element.
    func focusedElement() throws(AccessibilityError) -> (any AccessibilityElement)?
    /// Read on the system-wide element.
    func focusedApplication() throws(AccessibilityError) -> (any AccessibilityElement)?
    func owningApplication() throws(AccessibilityError) -> (any AccessibilityElement)?
    func bundleIdentifier() -> String?
    /// Set on an app element; Electron apps then expose their text fields.
    func setManualAccessibility(_ enabled: Bool) throws(AccessibilityError)
}

/// `AccessibilityElement` over a real `AXUIElement`.
public struct AXUIElementAccessibility: AccessibilityElement, @unchecked Sendable {
    let element: AXUIElement

    public init(_ element: AXUIElement) { self.element = element }

    public static func systemWide() -> AXUIElementAccessibility {
        let element = AXUIElementCreateSystemWide()
        // Caps every Accessibility call so an app that stops responding cannot stall dictation.
        AXUIElementSetMessagingTimeout(element, 0.25)
        return AXUIElementAccessibility(element)
    }

    private func copy(_ attribute: String) throws(AccessibilityError) -> CFTypeRef? {
        var out: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &out)
        switch error {
        case .success: return out
        case .noValue, .attributeUnsupported: return nil
        default: throw AccessibilityError(code: error.rawValue)
        }
    }

    private func copyElement(_ attribute: String) throws(AccessibilityError) -> (any AccessibilityElement)? {
        guard let out = try copy(attribute), CFGetTypeID(out) == AXUIElementGetTypeID() else { return nil }
        return AXUIElementAccessibility(out as! AXUIElement)
    }

    public func subrole() throws(AccessibilityError) -> String? { try copy(kAXSubroleAttribute) as? String }

    public func value() throws(AccessibilityError) -> String? { try copy(kAXValueAttribute) as? String }

    public func selectedTextRange() throws(AccessibilityError) -> NSRange? {
        guard let out = try copy(kAXSelectedTextRangeAttribute), CFGetTypeID(out) == AXValueGetTypeID() else { return nil }
        var range = CFRange()
        guard AXValueGetValue(out as! AXValue, .cfRange, &range) else { return nil }
        return NSRange(location: range.location, length: range.length)
    }

    public func numberOfCharacters() throws(AccessibilityError) -> Int? {
        (try copy(kAXNumberOfCharactersAttribute) as? NSNumber)?.intValue
    }

    public func focusedElement() throws(AccessibilityError) -> (any AccessibilityElement)? {
        try copyElement(kAXFocusedUIElementAttribute)
    }

    public func focusedApplication() throws(AccessibilityError) -> (any AccessibilityElement)? {
        try copyElement(kAXFocusedApplicationAttribute)
    }

    public func owningApplication() throws(AccessibilityError) -> (any AccessibilityElement)? {
        var pid: pid_t = 0
        let error = AXUIElementGetPid(element, &pid)
        guard error == .success else { throw AccessibilityError(code: error.rawValue) }
        return AXUIElementAccessibility(AXUIElementCreateApplication(pid))
    }

    public func bundleIdentifier() -> String? {
        var pid: pid_t = 0
        guard AXUIElementGetPid(element, &pid) == .success else { return nil }
        return NSRunningApplication(processIdentifier: pid)?.bundleIdentifier
    }

    public func setManualAccessibility(_ enabled: Bool) throws(AccessibilityError) {
        let error = AXUIElementSetAttributeValue(
            element, "AXManualAccessibility" as CFString, (enabled ? kCFBooleanTrue : kCFBooleanFalse) as CFTypeRef
        )
        guard error == .success else { throw AccessibilityError(code: error.rawValue) }
    }
}
