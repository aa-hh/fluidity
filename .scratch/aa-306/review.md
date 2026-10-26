# AA-306 review: Discovery · version 1

Reviewer: independent, read-only. Date: 2026-10-26. Figma file 5JcAX6bwl48LqQhqcUuGOJ, page 2044:237.
Method: get_screenshot of the 29 frames listed below (PNGs in the review scratchpad), get_metadata of the whole discovery page and the four protected pages, and three read-only use_figma scripts (pill instance main components and overrides; unbound fills in 12 frames; bubble text fill comparison). Nothing in Figma was changed.

## 1. Defects

Frames checked by screenshot: popover 2065:3955, 2065:4133, 2065:4309, 2066:4424, 2066:4614, 2067:4998, 2067:5171, 2068:5252, 2068:5565; Settings 2071:5586, 2071:5795, 2072:5884, 2072:6600, 2073:6560, 2073:6781, 2075:6850, 2075:7608, 2077:7634, 2077:7781, 2078:7832, 2078:7977, 2079:8178, 2079:8541, 2079:8720, 2079:8899; first-run 2080:9306, 2080:9437, 2081:8923, 2081:9217.
In all 29: no overlap, no clipping, no missing or placeholder text, the Light pane is light and the Dark pane is dark, and every layer name carries 2026-10-25, what it tries and the status `open`. Only the defects below were found.

| Frame | Node ID | What is wrong | Severity |
|---|---|---|---|
| Settings · General · recorder idle | 2071:5586 | The sidebar status line reads "Ready · Right ⌥" in both panes, but the frame shows no dictation key set and its note says dictation cannot start. The status line contradicts the state it sits in. | medium |
| Settings · General · recorder recording | 2071:5795 | The recorder reads "Press a key…". DESIGN.md (Shortcut recorder, Recording), screens.md and this frame's own note all say "Type a shortcut…". | low |
| First-run check · A · recording the key | 2081:8923 | Same mismatch: drawn "Press a key…", note says "Type a shortcut…". | low |
| Settings · Cleanup · checking the key | 2073:6560 | The sidebar status line shows amber "No Cerebras key" while the key is being checked. The field says checking is neutral; the status line turns amber during a neutral wait. | low |
| Settings · Permissions · both granted | 2079:8178 | The VoiceOver note says "the button is labelled by its text", but this state has no buttons. Note copied from another frame. | low |
| Settings · Permissions · microphone denied | 2079:8720 | The VoiceOver note is copied from "one of each": its example reads "Microphone, allowed" and the announcement "Accessibility allowed", the opposite of this state. | low |
| Settings · Words · editing a word in place | 2077:7781 | The field shows "Kubernet" with a caret where Parakeet was; the note says the word is shown selected and VoiceOver says "Editing Kubernetes". The drawing, the note and the word list disagree on which word is being edited. | low |
| Settings · Words · empty list | 2078:7832 | The empty-state line ("Add names and terms Fluidity should get right. One word or name per row.") repeats the group subtitle directly above it almost word for word. | low |
| All 71 screen frames | 2048:1603 (section) | The date and status live only in the frame's layer name. The visible heading inside each frame (for example "Popover · Offline") has neither, so an exported image or a screenshot of a frame carries no date or status. | low |
| Dark panes with keyboard focus: recorder recording, Words adding and editing, popover footer focus, first-run recorder | 2071:5795, 2077:7634, 2077:7781, 2068:5565, 2081:8923 | The Dark focus ring is ivory (Glass token focus/ring Dark = rgba(255, 228, 184, 0.85)) on screens where the mic is not live, which runs against the brief's "ivory only where the mic is live". The token predates this build; flag for Alec, not a build error. | low |

## 2. Coverage against AA-306

