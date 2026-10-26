# Glass (app windows)

## Purpose

The Glass look from `DESIGN.md` ("App surfaces") and the views built on it:
the settings window (`Settings/`), the menu bar popover and icon (`Popover/`),
the first-run check (`FirstRun/`) and a sample-data preview (`Preview/`).
Views only: they hold no decisions about dictation, cleanup or permissions.

## Rules

- **State flows in, actions flow out.** The app shell writes the models'
  state properties; the views report the user's changes through the models'
  `on…` closures. Setting a state property never calls a closure, so the
  shell can mirror `Settings` without echoing writes back.
- **The popover and windows draw their own shell** (blur, fill, outline, lit
  top edge). A host such as `NSPopover` or `MenuBarExtra` must not add its own
  opaque background behind `PopoverView`.
- **Recording a shortcut takes the next key press in this app only.** The
  global `Hotkey` still sees it; pause it while
  `SettingsModel.onShortcutRecordingChange` reports true.
- **Undo needs the app's Edit menu.** Command-Z reaches the window's undo
  manager through the standard Edit menu that the SwiftUI app provides.
- **`WindowPreview.openIfRequested()` runs only if the app calls it at launch.**
- Token values live in `GlassTheme`; copy new ones from `DESIGN.md`, never
  pick them by eye.

## Map

- `GlassTheme` → colours, type, sizes and motion from `DESIGN.md`.
- `GlassComponents.swift` → shell, lit top edge, panel, row, buttons, toggle, field chrome.
- `AppStatus` → what the status line and popover status row say.
- `SettingsModel`, `SettingsWindow` → settings state and the 720 × 520 window.
- `PopoverModel`, `PopoverView` → history and the 280 pt popover.
- `MenuBarIcon` → template image for each `MenuBarState`.
- `FirstRunModel`, `FirstRunWindow` → the 540 pt first-run check.
- `WindowPreview` → `FLUIDITY_PREVIEW` sample windows.
