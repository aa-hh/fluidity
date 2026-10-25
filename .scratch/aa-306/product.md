# AA-306 product inventory: what the version 1 design must cover

Author: `product`, 2026-10-25. Sources: PRODUCT.md, CONTEXT.md, DESIGN.md, .impeccable/surfaces/app.md, Linear AA-306, AA-296, AA-297, AA-298, AA-301, AA-302, AA-293 (no comments on any of them), and the FluidWispr pill code in `Sources/Fluid/UI/RecordingPill/`. Where a line says "Default", it is a placeholder for the exploration, not a decision; each one is listed again under "Open questions for Alec".

## Who and when

One user: Alec, on his own Mac, macOS 26 or later. 94% of his dictations go into the Claude desktop app (an Electron app), median 24 words (AA-296).

The moments the app is used:

1. Dictating into another app. His eyes are on the app he is typing in; the pill is seen in a glance at most. Most frequent by far.
2. Checking why nothing pasted. A bubble is waiting beside the pill, or he opens the popover to copy or paste a dictation again.
3. Changing a setting. He opens Settings from the popover, changes the shortcut, the cleanup key or rules, or the word list, and leaves.
4. First run. Grant Microphone and Accessibility, set the shortcut, go.

## Surfaces

### Recording pill
- Size: Medium 120 × 28 pt by default (Small 86 × 20, Large 156 × 36). Grows with the live preview up to 360 pt; two lines are 46 pt tall.
- Where: centred 12 pt above the bottom edge of the screen the pointer is on; six dock spots (top and bottom; left, centre, right); can be dragged.
- Must let him: see that the mic is live, see the live preview, see that the text is being worked on, see that the paste landed, paste a transcript again from the waiting bubble (click, or the paste-last-transcript shortcut), and go to the fix for a lost mic or a missing permission (click the bubble).
- Must never: take keyboard focus from the app he is in (it is a non-activating panel); catch a click while hidden; get a shadow, border or fill colour; use a second light colour; fade between ivory and a state colour; scale or bounce to say it can't hear him; stay on screen when nothing is happening or waiting.

### Menu bar icon
- Size: 18 × 18 pt (the FluidWispr candidate, `MenuBarGlyph.swift`). macOS draws it as a template image: one colour that follows the menu bar's light or dark look.
- Where: the menu bar, right side. There is no Dock icon.
- Must let him: tell the state at a glance, and click to open the popover.
- Must never: rely on colour (template images have none); draw the orange mic dot itself (macOS draws that).

### Popover
- Size: 280 pt wide, height to fit (20 or so rows plus status row and the two footer rows; scrolls).
- Where: drops from the menu bar icon.
- Must let him: read the status, see the last 20 or so dictations with the app each went to and when, copy one or paste it again into the app that has focus in one click, open Settings, quit.
- Must never: show a model line (version 1 has no model choice); show anything about training data or the Space drive; link to a history window (version 2).

### Settings window
- Size: 720 × 520 pt. Sidebar 184 pt with four panes (General, Cleanup, Words, Permissions) and the status line at its foot.
- Where: a normal window, opened from the popover's Settings row.
- Must let him: set the shortcut and understand tap versus hold; turn launch at login on or off; turn cleanup on or off, enter the Cerebras key, edit the cleanup rules and restore the default; add, edit and delete words; see Microphone and Accessibility status live and open the right System Settings page.
- Must never: show Models, Dictation or history panes; a model picker or mic picker; any training-data control; replace a standard macOS control with a custom one.

### First-run check
- Size: not set in any source. Default: a window on the Glass shell, 480 pt wide, height to fit.
- Where: on first launch, centred.
- Must let him: see Microphone and Accessibility each with a live granted state, grant each one, then set the shortcut, then finish.
- Must never: be a tour; show a consent screen or training-data text; ask for the cleanup key (that lives in Settings, cleanup is optional).

## State inventory

Column key: "Covered" says whether the locked pill (`RimState` case in `RimSimulation.swift`) or a Glass atom (Figma Atoms page 2007:400) already draws the state. "L+D" says whether light and dark versions are needed. The pill body looks the same on every background, so pill states need one design checked on a light and a dark desktop.

Accessibility fact from the code: the pill's panel is hidden from VoiceOver (`panel.setAccessibilityElement(false)`). Only the waiting bubble is an accessibility element, a button with the labels "Paste transcript", "Fix microphone", "Open Accessibility settings" or "Open Microphone settings". Nothing in FluidWispr posts a VoiceOver announcement for any pill state. Every "Announce" below is a recommendation (macOS `NSAccessibility` announcement request, which VoiceOver reads without moving focus), not something the locked pill already does.

### Recording pill (21 states)

