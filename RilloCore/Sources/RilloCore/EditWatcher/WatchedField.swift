/// The text field a dictation was pasted into, as `EditWatcher` sees it.
public protocol WatchedField: Sendable {
    /// The field as it is now, or nil when it cannot be read.
    /// `cursor` counts UTF-16 code units from the start of `value`, as Accessibility does.
    func read() -> (value: String, cursor: Int, hasFocus: Bool, isSecure: Bool)?

    /// Fires whenever the field's value, its selection or the focused element changes.
    /// Each watch iterates it once.
    var notifications: AsyncStream<FieldChange> { get }
}

public enum FieldChange: Sendable {
    case valueChanged, selectionChanged, focusChanged
}
