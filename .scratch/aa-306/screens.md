# AA-306 screens: every version 1 screen and state

Owner: `screens`. Date: 2026-10-25. Figma file 5JcAX6bwl48LqQhqcUuGOJ, page "Discovery · version 1" (2044:237), section "Screens" plus one section per screen.
Sources read: brief.md, product.md (state numbers P1 to P20, M1 to M6, O1 to O19, S, G, C, W, R, F come from its "State inventory"), atoms.md, AA-306, Fluidity DESIGN.md, .impeccable/surfaces/app.md, CONTEXT.md, the Dynamic Island motion notes, FluidWispr RimParameters.swift, RimSimulation.swift, RimBubble.swift, RecordingPillController.swift, MenuBarGlyph.swift, notes visual-direction.md and live-words-pill.md; Figma pages Tokens, Atoms, Style Guide and the approved pill page (27:2) read with get_metadata, get_screenshot and read-only scripts.

Impeccable ran as a subagent without access to Alec, so its interview step is replaced by AA-306 and product.md's defaults; every default is labelled as one.

## Screen plan

### Facts from the code that change the plan

- Nowhere to paste already uses the approved paste-failed bubble. `RecordingPillController.handle(_ event:)` sends `.noFocusedTextField` and `.failed(.pasteNotLanded)` to `holdFailedPaste()`, which enters `RimState.flux` (RecordingPillController.swift lines 432 to 437). It only does so when transcript history is saved (`takesFailedPastes`, line 74); version 1 always saves history.
- Fallback has no look of its own: the paste of a raw transcript ends in mint like any paste (`finish(pasted: true)` goes to `.done`).
- Cancel: `finish(pasted: false)` drops the words and goes to `.idle` with no mint; the pill leaves in 120 ms (`RimParameters.hideTime`).
- The lock bubble appears only after a permission granted earlier in the run is revoked (`PermissionWatcher.revoked`); Accessibility wins when both are off (`lockedPermission`). A permission never granted has no pill look yet (product open question 8).
- Reduce Motion in code: bubbles fade in place over 0.2 s (`RimBubble.swift` lines 159, 168, 180: `dt / 0.2`); no press bump (line 126), no shake (line 133); sizes jump (`RimSimulation.updateSize`). The brief and the Motion collection say 130 ms cross-fade for the app; the pill's bubbles use 0.2 s. Both stay as they are; noted per state.
- The approved component set 27:82: each variant is a 260 × 72 transparent frame with the Medium pill (120 × 28) at x 70, y 22 and the 28 pt bubble 6.1 pt to its right. Variants used here: Hidden 27:38, Rest 27:43, Listening 27:47, Processing: download 27:52, Processing: line 27:57, Complete: green line 27:63, Collapse: swell 46:101, Collapse: closing 46:107, Collapse: last glow 46:113, Mic lost: fix bubble 27:77, Permission revoked: fix bubble 45:110, Paste failed: split 31:65, Paste failed: waiting 31:69, Paste failed: hover 31:76, Retry failed 31:84, Retry worked 31:91, New dictation: merge back 31:98, Live words: waveform 2015:171, Live words: one line 2015:178, Live words: release 2016:182, Live words: pasted 2017:182.

### Frame conventions

