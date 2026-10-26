import FluidityCore
import Foundation

/// An `AccessibilityElement` whose answers a test sets directly.
final class FakeAccessibilityElement: AccessibilityElement, @unchecked Sendable {
    var subroleAnswer: String?
    var valueAnswer: String?
    var rangeAnswer: NSRange?
    var countAnswer: Int?
    var focused: FakeAccessibilityElement?
    var application: FakeAccessibilityElement?
    var bundleID: String?
    /// When set, every throwing read fails with this error.
    var failure: AccessibilityError?
    private(set) var manualAccessibility: Bool?

    private func check() throws(AccessibilityError) {
        if let failure { throw failure }
    }

    func subrole() throws(AccessibilityError) -> String? { try check(); return subroleAnswer }
    func value() throws(AccessibilityError) -> String? { try check(); return valueAnswer }
    func selectedTextRange() throws(AccessibilityError) -> NSRange? { try check(); return rangeAnswer }
    func numberOfCharacters() throws(AccessibilityError) -> Int? { try check(); return countAnswer }
    func focusedElement() throws(AccessibilityError) -> (any AccessibilityElement)? { try check(); return focused }
    func focusedApplication() throws(AccessibilityError) -> (any AccessibilityElement)? { try check(); return application }
    func owningApplication() throws(AccessibilityError) -> (any AccessibilityElement)? { try check(); return application }
    func bundleIdentifier() -> String? { bundleID }
    func setManualAccessibility(_ enabled: Bool) throws(AccessibilityError) { try check(); manualAccessibility = enabled }
}