| # | State | Trigger | Understand at a glance | Can do | Ends when | Covered | L+D | Accessibility |
|---|---|---|---|---|---|---|---|---|
| P1 | Hidden | Nothing dictating, nothing waiting | Nothing | Press the key | Key down | Yes: `idle` with "Only while dictating", pill gone | Desktop check only | Nothing to announce |
| P2 | Listening, hold | Key held past the tap threshold | Mic is live; letting go pastes | Talk; let go; Escape | Key up (P7), Escape (P6) | Yes: `listen` | Desktop check | Announce "Listening". Keyboard: the key itself |
| P3 | Listening, hands-free | Key tapped | Mic is live and stays live without holding | Talk; tap again; Escape | Next tap (P7), Escape (P6) | No: `listen` draws the same for tap and hold. AA-306 asks whether to show it | Desktop check | Announce "Listening, tap Right Option to stop" (key name from the setting) |
| P4 | Can't hear you | 2 s of silence while listening (P2 or P3) | No speech is reaching it | Speak; check mic | Speech heard | Yes: 0.2 s pulse every 3 s (`noSpeechAfter`, `nudgeEvery`) | Desktop check | Default: no announcement (VoiceOver users hear their own silence); open question |
| P5 | Live preview shown | Speech recognised while listening | What it heard so far; the newest words may still change | Keep talking | Key up or tap | Yes: words in the pill (default), bubble above, or waveform when off | Desktop check | Default: not read aloud while speaking (it would talk over him) |
| P6 | Cancelled with Escape | Escape while listening or waiting for cleanup | Nothing was pasted | Start again | Pill hidden after 120 ms | Yes: `finish(pasted: false)` goes to `idle` and hides without mint (`hideTime` 0.12) | Desktop check | Announce "Cancelled" |
| P7 | Waiting for cleanup | Key up or second tap, cleanup on with a working key | The text is being worked on, about 1 s at most | Wait; Escape | Cleaned text pasted (P9) or fallback (P8) | Yes: `think`, centre line; with words in the pill they dim to 60% with a light reading through | Desktop check | Default: no announcement (under 1 s) |
| P7b | Transcribing only | Key up, cleanup off or no key | Text is coming | Wait | Paste (P9) | Yes: `think`, brief | Desktop check | None |
| P8 | Fallback | Cleanup slow (about 1 s), offline, or its reply failed the output check; the raw transcript is pasted | Optional: the raw transcript went in, not cleaned text | Nothing needed; can check the popover | Pill gone after mint | No. The code says "The pill has no look for an AI fallback, so it ends normally", i.e. it shows mint like P9. AA-306 asks: quiet, or not shown? | Desktop check | Default: announce "Pasted" only; the popover row carries the reason |
| P9 | Pasted | The paste landed, or was sent and could not be read back (Electron, `unconfirmed`, which the code treats as landed) | It worked | Nothing | Mint 260 ms, then 340 ms collapse | Yes: `done` | Desktop check | Announce "Pasted" |
| P10 | Nowhere to paste | No text field had focus at paste time (`noFocusedTextField`) | Nothing went in; the text is waiting and is in history | Click the bubble or press the paste-last-transcript shortcut after focusing a field; or copy from the popover | Retry lands (P13), new dictation merges the bubble back | Yes: `flux`, transcript bubble splits off the right | Desktop check | Bubble is a button "Paste transcript" (exists). Announce "No text field. Transcript is waiting beside the pill" |
| P11 | Paste failed | Paste sent but did not land (`pasteNotLanded`) | Same as P10 | Same as P10 | Same as P10 | Yes: `flux` | Desktop check | As P10, announce "Paste didn't land. Transcript is waiting beside the pill" |
| P12 | Retrying | Bubble clicked or shortcut pressed while P10 or P11 | It is trying again | Wait | Lands (P13) or fails (P14) | Yes: press bump 1.015 × 1.03; the shortcut also flashes the hover glow and arrow for 320 ms | Desktop check | None (outcome follows at once) |
| P13 | Retry landed | Retry pasted | It worked | Nothing | Pill and bubble mint, bubble dissolves | Yes: `pasted` | Desktop check | Announce "Pasted" |
| P14 | Retry failed again | Retry did not land | Still not pasted; still waiting | Focus a field and try again | Back to waiting (P10 or P11) | Yes: `flux` with soft orange for 600 ms and one 8 pt shake | Desktop check | Announce "Still couldn't paste" |
| P15 | Microphone lost | The mic stopped responding | Dictation can't hear anything; the fix is in the bubble | Click the bubble ("Fix microphone") | Fix taken (P17), new dictation | Yes: `problem` with the crossed-out mic bubble | Desktop check | Bubble button "Fix microphone" (exists). Announce "Microphone stopped" |
| P16 | Permission revoked while running | Microphone or Accessibility, granted earlier this run, turned off | That access is off; the bubble opens its System Settings page | Click the bubble | Permission back (P17) | Yes: `problem` with the lock bubble; Accessibility shown first when both are off; comes back whenever the pill would rest | Desktop check | Bubble button "Open Accessibility settings" or "Open Microphone settings" (exist). Announce "Accessibility access is off" |
| P17 | Fixed | The permission came back, or the mic fix was taken | It is fine again | Nothing | Bubble dissolves over 0.5 s, back to ivory | Yes: `fixed` | Desktop check | Announce "Microphone access is back" or similar |
| P18 | Microphone missing at key down | Key pressed, Microphone never granted (or denied before launch) | It can't listen, and why | Open the fix | Granted | No. The lock bubble only follows a revoke (`PermissionWatcher` counts a permission as revoked only if it was granted earlier). Default: reuse P16's lock bubble, opening Microphone settings, no listening | Desktop check | Bubble "Open Microphone settings". Announce "Microphone access is off" |
| P19 | Accessibility missing at key down | Key pressed, Accessibility never granted | It can listen but can't paste | Dictate anyway (text goes to history), or open the fix | Granted | No (same reason as P18). Default: listen as normal, then at release show P16's lock bubble opening Accessibility settings; the text is in the popover | Desktop check | Announce "Accessibility access is off. Text is in the menu bar history" |
| P20 | Speech model not ready | Key pressed before Parakeet has downloaded or loaded | It can't transcribe yet | Wait | Model ready | No. No source covers it. Default: see open question 9 | Desktop check | Announce "Speech model loading" |

