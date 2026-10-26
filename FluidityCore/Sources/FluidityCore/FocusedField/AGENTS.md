# FocusedField

## Purpose

Reads the focused text field in another app through Accessibility: the text
around the cursor, the selection, and whether it is a password field. Shared
by every part that needs the field. It must never write to the field.

## Rules

- **Selection ranges and counts are UTF-16 units**, because Accessibility
  reports them that way. Slice through `NSString`, never by Swift `Character`
  offsets, or emoji and accented text shift the cursor.
- **A password field yields a reading with no text and zero counts.** Read
  the subrole before the value, so a password is never even fetched.
- **`isSecure` answers true when the subrole cannot be read**, so callers that
  skip saving on a password field also skip it when unsure.
- **Setting the manual accessibility attribute fails on apps that are not
  Electron.** That failure is expected and ignored.
- **The real wrapper stays thin and untested;** put any logic in
  `FocusedField` where the fake element can reach it.

## Map

- `FocusedField` → reads the field; `split` cuts the text at word boundaries.
- `FieldReading` → what one read found.
- `FieldReadError` → why a read failed.
- `AccessibilityElement` → the Accessibility reads the part needs; fakes conform.
- `AXUIElementAccessibility` → the real implementation over `AXUIElement`.
