import ApplicationServices
import FluidityCore
import Testing

struct FieldContextAdapterTests {
    // Fails if a field whose subrole cannot be read stops counting as a password field.
    @Test func unreadableFieldCountsAsSecure() async {
        let system = FakeAccessibilityElement()
        let element = FakeAccessibilityElement()
        element.failure = AccessibilityError(code: AXError.failure.rawValue)
        system.focused = element
        let context = await FieldContextAdapter(field: FocusedField(systemWide: system)).read()
        #expect(context?.isSecure == true)
    }

    // Fails if nothing having focus starts producing a field context.
    @Test func noFocusedElementGivesNil() async {
        let context = await FieldContextAdapter(field: FocusedField(systemWide: FakeAccessibilityElement())).read()
        #expect(context == nil)
    }
}