Not in version 1, so left out: the `send` bubble for a failed spoken rewrite (voice commands are in the later pool), the "Muted" label beside the pill, command mode, the resting pill for "Pill shows: Always" (only if Alec keeps that setting, open question 4).

### Menu bar icon (6 states)

| # | State | Trigger | Understand at a glance | Can do | Ends when | Covered | L+D | Accessibility |
|---|---|---|---|---|---|---|---|---|
| M1 | Ready | Permissions granted, nothing recording | Fluidity is running and ready | Click: popover | Any other state | Candidate only: `MenuBarGlyph.ready` (pill outline) in FluidWispr. No Glass atom | Yes (template image follows the menu bar) | Label "Fluidity" |
| M2 | Recording | Key down until the paste or cancel | The mic is live because of Fluidity | Click: popover | Paste, cancel | Candidate: `MenuBarGlyph.dictating` (filled pill). No Glass atom | Yes | Label "Fluidity, listening" |
| M3 | Mic warm | The 3 minutes after a dictation; macOS shows its orange dot | The orange dot is Fluidity keeping the mic ready, not recording | Click: popover (status row says so) | 3 minutes pass, or a new dictation (M2) | No candidate, no atom | Yes | Label "Fluidity, microphone kept ready" |
| M4 | Cleanup off or no key | No Cerebras key; or the switch is off. Default: also key invalid and offline | Text will be pasted as the raw transcript | Click: popover, then Settings, Cleanup | Key entered and accepted, switch on, back online | No | Yes | Label "Fluidity, cleanup off" |
| M5 | Permission missing | Microphone or Accessibility not granted | Dictation can't work fully; something needs fixing | Click: popover, status row has the fix button | Granted | Candidate: `MenuBarGlyph.microphoneProblem` (crossed-out outline), mic only. No atom | Yes | Label "Fluidity, Accessibility access is off" |
| M6 | Transcript waiting | A pill bubble is waiting (P10, P11, P14) | Not in AA-306's list. Default: not a separate icon state; open question 7 | | | No | Yes | |

Default order when several apply: M5 over M2 over M4 over M3 over M1. (M2 over M4 because recording still works with cleanup off.)

### Popover (19 states)

