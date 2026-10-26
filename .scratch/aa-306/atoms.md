# AA-306 atoms: tokens and atoms audit, and the atoms version 1 still needs

Owner: `atoms`. Date: 2026-10-25. Figma file 5JcAX6bwl48LqQhqcUuGOJ.
Sources checked: Fluidity DESIGN.md, .impeccable/design.json, .impeccable/surfaces/app.md, PRODUCT.md, CONTEXT.md; FluidWispr RimParameters.swift, RimSimulation.swift, RimSpring.swift, RecordingPillController.swift, MenuBarGlyph.swift; Figma pages Tokens (2008:402), Atoms (2007:400), Style Guide (2008:403), "Recording pill: Rim (approved)" (27:2), read through get_metadata, get_screenshot and the Plugin API (read only).

## Tokens that exist

The file has six variable collections. There is no collection called "Color Light/Dark": the Glass colours live in "Glass · Color", and the older colour collection is named "Color (superseded by Glass)".

### Colour roles: "Glass · Color" (VariableCollectionId:2021:704), modes Light and Dark

| Variable | Light | Dark | Matches DESIGN.md | Matches pill code |
|---|---|---|---|---|
| surface/window | #FFFFFF at 72% | #0E0F13 at 72% | yes | Dark base is pill body #0E0F13, yes |
| surface/sidebar | #FFFFFF at 40% | #0A0B0E at 50% | yes | not a pill value |
| surface/raised | #FFFFFF at 85% | #FFFFFF at 6% | yes | not a pill value |
| surface/selected | #141519 at 8% | #FFFFFF at 12% | yes | not a pill value |
| surface/hover | #141519 at 4% | #FFFFFF at 6% | yes | not a pill value |
| line/rule | #141519 at 10% | #FFFFFF at 10% | yes | not a pill value |
| line/strong | #141519 at 22% | #FFFFFF at 22% | yes | not a pill value |
| text/primary | #1C1C1E | #F4EFE6 | yes | Dark = pill words ivory #F4EFE6, yes |
| text/secondary | #6F6A62 | #A8A49C | yes | not a pill value |
| action/primary | #1C1C1E | #FFF6EA | yes | Dark = ivory white #FFF6EA, yes |
| action/on-primary | #FFFFFF | #0E0F13 | yes | Dark = pill body, yes |
| state/done | #1A8A52 | #3EDC8A | yes | Dark = pasted mint, yes |
| state/attention | #9A5B00 | #FFB020 | yes | Dark = problem amber, yes |
| state/retry | #B5531B | #FF9A5C | yes | Dark = retry failed orange, yes |
| state/destructive | #C83230 | #FF6B66 | yes | not a pill colour (allowed: red only for deleting) |
| live | #FFE4B8 | #FFE4B8 | yes | ivory warm, yes |
| control/knob | #FFFFFF | #D9D4CB | yes | not a pill value |
| focus/ring | #1C1C1E at 60% | #FFE4B8 at 85% | yes | Dark uses ivory warm, yes |

The Tokens page (2008:402) lists exactly these 18 roles with the same values.

### Colour roles: "Color (superseded by Glass)" (VariableCollectionId:43:2), modes Light and Dark