- Name: "2026-10-25 · <screen> · <state> · <what it tries> · open".
- Inside each frame, left to right: a Light pane and a Dark pane (explicit "Glass · Color" mode Light 2021:5 and Dark 2021:6), each on the Style Guide's desktop gradient (Light #DCE6F2 to #F3E7DA, Dark #1B2030 to #2A1F1E), then a note column 320 pt wide in Glass/Detail: what it tries, recommendation and why (option frames only), keyboard path, VoiceOver announcement, Reduce Motion.
- Every screen part is an instance of a Glass atom (Atoms page) or a `components` component, with content in slots, colours bound to "Glass · Color" by name, text in Glass/* styles. No overrides of instance styling.
- One section per screen: "Screens · Recording pill", "Screens · Menu bar icon", "Screens · Popover", "Screens · Settings", "Screens · First-run check", all inside or beside the "Screens" section.

### A. Recording pill (build first: approved set 27:82 only)

Layout at real size: each pane 480 × 200, the bottom strip of a desktop with a plain mock app window (like Style Guide 2021:5544) above; the pill instance placed so the Medium pill (120 × 28) sits centred, its bottom edge 12 pt above the pane's bottom edge. Sequences show two to four instances in time order with a Glass/Small caption under each ("key down", "+0.15 s").

| Frame | States drawn (instances) | Options |
|---|---|---|
| A1a Hands-free versus hold, no difference | Hold: Listening 27:47; Hands-free: Listening 27:47; captions only | Recommended. The pill is glanced at, not read; the key he pressed tells him which mode he chose; the popover status and the status line say "tap Right ⌥ to stop" or "let go to paste"; VoiceOver says it once. Adds nothing to the locked look. |
| A1b Hands-free versus hold, the bubble above as a one-time hint | Hands-free: Live words: first word 2017:171 style bubble holding "Tap Right ⌥ to stop" for the first 1.5 s, then Listening | Uses only approved shapes (the bubble above, 11 pt words) but gives the bubble a second meaning and clashes with "Bubble above" live preview; open question for Alec. Not recommended. |
| A2 Cancelled with Escape | Listening 27:47 (live preview in the pill, 2015:178) then Hidden 27:38, caption "Escape · nothing pasted · gone in 120 ms, no mint" | No question. |
| A3 Waiting for cleanup | Waveform path: Processing: download 27:52 then Processing: line 27:57 then Complete: green line 27:63; live preview path: Live words: one line 2015:178 then Live words: release 2016:182 then Live words: pasted 2017:182 | No question. Up to about 1 s on the line; then fallback (A4) if no cleaned text. |
| A4a Fallback, not shown at all | Processing: line then Complete: green line then Collapse: swell; the popover row shows no mark | |
| A4b Fallback, quiet | The same pill sequence (mint) plus a note: the popover row says "Raw transcript · cleanup too slow" (drawn in Popover C) | Recommended. The pill is the same in both, because amber means "act now" and fallback needs no action; the reason lives in history where he looks when the text reads uncleaned. |
| A5a Nowhere to paste, paste-failed bubble | Processing: line then Paste failed: split 31:65 then Paste failed: waiting 31:69 then hover 31:76 | Recommended, and what the locked code already does. One click after focusing a field pastes it. |
| A5b Nowhere to paste, quiet collapse | Processing: line then Hidden, caption "text kept in history" | Looks identical to a cancel, so he would think the dictation was lost. Not recommended. |
| A6 Microphone missing at key down | Permission revoked: fix bubble 45:110 (lock) straight from key down, no listening; hover shows glow | Default from product open question 8. Click opens Privacy & Security, Microphone. |
| A7 Accessibility missing at key down | Listening 27:47 then Processing: line then Permission revoked: fix bubble 45:110 | Default from product open question 8: dictation runs, the text lands in history, the lock bubble opens Accessibility settings. |

Reduce Motion per state goes in each note. Speech model not ready (P20) is not in AA-306's pill list; left as an open question.

### B. Menu bar icon

Layout: a macOS menu bar strip 480 × 24 pt (Light: white at 40% over the Light gradient, Dark: the Dark gradient with near-black at 40%), right side: two neutral placeholder status items, the Fluidity item (18 × 18 pt icon in a 28 × 20 pt hit area), the clock "Sun 25 Oct 09:41" in 13 pt. The same strip again at 2x (scaled copy, 960 × 48) to check the 1.5 pt strokes on Retina. Light and dark, 1x and 2x, per state.
States, one frame each: ready (M1), recording (M2), mic warm (M3, with macOS's own orange privacy dot drawn to the right as macOS places it, labelled "drawn by macOS"), cleanup off or no key (M4), permission missing (M5).
Icons: instances of the atoms agent's "Menu bar icon/Pill outline" set (2045:344: Ready 2045:319, Recording 2045:323, Mic warm 2045:325, Cleanup off 2045:330, Permission missing 2045:337), plus any second option `atoms` adds. Recommendation per state follows its options.

### C. Popover (280 pt wide)

Layout at real size, top to bottom: shell (surface/window over 40 pt blur, line/rule outline, Elevation/Float, 16 pt corners, resting lit top edge; live while listening); status row 38 pt (8 pt status dot, status in Glass/Label, hint in Glass/Small secondary, 16 pt side padding); rule; history list: rows inset 6 pt, each 8 pt top and bottom and 10 pt side padding, transcript up to 2 lines in Glass/Transcript (13/17), then "Claude · 2 min ago" in Glass/Small secondary, row height about 66 pt; five rows visible at 480 pt total height, the rest scrolls; rule; Settings… (⌘,) and Quit Fluidity (⌘Q) as 28 pt capsules inset 6 pt. Placed under a menu bar strip so it drops from the icon.

States, one frame each, Light and Dark: ready with history (O1, O11), listening hold (O2), listening hands-free (O3), waiting for cleanup (O4), mic warm (O5), cleanup off or no key (O7), key invalid (O8), offline (O9), permission missing (O6), transcript waiting in the pill bubble (O10, newest row marked "Not pasted"), empty history (O17), hover and keyboard focus on a row (O12), a row just copied (O13), a fallback row and a not-pasted row (O15, O16, inside the ready frame), Settings and Quit rows hovered (O18).

Question (AA-306 "one click to copy, or to paste again"): what a click on a row does.
- C-a: click pastes again into the app that had focus; a Copy button appears at the row's right on hover and keyboard focus; ⌘C copies the focused row. Recommended: paste again is the action he opens the popover for after "nowhere to paste", and the popover closes first so focus returns to his app.
- C-b: click copies; a Paste button appears on hover. Safer (never types into the wrong field) but always two steps to get text back in.
- C-c: both buttons always visible on every row. No hover needed (good for Voice Control) but 20 rows of two buttons is noise.

### D. Settings window (720 × 520)

Layout at real size from the Style Guide comp (2021:4479): outer frame 800 × 600 with the desktop gradient; window 720 × 520 (Elevation/Float); shell with 16 pt corners and resting lit top edge; sidebar 184 pt (12 pt padding, window controls 28 pt, 12 pt gap, four Sidebar item instances General, Cleanup, Words, Permissions 2 pt apart, spacer, status line at the foot); content pane 20 pt padding, Glass/Title, 16 pt between title and groups, Section header then a raised panel 8 pt below, rows at least 44 pt, 1 pt rules.

Status line at the sidebar's foot in every status (S2 to S5): Ready · Right ⌥; Listening (live dot, ivory); Accessibility access is off (attention dot, a button to Permissions); Cleanup off (secondary dot, a button to Cleanup). Drawn as one frame with four sidebars side by side, Light and Dark.

General (frames: recorder idle G1, recording G2, set to Right ⌥ G3, rejected Escape G4; launch at login on and off G6):
- Group "Dictation key": row "Start dictation" with the Shortcut recorder; row "Paste last transcript" with a second recorder (product default G7); row "Launch at login" with the Toggle.
- Tap versus hold question (AA-306 "make it clear"):
  - D-G-a: one detail line in the recorder row: "Tap to keep listening until you tap again. Hold to talk, let go to paste."
  - D-G-b: a raised panel "How the key works" with three short rows, each a keycap and one sentence: Tap, Hold, Escape. Recommended: three facts read in one glance each, Escape gets said, and the keycap uses the chosen key so the sentence is concrete.

Cleanup (frames: no key C1 and C2, checking C3, key accepted with cleanup on C4, key invalid C5, offline C6, cleanup switched off with a key saved C7, rules edited with Restore default enabled C9, the privacy line C12 in all):
- Group "Cleanup": row "Clean up dictations" with Toggle (disabled with "Add a key to turn cleanup on" when no key); row "Cerebras API key" with the Text field and its state (needs `components` key field states: checking, accepted, masked value).
- Key invalid (orchestrator correction, 2026-10-25): red by default, as a field error (state/destructive, DESIGN.md "Text field" and Atoms Text field State=Error 2021:2274). Amber drawn as the alternative frame, marked as an open question for Alec. Offline and no key stay amber. The same applies to the popover's key-invalid status row.
- Group "Rules": the multi-line rules field (about 470 × 150) with "Restore default" (Button Quiet, disabled at default).
- Privacy line: Icon/Info and "Text goes to Cerebras's US servers, which keep nothing." in Glass/Detail secondary.

Words (frames: list with rows W2, empty W1, selected W3, adding W4, editing W5, duplicate W6, just deleted with undo W7, keyboard-only flow):
- One raised panel as a list, rows 28 pt (one word or name per row, Glass/Body), selection in surface/selected; a bar under it with + and − buttons (Icon/Plus, Icon/Minus from atoms) as on standard macOS lists; edit in place on Return or double-click; Delete key or − removes; "Deleted "Parakeet" · Undo" line for 5 s and ⌘Z.

Permissions (frames: both granted R3 R5, both not granted R1 R4, one of each, checking):
- One raised panel with two Status row instances: Microphone (Icon/Dictation glyph), Accessibility (Icon/Accessibility); attention rows carry "Allow microphone" or "Open Accessibility settings"; the granted state replaces the attention state at once.

Window-level frames: mic live (lit top edge live, status line ivory "Listening"), Reduce Motion (same window, note on what stops: no edge travel, 130 ms cross-fade on every change).

### E. First-run check

Layout default (product open question 18): a window on the Glass shell, 480 pt wide, height to fit (about 400 pt), centred on the desktop. Title "Set up Fluidity", one line of detail, then a raised panel with the Microphone row, the Accessibility row and, if the speech model download default stays (product open question 9), a "Speech model" row with progress. Then the shortcut part: the Shortcut recorder with the tap versus hold rows from D-G-b, and "Done" (Button Primary) bottom right.
States, one frame each: nothing granted (F1), one granted (F2), waiting while he is in System Settings (F3), both granted live (F4), shortcut step idle (F5), shortcut recording, shortcut set (F6), done (F8).
Question (how "then the shortcut" is laid out):
- E-a: one window, both parts visible; the shortcut part is dimmed and unavailable until both permissions are granted. Recommended: nothing to navigate, he sees the whole job up front, and the live granted state visibly unlocks the next part.
- E-b: two steps in place: the permission check, then "Continue" replaces it with the shortcut step. Standard setup-assistant pattern, one more press.

### Accessibility checks to run on every screen

4.5:1 text contrast in both appearances (DESIGN.md's measured pairs; flag any new pair); a keyboard path for every action; a VoiceOver announcement for every state change; no long typing or precise pointing.

Sections C, D and E were built after the components build-done message; A and B before it, from 27:82 and atoms only.

## Explorations

Top section "Screens" 2048:1603 (x 0, y 4000 on page 2044:237).

### A. Recording pill: section "Screens · Recording pill" 2048:1604

Every frame: Light row above Dark row (each moment a 220 × 140 desktop crop with the Medium pill docked 12 pt above the bottom edge, built from instances of 27:82), notes on the right. Light and Dark are stacked rather than side by side here because each frame shows a sequence of up to four moments. All screenshot-checked.

| Frame | Node | What it tries | Recommendation |
|---|---|---|---|
| Hands-free versus hold · A: no difference on the pill | 2048:1605 | Listening for both | Recommended: he chose the mode with his own finger a moment ago; the popover status, the status line and VoiceOver say how it will stop. Adds nothing to the locked look. |
| Hands-free versus hold · B: one-time hint in the bubble above | 2048:1675 | "Tap Right ⌥ again to stop" in the approved bubble above after a tap | Not recommended: gives the bubble a second meaning (it holds the live preview when "Bubble above" is chosen) and needs a hint duration the pill does not have. |
| Cancelled with Escape | 2048:2097 | Listening, then gone in 120 ms with no mint | The locked behaviour as is. No history row (product default). |
| Waiting for cleanup | 2048:2161 | Inward light 150 ms, centre line up to about 1 s, mint; with live preview, words dim to 60% | The approved look covers it. |
| Fallback · A: not shown at all | 2048:2289 | Mint like any paste; history row unmarked | Not recommended: a slow network, a bad key and bad rules all look the same. |
| Fallback · B: quiet | 2048:2387 | Mint on the pill; the popover row adds "Raw transcript · cleanup too slow" in secondary text | Recommended: amber means "act now", a fallback needs nothing in the moment; the reason waits in history. |
| Nowhere to paste · A: paste-failed bubble | 2048:2541 | Split, waiting, hover with send arrow | Recommended, and what the locked code already does (`.noFocusedTextField` goes to `holdFailedPaste()`, RecordingPillController.swift lines 432 to 437). |
| Nowhere to paste · B: quiet collapse | 2048:2665 | Hidden, text only in history | Not recommended: identical to a cancel; three steps to recover instead of one. |
| Microphone missing at key down | 2048:2731 | Lock bubble at once, no listening | Recommended default (product open question 8). Needs a code change: the lock bubble today only follows a revoke. |
| Accessibility missing at key down | 2048:2807 | Listen, wait, then the lock bubble; text in history | Recommended default. Open question: after access comes back, should the bubble become the paste-failed bubble? |

### B. Menu bar icon: section "Screens · Menu bar icon" 2048:3221

Each frame compares atoms' three options as instances (A pill outline 2045:344, B microphone 2045:1007, C dot and pill 2046:581) in a 280 × 24 pt menu bar strip (desktop gradient under surface/sidebar, a neutral Control Center placeholder, the clock), Light and Dark, at 1x and at 2x (a rescaled copy). The mic warm and recording strips carry macOS's own orange microphone-in-use dot, labelled as drawn by macOS. All screenshot-checked.

| Frame | Node | Recommendation |
|---|---|---|
| Ready | 2048:3222 | A: the pill itself, already in code (MenuBarGlyph.swift). B is one microphone among macOS's own; C is too small at 1x. |
| Recording | 2048:3383 | A: filled pill. |
| Mic warm | 2048:3548 | A, with a caution: at 1x the inner bar and the Recording fill differ by a thin ring; the popover status row says it in words. No ivory (product open question 19). |
| Cleanup off or no key | 2048:3837 | A, plus an open question: show it only for key invalid and offline, nothing for no key or switched off. |
| Permission missing | 2048:4042 | A: the struck-through pill (FluidWispr microphoneProblem). |

### C. Popover: section "Screens · Popover" 2064:3661

Every frame: a Light and a Dark desktop pane (360 pt wide) with a menu bar strip and the 280 pt popover dropped under the icon, notes on the right. Shell built from bound frames (surface/window, 40 pt background blur, line/rule, 16 pt corners, Elevation/Float, resting lit top edge; live edge while listening); content is instances of components' Popover status row 2049:1900, History row/Row click 2050:2012 (or Hover buttons 2052:2373), Popover footer row 2051:2508, Popover empty history 2048:3199 and atoms' menu bar icon A. Row content: five realistic dictations with app and time, one a fallback.

| Frame | Node | Shows | Recommendation |
|---|---|---|---|
| Ready with history | 2064:3662 | Status Ready, five rows (third a fallback with its reason), Settings and Quit | |
| History scrolled to its end (added 2026-10-26) | 2086:9913 | Rows 16 to 20 of 20, overlay scroller, footer fixed below | Shows "last 20 or so": the oldest row drops off at 21 |
| Listening, hold | 2065:3777 | Ivory dot, live lit top edge, "Let go to paste" | |
| Listening, hands-free | 2065:3955 | "Tap Right ⌥ to stop" | Where hands-free versus hold is spelled out |
| Waiting for cleanup | 2065:4133 | "Cleaning up", edge back to resting | |
| Mic warm | 2065:4309 | Explains the orange dot; hollow ring, no ivory | |
| Cleanup off or no key | 2066:4235 | Light: no key, amber, button to Cleanup. Dark: switched off by choice, neutral | Open question: amber or neutral for no key |
| Key invalid | 2066:4424 | Amber status with button | Status stays amber; the red field error lives in Settings, Cleanup |
| Offline | 2066:4614 | Amber, no button | |
| Permission missing | 2066:4797 | Light: Accessibility off. Dark: Microphone off. Each with its System Settings button | |
| Transcript waiting | 2067:4742 | "1 transcript not pasted"; newest row marked "Not pasted · No text field had focus" | Menu bar icon unchanged (product default) |
| Empty history | 2067:4921 | "Nothing dictated yet." and how to start | |
| Row just copied | 2067:4998 | "Copied" with mint check for 260 ms | |
| Row pasted again | 2067:5171 | "Pasted into Claude · just now" | |
| Row action · A: buttons on hover | 2068:5120 | Paste and Copy appear on hover; text rewraps | Not recommended |
| Row action · B: click the row, Copy always there | 2068:5252 | Hover hint "Click to paste" | Recommended (components agrees): one large target for paste again, Copy reachable by Voice Control without hover, nothing reflows. Risk: a click to read pastes |
| Row keyboard focus | 2068:5410 | Light: selected with arrows. Dark: Full Keyboard Access ring | |
| Settings and Quit rows | 2068:5565 | Light: Settings hovered. Dark: Quit focused | |

### D. Settings window: section "Screens · Settings" 2070:5484

Every frame: Light and Dark 800 × 600 desktops holding the 720 × 520 window (sidebar 184 pt with macOS window controls, four Sidebar item instances, status line instance at the foot; content 20 pt padding, Glass/Title, groups of Section header plus a raised panel). Panels are clones of components' compositions (2054:2572 General, 2056:3382 and 2056:3430 Cleanup, 2058:3164 and 2059:3350 Words) with variant and text changes only; Permissions panel built from Permission row 2048:2540.

General:

| Frame | Node | Shows | Recommendation |
|---|---|---|---|
| Key set to Right ⌥, tap and hold A | 2070:5485 | Dictation key, two help lines (Escape included), Paste last transcript recorder, Launch at login | Tap versus hold A, two help lines, recommended (components agrees) |
| Key set to Left ⌘ on its own (added 2026-10-26) | 2086:9231 | Keycap "Left ⌘" in the recorder and the status line hint | Covers AA-306's "left or right Command or Option on its own" |
| Recorder idle, launch at login off | 2071:5586 | "Record Shortcut"; toggle off; status line "No dictation key" (components' 2085:9691) | |
| Recording | 2071:5795 | "Type a shortcut…" | |
| Key refused · A: red | 2071:6006 | Escape refused, red field error | Default (orchestrator) |
| Key refused · B: amber | 2072:5884 | Same in amber | Alternative; open question |
| Tap versus hold · B: picture | 2072:6130 | Components' tap and hold picture as a second group | Not recommended in Settings |
| Window with the mic live | 2072:6400 | Live lit top edge, status line Listening with ivory dot | |
| Reduce Motion | 2072:6600 | Same window; notes on what stops moving | |

Cleanup:

| Frame | Node | Shows | Recommendation |
|---|---|---|---|
| No key | 2073:6374 | Switch unavailable with reason, empty key field, default rules, privacy line | |
| Checking | 2073:6560 | "Checking key…" | |
| Key accepted, cleanup on | 2073:6781 | Mint check icon, Restore Default unavailable | |
| Key invalid · A: red | 2073:7008 | Red field error; switch says paused | Default (orchestrator) |
| Key invalid · B: amber | 2075:6850 | Amber field | Alternative; open question |
| Offline | 2075:7116 | Amber line under the key | |
| Whole pane, cleanup switched off | 2075:7379 | Neutral; key and rules kept | |
| Rules edited | 2075:7608 | Restore Default available | |
| Rules restored | 2075:7819 | Button becomes Undo; no dialog | Product default (undo, no confirmation) |

Words:

| Frame | Node | Shows | Recommendation |
|---|---|---|---|
| B: add field above · list, hover, selection | 2077:7482 | Add field heads the panel; trash on hovered row | Recommended (components agrees): adding is the task, and the field already has focus |
| Adding | 2077:7634 | Typing in the add field | |
| Editing in place | 2077:7781 | Row as a field | |
| Duplicate | 2077:7968 | "Cerebras" again: red "Already in the list" | Red default, amber alternative in components |
| Empty | 2078:7832 | What the list is for | |
| Just deleted, with Undo | 2078:7977 | Undo line and Command-Z | Open question: how long the line stays |
| Keyboard only | 2078:8131 | Full Keyboard Access ring on a row; the whole flow in notes | |
| A: plus and minus bar | 2078:8362 | Standard macOS list | Not recommended |

Permissions:

| Frame | Node | Shows |
|---|---|---|
| Both allowed | 2079:8178 | Two mint circles, no buttons |
| Neither allowed | 2079:8353 | Allow Microphone; Open Accessibility Settings |
| One of each | 2079:8541 | Microphone allowed, Accessibility not |
| Microphone denied | 2079:8720 | Open Microphone Settings |
| Checking | 2079:8899 | Neutral rows, no buttons |

Status line in every status: 2079:9071 (all 13 statuses of components' Sidebar status line 2053:2455, Light and Dark, including hover and focus on a linking line).

### E. First-run check: section "Screens · First-run check" 2080:9162

Window on the Glass shell, 540 pt wide (the 494 pt component rows set the width; product's 480 pt default is too narrow), height to fit, close button only. Rows: Permission row Microphone and Accessibility, Speech model row 2059:4210, Shortcut row 2054:2569, Button Primary.

| Frame | Node | Shows | Recommendation |
|---|---|---|---|
| A · nothing allowed | 2080:9163 | Both rows amber, model downloading, key group at 40% until both are allowed, Done unavailable | A recommended: the whole job visible, nothing to navigate, each allowed row brings the next part to life |
| A · one allowed | 2080:9306 | Microphone allowed; also how it looks while he is in System Settings | |
| A · both allowed | 2080:9437 | Accessibility switched by itself; key group available; model loading | |
| A · recording the key | 2081:8923 | "Type a shortcut…" | |
| A · key set | 2081:9046 | Right ⌥ set, Done filled and focused | |
| Done | 2081:9182 | Window closed; the icon in the menu bar | Product default: nothing else appears |
| B · step 1, access | 2081:9217 | Permissions alone, Continue | Not recommended: one more press, the window changes height |
| B · step 2, the key with the picture | 2081:9318 | Key step with components' tap and hold picture, Back and Done | Picture left as Alec's call |

### Fixes from the independent review (review.md, 2026-10-26)

Each checked with get_screenshot after the change.
1. 2071:5586: status line swapped to components' new Status=No dictation key (2085:9691); its note updated.
2. 2071:5795 and 2081:8923: the recorder now reads "Type a shortcut…", matching DESIGN.md and the notes.
3. 2073:6560: status line swapped to the neutral "Cleanup off" while the key is checked.
4. 2079:8178: VoiceOver note rewritten (no buttons in this state).
5. 2079:8720: VoiceOver note rewritten to match the denied row, quoting its text.
6. 2077:7781: the editing row now holds "Kubernetes" with the cursor at the end; notes say the same.
7. 2078:7832: the empty-list line now reads "No words yet. Type one in the field above and press Return.", so it no longer repeats the group subtitle.
8. Every frame in the five sections (73) carries a visible "date · status" line under its title, taken from the frame name.
9. Two new frames: 2086:9231 (General, Left ⌘) and 2086:9913 (popover scrolled to row 20). Frames below each were moved down; no overlaps (checked by script).
Not touched, per the orchestrator: the Dark focus ring being ivory.

### Impeccable critique (macOS Human Interface Guidelines, Operate mode)

Run per screen against impeccable's operate.md and craft-floor.md, then fixed in one pass and confirmed with screenshots:
- Fixed: placeholder menu bar items looked like the pill-outline icon; replaced with a two-bar glyph.
- Fixed: the hands-free hint overran the bubble edge; shortened to "Tap Right ⌥ again to stop".
- Fixed: a two-line switch help clipped in its row (key invalid); shortened.
- Fixed: the switched-off Cleanup frame said "Key accepted · cleanup on"; now "Key accepted".
- Fixed: the duplicate-word sample was not a real duplicate; now "Cerebras" twice.
- Fixed: the first-run key description was cut off by the section header's single line; shortened.
- Fixed: a VoiceOver note misquoted the status row; corrected.
- Applied from `components`: cleanup switch help now "Removes filler words and resolves self-corrections before pasting." (6 rows); status line list gap widened so focus rings are not covered.
- Kept, flagged: in Light the ivory Listening dot on white reads close to the hollow Mic warm ring (atoms' dot; the words differ).
- Kept, flagged: the first-run window is 540 pt, not 480.
- Nothing invents a control: sidebar, toggle, recorder, secure field, text area, list and buttons are the standard macOS controls in Glass colours; one filled button per window or pane.

## Accessibility check

Contrast: DESIGN.md's measured pairs cover most text (lowest Light 4.68:1 secondary on sidebar, lowest Dark 7.27:1). New pairs these screens add, computed against an approximate blurred desktop (Light #E8E6E4, Dark #231F27, so treat as estimates): red error text on raised panel 5.27:1 Light, 5.74:1 Dark; amber text on window 5.12:1 Light, 10.1:1 Dark; secondary text on raised panel 5.32:1 Light, 6.43:1 Dark. The 40% dimmed key group in the first-run check fails 4.5:1 on purpose (disabled controls are exempt) and carries no information that is not also said in the heading. Mint is used only as an icon fill (Light state/done is 4.11:1, never text).

Per screen:
- Recording pill: the pill takes no focus by design; every pill action has a keyboard path elsewhere (paste-last-transcript shortcut; popover status row and Permissions buttons for the fixes). VoiceOver: the panel is hidden and only the bubble is a button in the locked code; recommended announcements for every state change are in each frame (Listening, Cancelled, Pasted, Not pasted, Microphone or Accessibility access is off). Reduce Motion noted per state.
- Menu bar icon: reachable with Control-F8 and arrows; accessibility label per state; shape alone carries state (template image).
- Popover: arrows, Return to paste again, Command-C, Command-comma, Command-Q, Escape; status row read first; each row exposes named actions "Paste again" and "Copy"; announcements for Copied, Pasted and permission changes. Targets: 266 × 68 pt rows, 28 pt buttons.
- Settings: Tab order through every control; Command-1 to Command-4 for panes (product default); recorder by Space or Return; the key is pasted, never typed; words added one per entry with Return; Delete and Command-Z; live permission change announced. Voice Control names: "Click Add a word or name", "Click Delete", "Click Open Accessibility Settings".
- First-run check: focus starts on the first button; each change announced; Done is the default button; no long typing.

Not verified: no prototype or VoiceOver run; behaviour is specified in notes and drawn as static states. Contrast of the blurred shell depends on the real wallpaper.

## Open questions for Alec

1. Hands-free hint in the bubble above (pill option B): if wanted, how long it stays (no timing exists).
2. Fallback: quiet (reason on the popover row, recommended) or not shown at all.
3. Field errors red (default per orchestrator) or amber: refused key in the recorder, invalid Cerebras key, duplicate word.
4. "No key": amber nudge (drawn) or neutral like "Cleanup off by choice", in the popover, the status line and the menu bar icon. Related: should cleanup off show in the menu bar at all? My lean: only for key invalid and offline.
5. History row: click pastes again (B, recommended) or buttons on hover (A). Risk with B: a click to read a row pastes it.
6. After Accessibility comes back, should the lock bubble become the paste-failed bubble so the waiting text pastes in one click? Lean: yes; it reuses the approved paste-failed state, so the text is one click away with no new look.
7. Pill look for a key press before the speech model is ready (product open question 9); not drawn, not in AA-306's pill list. Lean: the approved processing line until the model has loaded (seconds), plus a VoiceOver "Speech model loading"; it says "working" without a new look.
8. Tap versus hold: help lines (recommended) or the picture, and should the picture appear once in the first-run key step? Lean: no picture in first run either; one wording everywhere, and the picture adds a group's height for two sentences.
9. First-run layout: one window (A, recommended) or two steps (B). Window width 540 pt instead of product's 480 pt default.
10. After first run, should the popover open once to show where Fluidity lives? Drawn: nothing (no tour).
11. How long the word list's Undo line stays. Drawn: until he leaves the pane.
12. Mic warm: is the hollow ring enough, given the Light ivory Listening dot reads close to it on white? Lean: keep the ring; the words carry the state, and the fix belongs on the Light Listening dot (atoms), not on mic warm.
13. The Motion collection has no value for the lit top edge going from resting to live; drawn as an instant switch. Lean: use the existing 130 ms snap (duration/snap), the same as the pill's state switches; no new timing.
14. Reduce Motion: the pill's bubbles fade over 0.2 s in code (RimBubble.swift); the app's cross-fade is 130 ms. Both kept as they are.
15. Wording: macOS title case on buttons ("Open Accessibility Settings") versus the code's bubble label "Open Accessibility settings"; recommend the code follow the button.
16. Code change implied by the recommended permission defaults: the lock bubble must also show for a permission never granted, not only after a revoke.

## Team messages

Received:
- From `components` (draft list): Settings row 2048:1602, Permission row 2048:2540, Popover empty history 2048:3199, Status icon 2048:1483 built; coming: popover status row, history row (two options), sidebar status line, shortcut row with tap-versus-hold help (two options), cleanup key row, rules area, privacy line, word list (two layouts), secure field row. No separate first-run step row.

- From the orchestrator: an invalid key is a field error, so red (state/destructive) by default, with amber as the alternative and an open question for Alec; offline and no key stay amber. Atoms is finished; its section 2044:238 moved to x -1600. Applied to the Cleanup and popover plan above; nothing built so far used red or amber for a key.

- From `components` (build done): every component and variant ID (status row 2049:1900, history rows 2050:2012 and 2052:2373, footer row 2051:2508, sidebar status line 2053:2455, shortcut row 2054:2569, tap and hold picture 2055:2658, cleanup key row 2056:2880 and rules 2056:2918, word parts 2057:3181, 2057:3182, 2057:3193 and compositions 2058:3164, 2059:3350, permission row 2048:2540, speech model row 2059:4210); shells are mine.
- From `components` (reply to my findings): Mic warm status line now "Mic kept ready"; focus ring covered by neighbouring rows, fix with a gap (applied); cleanup switch help reworded (applied to my 6 rows).

- From the orchestrator: the independent review (review.md) with ten fixes; all applied and checked.
- From `components`: added Sidebar status line Status=No dictation key 2085:9691 ("No dictation key"; the longer wording wrapped).

Sent:
- To `components`: asked for a "no dictation key" status line variant (for the recorder idle frame).
- To `components` (after the build): three findings: the Mic warm status line read "Ready"; a focus ring looked clipped; the cleanup switch help wording. Plus a note that the Light ivory Listening dot reads close to the Mic warm ring.
- To `components`: the exact states I compose from (popover status row in ten statuses, history row states and marks, footer rows, sidebar status line in four, shortcut row including Rejected and a paste-last-transcript row, word list states with the +/− bar and an undo line, Permission row Checking, a speech model download row with a progress bar), and that I build the window and popover shells myself from bound frames unless it makes them components.