| # | State | Trigger | Understand at a glance | Can do | Ends when | Covered | L+D | Accessibility |
|---|---|---|---|---|---|---|---|---|
| O1 | Status: Ready | M1 | Ready, and the key to use | Read | Other status | Yes: atom Menu bar popover/Ready | Yes | Status row read first; label "Ready. Hold Right Option to dictate" |
| O2 | Status: Listening, hold | P2 while the popover is open | Live; let go to paste | Read | Key up | Yes: Menu bar popover/Listening (hint "Let go to paste"), lit top edge live | Yes | VoiceOver reads the row; no extra announcement |
| O3 | Status: Listening, hands-free | P3 | Live; tap to stop | Read | Tap | Partly: Listening atom, hint text changes | Yes | Same |
| O4 | Status: Cleaning up | P7 | Working | Read | Paste | No | Yes | Same |
| O5 | Status: Mic warm | M3 | Why the orange dot is on | Read | 3 min | No | Yes | Same |
| O6 | Status: Permission missing | M5 | Which access is off | Button opening its System Settings page | Granted | Partly: Status row/Attention with its secondary button | Yes | Button label "Open Microphone settings" |
| O7 | Status: Cleanup off, no key | No key | Raw transcript will be pasted | Button opening Settings, Cleanup | Key entered | Partly: Status row/Attention | Yes | |
| O8 | Status: Key invalid | Cerebras refused the key | Same, and the key needs replacing | Button to Settings, Cleanup | Valid key | Partly: Status row/Attention | Yes | |
| O9 | Status: Offline | No network | Raw transcript will be pasted until back online | Read | Network back | Partly: Status row/Attention, no button | Yes | |
| O10 | Status: Transcript waiting | P10, P11, P14 | One dictation was not pasted | Newest row is marked; one click pastes it | Pasted or next dictation | No | Yes | |
| O11 | History row, at rest | A saved dictation | The text (first 2 lines, default), the app it went to, when ("Claude · 2 min ago") | Click or Return: paste again; copy button or Command-C: copy | | No: needs a new history row | Yes | Row label is the text, then app and time; two actions exposed as named actions "Paste again", "Copy" |
| O12 | History row, hover or keyboard focus | Pointer over it, or arrow keys | Which row an action will hit; the two actions | Same | Pointer leaves | Partly: `surface/hover` and `surface/selected` fills exist; row does not | Yes | Arrow keys move between rows (Full Keyboard Access) |
| O13 | History row, copied | Copy chosen | It is on the clipboard | | 260 ms hold (`duration/hold`) | No | Yes | Announce "Copied" |
| O14 | History row, pasted again | Paste again chosen | It went into the app that has focus | | Popover closes first so the previous app has focus, then pastes | No | Yes | Announce "Pasted" |
| O15 | History row, fallback | That dictation's raw transcript was pasted | It went in without cleanup, and why | Same as O11 | | No: needs a quiet mark on the row | Yes | Appended to row label: "raw transcript, cleanup too slow" |
| O16 | History row, not pasted | Nowhere to paste or paste failed | It never went in | Same as O11 | Pasted again | No: needs a mark on the row | Yes | "Not pasted" in row label |
| O17 | Empty history | No dictations yet | Nothing yet, and how to start | Read | First dictation | No | Yes | Reads as one line |
| O18 | Footer rows | Always | Settings and Quit | Click, or Command-, and Command-Q | | Yes: popover footer rows in the atom | Yes | Standard menu shortcuts |
| O19 | Long history | 20 or so rows | Newest first | Scroll | | No | Yes | Scroll with arrow keys |

### Settings window (window-level 6, General 7, Cleanup 12, Words 9, Permissions 6: 40 states)

Window-level

| # | State | Trigger | Understand at a glance | Can do | Ends when | Covered | L+D | Accessibility |
|---|---|---|---|---|---|---|---|---|
| S1 | Sidebar item default, hover, selected | Pane choice | Which pane is open | Click, or arrow keys, or Command-1 to 4 (default) | | Yes: Sidebar item Default/Hover/Selected | Yes | Sidebar is a list; Voice Control "Click Cleanup" |
| S2 | Status line: Ready | M1 | Ready, and the key ("Ready · Right ⌥") | Read | | No atom; text styles exist | Yes | Read at the end of the sidebar |
| S3 | Status line: Listening | M2 | Live | Read | | No | Yes | |
| S4 | Status line: Permission missing | M5 | Which access is off | Click: goes to Permissions (default) | | No | Yes | Is a button when it links |
| S5 | Status line: Cleanup off or a key problem | M4 | Raw transcript will be pasted | Click: goes to Cleanup (default) | | No | Yes | |
| S6 | Lit top edge resting or live | Mic live | One system with the pill | | | Yes: shell in Style Guide | Yes | Decorative, hidden from VoiceOver |

General

