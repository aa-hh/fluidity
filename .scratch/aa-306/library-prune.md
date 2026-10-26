# Library prune log (AA-306)

Figma file 5JcAX6bwl48LqQhqcUuGOJ ("Fluidity -- Design Library"). Date: 2026-10-26. The screens file jQqsc13MjOVaVST36jaxd8 was not opened.

## Before

Pill page 27:2: get_metadata read (30 pill components in "Pill rim" 27:82, "Rim spec" 28:2). Fingerprint of every node (id, type, name, x, y, width, height, visibility, fills, strokes, effects, bound variables, style IDs, opacity, corner radius, stroke weight, description, text, main component of each instance): 689 nodes, 603,972 characters, hashes 4174fe58 and dbcb4a7.

## 1. Discovery page

- Walked Screens section 2048:1603 for COMPONENT and COMPONENT_SET nodes: none. Nothing to move.
- Deleted Screens section 2048:1603 (11,248 layers inside it).
- Moved Atoms section 2044:238 from x -1600 to x 0, y 0 (1480 wide). Moved Components section 2048:1465 from x 1600 to x 1680, y 0 (200 pt gap).
- Renamed page 2044:237 "Discovery · version 1" to "Discovery · atoms and components". The page now holds only those two sections.

## 2. Icon/Microphone

- Copied the Style Guide drawing 2093:9911 into the Atoms icon row 2021:1681 at position 5 (after Icon/Permissions) and made it a component: Icon/Microphone 2098:9830, 16 × 16, layers Glyph 2098:9827 and two vectors 2098:9828, 2098:9829 (1.4 pt strokes, still bound to text/primary).
- Instance in the Dark row 2021:5645 at the same position: 2098:9831.
- Style Guide: replaced the drawing 2093:9911 with instance 2098:9835 "Microphone" in "Fluidity menu bar item" 2021:5553, same index and position (x 6, y 2, 16 × 16). 2093:9911 is deleted.
- Discovery Permission row (set 2048:2540) left on the Status row's state circle, as asked.

## 3. Stale copy

