# Paster

## Purpose

Pastes the pasted text at the cursor through the clipboard, learns whether it
landed from the other app reading the text, and puts the user's clipboard
back. It never decides what to paste or what to show in the pill.

## Rules

- **Never send ⌘V a second time.** A paste with no read inside the time limit
  may still land late; a retry can insert the text twice.
- **The landed signal is the other app reading our item.** Anything else that
  reads it counts too, which is why the item carries the
  `org.nspasteboard` skip types: clipboard managers honour them and leave it
  unread. Dropping them turns every clipboard manager into a false "landed".
- **AppKit asks for the text on the main thread.** Waiting for it must stay an
  `await`; blocking the main thread means the read never arrives and every
  paste times out.
- **`Paster.paste` returns only after the restore step.** Callers that start
  the next paste before it returns would snapshot our own text as the
  user's clipboard.
- **Restore only while the clipboard is still ours** (change count unchanged
  and our marker type present), so a copy made during the delay survives.

## Map

- `Paster` → the paste sequence and its timing.
- `Pasteboard`, `KeySender`, `FocusChecking` → the system parts it drives.
- `NSPasteboardPasteboard` → `Pasteboard` over the general clipboard.
- `CGEventKeySender` → posts ⌘V with the layout's "v" key.
- `AXFocusChecking` → frontmost app and focused element through Accessibility.