| # | State | Trigger | Understand at a glance | Can do | Ends when | Covered | L+D | Accessibility |
|---|---|---|---|---|---|---|---|---|
| G1 | Shortcut recorder idle | No key set | It needs a key | Click or Space to record | Recording | Yes: Shortcut recorder/Idle | Yes | Button "Record shortcut" |
| G2 | Shortcut recorder recording | Clicked | Press any key now, including one modifier alone | Press a key; Escape stops recording | Key pressed | Yes: Shortcut recorder/Recording | Yes | Announce "Press the key to use" |
| G3 | Shortcut set, single modifier | Right or left Command or Option alone | Which side: "Right ⌥" | Clear, record again | | Partly: Shortcut recorder/Set shows keycaps; a side label on one modifier is not shown | Yes | Value reads "Right Option" |
| G4 | Shortcut rejected | Escape (it cancels dictation). Default: also a plain letter or Space alone, which would stop him typing it | Why it can't be used | Record another | New key | Partly: no recorder error state; Text field/Error has the pattern | Yes | Error read with the control |
| G5 | Tap versus hold explanation | Always under the recorder | Tap once: stays on until the next tap. Hold: talk, let go to paste. Escape cancels | Read | | No: needs a small explanation, text or a two-part picture | Yes | Plain text, read in order |
| G6 | Launch at login on, off | Toggle | | Toggle; Space | | Yes: Toggle | Yes | Toggle label "Launch at login" |
| G7 | Paste last transcript shortcut | AA-296 has the shortcut; AA-306 does not place it | Which key pastes the newest dictation again | Default: a second recorder row (open question 6) | | Yes if a second recorder | Yes | |

Cleanup

| # | State | Trigger | Understand at a glance | Can do | Ends when | Covered | L+D | Accessibility |
|---|---|---|---|---|---|---|---|---|
| C1 | No key | First visit | Cleanup is off until a key is entered; dictation works without it | Paste or type a key | Key entered | Partly: Text field/Default, Toggle | Yes | Field label "Cerebras API key" |
| C2 | Switch off and unavailable with no key | No key | Why the switch can't turn on. Default: switch disabled at 40% with detail "Add a key to turn cleanup on" | | Key entered | Yes: Toggle, disabled at 40% | Yes | Disabled state read with the reason |
| C3 | Key being checked | Key entered | It is checking | Wait | Valid or invalid | No: no field state for checking | Yes | Announce "Checking key" |
| C4 | Key accepted, cleanup on | Cerebras accepted it | It works, and cleanup turned itself on | Switch off; replace or remove the key | | Partly: Text field with masked value; no "accepted" field state | Yes | Announce "Key accepted. Cleanup on" |
| C5 | Key invalid | Cerebras refused it | This key won't work | Replace it | Valid key | Yes: Text field/Error, message 6 pt below | Yes | Error read with the field |
| C6 | Offline | No network while checking, or while cleanup is on | Can't check or clean up now; raw transcript will be pasted | Wait | Network back | No: a status line inside the pane | Yes | |
| C7 | Cleanup on, switched off by him | Switch turned off with a key saved | Off by choice; key kept | Switch on | | Yes: Toggle | Yes | |
| C8 | Rules at default | Never edited | These are the rules sent to Cerebras | Edit | Edited | No: a long, multi-line text field is not an atom | Yes | Text area labelled "Cleanup rules"; Tab moves out of it (default: Tab leaves the field, does not insert a tab) |
| C9 | Rules edited | Edited | They differ from the default | "Restore default" | Restored | Partly: Button Quiet or Secondary | Yes | |
| C10 | Restore default unavailable | Rules at default | Nothing to restore | | Edited | Yes: Button Disabled | Yes | |
| C11 | Restore default confirm | Clicked | His edits will be lost. Default: no dialog; one undo (Command-Z) instead | Undo | | No | Yes | Open question 12 |
| C12 | Privacy line | Always | Text goes to Cerebras's US servers, which keep nothing | Read | | Partly: Icon/Info | Yes | Plain text |

Words

| # | State | Trigger | Understand at a glance | Can do | Ends when | Covered | L+D | Accessibility |
|---|---|---|---|---|---|---|---|---|
| W1 | Empty list | No words | What the list does: names and terms it should get right | Add | First word | No | Yes | |
| W2 | List with rows | Words saved | One word or name per row | Select, edit, delete | | No: needs a word-list row | Yes | List; each row reads its word |
| W3 | Row selected | Click or arrow keys | Which row actions hit | Return: edit; Delete key: delete | | Partly: `surface/selected` fill | Yes | Full Keyboard Access arrow keys |
| W4 | Adding | Add button or Command-N (default) | A new empty row with the cursor in it | Type; Return saves; Escape cancels | Saved or cancelled | No: new row in edit state | Yes | Voice Control: "Click Add word", then dictate the word |
| W5 | Editing | Double-click or Return | That row is now editable | Type; Return saves; Escape cancels | Saved | Partly: Text field/Focused inside a row | Yes | |
| W6 | Duplicate word | Saved a word already in the list | It is already there | Change or cancel | | Partly: Text field/Error | Yes | Error read with the field |
| W7 | Delete | Delete key, or the row's delete button | Gone (red is used only for deleting) | Undo with Command-Z (default, no dialog) | | Partly: `state/destructive` colour; no row delete control | Yes | Named action "Delete" on each row, so no precise pointing is needed |
| W8 | Long list | Many words | Scrolls; newest where? Default: alphabetical | Scroll | | No | Yes | |
| W9 | Empty row saved | Return on an empty new row | Nothing added | | | No | Yes | Row removed quietly |

