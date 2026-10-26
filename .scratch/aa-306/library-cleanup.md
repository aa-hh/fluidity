# Library clean-up log (AA-306)

Figma file 5JcAX6bwl48LqQhqcUuGOJ ("Fluidity -- Design Library"). Date: 2026-10-26.

## Before

Saved before any change:
- get_metadata of the approved pill page 27:2: `/private/tmp/claude-501/-Users-alechenderson-Projects-Fluidity--claude-worktrees-design-discovery-v1-screens-842bfb/eea079bf-f190-4547-9b1f-a8c565dc1090/scratchpad/cleanup/pill-27-2-before.xml` (36,895 bytes).
- A fingerprint of every node on 27:2 (type, name, position, size, fills, strokes, effects, style IDs, bound variables, text segments, main component of each instance): 689 nodes, hashes adb53e1c and 2e20a01d over 799,572 characters.
- What 27:2 uses outside the Rim collection: Type size/small and Dimension radius/container. It uses no variable from "Color (superseded by Glass)", no text style, no paint style.

Variable collections:
| Collection | ID | Modes | Variables |
|---|---|---|---|
| Rim | VariableCollectionId:27:3 | Approved | 53 |
| Color (superseded by Glass) | VariableCollectionId:43:2 | Light, Dark | 22 |
| Dimension | VariableCollectionId:43:25 | Value | 27 |
| Motion | VariableCollectionId:43:53 | Value | 17 |
| Type | VariableCollectionId:43:64 | Value | 10 |
| Glass · Color | VariableCollectionId:2021:704 | Light, Dark | 18 |

(atoms.md said 27 old colour variables and 52 Rim variables; the file has 22 and 53.)

Text styles (16): Record/Title, Record/Section, Record/Transcript, Record/Body, Record/Label, Record/Detail, Record/Detail strong, Record/Small, Record/Small strong; Glass/Title, Glass/Section, Glass/Label, Glass/Body, Glass/Transcript, Glass/Detail, Glass/Small. No text style binds a variable.
Effect styles (1): Elevation/Float. Paint styles: none.

Type collection before: font/family "SF Pro"; size/title 22, size/section 15, size/transcript 15, size/body 13, size/label 13, size/detail 12, size/detail-strong 12, size/small 11, size/small-strong 11.

## 1. Usage audit

Walked every node on each page (including layers inside instances), reading bound variables on the node, its fills, strokes and effects, and each text run's style and bindings.

| Candidate | Style Guide | Tokens | Atoms | Pill page 27:2 | Discovery |
|---|---|---|---|---|---|
| Any of the 22 "Color (superseded by Glass)" variables | 0 | 0 | 0 | 0 | 0 |
| Any Record text style | 0 | 0 | 0 | 0 | 0 |
| size/margin, size/rule-gap, line/spoken-scale | 0 | 0 | 0 | 0 | 0 |
| Type variables | 0 | 0 | 0 | size/small on 1 node | size/small on 4 layers, all inside pill instances |
| Icon/Models instances | 5 inside instances (2 sidebar items, 3 popovers) | 0 | 3 (2 popover model lines, 1 icon row) + 2 inside popover instances | 0 | 0 |
| Icon/Dictation instances | 1 (menu bar glyph 2021:5554) + 2 inside sidebar items | 0 | 1 (icon row) | 0 | 0 |
| Six-pane sidebar | 2 (Settings Light 2021:4482, Dark 2021:5117) | 0 | 0 | 0 | 0 (all 62 sidebars there already show four panes) |
| Popover model line | 3 popover instances (2021:5478, 2021:5308, 2021:5559) | 0 | 2 components (2021:5278, 2021:5385) + 2 instances | 0 | 0 (Discovery instances no popover atom) |

No other variable aliases any of these, and no text or effect style binds a variable.
Nothing to skip for the pill page: it uses none of the candidates. (It uses Type size/small and Dimension radius/container, which stay.)

## 2. FluidWispr leftovers

Rebound: none needed (0 users on every page). Re-checked all five pages just before deleting: still 0.
Deleted, in order:
- Collection "Color (superseded by Glass)" with its 22 variables.
- 9 text styles: Record/Title, Section, Transcript, Body, Label, Detail, Detail strong, Small, Small strong.
- 3 Dimension variables: size/margin, size/rule-gap, line/spoken-scale.