27 variables from the earlier direction, still in the file: surface/window, surface/sidebar, surface/selected, surface/hover, surface/sunken, surface/raised, line/rule, line/margin, line/strong, line/spoken, text/primary, text/secondary, text/tertiary, ink, action/primary, action/on-primary, state/done (#11804A / #5BE39B), state/attention (#975A00 / #FFC24D), state/retry (#B4531B / #FF9A5C), state/destructive (#C8322F / #FF6B66), live/ivory (#FFE4B8 both), pill/body (#0E0F13 both). Not used by the Glass atoms I checked (every solid fill on the Atoms page binds to "Glass · Color").

### Dimensions: "Dimension" (VariableCollectionId:43:25), one mode "Value"

space/1 2, space/2 4, space/3 8, space/4 12, space/5 16, space/6 20, space/7 24, space/8 32, space/9 40, space/10 56; size/control-s 20, size/control-m 28, size/control-l 36 (the three pill heights, matches RimParameters Small/Medium/Large); size/row-min 44; size/sidebar 184; size/margin 168; size/rule-gap 2; size/icon-s 13, size/icon-m 15, size/icon-l 17; radius/capsule 999; radius/container 14; radius/inner 8; radius/window 16; line/hairline 1; line/focus 2; line/spoken-scale 5.

### Motion: "Motion" (VariableCollectionId:43:53), one mode "Value"

duration/snap 130, duration/exit 150, duration/enter 180, duration/hold 260, duration/collapse 340, duration/reduce-crossfade 130 (ms); spring/size 0.816 / 0.512 s; spring/collapse 0.816 / 0.45 s; spring/layout 0.78 / 0.4 s; spring/recombine 0.6 / 0.222 s; spring/split 0.141 / 0.222 s with 130 ms head start. All match RimParameters.swift and RimSpring.swift.

### Type: "Type" (VariableCollectionId:43:64), one mode "Value"

font/family "SF Pro"; size/title 22, size/section 15, size/transcript 15, size/body 13, size/label 13, size/detail 12, size/detail-strong 12, size/small 11, size/small-strong 11.

### Text styles

Glass (the ones version 1 uses): Glass/Title SF Pro Rounded Semibold 22/28; Glass/Section SF Pro Rounded Medium 15/20; Glass/Label SF Pro Rounded Medium 13/16; Glass/Body SF Pro Regular 13/18; Glass/Transcript SF Pro Regular 13/17; Glass/Detail SF Pro Regular 12/16; Glass/Small SF Pro Regular 11/14. All match DESIGN.md.
Older: Record/Title, Record/Section, Record/Transcript (15/24), Record/Body, Record/Label, Record/Detail, Record/Detail strong, Record/Small, Record/Small strong, all SF Pro. These belong to FluidWispr's window direction, which the brief says is not a reference.

### Rim: "Rim" (VariableCollectionId:27:3), one mode "Approved"

52 variables. Every value matches RimParameters.swift: rim/width 1.2, rim/width-gain 0.95, rim/glow-reach 2.6, rim/glow-strength 1, rim/intensity 1.4, rim/contrast-quiet 0.16, rim/contrast-speaking 1, rim/light-quiet 0.26, rim/light-loud 0.53, rim/band-lift 1.2, rim/slide-idle 0.1, rim/slide-speaking 0.5, rim/bloom 1.1, rim/bloom-decay 250 ms, rim/bloom-width 0.03, rim/bloom-spread 1.3, rim/hue-shift 0.3, rim/hue-cycles 3, rim/tilt 0, rim/attack 15 ms, rim/release 240 ms, rim/idle-activity 0.3, rim/idle-fps 31; line/length-ratio 0.5, line/width 1, line/glow 0.1, line/breath-depth 0, line/breath-period 1500, line/blooms 0; motion/download 150, motion/green-hold 260, motion/expand-back 130, motion/collapse 340, motion/appear 180; bubble/offset 6, bubble/max-width 300, bubble/max-lines 6, bubble/text-size 11, bubble/line-height 14.5, bubble/padding-x 10, bubble/padding-y 7, bubble/radius-max 14, bubble/ring 0.6, bubble/blob-radius 6.67, bubble/blob-radius-settled 3.33; words/batch-interval 600, words/word-gap 35, words/confirmed 0.94, words/pending 0.5, words/processing 0.6; waveform/window 1500, waveform/flatten 150, waveform/glow 3.

### Effects

Effect style Elevation/Float: drop shadow 0 8 24, black at 16%. Matches DESIGN.md.
Effects drawn on nodes without a style (values match DESIGN.md): toggle knob 0 1 2 black 22%; selected segment 0 1 2 black 12%; focus ring 2 pt spread bound to focus/ring; background blur 40 on the shell; popover listening dot glow 6 pt bound to live; live lit edge halo layer blur 4.
No paint styles exist.

### Mismatches and gaps (reported, not fixed)

1. Type collection size/transcript is 15; Glass/Transcript and DESIGN.md say 13 pt on a 17 pt line.
2. Type collection font/family is "SF Pro" only; Glass sets Title, Section and Label in SF Pro Rounded, which the collection cannot express. The collection also carries size/detail-strong and size/small-strong, which only the Record styles use.
3. Dimension size/icon-s 13, size/icon-m 15, size/icon-l 17; every Glass icon on the Atoms page is 16 × 16 and DESIGN.md names 16 pt sidebar icons and a 16 pt chevron. The recorder's clear button uses a 12 pt Icon/Close. No variable holds 16.
4. Dimension radius/container is described "Sheets, popovers"; DESIGN.md gives the popover 16 pt (radius/window) and keeps 14 pt for raised panels and an open pop-up menu.
5. Dimension size/margin 168, size/rule-gap 2, line/spoken-scale 5 and the "record line" wording on size/row-min come from FluidWispr's window direction, which the brief rules out.
6. The lit top edge has no variables: its resting gradient (#FFF6EA, transparent at both ends) and the live four-tone gradient (#FFE4B8 #FFF6EA #FFCFA0 #FFEBD2) are typed into the gradient stops. The values match the pill. "Glass · Color" also has no pill body and no ivory white variable of its own (action/primary Dark happens to be #FFF6EA).
7. Red for errors. The brief says red is only for deleting. DESIGN.md says "Destructive red marks field errors", and the Atoms page Text field State=Error (2021:2274) uses state/destructive for "Key not recognised". These two rules disagree. Open question 1.
8. Motion collection gaps against RimParameters.swift and the brief: hide 120 ms, fail flash 600 ms, shortcut flash 320 ms, press bump spring 0.694 / 0.85 s (scale 1.015 × 1.03), shake 8 island pt. RimSpring.swift also has a shake spring (0.35, 0.18) that neither the brief nor DESIGN.md mentions, and the pill page describes a drag spring (0.456, 0.35 s) that the brief does not list. None of these are in Figma as variables.
9. Reduce Motion: the brief says a 130 ms cross-fade (matches duration/reduce-crossfade); DESIGN.md's pill section and design.json's reduce-motion-fade say bubbles fade over 0.2 s. I did not find the value in the pill code.
10. design.json's pill sample CSS sets the newest words at 53% opacity; DESIGN.md and words/pending say 50%.
11. Stale for version 1 (DESIGN.md says so itself): six panes, the status line "Ready · ⌥ Space", the popover's model line. The Atoms page text field placeholder says "Paste your OpenAI API key" and its error says "Copy it again from OpenAI"; version 1 cleanup uses Cerebras. The Tokens page sample says "Whisper Large v3 Turbo · 1.6 GB" and "Hold ⌥ Space".
12. The approved pill page's "Pill always on" row says "Mint fades back to ivory". That is the always-on pill mode, not the default, but it reads against "switch never fade". Not mine to change; noted.

## Atoms that exist

Atoms page (2007:400), one section "Atoms" (2021:1107) with two panes: "Atoms · Light" (2021:1677, Glass · Color mode Light) holding the components, and "Atoms · Dark" (2021:1678, mode Dark) holding instances.

| Component | Node | Variants | Version 1? |
|---|---|---|---|
| Icon/General | 2021:1682 | one, 16 × 16, 1.4 pt stroke bound to text/primary | yes (General pane) |
| Icon/Dictation | 2021:1687 | one (a microphone) | version 2 only as a sidebar icon (no Dictation pane in version 1); reusable as the microphone glyph for the Microphone permission row |
| Icon/Models | 2021:1691 | one | version 2 only (no model library in version 1) |
| Icon/Cleanup | 2021:1695 | one | yes |
| Icon/Words | 2021:1699 | one | yes |
| Icon/Permissions | 2021:1702 | one (a lock) | yes |
| Icon/Chevron up down | 2021:1706 | one | yes |
| Icon/Check | 2021:1709 | one | yes |
| Icon/Info | 2021:1712 | one | yes |
| Icon/Close | 2021:1717 | one | yes |
| Button | 2021:1941 | Kind Primary, Secondary, Quiet × State Default, Hover, Pressed, Disabled; Label text property | yes as is |
| Toggle | 2021:2254 | Value On, Off × State Enabled, Disabled | yes as is |
| Text field | 2021:2280 | State Default, Focused, Error | yes; sample copy names OpenAI; needs version 1 key states (see below) |
| Pop-up button | 2021:2553 | State Default, Open; Value text property | yes as is |
| Segmented control | 2021:2607 | Selected Small, Medium, Large | yes as is (labels are instance text) |
| Sidebar item | 2021:3242 | State Default, Hover, Selected; Label text, Icon swap | yes as is |
| Section header | 2021:3267 | one | yes as is |
| Shortcut recorder | 2021:3295 | State Idle, Recording, Set (shows ⌥ and Space keycaps) | needs version 1 variants: a single key on its own, and copy for one key |
| Status row | 2021:3550 | State Done, Attention, Retry | yes; needs a neutral variant for notes such as the Cerebras line or cleanup off |
| Focus ring | 2021:3597 | Target Button, Toggle, Segmented control | yes as is |
| Menu bar popover | 2021:5417 | Status Ready, Listening (with the model line and one "Last dictation") | version 2 shape; version 1 needs a popover without the model line and with the history list (owned by `components` and `screens`) |

Things that exist only inside other components, not as components of their own: the keycap (inside Shortcut recorder Set), the status dot (inside Menu bar popover), the lit top edge rectangles, the settings row with a toggle (inside the Style Guide screens). The Style Guide's context frame (2021:5543) draws a microphone in the menu bar; there is no menu bar icon component.

## Atoms version 1 needs

Reconciled with `product`'s state inventory (product.md, "Visual elements the Glass atoms do not have"). Split agreed with `components`: I build single controls; `components` builds every composed row and list from them. Every new atom binds its colours to "Glass · Color", its text to the Glass text styles, and its heights to 20, 28 or 36 pt (or 18 pt for the keycap and clear button, as the existing recorder does).


Page "Discovery · version 1" is 2044:237 (last page). Section "Atoms" is 2044:238, at x = -1600 so it clears the Screens section. Each exploration frame holds a Light pane (Glass · Color mode Light, holding the component set) and a Dark pane (mode Dark, holding instances). Pane backgrounds are copied from the Atoms page panes.

| Needed for version 1 | Status | What I built or what to use (node) | Glass tokens | Pill rule it borrows |
|---|---|---|---|---|
| Menu bar icon, 18 × 18 template image, five states | missing, built three designs | A: Menu bar icon/Pill outline 2045:344 (recommended), frame 2045:312. B: Menu bar icon/Microphone 2045:1007, frame 2045:958. C: Menu bar icon/Dot and pill 2046:581, frame 2046:557. State = Ready, Recording, Mic warm, Cleanup off, Permission missing | text/primary (stands in for the template tint) | the pill's own shape (A); colour is for state, so a template image carries state by shape alone |
| Status dot | exists only as a layer inside Menu bar popover; built | Status dot 2048:655, frame 2048:638. State = Ready, Listening, Mic warm, Cleaning up, Attention | text/secondary, live, line/strong, text/primary, state/attention; glow bound to live | ivory means live (only Listening); switch never fade |
| Keycap that names the side | exists only as a layer inside Shortcut recorder; built | Keycap 2048:1185 (one component, text property Label#2048:3), frame 2048:709 | surface/selected, text/primary, radius/inner | 18 pt, as the existing layer |
| Shortcut recorder, one key on its own and a refused key | exists but needs variants; built | Shortcut recorder (version 1) 2048:3134, frame 2048:3098. State = Recording, Set (one key), Not allowed | surface/raised, line/rule, line/strong, state/attention, focus/ring | 28 pt height; lit top edge on focus |
| Tap versus hold explanation | missing | `components` (recorder row with help), from Keycap and Glass/Detail | | |
| History row copy and paste-again affordance | missing; built the control, `components` builds the row | Icon button 2048:1276 (Kind = Quiet, Destructive; State = Default, Hover, Pressed, Focused, Disabled), frame 2048:1203, with Icon/Copy 2044:249 and Icon/Paste 2044:258 | surface/hover, surface/selected, focus/ring, text/primary, state/destructive | 28 pt; red only for deleting |
| Word-list row (editable, deletable, keyboard) | missing; `components` builds the row | parts: Icon button Kind=Destructive with Icon/Trash 2044:284; Icon/Plus 2044:267 and Icon/Minus 2044:274 for an add/remove bar; Text field 2021:2280 Focused for editing; Inline note Attention for a duplicate | | red only for deleting |
| Permission status with button | exists (Status row Done and Attention 2021:3550, Button Secondary); `components` composes the row | Icon/Accessibility 2044:299 is new; Icon/Dictation 2021:1687 serves Microphone | state/done, state/attention | colour is for state; the live change from Attention to Done snaps |
| Neutral status (offline, no key, cleaning up) | exists but needs a variant; built | Status row (version 1) 2048:3178, State=Info 2048:3171, frame 2048:3165 | text/secondary, action/on-primary | a screen at rest is neutral |
| Text field key states, secure field for the API key | exists but needs variants; built as one control | Secure field 2048:1983, frame 2048:1900. State = Empty, Focused, Checking, Accepted, Not accepted, Offline, Shown. Uses Icon button with Icon/Eye 2047:619 and Icon/Eye slash 2047:624 | surface/raised, line/rule, line/strong, state/attention, state/done (icon only), focus/ring | 28 pt; amber not red for "not accepted" (open question 1) |
| Message under a field or at a group's foot (privacy line, checking, offline) | missing; built | Inline note 2048:1372, frame 2048:1346. Tone = Neutral, Done, Attention | text/secondary, state/done (icon only), state/attention | colour is for state |
| Multi-line text area for cleanup rules | missing; built | Text area 2048:2090, frame 2048:2078. State = Default, Focused | surface/raised, line/rule, line/strong, focus/ring, radius/inner | 8 pt corners instead of a capsule (open question 3) |
| "Restore default" quiet button | exists as is | Button 2021:1941 Kind=Quiet (Disabled when the rules are at default), Label "Restore Default" | | |
| Launch-at-login toggle row | Toggle exists as is; the row is `components`' | Toggle 2021:2254 | | |
| Empty state (history, word list) | missing; `components` builds it | parts: Glass/Label, Glass/Detail, Keycap | | |
| Sidebar status line | missing; `components` builds it | parts: Status dot 2048:655, Keycap, Glass/Small | | ivory means live |
| Popover status row variants | partly exists (inside Menu bar popover); `components` builds it | parts: Status dot, Glass/Label, Glass/Small | | |
| Sidebar icons | exist as is for General, Cleanup, Words, Permissions | Icon/General, Icon/Cleanup, Icon/Words, Icon/Permissions | | |
| Icons version 2 only | Icon/Models 2021:1691; Icon/Dictation 2021:1687 as a sidebar icon | | | |

New icons, all 16 × 16 with a 1.4 pt round stroke on text/primary, in frame 2044:239: Icon/Copy 2044:249, Icon/Paste 2044:258, Icon/Plus 2044:267, Icon/Minus 2044:274, Icon/Trash 2044:284, Icon/Accessibility 2044:299, Icon/Eye 2047:619, Icon/Eye slash 2047:624.

Variant node IDs:
- Menu bar icon/Pill outline: Ready 2045:319, Recording 2045:323, Mic warm 2045:325, Cleanup off 2045:330, Permission missing 2045:337.
- Menu bar icon/Microphone: Ready 2045:965, Recording 2045:970, Mic warm 2045:975, Cleanup off 2045:981, Permission missing 2045:994.
- Menu bar icon/Dot and pill: Ready 2046:564, Recording 2046:567, Mic warm 2046:570, Cleanup off 2046:573, Permission missing 2046:577.
- Status dot: Ready 2048:645, Listening 2048:647, Mic warm 2048:649, Cleaning up 2048:651, Attention 2048:653.
- Icon button: Quiet Default 2048:1211, Hover 2048:1216, Pressed 2048:1221, Focused 2048:1226, Disabled 2048:1231; Destructive Default 2048:1236, Hover 2048:1244, Pressed 2048:1252, Focused 2048:1260, Disabled 2048:1268.
- Inline note: Neutral 2048:1353, Done 2048:1360, Attention 2048:1365.
- Secure field: Empty 2048:1907, Focused 2048:1910, Checking 2048:1914, Accepted 2048:1929, Not accepted 2048:1945, Offline 2048:1960, Shown 2048:1975.
- Text area: Default 2048:2085, Focused 2048:2087.
- Shortcut recorder (version 1): Recording 2048:3105, Set (one key) 2048:3109, Not allowed 2048:3118 (amber), Not allowed (red) 2051:1974.
- Red variants added after the orchestrator set red (state/destructive) as the default for field errors, matching Text field State=Error 2021:2274; the amber ones stay as the alternative: Secure field State=Not accepted (red) 2051:1952, Shortcut recorder State=Not allowed (red) 2051:1974, Inline note Tone=Error 2051:1945.

Menu bar icon recommendation: A, the pill outline. It is the pill itself, it already exists in FluidWispr code (Ready, Recording and Permission missing are MenuBarGlyph.swift geometry exactly), and filled versus outline is the macOS idiom for on versus off. B, a microphone, would be one microphone among several next to macOS's own orange microphone dot. C reads Mic warm best but both halves are tiny at 18 pt.

Not verified: how the template images look in the real menu bar (tinting, Retina versus non-Retina, a coloured desktop behind a translucent menu bar). The Figma strips use surface/window and text/primary as stand-ins.

## Open questions for Alec

1. Red for a key Cerebras refuses or a refused shortcut: the brief says red only for deleting; DESIGN.md and the existing Text field State=Error use red for field errors. The orchestrator set red as the default; both are drawn (red: Not accepted (red), Not allowed (red), Inline note Error; amber: Not accepted, Not allowed, Inline note Attention). Which rule wins?
2. Mic warm: is the warm mic "live" (ivory) or not? Default drawn: not live, so no ivory anywhere (Status dot open ring, menu bar inner bar). macOS already shows its orange dot then, so the menu bar may not need a Mic warm shape at all.
3. Text area corners: DESIGN.md says every control is a capsule, which a multi-line box cannot be. Default drawn: radius/inner 8 pt.
4. Cleanup off in the menu bar: dictation still works and pastes the raw transcript. Should the menu bar icon change for it at all, or only the popover and sidebar status line?
5. Menu bar icon: A (pill outline, recommended), B (microphone) or C (dot and pill)?
6. Template image or not: a template image cannot show ivory while recording. Keep it a template (default), or allow a non-template ivory icon while the mic is live?
7. The Type collection disagrees with Glass (transcript 15 versus 13; no SF Pro Rounded). Fix the collection, or retire it with the Record styles?
8. Dimension icon sizes are 13/15/17 but every Glass icon is 16 (and the recorder's clear icon 12). Add a 16 pt variable?
9. The lit top edge and the pill body have no Glass variables (gradient stops are typed in). Add them?
10. The pill timings missing from Figma (hide 120 ms, fail flash 600 ms, shortcut flash 320 ms, press bump spring 0.694 / 0.85 s, shake spring 0.35 / 0.18 s, drag spring 0.456 / 0.35 s): add them to Motion or Rim?
11. Reduce Motion for bubbles: 130 ms cross-fade (brief, Motion collection) or 0.2 s fade (DESIGN.md pill section, design.json)?

## Team messages

- Sent to `components` (first attempt failed: not running yet). Retried after their message.
- Received from `product`: state inventory in product.md; twelve elements the Glass atoms lack; code facts (the pill has no fallback look; the lock bubble only follows a revoke; the pill panel is hidden from VoiceOver except the waiting bubble).
- Sent to `product`: acknowledged; asked whether the warm mic counts as live. Default: not live.
- Received from `product`: open question for Alec; sources only say the mic stays open and audio is picked up a moment before the key press; use the default (not live). Added as product's open question 19.
- Received from `components`: proposed split (they build composed rows and lists; I build single controls) and asked for set IDs, variant names and property keys.
- Sent to `components`: split accepted; list of what I would build; heads-up that "not accepted" is amber.
- Sent to `components`: every node ID, variant property and value, property keys (Keycap Label#2048:3; no swap property on Icon button), and two Figma gotchas (spread focus ring needs clip content; use_figma's inline screenshot can be stale).
- Received from `components`: the orchestrator's correction makes red the default for field errors; asked for red variants of Secure field and Shortcut recorder, keeping amber.
- Sent to `components`: Secure field Not accepted (red) 2051:1952, Shortcut recorder Not allowed (red) 2051:1974, Inline note Tone=Error 2051:1945.