Permissions

| # | State | Trigger | Understand at a glance | Can do | Ends when | Covered | L+D | Accessibility |
|---|---|---|---|---|---|---|---|---|
| R1 | Microphone not asked yet | Fresh install | Needs allowing | "Allow" shows macOS's own prompt | Allowed or denied | Partly: Status row/Attention with a button | Yes | Button "Allow microphone" |
| R2 | Microphone denied | He chose Don't Allow, or turned it off | Off; only System Settings can turn it on | Button opens Privacy & Security, Microphone | Allowed | Partly: Status row/Attention | Yes | Button "Open Microphone settings" (same words as the pill bubble) |
| R3 | Microphone granted | Allowed | Done | Nothing | Turned off | Yes: Status row/Done | Yes | Status read as "Microphone, allowed" |
| R4 | Accessibility not granted | Fresh install or turned off | Needed to paste | Button opens Privacy & Security, Accessibility | Granted | Partly: Status row/Attention | Yes | Button "Open Accessibility settings" |
| R5 | Accessibility granted | Allowed | Done | Nothing | Turned off | Yes: Status row/Done | Yes | |
| R6 | Live change | He grants it in System Settings and comes back | The row changes from not granted to granted by itself, without a reload | | | No: the switch from Attention to Done is not drawn; it must snap, not fade | Yes | Announce "Accessibility allowed" |

### First-run check (8 states)

| # | State | Trigger | Understand at a glance | Can do | Ends when | Covered | L+D | Accessibility |
|---|---|---|---|---|---|---|---|---|
| F1 | Both missing | First launch | Two things to allow before dictating | Allow Microphone; open Accessibility settings | Both granted | Partly: two Status row/Attention | Yes | Focus starts on the first button |
| F2 | One granted, one missing | Either order | One done, one left | The remaining button | Both granted | Partly: Status row Done and Attention | Yes | |
| F3 | Waiting while he is in System Settings | He clicked a button and left | Nothing to do here until he comes back | Come back | Granted | No | Yes | |
| F4 | Both granted, live | Both allowed | Done, without pressing anything | Continue | Continue | Partly: Status row/Done twice; the live switch is not drawn | Yes | Announce "Both allowed" |
| F5 | Shortcut step, idle | After F4 | Pick the key; tap versus hold explained | Record | Key set | Yes: Shortcut recorder/Idle plus G5 | Yes | |
| F6 | Shortcut step, set | Key pressed | The key, side included | Finish; record again | Finish | Yes: Shortcut recorder/Set | Yes | Primary button "Done" gets focus |
| F7 | Shortcut rejected | Escape, or a key that would block typing | Why | Record another | | Partly (as G4) | Yes | |
| F8 | Finished | Done pressed | The app is in the menu bar now | Try a dictation | Window closes | No: where to point at the menu bar icon is not designed. Default: the window closes and nothing else | Yes | |

Counts: pill 21 (P1 to P20 plus P7b), menu bar icon 6, popover 19, settings window 40, first-run check 8.

### Visual elements the Glass atoms do not have

For `atoms` and `components`:

1. History row for the popover: text (2 lines), app and time, two actions (paste again, copy), hover and keyboard focus, copied and pasted-again confirmations, a quiet fallback mark, a not-pasted mark.
2. Popover empty history.
3. Popover status row variants beyond Ready and Listening: hands-free listening hint, cleaning up, mic warm, transcript waiting (Attention rows can reuse Status row/Attention).
4. Status line at the sidebar's foot, in four states (Ready, Listening, Permission missing, Cleanup problem).
5. Shortcut recorder: an error state, and a keycap that names the side of a single modifier ("Right ⌥").
6. Tap versus hold explanation under the recorder (a "tap or hold" indicator).
7. Text field states: checking (in progress) and accepted, for the API key; a masked key value.
8. Multi-line text field for the cleanup rules, with its "Restore default" button.
9. Word-list row: default, selected, editing, error (duplicate), delete control; the empty list; an add row.
10. Permission row with a live granted state: the snap from Attention to Done, and a three-way Microphone row (not asked yet, denied, granted).
11. First-run window shell and its two steps.
12. Menu bar icon set: M1 to M5 as template images (FluidWispr's `MenuBarGlyph` is a candidate for M1, M2, M5; M3 and M4 have nothing).
13. Pill (for `screens`, only if Alec wants them shown): a hands-free indicator, a fallback look, and P18 to P20. These would be additions to the locked pill, so each is an open question, not a design decision.

## Flows

### Dictation, from key down to pasted text

Hold variant:
1. Key down. If Microphone is missing: P18, stop. If the speech model isn't ready: P20 (default handling in open question 9). Otherwise P2 Listening, hold. Menu bar M2; popover O2 if open; lit top edges go live.
2. He speaks. P5 shows the live preview. After 2 s of silence, P4 pulses until speech returns.
3. Escape at any point up to the paste: P6 Cancelled, nothing pasted. Default: no history row (open question 5). Go to step 9.
4. Key up. Audio continues for 200 ms so the last word isn't cut (AA-296). If Accessibility is missing: transcribe, save to history, show P19, go to step 9.
5. Cleanup on with a working key: P7 Waiting for cleanup. Cleanup off or no key: P7b, then step 7 with the raw transcript.
6. Cleanup result:
   - cleaned text passes the output check within about 1 s: paste the cleaned text, step 7;
   - slow (about 1 s), offline (pasted at once), or failed the check: fallback, paste the raw transcript, P8, step 7.
7. Paste at the cursor, then restore the clipboard.
   - Landed or unconfirmed: P9 Pasted (mint, collapse). History row O11 (O15 if fallback).
   - No text field had focus: P10 Nowhere to paste. History row O16.
   - Paste sent but not landed: P11 Paste failed. History row O16.
8. From P10 or P11: he focuses a field and clicks the bubble or presses the paste-last-transcript shortcut: P12 Retrying.
   - lands: P13 Retry landed, row loses its not-pasted mark;
   - fails: P14, back to waiting;
   - a new dictation instead: the bubble merges back into the pill, the transcript stays in history, step 1.
9. Mic stays warm for 3 minutes: menu bar M3, popover O5. Then M1.

Tap variant: as above, except step 1 enters P3 Listening, hands-free; step 4 is the second tap instead of key up. A press longer than the tap threshold is a hold; the threshold is not in any source (open question 2).

Interruptions at any step:
- Microphone stops responding: P15, bubble "Fix microphone"; taking it goes to P17.
- A permission granted earlier is turned off: P16 (lock bubble), back to P17 when restored. It returns whenever the pill would otherwise rest.

### First run

1. First launch: the first-run window opens with F1. The menu bar icon is M5.
2. He clicks "Allow microphone": macOS's own prompt. Allow: row snaps to granted (F2). Don't Allow: the row becomes R2 with "Open Microphone settings".
3. He clicks "Open Accessibility settings": System Settings opens on Privacy & Security, Accessibility. The window shows F3 while he is away.
4. He turns Fluidity on there and comes back: the row snaps to granted without a click (F4).
5. Continue: F5, the shortcut step, with the tap versus hold explanation.
6. He presses a key: F6 (or F7 if it can't be used).
7. Done: F8. The window closes, menu bar icon M1. The first dictation follows the flow above.

Default (open question 9): if the speech model needs a download on first launch, it starts at step 1 and shows its progress in this window.

## Vocabulary

CONTEXT.md terms used exactly: live preview, raw transcript, cleaned text, pasted text, final text, fallback, correction, cleanup. "Final text" and "correction" never appear on screen in version 1 (corrections are saved silently). The approved pill code and notes say "live words" for what CONTEXT.md calls the live preview; use "live preview" on screen if the setting is shown.

Recommended on-screen wording, one line per state (the key name comes from the setting; "Right ⌥" shown as an example):

| State | Wording |
|---|---|
| Ready (popover, status line) | Ready · Right ⌥ |
| Listening, hold | Listening · let go to paste |
| Listening, hands-free | Listening · tap Right ⌥ to stop |
| Cancelled | Cancelled. Nothing pasted. |
| Waiting for cleanup | Cleaning up |
| Pasted | Pasted |
| Fallback (popover row) | Raw transcript pasted · cleanup too slow / offline / didn't pass the check |
| Nowhere to paste | No text field to paste into |
| Paste failed | Paste didn't land |
| Transcript waiting (popover status) | 1 transcript not pasted |
| Retry failed again | Still couldn't paste |
| Pill bubble labels (existing) | Paste transcript · Fix microphone · Open Microphone settings · Open Accessibility settings |
| Microphone lost | Microphone stopped |
| Permission missing | Microphone access is off / Accessibility access is off |
| Permission granted | Allowed |
| Permission not granted | Not allowed yet |
| Mic warm | Microphone kept ready for 3 minutes |
| Cleanup off | Cleanup off · raw transcript pasted |
| No key | Add a Cerebras key to turn cleanup on |
| Checking key | Checking key… |
| Key accepted | Key accepted · cleanup on |
| Key invalid | Cerebras didn't accept this key |
| Offline | Offline · raw transcript pasted until you're back online |
| Privacy line | Text goes to Cerebras's US servers, which keep nothing. |
| Restore default | Restore default |
| Empty history | Nothing dictated yet. Hold Right ⌥ and speak. |
| Empty word list | Add names and terms Fluidity should get right. |
| Duplicate word | Already in the list |
| History row meta | Claude · 2 min ago |
| Copied | Copied |
| Pasted again | Pasted into Claude |
| Shortcut recorder idle / recording | Record Shortcut / Type a shortcut… (existing atom text) |
| Shortcut rejected (Escape) | Escape cancels dictation, so it can't start it |
| Tap versus hold | Tap: keeps listening until you tap again. Hold: talk, let go to paste. Escape cancels. |
| Model not ready | Speech model loading |

## Open questions for Alec

1. Hands-free versus hold on the pill (AA-306 asks). Default: not shown on the pill; the popover and status line hint say "tap to stop" versus "let go to paste".
2. How long a press counts as a tap? No source gives the threshold. Default for explorations: none needed visually; flag for AA-302.
3. Fallback on the pill: quiet, or not shown (AA-306 asks)? The code shows mint as for a normal paste. Default: not shown on the pill; a quiet mark on the popover row with the reason.
4. Pill settings in version 1. AA-306's General pane lists only the shortcut, tap versus hold and launch at login; the old Glass comp had size and position; FluidWispr has "Pill shows", size and live preview. Default: no pill settings in version 1; approved defaults (Medium, live preview in the pill, only while dictating).
5. Does a cancelled or empty dictation get a history row? Default: no.
6. Where is the paste-last-transcript shortcut (AA-296) set or shown? Default: a second shortcut recorder row in General.
7. Should the menu bar icon have a state for a transcript waiting in the pill bubble? Default: no; the popover status row says it.
8. Permission missing at the moment of dictating (never granted): the locked pill has no look for it. Default: reuse the lock bubble from the revoked case; with Accessibility missing, dictation still runs and the text goes to history.
9. Speech model download and loading on first launch: no source covers it, and dictation can't work before it. Default: a third row in the first-run check with download progress; the pill shows P20 if the key is pressed before it is ready.
10. Which shortcut is set before he picks one? Default: none; the first-run check asks.
11. Which keys does the recorder refuse? Default: Escape only is refused; a plain letter or Space alone gets a warning but is allowed.
12. Restore default for the cleanup rules: confirm first, or undo? Default: no dialog, Command-Z undoes.
13. Should the pill post VoiceOver announcements? Nothing in the locked pill does. Default: yes, for the states marked "Announce" above.
14. Mic warm wording and whether it shows a countdown. Default: no countdown.
15. The menu bar icon set: FluidWispr's pill-outline icon as the base? Default: use it as an exploration option, with new drawings for mic warm and cleanup off.
16. Menu bar state for key invalid and offline: same as cleanup off? Default: yes.
17. Word list order. Default: alphabetical.
18. First-run window size. Default: 480 pt wide, height to fit.
19. Does mic warm count as live under "ivory means live"? AA-306 says only that the mic "stays open for 3 minutes". AA-296's "audio picked up a moment before the key press" suggests the mic feeds a short rolling buffer while warm, but nothing is saved or transcribed without a key press; no source says which. Default: not live, so no ivory for mic warm on the status dot or the menu bar icon.

## Team messages

Sent:
- To `atoms`: the file path and the 12 missing elements (history row, empty history, popover status variants, sidebar status line, recorder error and side-named modifier, tap versus hold explanation, key field checking and accepted, multi-line rules field, word-list row, live permission row with three Microphone states, first-run shell, menu bar icon set), plus three code facts (no fallback look; lock bubble only after a revoke; pill hidden from VoiceOver except the bubble). Delivered.
- To `components`: the same list, plus the rule that every row exposes named actions and arrow-key movement. Not delivered: no agent named `components` was running.
- To `screens`: the flows section, the state numbering, the wording table, and the four pill states the locked pill does not draw (P3, P8, P18 to P20). Not delivered: no agent named `screens` was running.
- To `main`: asked it to point `components` and `screens` at this file when they start.

Received:
- From `atoms`: its atoms.md covers items 1, 2, 4 to 9 and 12 as atoms; 3, 10 and 11 go to `components`; it supplies a Status dot (Ready, Listening, Mic warm, Cleaning up, Attention). It asked whether mic warm counts as live. Answered: open question 19, default not live, no ivory.