Descriptions rewritten:
- size/row-min: "Minimum record line height" to "Minimum row height".
- spring/size-damping: "Layout changes, a new record line arriving" to "Size changes: the pill growing with words, shrinking after cleanup" (DESIGN.md wording).
- radius/container: "Sheets, popovers" to "Raised panels, an open pop-up menu" (atoms.md mismatch 4). Only the description changed; the value and every binding stay, including the one on the pill page.
- radius/window: "Window (system)" to "Window and popover" (same mismatch).
No description in the file mentions "record" now.

## 3. Type collection

The collection had one mode ("Value"), one string variable font/family and nine sizes; no line heights and no weights. No text style binds to it; the only bound variable is size/small (pill page and pill instances), which is unchanged.
- size/transcript: 15 to 13.
- Added font/family-rounded = "SF Pro Rounded" (font family scope), for Title, Section and Label. font/family ("SF Pro") now has the description "Body, Transcript, Detail and Small".
- Added seven line heights (line height scope) so the collection can state the 17 pt transcript line and matches all seven Glass styles: line-height/title 28, section 20, label 16, body 18, transcript 17, detail 16, small 14.
- Deleted size/detail-strong and size/small-strong (0 users). There were no weight variables.
- Glass text styles: unchanged. All seven already match DESIGN.md.

## 4. Version 2 atoms

Discovery instances neither icon, nor the popover, nor the six-pane sidebars, so nothing there needed relinking.

Style Guide (2008:403):
- Sidebars cut to General, Cleanup, Words, Permissions: removed "Sidebar item · Dictation" and "Sidebar item · Models" from Settings Light (2021:4499, 2021:4509) and Dark (2021:5124, 2021:5125). The spacer fills, so the status line stays at the foot.
- Sidebar status line "⌥ Space" to "Right ⌥" (2021:4552, 2021:5133), the discovery wording.
- Both "Dictation shortcut" recorders (2021:4952, 2021:5143): first keycap now reads "Right ⌥", the "Space" keycap is hidden. These are instance overrides; the Atoms recorder component still shows ⌥ and Space.
- Menu bar glyph 2021:5554 was the only remaining instance of Icon/Dictation. Detached it so the drawing stays (now frame 2093:9911, named "Microphone"). Swap it for the chosen menu bar icon once open question 5 is decided.
- Popover model lines and "Whisper Large v3 Turbo" disappear through the component change below. No text on the page names OpenAI.

Atoms (2007:400):
- Removed the "Model" row (icon, model name, model detail) from Menu bar popover Status=Ready (2021:5289) and Status=Listening (2021:5396). Both popovers now 206 pt tall, down from 260; the Style Guide's three popovers follow.
- Popover Ready hint "Hold ⌥ Space" to "Tap or hold Right ⌥" (2021:5283), the discovery popover wording, so the Style Guide popovers show it too.
- Removed the Icon/Dictation and Icon/Models instances from the "Icons · instances" row (2021:5651, 2021:5655).
- Deleted components Icon/Models (2021:1691) and Icon/Dictation (2021:1687) after a check on all five pages found 0 instances and no swap property using them.