| AA-306 item | Frame(s) | Result |
|---|---|---|
| Pill: hands-free versus hold | 2048:1605 (A, recommended), 2048:1675 (B) | covered |
| Pill: cancelled with Escape | 2048:2097 | covered |
| Pill: waiting for cleanup, up to about 1 s | 2048:2161 | covered |
| Pill: fallback, quiet or not shown | 2048:2289 (A), 2048:2387 (B, recommended) | covered |
| Pill: nowhere to paste | 2048:2541 (A, recommended), 2048:2665 (B) | covered |
| Pill: permission missing at the moment of dictating | 2048:2731 (Microphone), 2048:2807 (Accessibility) | covered |
| Menu bar: ready | 2048:3222 | covered |
| Menu bar: recording | 2048:3383 | covered |
| Menu bar: mic warm | 2048:3548 | covered |
| Menu bar: cleanup off or no key | 2048:3837 | covered |
| Menu bar: permission missing | 2048:4042 | covered |
| Popover: status row | every popover frame; statuses in 2064:3662, 2065:3777, 2065:3955, 2065:4133, 2065:4309, 2066:4235, 2066:4424, 2066:4614, 2066:4797, 2067:4742 | covered |
| Popover: last 20 or so dictations | 2064:3662 (five rows drawn, note and layer name say "last 20 or so, scrolls") | partly: no frame shows the list scrolled or its end |
| Popover: one click to copy or paste again | 2068:5120 (A), 2068:5252 (B, recommended), 2067:4998 (copied), 2067:5171 (pasted again), 2068:5410 (keyboard focus) | covered |
| Popover: app and time per row | every popover frame with history | covered |
| Popover: empty history | 2067:4921 | covered |
| Popover: Settings and Quit | 2068:5565, plus every popover frame | covered |
| General: shortcut recorder | 2071:5586 (idle), 2071:5795 (recording), 2070:5485 (set), 2071:6006 and 2072:5884 (refused) | covered |
| General: accepts a lone left or right Command or Option | 2070:5485 shows Right ⌥ only | partly: no Left key and no Command drawn on a screen (the Keycap atom 2048:709 covers side naming) |
| General: tap versus hold made clear | 2070:5485 (A, recommended), 2072:6130 (B) | covered |
| General: launch at login | 2071:5586 (off), 2070:5485 (on) | covered |
| Cleanup: on/off switch | 2073:6781, 2075:7379 | covered |
| Cleanup: Cerebras key field (Keychain) | 2073:6374, 2073:6560, 2073:6781 | covered |
| Cleanup: rules with restore default | 2075:7608, 2075:7819 | covered |
| Cleanup: Cerebras US servers line | every Cleanup frame | covered |
| Cleanup: no key | 2073:6374 | covered |
| Cleanup: key invalid | 2073:7008 (red, default), 2075:6850 (amber) | covered |
| Cleanup: offline | 2075:7116 | covered |
| Words: add, edit, delete | 2077:7634, 2077:7781, 2078:7977, 2077:7968 (duplicate) | covered |
| Words: without long typing or precise pointing | 2078:8131 (keyboard only), 2077:7482 (B), 2078:8362 (A) | covered |
| Permissions: Microphone and Accessibility, live state, button to System Settings | 2079:8178, 2079:8353, 2079:8541, 2079:8720, 2079:8899 | covered |
| Status line at the sidebar's foot | 2079:9071 (every status) | covered |
| First-run: bare check with live granted state | 2080:9163, 2080:9306, 2080:9437 | covered |
| First-run: then the shortcut | 2081:8923, 2081:9046, 2081:9318 | covered |
| First-run: no tour | 2081:9182 | covered |
| Light and dark for every screen | all 71 screen frames have a Light and a Dark pane (checked in metadata) | covered |
| A recommendation for every question | see gaps below | partly |

Questions with no recommendation (screens.md "Open questions" and frame notes):
- Q6: should the lock bubble become the paste-failed bubble once Accessibility comes back? No lean given.
- Q7: pill look for a key press before the speech model is ready. Not drawn, no lean (outside AA-306's pill list, so optional).
- Q8, second half: should the tap and hold picture appear in the first-run key step? "Left as Alec's call".
- Q12: is the hollow ring enough for mic warm? No lean.
- Q13: timing for the lit top edge going from resting to live. No lean (drawn as an instant switch, which is a default but not stated as the recommendation).

## 3. Pill lock

- All 56 pill instances on the discovery page are in section 2048:1604, and every one is an instance of a variant of component set 27:82 whose main component is on page 27:2. No pill appears anywhere else on the page.
- No instance has an effect, stroke, changed opacity or rotation. Sizes are the component's own (52 at 260 × 72, 4 at 260 × 107).
- Overrides: the layer name on all 56; text content of the bubble text (2015:183) on 2048:1687 and 2048:1729 (hands-free B hint). The fill override there uses the component's own settled-word colour (#F4EFE6 at 94%), so no new colour.
- Unbound colours in 12 spot-checked frames (2065:3955, 2066:4424, 2068:5565, 2071:5586, 2073:6781, 2075:6850, 2078:7977, 2079:8720, 2080:9437, 2081:9217, 2048:2541, 2048:3548): the white canvas frame, the Style Guide desktop gradients (#DCE6F2 to #F3E7DA, #1B2030 to #2A1F1E), the lit top edge (resting #FFF6EA, live in the four ivory tones, both as DESIGN.md specifies), macOS window controls (#FF5F57, #FEBC2E, #28C840 with a 12% black outline; inactive #999999 at 35%), macOS's orange microphone dot #FF9F0A, and the mock app shapes in the pill frames. Every text and app shape colour is bound to a Glass role. No new colour.
- Timings in note text: 0.2 s, 1 s, 120, 130, 150, 260 ms and 3 minutes, all from the brief or the locked code. Springs mentioned: "the approved collapse spring" and "the size spring". No new timing or spring.

## 4. Protected pages (direct children)

No child on these pages is named with "2026-10-25" or "Discovery".

- Tokens 2008:402: section 2021:1103 "Colour"; section 2021:1105 "Type".
- Atoms 2007:400: section 2021:1107 "Atoms" (holds frames 2021:1677 "Atoms · Light" and 2021:1678 "Atoms · Dark").
- Style Guide 2008:403: section 2021:1101 "Direction"; section 2021:1109 "Screens".
- Recording pill: Rim (approved) 27:2: 27:82 "Pill rim" (the component set, 30 variants); frame 28:2 "Rim spec".
- File pages: 2008:403 Style Guide, 2008:402 Tokens, 2007:400 Atoms, 27:2 Recording pill: Rim (approved), 2044:237 Discovery · version 1.