Tokens page (2008:402):
- Glass/Body sample 2021:1592: "Hold ⌥ Space, talk, and let go. Fluidity pastes the text into whatever app has focus." to "Tap or hold Right ⌥ and talk. Fluidity pastes the text into whatever app has focus." ("let go" dropped, since a tap keeps listening until the next tap.)
- Glass/Small sample 2021:1607: "Whisper Large v3 Turbo · 1.6 GB" to "Parakeet TDT v2 · on this Mac".
- Colour table (Swatch grid 2021:1365): added two rows, copied from the line/strong row in each column, chips bound to the variable, value text bound to text/primary as before.
  - line/lit-edge (VariableID:2094:184), after line/strong: Role 2098:9839, Light 2098:9841 (#FFF6EA), Dark 2098:9844 (#FFF6EA).
  - pill/body (VariableID:2094:185), after focus/ring: Role 2098:9847, Light 2098:9849 (#0E0F13), Dark 2098:9852 (#0E0F13).
  - The table grew 112 pt, so the "Why" note 2021:1519 moved from y 1272 to 1384 and the Colour section 2021:1103 grew from 1432 to 1528 tall.

Atoms page (2007:400), Text field component set 2021:2280:
- State=Default placeholder 2021:2268: "Paste your OpenAI API key" to "Paste your Cerebras API key".
- State=Error message 2021:2277: "Key not recognised. Copy it again from OpenAI." to "Cerebras didn’t accept this key. Copy it again from cloud.cerebras.ai."
- Wording taken from the Cleanup key row set 2056:2880 (States No key and Not accepted) in the Components section. 2073:6374 could not be read: it was inside the Screens section deleted in step 1.
- The Dark-pane instances follow (checked). No text on the Atoms page names OpenAI now.

Style Guide (2008:403):
- Labels 2021:4950 and 2021:5141 "Dictation shortcut" to "Dictation key"; their row layers 2021:4948 and 2021:5139 renamed "Row · Dictation key".

## 4. Descriptions

Set on every component set and every component outside a set whose description was empty: 45 in all. Variants inside a set were left without their own description; the set's description covers them. Pill page skipped. No existing description changed.
- Atoms page (9): the nine icons, Icon/General through Icon/Close, including the new Icon/Microphone. The 10 sets and Section header already had descriptions.
- Discovery page (36): 10 atom sets (three menu bar icon designs, Status dot, Icon button, Inline note, Secure field, Text area, Shortcut recorder (version 1), Status row (version 1)), 8 new icons, 14 component sets (Status icon to Speech model row), and Tap and hold picture, Word list bar, Word add row, Progress bar. Keycap 2048:1185 already had one.
- Style Guide and Tokens hold no components.
- Found, not changed: Keycap's existing description contains the literal text "&quot;" where quote marks were meant.

## 5. Verification

Screenshots looked at:
- Discovery page 2044:237: Atoms section on the left, Components section to its right, nothing else on the page.
- Tokens Colour section 2021:1103: 20 rows; line/lit-edge under line/strong and pill/body last, chips and values in both columns; "Why" note sits clear below the table.
- Tokens Type section 2021:1105: Body sample "Tap or hold Right ⌥ and talk. …", Small sample "Parakeet TDT v2 · on this Mac".
- Atoms icon rows 2021:1679 (Light) and 2021:5643 (Dark): nine icons, microphone fifth, after the lock.
- Atoms Text field 2021:2280: Cerebras placeholder; the Error message now wraps to two lines inside the variant.
- Style Guide 2008:403: "Dictation key" label in both Settings windows; the menu bar item 2021:5553 shows the microphone instance.

Pill page 27:2 after step 4: fingerprint 689 nodes, 603,972 characters, hashes 4174fe58 and dbcb4a7, the same as before step 1. get_metadata of "Pill rim" 27:82 lists the same 30 components with the same IDs, names, positions and sizes as before.

## Publish inventory (pill page excluded)

Style Guide and Tokens: no components.

Atoms page 2007:400, component sets:
- Button 2021:1941 (12 variants)
- Toggle 2021:2254 (4)
- Text field 2021:2280 (3)
- Pop-up button 2021:2553 (2)
- Segmented control 2021:2607 (3)
- Sidebar item 2021:3242 (3)
- Shortcut recorder 2021:3295 (3)
- Status row 2021:3550 (3)
- Focus ring 2021:3597 (3)
- Menu bar popover 2021:5417 (2)

Atoms page, components:
- Icon/General 2021:1682, Icon/Cleanup 2021:1695, Icon/Words 2021:1699, Icon/Permissions 2021:1702, Icon/Microphone 2098:9830, Icon/Chevron up down 2021:1706, Icon/Check 2021:1709, Icon/Info 2021:1712, Icon/Close 2021:1717
- Section header 2021:3267

Discovery page 2044:237, Atoms section, component sets:
- Menu bar icon/Pill outline 2045:344 (5)
- Menu bar icon/Microphone 2045:1007 (5)
- Menu bar icon/Dot and pill 2046:581 (5)
- Status dot 2048:655 (5)
- Icon button 2048:1276 (10)
- Inline note 2048:1372 (4)
- Secure field 2048:1983 (8)
- Text area 2048:2090 (2)
- Shortcut recorder (version 1) 2048:3134 (4)
- Status row (version 1) 2048:3178 (1)

Discovery page, Atoms section, components:
- Icon/Copy 2044:249, Icon/Paste 2044:258, Icon/Plus 2044:267, Icon/Minus 2044:274, Icon/Trash 2044:284, Icon/Accessibility 2044:299, Icon/Eye 2047:619, Icon/Eye slash 2047:624
- Keycap 2048:1185

Discovery page, Components section, component sets:
- Status icon 2048:1483 (3)
- Settings row 2048:1602 (7)
- Permission row 2048:2540 (7)
- Popover empty history 2048:3199 (2)
- Popover status row 2049:1900 (12)
- History row/Row click 2050:2012 (9)
- Popover footer row 2051:2508 (3)
- History row/Hover buttons 2052:2373 (9)
- Sidebar status line 2053:2455 (14)
- Shortcut row 2054:2569 (7)
- Cleanup key row 2056:2880 (8)
- Cleanup rules 2056:2918 (4)
- Word row 2057:3181 (6)
- Speech model row 2059:4210 (4)

Discovery page, Components section, components:
- Tap and hold picture 2055:2658, Word list bar 2057:3182, Word add row 2057:3193, Progress bar 2059:4170

Totals: 34 component sets (182 variants) and 24 components outside sets.