Left alone (outside the step's list, reported): the Atoms Text field sample copy still says "Paste your OpenAI API key" and "Copy it again from OpenAI"; Discovery instances that component 30 times. The Atoms Shortcut recorder Set variant still shows ⌥ and Space.

## 5. Added variables and bindings

Added (13 variables), values checked against FluidWispr source (RimParameters.swift, RimSpring.swift, RimDrag.swift):
- Dimension: size/icon 16 ("Glass icons: sidebar, chevron, status glyphs"), size/icon-xs 12 (the recorder's clear-button glyph). Width and height scope. size/icon-s, -m, -l (13, 15, 17) stay.
- Glass · Color: line/lit-edge #FFF6EA in Light and Dark (ivory-white, the resting lit top edge); pill/body #0E0F13 in Light and Dark.
- Motion (no scopes and "seconds" on responses, like the existing ones): duration/hide 120 (hideTime 0.12), duration/fail-flash 600 (failFlash 0.6), duration/shortcut-flash 320 (shortcutFlash 0.32); spring/press-damping 0.694 and press-response 0.85 (pressDamping, pressResponse); spring/shake-damping 0.35 and shake-response 0.18 (RimSpring.shakeSpring); spring/drag-damping 0.456 and drag-response 0.35 (RimDrag.dragSpring).

Bound to line/lit-edge: every fully opaque #FFF6EA gradient stop on a layer outside an instance.
| Page | Layers changed | Stops bound | Transparent #FFF6EA stops left typed |
|---|---|---|---|
| Style Guide | 3 (2021:4554, 2021:5232, 2021:5233) | 7 | 2 |
| Atoms | 6 (2021:2273, 2021:2550, 2021:3282, 2021:5305, 2021:5413, 2021:5414) | 10 | 8 |
| Discovery | 123 | 155 | 214 |
Layers inside instances follow their main components (Style Guide 8 stops, Discovery 24 stops now bound through them).

Not bound, and why:
- The transparent end stops of the resting lit edge (#FFF6EA at 0%). Tested on a temporary rectangle: a bound stop takes the variable's own opacity, so binding them to line/lit-edge makes them fully opaque. Binding them would need a second variable at 0% opacity.
- The other three live-edge tones: #FFE4B8 matches the existing `live` variable but was not one of the new variables, so I left it typed; #FFCFA0 and #FFEBD2 have no variable.
- 12 #FFF6EA stops on "Processing line" layers inside instances of the approved pill's Processing: line component (27:61) on Discovery. Binding them means changing the pill page or adding instance overrides; left alone.
- pill/body: no typed #0E0F13 fill exists outside instances on the Style Guide, Atoms or Discovery pages. The pill body fills live in the pill page's components, which are not to be touched. pill/body has no users yet.

## 6. Verification

Screenshots, looked at one by one (saved in `/private/tmp/claude-501/-Users-alechenderson-Projects-Fluidity--claude-worktrees-design-discovery-v1-screens-842bfb/eea079bf-f190-4547-9b1f-a8c565dc1090/scratchpad/cleanup/shots/`): Tokens, Atoms, Style Guide pages; discovery frames 2070:5485 (Settings General), 2064:3662 (popover with history), 2080:9163 (first-run check), 2045:312 (menu bar icon A), 2050:1911 (history row). Every colour, font and icon still renders. The Style Guide shows four panes, "Right ⌥" in the status lines and recorders, popovers without the model line, and the menu bar microphone. The Atoms icon row now has eight icons.

Pill page 27:2:
- get_metadata after the changes is byte-for-byte identical to the copy saved before (both 36,895 bytes, SHA-1 5600f9ba690d7e7b3bee4b692a6b5cedd83e71ff). After copy: `/private/tmp/claude-501/-Users-alechenderson-Projects-Fluidity--claude-worktrees-design-discovery-v1-screens-842bfb/eea079bf-f190-4547-9b1f-a8c565dc1090/scratchpad/cleanup/pill-27-2-after.xml`.
- The deeper fingerprint (fills, strokes, effects, bound variables, styles, text runs, main components) is unchanged: 689 nodes, hashes adb53e1c and 2e20a01d, same as before.

## After

| Collection | Modes | Variables (before, after) |
|---|---|---|
| Rim | Approved | 53, 53 (untouched) |
| Dimension | Value | 27, 26 (minus 3, plus size/icon, size/icon-xs) |
| Motion | Value | 17, 26 (plus 9) |
| Type | Value | 10, 16 (minus 2, plus font/family-rounded and 7 line heights) |
| Glass · Color | Light, Dark | 18, 20 (plus line/lit-edge, pill/body) |
| Color (superseded by Glass) | Light, Dark | 22, deleted |

Text styles (16 before, 7 after): Glass/Title SF Pro Rounded Semibold 22/28, Glass/Section SF Pro Rounded Medium 15/20, Glass/Label SF Pro Rounded Medium 13/16, Glass/Body SF Pro Regular 13/18, Glass/Transcript SF Pro Regular 13/17, Glass/Detail SF Pro Regular 12/16, Glass/Small SF Pro Regular 11/14.
Effect styles: Elevation/Float (unchanged). Paint styles: none.

## Left for Alec

- Tokens page sample copy still reads "Hold ⌥ Space, talk, and let go…" (Glass/Body row) and "Whisper Large v3 Turbo · 1.6 GB" (Glass/Small row), and its colour table lists the 18 original roles only (not line/lit-edge or pill/body). Step 4 named the Style Guide only.
- Atoms Text field sample copy names OpenAI; the Atoms Shortcut recorder Set variant shows ⌥ and Space.
- Style Guide "Dictation shortcut" row label and its "Dictation" group title are unchanged (discovery says "Dictation key").
- The Style Guide's menu bar microphone (2093:9911) is now a plain drawing, waiting on the menu bar icon decision.
- Version 1's Microphone permission row has no microphone icon now that Icon/Dictation is gone (atoms.md had pointed it there).
- The transparent ends of the resting lit edge and the #FFE4B8, #FFCFA0, #FFEBD2 live-edge stops are still typed in.
