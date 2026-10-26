# AA-306 components: composed controls for version 1

Owner: `components`. Date: 2026-10-25. Figma file 5JcAX6bwl48LqQhqcUuGOJ, page "Discovery · version 1" (2044:237), section "Components" (2048:1465, at x 1600, y 0, 2408 × 16002).
Sources: brief.md, product.md (state numbers P, M, O, S, G, C, W, R, F are product's), atoms.md and atoms' messages, Fluidity DESIGN.md "App surfaces", .impeccable/surfaces/app.md, CONTEXT.md, FluidWispr RimParameters.swift (greenHold 0.26, snapTime 0.13, failFlash 0.6, appearTime 0.18, hideTime 0.12, shortcutFlash 0.32), Figma Atoms (2007:400) and Style Guide (2008:403).

Every frame below was checked with get_screenshot after its last change.

## How every frame is built

- One frame per exploration, named "2026-10-25 · <component> · <what it tries> · open", white card, title in Glass/Section, a note in Glass/Detail saying what it tries and what I recommend, then a Light pane and a Dark pane ("Glass · Color" set to Light 2021:5 or Dark 2021:6, desktop gradients copied from atoms' panes).
- The component set lives in the Light pane. The Dark pane holds instances, so the two cannot drift.
- Fills and strokes are bound to "Glass · Color" variables; padding to space variables where the value has one; heights to size/control-m (28), size/control-l (36) or size/row-min (44); corners to radius variables; text uses Glass text styles. Atoms are instances; only their text, their variant properties and nested icon swaps change.
- Popover and settings shells in my frames are plain bound frames labelled "context only". Screens owns the real shells.
- Variant sets share one default for a text property, so per-variant wording is plain text in each variant (editable on instances). Only Settings row, Popover footer row and Keycap use text properties.

## Component list

### Status icon (part)
Frame 2048:1466. Set 2048:1483: State=Done 2048:1472, Attention 2048:1475, Retry 2048:1479.
The 20 pt state circle from the Status row atom, lifted out unchanged so rows can show a granted or not-granted mark. Used by Settings row (Status variants) and History row (Copied).

### Settings row
Frame 2048:1526. Set 2048:1602. Control = Toggle 2048:1532, Pop-up 2048:1539, Text field 2048:1550, Shortcut recorder 2048:1558 (atoms' one-key recorder), Button 2048:1573, Status granted 2048:1580, Status not granted 2048:1590.
Properties: Label#2048:43, Help#2048:44 (text), Show help#2048:45, Rule below#2048:46 (switches).
494 pt, at least 44 pt, 8 pt top and bottom, 12 pt sides, 12 pt to the control, label Glass/Label, help Glass/Detail secondary, 1 pt line/rule under every row except where Rule below is off (the last row in a panel).
Atoms: Toggle, Pop-up button, Text field, Shortcut recorder (version 1), Button Secondary, Status icon.
Recommendation: one row shape in every pane. The Cerebras key does not fit it (see Cleanup controls). No version 1 pane uses the pop-up; the variant stays for completeness.

### Permission row
Frame 2048:2485 (option A recommended, option B shown in the same frame). Set 2048:2540:
Microphone: Not asked 2048:2491, Denied 2048:2502, Granted 2048:2513, Checking 2059:4114.
Accessibility: Not granted 2048:2521, Granted 2048:2532, Checking 2059:4130.
Property Rule below#2048:47.
Atoms: Status row Attention and Done (2021:3550), Status row (version 1) Info (2048:3171) for Checking, Button Secondary.
Live change: Attention switches to Done at once, no fade; announce "Accessibility allowed".
Option B is Settings row Control=Status (state at the right edge).
Recommendation: A. The state sits at the left edge where each row is read from, the circles scan down the list, and it is the atom drawn for this job. Same rows serve the Permissions pane and the first-run check (F1 to F4).

### Popover empty history
Frame 2048:3187. Set 2048:3199: Key=Set 2048:3193 ("Nothing dictated yet." / "Hold Right ⌥ and speak. Your last 20 dictations show here."), Key=Not set 2048:3196 ("Choose a dictation key in Settings, General.").
278 pt, 12/16/16 pt padding. No picture, no button. Recommendation: this one.

### Popover status row
Frame 2049:1803. Set 2049:1900. Status = Ready 2049:1809, Listening hold 2049:1815, Listening hands-free 2049:1821, Cleaning up 2049:1827, Mic warm 2049:1833, Cleanup off 2049:1841, No key 2049:1849, Key not accepted 2049:1859, Offline 2049:1868, Microphone off 2049:1875, Accessibility off 2049:1884, Transcript waiting 2049:1893.
278 pt; the atom's 12, 12, 10, 16 pt padding; dot, status Glass/Label, hint Glass/Small; optional detail and Secondary button indented to the text.
Atoms: Status dot (2048:655), Button Secondary.
Colour: ivory dot only for the two Listening rows; hollow ring for mic warm; amber for no key, key not accepted, offline, permission off; neutral for cleanup switched off by choice and for transcript waiting.
Hints carry tap versus hold: "Tap or hold Right ⌥", "Let go to paste", "Tap Right ⌥ to stop".

### History row (popover)
Two options, both with State = Default, Hover, Selected, Focused, Copied, Fallback, Not pasted, Pasted again, Paste again failed.
- B, recommended: frame 2050:1911, set "History row/Row click" 2050:2012. Default 2050:1917, Hover 2050:1927, Selected 2050:1938, Focused 2050:1949, Copied 2050:1960, Fallback 2050:1969, Not pasted 2050:1980, Pasted again 2050:1991, Paste again failed 2050:2001.
- A: frame 2052:2285, set "History row/Hover buttons" 2052:2373. Default 2052:2291, Hover 2052:2295, Selected 2052:2310, Focused 2052:2325, Copied 2052:2340, Fallback 2052:2354, Not pasted 2052:2359, Pasted again 2052:2364, Paste again failed 2052:2368.
266 pt (the popover rows' 6 pt inset), 8 and 10 pt padding, radius/inner 8, transcript Glass/Transcript two lines then an ellipsis, meta Glass/Detail ("Claude · 2 min ago"), an optional reason line in Glass/Small ("Raw transcript · cleanup too slow", "No text field had focus").
Atoms: Icon button Quiet (2048:1276) with Icon/Copy or Icon/Paste, Status icon Done for Copied.
B: the whole row (click or Return) pastes again; a Copy button sits at the right at all times; Command-C copies the selected row; hover hint "Click to paste", selected hint "Return to paste".
A: Paste and Copy buttons appear only on hover and on the selected row; the transcript rewraps from 246 to 182 pt when they appear.
Recommendation: B. One click on a 266 × 66 pt target for the common action, Copy visible to Voice Control without hovering, nothing reflows under the pointer.
Paste again closes the popover so the app regains focus, so its live result is the pill's (P13 mint, P14 soft orange 600 ms and one shake). "Pasted again" and "Paste again failed" are what the row says the next time the popover opens. Copied is the only live row confirmation: mint for 260 ms, then straight back.
Both frames include the row in a popover-width context with the status row and footer.

### Popover footer row
Frame 2051:2493. Set 2051:2508: Default 2051:2499, Hover 2051:2502, Focused 2051:2505. Properties Label#2051:6, Shortcut#2051:7 ("Quit Fluidity", "⌘ Q").
The atom's Settings and Quit rows lifted out unchanged (266 × 28 capsule). Asked for by screens.

### Sidebar status line
Frame 2053:2396. Set 2053:2455. Status = Ready 2053:2402, Listening 2053:2407, Cleaning up 2053:2412, Mic warm 2053:2416 ("Mic kept ready", hollow ring), Cleanup off 2053:2421, Transcript waiting 2053:2426, Microphone off 2053:2431, Accessibility off 2053:2435, Accessibility off hover 2053:2439, Accessibility off focused 2053:2443, No key 2060:3663, No dictation key 2085:9691 (links to General; "Choose a dictation key" wrapped, so it reads "No dictation key"), Key not accepted 2053:2447, Offline 2053:2451.
160 × 28 pt, the Style Guide line's metrics. Problem lines are buttons that open Permissions or Cleanup (hover adds surface/hover, focus ring for Full Keyboard Access). Cleanup off by choice and Transcript waiting do not link.
Atoms: Status dot.

### Shortcut row
Option A, recommended: frame 2054:2449, set 2054:2569. State = Idle 2054:2455, Recording 2054:2462, Set plain key 2054:2471 ("F5"), Set left Command 2054:2485, Set right Option 2054:2499, Refused 2054:2513 (red, default), Refused amber 2054:2541 (alternative). Properties Show tap and hold help#2054:14, Rule below#2054:15.
Tap versus hold as two help lines: "Tap: keeps listening until you tap again." / "Hold: talk, let go to paste. Escape cancels." Refused shows "Escape cancels dictation, so it can't start it." under the label (Inline note Error or Attention).
Context panel shows a second row, "Paste last transcript", with the recorder Idle (product open question 6 default).
Atoms: Shortcut recorder Idle (2021:3278) and version 1 (2048:3134: Recording, Set (one key), Not allowed (red) 2051:1974, Not allowed 2048:3118), Keycap, Inline note.
Option B: frame 2055:2652, component "Tap and hold picture" 2055:2658: two tiles with a keycap, a key lane (text/secondary) and a listening lane (line/strong), one line each, and "Escape cancels either way: nothing is pasted."
Recommendation: A in Settings. VoiceOver reads it in order, it costs one line, and the picture needs the same two sentences as its label anyway. B could appear once in the first-run shortcut step (screens to judge).

### Cleanup controls
Frame 2056:2742.
- Cleanup key row, set 2056:2880, stacked (label and help above, key field below at full width). State = No key 2056:2748, Focused 2056:2756, Checking 2056:2765, Accepted 2056:2785, Not accepted 2056:2806 (red, default), Not accepted amber 2056:2826 (alternative), Offline 2056:2846, Shown 2056:2866. Property Rule below. Atoms: Secure field (2048:1983, red variant 2051:1952), Inline note.
- Cleanup rules, set 2056:2918. State = At default 2056:2881 (Restore Default disabled), Focused 2056:2890, Edited 2056:2900, Restored 2056:2909 (button becomes "Undo", help "Default rules restored. Command-Z also undoes this."). Atoms: Text area (2048:2090), Button Quiet.
- Switch row: Settings row Control=Toggle with the nested Toggle set to On (help "Removes filler words and resolves self-corrections before pasting."), Off, or Off Disabled ("Add a Cerebras key below to turn cleanup on.").
- Privacy line: Inline note Neutral (2048:1353), "Text goes to Cerebras's US servers, which keep nothing.", under the panel with a 4 pt inset.
Context: the Cleanup pane with a working key, and with no key, both modes.
Recommendation: the stacked key row; no confirmation dialog for Restore Default.

### Word list
Parts frame 2057:3126:
- Word row, set 2057:3181. State = Default 2057:3132, Hover 2057:3135, Selected 2057:3146, Focused 2057:3157, Editing 2057:3168, Duplicate 2057:3175 ("Already in the list", red). Properties Delete button#2057:12, Rule below#2057:13. 36 pt rows (size/control-l). Atoms: Text field Focused and Error, Icon button Destructive (trash).
- Word list bar (option A) 2057:3182: Quiet Icon buttons with Icon/Plus and Icon/Minus (minus disabled until a row is selected).
- Word add row (option B) 2057:3193: Text field "Add a word or name" and a Secondary "Add" button, disabled until he types.
Option B, recommended: frame 2058:3164. The add field heads the panel; Return adds, sorts alphabetically and keeps the cursor in the field; trash on the hovered or selected row; Delete key removes; an Undo line under the list ("Removed "Parakeet". Command-Z puts it back."). States drawn: list with hover and selection, adding, editing in place with a duplicate, empty, after a delete.
Option A: frame 2059:3350. The macOS list with plus and minus at its foot; plus adds an editing row at the end. Same states.
Recommendation: B. Adding is the task he comes for, and B puts it in a 400 pt field that already has focus; removing never needs the pointer.

### Speech model row (first run)
Frame 2059:4164. Set 2059:4210: Downloading 2059:4172, Loading 2059:4183, Ready 2059:4191, Stopped 2059:4199 ("Try Again"). Component Progress bar 2059:4170 (4 pt capsule, track surface/selected, fill text/secondary).
Built on the Status row atoms so it lines up with the permission rows in the first-run check. Asked for by screens for product's open question 9 default. Sizes ("312 of 600 MB") are placeholders.

### First-run step row
Not built. The permission row covers F1 to F4, the speech model row covers the download, and the shortcut step is the Shortcut row. Screens agreed.

## Rules carried from the pill

- Ivory means live: the ivory dot (Status dot Listening) appears only in the two Listening popover rows and the Listening sidebar line. Mic warm is a hollow ring, not ivory (product open question 19). The tap and hold picture draws its listening lane in line/strong, and its key lane in text/secondary because text/primary Dark (#F4EFE6) read as ivory light. The progress bar is not ivory.
- Colour is for state: mint only on the Copied confirmation, the granted circles and the accepted key check, always as an icon fill (Light state/done is never text); amber for something that needs him or is out of his hands; red for field errors (refused key, refused shortcut, duplicate word) by the orchestrator's correction, with amber drawn as the alternative; soft orange is left to the pill (a failed paste again shows in the pill for 600 ms, not as a lasting row colour). Every resting row is neutral, fallback included.
- Switch, never fade: Copied switches to mint and back at once after 260 ms (greenHold 0.26); a permission row switches from Attention to Done at once; Restore Default and Undo swap without a cross-fade.
- Timings used: 260 ms hold (Copied). No other new timing. Hover and press states rely on the Motion collection's 130 ms snap already in DESIGN.md.
- Heights: 28 pt controls and footer rows, 36 pt word rows (size/control-l), at least 44 pt settings rows (size/row-min), the 38 pt popover status row and the 28 pt sidebar line from the existing atoms.
- No new colour, typeface, spring or timing was introduced. The progress bar's colours are existing roles.

## Impeccable critique (macOS Human Interface Guidelines, Operate mode)

Run against operate.md and craft-floor.md, then fixed in one batch:
- Fixed: the return-arrow hint rendered as an emoji; replaced with words ("Click to paste", "Return to paste").
- Fixed: "Pill shows" on the pop-up sample implied a pill setting version 1 does not have; now a neutral sample.
- Fixed: the settings row showed the old two-key recorder (⌥ Space); now atoms' one-key recorder.
- Fixed: the word list's Add button was enabled with an empty field; now disabled until he types.
- Fixed: the empty word list used the Focused field, which draws the placeholder as typed text; now the resting field.
- Fixed: two-line help and detail text clipped in fixed-height variants; every row now hugs its content.
- Kept, with reasons in the frames: the stacked key row (wider than the settings row's right column), red field errors with amber alternatives, the hidden recorder note in the refused shortcut row (its 400 pt note would crush the label; the same Inline note sits under the label instead).
- Every interactive part has default, hover, keyboard focus and disabled states where the atom provides them; empty states teach what the area is for.

## Open questions for Alec

1. Field errors red or amber (refused key, refused shortcut key, duplicate word)? Default drawn: red; amber variants exist beside each.
2. History row: should clicking a row paste it again (option B) or should paste again need its own button (option A)? Default: B. Risk with B: a click to read a row pastes it.
3. Is Command-C on the selected history row enough for copy, or should Copy also be the Return action? Default: Return pastes again, Command-C copies.
4. Popover status for "no key": amber (drawn, per the orchestrator) or neutral, since dictation still works?
5. Mic warm: hollow ring dot (drawn). Should the popover explain the orange dot in words, as drawn ("Microphone kept ready for 3 minutes, so macOS shows its orange dot.")?
6. Tap versus hold: two help lines (A, recommended) or the picture (B)? Should the picture appear once in the first-run shortcut step?
7. Word list layout: add field above (B, recommended) or the macOS plus and minus bar (A)?
8. Speech model download: a neutral progress bar (drawn) or text only?
9. History row corner radius: radius/inner 8 (drawn), against a concentric 10 that has no token.
10. Restore Default for the cleanup rules: undo instead of a confirmation (drawn), as product's default.
11. "Paste last transcript" key row in General (drawn as product's default for its open question 6), or no second key in version 1?
12. Text area corners: radius/inner 8 (atoms' choice, a capsule is impossible for many lines).
13. In Light, atoms' Listening dot (ivory with a line/strong outline on white) looks close to the hollow Mic warm ring; the words beside them differ. Keep, or make the two dots more distinct? (Raised by screens.)

## Not verified

- Hover, focus and timing behaviour is drawn as static variants; nothing was prototyped or animated.
- Contrast of atoms' Inline note Attention text (state/attention as text) was not measured by me.
- VoiceOver, Voice Control and Full Keyboard Access behaviour is specified in the notes, not tested.

## Team messages

Sent:
- To `atoms`: proposed split (atoms: small parts; components: every row and list), asked for node IDs and property keys.
- To `screens`: draft list with built node IDs (Settings row, Permission row, Popover empty history, Status icon) and the build order.
- To `atoms`: asked for red variants of Secure field and the version 1 recorder after the orchestrator's correction.
- To `screens`: build-done message with every node ID.
- To `screens`: replies to its three findings.
- To `screens`: node ID of the new sidebar line No dictation key.

Received:
- From `screens` (orchestrator review): add a sidebar line for no dictation key set. Added 2085:9691.
- From `screens` (after build): Mic warm sidebar read "Ready" (fixed: "Mic kept ready"); focus ring clipped in its list (cause: neighbouring rows draw over the 2 pt ring when rows touch; told screens to add a 4 pt gap); switch help wording (fixed: "resolves self-corrections"); Light Listening dot close to Mic warm ring (open question 13).
- From `atoms`: split accepted; first batch (icons, menu bar icons) and the plan for the rest.
- From `atoms`: build done: Status dot 2048:655, Keycap 2048:1185, Icon button 2048:1276, Inline note 2048:1372, Secure field 2048:1983, Text area 2048:2090, Shortcut recorder (version 1) 2048:3134, Status row (version 1) Info 2048:3171; Eye icons; gotchas (spread shadow needs clip on; inline screenshots can be stale).
- From `screens`: the exact states it composes from, plus requests for the footer row component, a "Paste last transcript" row, the plus and minus bar, an undo line, Permission row Checking, and a speech model download row with a determinate progress bar. All covered. Screens builds the window and popover shells itself.
- From the orchestrator: field errors default to red, amber is the alternative; offline and no key stay amber.
- From `atoms`: red variants Secure field Not accepted (red) 2051:1952, recorder Not allowed (red) 2051:1974, Inline note Tone=Error 2051:1945.
