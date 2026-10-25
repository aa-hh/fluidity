---
name: Fluidity
description: A near-black pill edged with ivory light that moves with your voice, then pastes what you said.
colors:
  pill-body: "#0E0F13"
  words-ivory: "#F4EFE6"
  ivory-warm: "#FFE4B8"
  ivory-white: "#FFF6EA"
  ivory-apricot: "#FFCFA0"
  ivory-cream: "#FFEBD2"
  pasted-mint: "#3EDC8A"
  pasted-pale-mint: "#9CEFB2"
  pasted-sea: "#79EFCF"
  pasted-lime: "#B4EE62"
  problem-amber: "#FFB020"
  problem-gold: "#FFCF6A"
  problem-orange: "#FF8A00"
  problem-honey: "#FFC24D"
  retry-failed-orange: "#FF9A5C"
  retry-failed-peach: "#FFB27E"
  retry-failed-coral: "#FF8B57"
  retry-failed-apricot: "#FFC196"
  app-window-light: "rgba(255, 255, 255, 0.72)"
  app-window-dark: "rgba(14, 15, 19, 0.72)"
  app-sidebar-light: "rgba(255, 255, 255, 0.4)"
  app-sidebar-dark: "rgba(10, 11, 14, 0.5)"
  app-raised-light: "rgba(255, 255, 255, 0.85)"
  app-raised-dark: "rgba(255, 255, 255, 0.06)"
  app-selected-light: "rgba(20, 21, 25, 0.08)"
  app-selected-dark: "rgba(255, 255, 255, 0.12)"
  app-hover-light: "rgba(20, 21, 25, 0.04)"
  app-hover-dark: "rgba(255, 255, 255, 0.06)"
  app-line-rule-light: "rgba(20, 21, 25, 0.1)"
  app-line-rule-dark: "rgba(255, 255, 255, 0.1)"
  app-line-strong-light: "rgba(20, 21, 25, 0.22)"
  app-line-strong-dark: "rgba(255, 255, 255, 0.22)"
  app-text-primary-light: "#1C1C1E"
  app-text-primary-dark: "#F4EFE6"
  app-text-secondary-light: "#6F6A62"
  app-text-secondary-dark: "#A8A49C"
  app-action-primary-light: "#1C1C1E"
  app-action-primary-dark: "#FFF6EA"
  app-action-on-primary-light: "#FFFFFF"
  app-action-on-primary-dark: "#0E0F13"
  app-state-done-light: "#1A8A52"
  app-state-done-dark: "#3EDC8A"
  app-state-attention-light: "#9A5B00"
  app-state-attention-dark: "#FFB020"
  app-state-retry-light: "#B5531B"
  app-state-retry-dark: "#FF9A5C"
  app-state-destructive-light: "#C83230"
  app-state-destructive-dark: "#FF6B66"
  app-live-light: "#FFE4B8"
  app-live-dark: "#FFE4B8"
  app-control-knob-light: "#FFFFFF"
  app-control-knob-dark: "#D9D4CB"
  app-focus-ring-light: "rgba(28, 28, 30, 0.6)"
  app-focus-ring-dark: "rgba(255, 228, 184, 0.85)"
typography:
  pill-words:
    fontFamily: "SF Pro Text (system font)"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: "17px"
  bubble-words:
    fontFamily: "SF Pro Text (system font)"
    fontSize: "11px"
    fontWeight: 400
    lineHeight: "14.5px"
  app-title:
    fontFamily: "SF Pro Rounded (system font, rounded design)"
    fontSize: "22px"
    fontWeight: 600
    lineHeight: "28px"
  app-section:
    fontFamily: "SF Pro Rounded (system font, rounded design)"
    fontSize: "15px"
    fontWeight: 500
    lineHeight: "20px"
  app-label:
    fontFamily: "SF Pro Rounded (system font, rounded design)"
    fontSize: "13px"
    fontWeight: 500
    lineHeight: "16px"
  app-body:
    fontFamily: "SF Pro (system font)"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: "18px"
  app-detail:
    fontFamily: "SF Pro (system font)"
    fontSize: "12px"
    fontWeight: 400
    lineHeight: "16px"
  app-small:
    fontFamily: "SF Pro (system font)"
    fontSize: "11px"
    fontWeight: 400
    lineHeight: "14px"
rounded:
  bubble-cap: "14px"
  app-capsule: "999px"
  app-window: "16px"
  app-container: "14px"
  app-inner: "8px"
spacing:
  pill-pad-x: "13px"
  bubble-pad-x: "10px"
  bubble-pad-y: "7px"
  bubble-gap: "6px"
  retry-bubble-gap: "8px"
  dock-margin: "12px"
  app-space-1: "2px"
  app-space-2: "4px"
  app-space-3: "8px"
  app-space-4: "12px"
  app-space-5: "16px"
  app-space-6: "20px"
  app-size-control-m: "28px"
  app-size-row-min: "44px"
  app-size-sidebar: "184px"
components:
  pill:
    backgroundColor: "{colors.pill-body}"
    textColor: "{colors.words-ivory}"
    typography: "{typography.pill-words}"
    padding: "0 13px"
    height: "28px"
    width: "120px to 360px"
  pill-two-lines:
    backgroundColor: "{colors.pill-body}"
    textColor: "{colors.words-ivory}"
    typography: "{typography.pill-words}"
    height: "46px"
    width: "360px"
  bubble-above:
    backgroundColor: "{colors.pill-body}"
    textColor: "{colors.words-ivory}"
    typography: "{typography.bubble-words}"
    rounded: "{rounded.bubble-cap}"
    padding: "7px 10px"
    width: "up to 300px"
  retry-bubble:
    backgroundColor: "{colors.pill-body}"
    size: "same as the pill's height"
  button-primary:
    backgroundColor: "{colors.app-action-primary-light}"
    textColor: "{colors.app-action-on-primary-light}"
    typography: "{typography.app-label}"
    rounded: "{rounded.app-capsule}"
    padding: "0 16px"
    height: "28px"
  button-secondary:
    backgroundColor: "{colors.app-raised-light}"
    textColor: "{colors.app-text-primary-light}"
    typography: "{typography.app-label}"
    rounded: "{rounded.app-capsule}"
    padding: "0 16px"
    height: "28px"
  button-quiet:
    backgroundColor: "transparent"
    textColor: "{colors.app-text-primary-light}"
    typography: "{typography.app-label}"
    rounded: "{rounded.app-capsule}"
    padding: "0 16px"
    height: "28px"
  text-field:
    backgroundColor: "{colors.app-raised-light}"
    textColor: "{colors.app-text-primary-light}"
    typography: "{typography.app-body}"
    rounded: "{rounded.app-capsule}"
    padding: "0 12px"
    height: "28px"
  sidebar-item:
    backgroundColor: "transparent"
    textColor: "{colors.app-text-primary-light}"
    typography: "{typography.app-label}"
    rounded: "{rounded.app-capsule}"
    padding: "0 10px"
    height: "28px"
  sidebar-item-selected:
    backgroundColor: "{colors.app-selected-light}"
    textColor: "{colors.app-text-primary-light}"
    typography: "{typography.app-label}"
    rounded: "{rounded.app-capsule}"
    padding: "0 10px"
    height: "28px"
  popover:
    backgroundColor: "{colors.app-window-light}"
    textColor: "{colors.app-text-primary-light}"
    rounded: "{rounded.app-window}"
    width: "280px"
  settings-window:
    backgroundColor: "{colors.app-window-light}"
    textColor: "{colors.app-text-primary-light}"
    rounded: "{rounded.app-window}"
    width: "720px"
    height: "520px"
---

# Design System: Fluidity

All sizes are macOS points; `px` in the frontmatter means points. Source: the approved "Live words" pill page (claude.ai/artifact/T99ohW8MS4hmonR6swB4C2, its `rim.js` defaults dated 2026-10-21) and the Dynamic Island notes read from the iOS 26.4.1 simulator (`~/Documents/# Dynamic Island look and motion (iOS 26.4 simulator build).md`).

The pill content below is approved and stays the authority for the recording pill overlay. The settings window and the menu bar popover follow the Glass direction, chosen on 23 Oct 2026, and are documented in the "App surfaces" part of each section. App source: Figma file 5JcAX6bwl48LqQhqcUuGOJ, pages Tokens, Atoms and Style Guide; Figma names such as `surface/window`, `Glass/Label` and `Elevation/Float` are kept so you can find them there. First-run setup has no design yet; don't extend these values to it without a design pass.

## Overview

**Creative North Star: "Bright future"**

Fluidity shows one thing on screen: a small near-black pill, docked 12 pt above the bottom edge of the screen, that appears only while you dictate. Its edge is a thin ring of ivory light that brightens, drifts and blooms with your voice. Your words appear inside the pill, or in a bubble that splits off above it. When you let go, the light travels inward and becomes one line through the centre while the text is cleaned up. When the paste lands, the line turns mint green, holds for 260 ms, and the pill collapses and is gone.

The shape and motion come from the iPhone's Dynamic Island. The pill's sizes and springs, and the way the bubble splits off and merges back, all use values read from SpringBoard, so it moves like a system part of the Mac rather than an app's window. The body stays the same near-black on any background, and the light is the only colour.

The app around the pill, its settings window and menu bar popover, follows the direction the Figma file names "Glass". Its shell is macOS's own translucent material, so it floats over other apps the way the pill does, and its only colour is light caught on edges: a 1 pt lit top edge on every floating panel that brightens to the pill's ivory rim while the mic is live. Type, palette, density and the lit top edge are Fluidity's own; navigation and controls are standard macOS.

**Key Characteristics:**
- One near-black capsule; colour comes only from the light around its edge.
- Ivory light by default; mint for a paste that landed, amber for a problem, soft orange for a retry that failed again.
- Dynamic Island sizes, springs and splitting, not app-style easing.
- On screen only while dictating, then it collapses and disappears.

## Colors

A dark, neutral body with warm ivory light, and three state colours that replace the ivory entirely.

### Primary
- **Ivory light** (`ivory-warm`, `ivory-white`, `ivory-apricot`, `ivory-cream`): the four tones that slide around the rim as bands while you speak and while the text is processed. Drawn at 1.4× intensity. This is the only rim colour set; the Ember, Rose quartz and Tide sets in `rim.js` were dropped.

### Secondary
- **Pasted** (`pasted-mint`, `pasted-pale-mint`, `pasted-sea`, `pasted-lime`): replaces the ivory on the centre line and the bubble's ring when a paste lands. It switches at once rather than fading, because a blend from warm to green passes through grey.

### Tertiary
- **Problem** (`problem-amber`, `problem-gold`, `problem-orange`, `problem-honey`): a lost microphone or a revoked permission.
- **Retry failed** (`retry-failed-orange`, `retry-failed-peach`, `retry-failed-coral`, `retry-failed-apricot`): shown for 600 ms when a retried paste fails again.

### Neutral
- **Pill body** (`pill-body`): the fill of the pill and every bubble, on any background.
- **Words** (`words-ivory`): all text in the pill and bubble. Confirmed words at 94% opacity; the newest one or two, which may still change, at 50%. While the AI cleans up, words dim to 60%.

### App surfaces
Light and Dark are equals, so every role has a `-light` and a `-dark` key, named after its Figma role (`surface/window` becomes `app-window-light` and `app-window-dark`).
- **Shell** (`app-window`, `app-sidebar`): the window and popover fill, white in Light and the pill's near-black in Dark, both at 72% over a 40 pt background blur. The sidebar lays a second fill on the same shell. The pill body stays `pill-body` in both appearances.
- **Raised panels** (`app-raised`): the grouped rows inside a pane and the fill of most controls. Plain fills with no blur of their own.
- **Hover and selected** (`app-hover`, `app-selected`): fills laid on top of another fill. Hover on rows and buttons; selected on the current sidebar item, a pressed control, an open pop-up button and the highlighted popover row.
- **Lines** (`app-line-rule`, `app-line-strong`): 1 pt. Rule for dividers, panel and shell outlines and resting field outlines; strong for button, pop-up and selected-segment outlines and a focused field.
- **Text** (`app-text-primary`, `app-text-secondary`): secondary text is tinted warm, never a neutral grey.
- **Primary action** (`app-action-primary`, `app-action-on-primary`): the one filled button on a pane and the toggle's on track; near-black in Light, ivory-white in Dark.
- **Live** (`app-live`): the pill's warm ivory in both appearances, and the only "live" light in the app: the listening status dot and the live lit top edge.
- **States** (`app-state-done`, `app-state-attention`, `app-state-retry`, `app-state-destructive`): the Dark values are the pill's mint, amber and soft orange; the Light values are darker versions of the same hues. Destructive red marks field errors.
- **Controls** (`app-control-knob`, `app-focus-ring`): the toggle knob when off, and the focus ring (near-black in Light, ivory in Dark).

Every text pair passes 4.5:1 over the blurred desktop in both appearances. The lowest Light pair is secondary text on the sidebar, 4.68:1 (5.04:1 on the window); the lowest Dark pair is 7.27:1. `app-state-done-light` reaches only 4.11:1 on the window, so it colours icons and never text.

## Typography

**Body Font:** SF Pro Text, the macOS system font, regular weight (400), with kerning on.

**Character:** One face at small sizes. The text is read in a glance while you talk, so it stays plain and the light carries the expression.

### Hierarchy
- **Pill words** (400, 13 pt, 17 pt line): one line by default; two lines when the user picks that setting, after which it scrolls a line at a time. The oldest words fade out at the left edge once the line scrolls.
- **Bubble words** (400, 11 pt, 14.5 pt line): up to six lines, then it scrolls up a line at a time. The oldest fade out at the top.

Changed words cross-fade and glow briefly (`text-shadow` 5 pt in `rgba(255, 238, 214)`, strength 0.6 for new words, 0.21 for revised ones). Words arrive in batches every 0.6 s, 35 ms apart within a batch.

### App surfaces
SF Pro Rounded for anything you click or scan, matching the capsule controls; SF Pro for reading. The Figma text styles carry the `Glass/` prefix.
- **Title** (`app-title`, SF Pro Rounded 600, 22 pt, 28 pt line): pane titles.
- **Section** (`app-section`, SF Pro Rounded 500, 15 pt, 20 pt line): group headings.
- **Label** (`app-label`, SF Pro Rounded 500, 13 pt, 16 pt line): sidebar items, control labels, row titles, button text.
- **Body** (`app-body`, SF Pro 400, 13 pt, 18 pt line): running text and text field values.
- **Detail** (`app-detail`, SF Pro 400, 12 pt, 16 pt line): row descriptions, helper text, error messages.
- **Small** (`app-small`, SF Pro 400, 11 pt, 14 pt line): captions and keyboard shortcuts.
- **Transcript** in the popover uses `pill-words` (13 pt, 17 pt line), the same metrics as the pill.

## Layout

- **Dock:** the pill centres horizontally, 12 pt above the bottom edge of the screen, and grows upward from there.
- **Pill:** 28 pt tall at rest and 120 pt wide, growing with the words up to 360 pt; 13 pt side padding. Two-line layout: 46 pt tall at the full 360 pt.
- **Bubble above:** sits 6 pt above the pill, up to 300 pt wide, 10 pt side and 7 pt top/bottom padding.
- **Retry bubble:** when a paste fails, the transcript waits in a round bubble the height of the pill, 8 pt to the right of it.
- **Scaling rule:** distances copied from the Dynamic Island are in island points and scale by the pill's height ÷ 36.67 (the island's resting height).

### App surfaces
- **Settings window:** 720 × 520 pt. The sidebar (`app-size-sidebar`) sits on the left with 12 pt padding: window controls on top, a 12 pt gap, six panes 2 pt apart (General, Dictation, Models, Cleanup, Words, Permissions), and the status line ("Ready · ⌥ Space") at its foot. The content pane has 20 pt padding and 16 pt between the title and each group.
- **Groups:** a section header (title, then description 2 pt below, both inset 4 pt), then a raised panel 8 pt below holding the rows.
- **Rows:** at least 44 pt tall (`app-size-row-min`), 8 pt top and bottom and 12 pt side padding, 12 pt between the text and the control at the right end, a 1 pt rule between rows.
- **Controls:** 28 pt tall (`app-size-control-m`); toggles 38 × 22 pt.
- **Primary action:** the one filled capsule button on a pane, bottom right of its section.
- **Menu bar popover:** 280 pt wide. Top to bottom: status row (38 pt), rule, last dictation (caption, transcript, where it was pasted), model line, rule, then the Settings and Quit rows as 28 pt capsules inset 6 pt. Text blocks have 16 pt side padding.
- **Spacing:** steps come from `app-space-1` to `app-space-6`; most gaps are 12 or 16 pt.

## Elevation & Depth

No drop shadow. Depth comes from light: the rim is a 1.2 pt line of light with a soft halo reaching 2.6 pt outward. The rim width never exceeds 1.5 pt and the halo never exceeds 3 pt, including the extra glow on hover.

When the bubble splits off or merges back, the shapes are blurred together and cut at an opacity threshold so they melt into one outline, as the Dynamic Island does. The blur radius is 6.67 pt, easing to 3.33 pt as the bubble settles.

### App surfaces
Depth comes from one translucent shell, a shadow under things that float, and the lit top edge.
- **Shell:** `app-window` over a 40 pt background blur, a 1 pt `app-line-rule` outline inside the edge, and the Elevation/Float shadow (0 8 pt 24 pt, black at 16%). The window, the popover and an open pop-up menu use it. In Figma the window is two nested frames: the outer one carries the shadow; the inner one carries the fill, blur, outline, corners and lit top edge.
- **Inside the shell:** raised panels and controls are plain fills with no blur. Only two small shadows: the toggle knob (0 1 pt 2 pt, black at 22%) and the selected segment (0 1 pt 2 pt, black at 12%).
- **Lit top edge, resting:** a 1 pt line along the top edge of every floating panel (the window, the popover, an open pop-up menu, a focused text field or shortcut recorder), a gradient of `ivory-white` from transparent at both ends to full at the centre.
- **Lit top edge, live:** while the mic is live it brightens to the pill's four-tone rim: a 1.2 pt line repeating `ivory-warm`, `ivory-white`, `ivory-apricot` and `ivory-cream` along its length, over a 2.6 pt halo of the same gradient at 70% opacity, blurred 4 pt.
- **Focus ring:** a 2 pt solid ring outside the control in `app-focus-ring`, no blur.
- Elevation/Float is not used on the pill; the pill keeps its own rule above, no drop shadow.

## Shapes

- **Pill:** a full capsule, corner radius half its height, with Apple's continuous corner curve.
- **Bubble above:** corner radius half its height, capped at 14 pt, continuous curve.
- **Retry bubble:** a circle.

### App surfaces
- **Capsules** (`app-capsule`, radius half the height): buttons, text fields, pop-up buttons, the segmented track and its segments, toggles, sidebar items, popover rows and pop-up menu items.
- **Window and popover** (`app-window`): 16 pt corners.
- **Raised panels and an open pop-up menu** (`app-container`): 14 pt corners.
- **Keycaps** in the shortcut recorder (`app-inner`): 8 pt corners.
- **Circles:** status dots (8 pt), status icons (20 pt) and the shortcut recorder's clear button (18 pt).

## Components

### Pill
- **Listening:** the rim light reacts to your voice through eight bands that lift with loudness; contrast rises from 0.16 when quiet to 1 when speaking. If no speech is heard for 2 s, a 0.2 s pulse of light repeats every 3 s. The pill never changes size for this.
- **Waveform:** when the words are in the bubble above, or live words are off, the pill shows a mirrored waveform of the last 1.5 s of sound, newest at the centre and older sound travelling out to both ends, feathered where it ends. Fill runs from `rgba(255, 228, 196, 0.18)` at its top and bottom edges to `rgba(255, 247, 236, 1)` on the centre line, with a 3 pt glow in `rgba(255, 222, 184, 0.55)`.
- **Processing:** on release the light travels inward over 150 ms and becomes a 1 pt line along the centre, half the pill's width long. The line carries the sliding ivory bands. The rim dims to 60%.
- **Pasted:** the line turns mint, holds 260 ms, then the pill swells to 1.08 (words 1.05) and collapses over 340 ms, height leading width by 80 ms, fading from 120 ms in.

### Bubble above
- Splits off the top of the pill while you talk, using the island's size spring, and grows to fit the words. Its ring is the same light as the pill's rim at 60% brightness.
- When you stop talking it is pulled back into the pill: in mint for a paste, or before the retry bubble splits off for a failed one.

### Retry bubble
- Splits off the right of the pill using the island's split spring (damping 0.141, response 0.222 s, 130 ms head start).
- Hover: a soft glow on its ring and a send arrow. If it holds a fix rather than a transcript, it shows a microphone or lock icon at all times, brighter on hover.
- Click retries the paste. If the retry fails again, the ring shows soft orange for 600 ms and the bubble shakes once, 8 pt.

### Motion
All motion uses the Dynamic Island's springs: mass 1, stiffness (2π ÷ response)², damping ratio × 4π ÷ response.
- **Size changes** (the pill growing with words, shrinking after cleanup): damping 0.816, response 0.512 s.
- **Words sliding into their cleaned-up place:** damping 0.78, response 0.4 s.
- **Removed words leaving, bubble merging back:** damping 0.816, response 0.45 s.
- **Recombine:** damping 0.6, response 0.222 s.
- **Press bump on the bubble:** scale 1.015 × 1.03, damping 0.694, response 0.85 s.

### Reduce Motion
No travel, wobble, bump or shake. Bubbles fade in and out in place over 0.2 s, sizes jump instead of springing, and the waveform shows loudness without moving along.

### App surfaces
Each control is the standard macOS control for its job, drawn in Glass colours. The frontmatter components use the Light keys; in Dark each takes the `-dark` key of the same role. Disabled controls drop to 40% opacity. The settings window and popover described here are the Glass comps of 23 Oct 2026, made before version 1's features were fixed. Version 1 (PRODUCT.md, Linear AA-296) has four panes (General, Cleanup, Words, Permissions), no model line, and a popover listing the last 20 or so dictations; the popover's sample text is not a decision.

#### Buttons
- 28 pt tall, 16 pt side padding, text in `app-label`.
- **Primary** (`button-primary`): filled with `app-action-primary`. One per pane.
- **Secondary** (`button-secondary`): `app-raised` fill with a 1 pt `app-line-strong` outline. Hover adds `app-hover` on top; pressed adds `app-selected`.
- **Quiet** (`button-quiet`): no fill or outline at rest; `app-hover` on hover, `app-selected` when pressed.

#### Text field
- `text-field`: `app-raised` fill, 1 pt `app-line-rule` outline, value in `app-body`, placeholder in secondary text.
- **Focused:** the outline turns `app-line-strong`, the focus ring appears and the field gets a resting lit top edge.
- **Error:** the outline turns `app-state-destructive`; the message sits 6 pt below in `app-detail`, same colour.

#### Pop-up button
- 28 pt tall, `app-raised` fill, `app-line-strong` outline, 12 pt left and 8 pt right padding, value in `app-label`, then a 16 pt up-down chevron 8 pt after it.
- **Open:** the button adds `app-selected`. The menu opens 4 pt below on the shell material with 14 pt corners, Elevation/Float and a resting lit top edge; 6 pt padding, 24 pt capsule items with a 16 pt check column, the highlighted item in `app-selected`.

#### Toggle
- 38 × 22 pt capsule, 2 pt padding, 18 pt knob. On: `app-action-primary` track, `app-action-on-primary` knob. Off: `app-selected` track with an `app-line-rule` outline, `app-control-knob` knob.

#### Segmented control
- Track 28 pt tall: `app-hover` fill, `app-line-rule` outline, 2 pt padding, 2 pt between segments. Selected segment: 24 pt tall, `app-raised` fill, `app-line-strong` outline, its small shadow, label in primary text. Other labels in secondary text.

#### Sidebar
- `sidebar-item` and `sidebar-item-selected`: 28 pt tall, 16 pt icon, 8 pt gap, label in `app-label`. Hover adds `app-hover`; the selected pane is an `app-selected` capsule.
- The sidebar itself: `app-sidebar` fill over the shell, a 1 pt `app-line-rule` on its right edge.

#### Section header
- Title in `app-section`, description 2 pt below in `app-detail` secondary text.

#### Shortcut recorder
- 160 × 28 pt capsule on `app-raised`. Idle: `app-line-rule` outline, "Record Shortcut" in secondary text. Recording: `app-line-strong` outline, focus ring and resting lit top edge, "Type a shortcut…" in primary text. Set: one keycap per key (18 pt tall, `app-selected` fill, 6 pt side padding) and an 18 pt round clear button on `app-hover`.

#### Status row
- 8 pt top and bottom and 12 pt side padding, 12 pt gaps: a 20 pt circle filled with the state colour holding an `app-action-on-primary` glyph, then a title in `app-label` and detail in `app-detail` secondary text. Attention rows carry a secondary button at the right.

#### Menu bar popover
- `popover`: shell material, Elevation/Float, resting lit top edge.
- Status row: 8 pt dot, status in `app-label`, shortcut hint in `app-small` secondary text. Ready: the dot in secondary text colour. Listening: the dot in `app-live` with a 1 pt `app-line-strong` outline and a 6 pt ivory glow, the hint reads "Let go to paste", and the lit top edge goes live.
- Settings and Quit rows: 28 pt capsules, 10 pt side padding, shortcut in `app-small` secondary text, `app-selected` on hover.

#### Settings window
- `settings-window`: shell material, Elevation/Float, resting lit top edge; the edge goes live while the mic is live (shown on the Dark window in Figma).

#### Motion
The app uses the Figma Motion collection, whose values are copied from the pill.
- 130 ms for hover, press and toggle (`duration/snap`); 180 ms to open or reveal (`duration/enter`); 150 ms to close or remove (`duration/exit`); 260 ms for a success mark to hold (`duration/hold`); 340 ms to dismiss to nothing (`duration/collapse`).
- Layout changes use the size spring (damping 0.816, response 0.512 s); sheets and popovers close on damping 0.816, response 0.45 s.
- Reduce Motion: a 130 ms cross-fade replaces every move (`duration/reduce-crossfade`).
- The collection has no value for the lit top edge going from resting to live; set one in a design pass before building it.

## Do's and Don'ts

### Do:
- **Do** keep the pill and every bubble `pill-body` on every background; colour lives only in the light.
- **Do** use the Dynamic Island springs above for every size, position and merge change.
- **Do** switch from ivory to mint at once when a paste lands, and hold green for 260 ms.
- **Do** scale any distance taken from the Dynamic Island by the pill's height ÷ 36.67.
- **Do** honour Reduce Motion exactly as described above.

### Don't:
- **Don't** use the Ember, Rose quartz or Tide rim colours; Ivory is the only rim colour set.
- **Don't** add a drop shadow, a border or a fill colour to the pill.
- **Don't** let the rim exceed 1.5 pt or its halo 3 pt.
- **Don't** scale or bounce the pill to say it can't hear you; pulse the light instead.
- **Don't** keep the pill on screen when the user isn't dictating.
- **Don't** fade between the ivory and a state colour; it passes through grey.

### App surfaces
- **Do** build the shell of the window, the popover and an open pop-up menu from one material: `app-window` over a 40 pt background blur with Elevation/Float.
- **Do** draw the lit top edge on floating panels only: the window, the popover, an open pop-up menu, a focused text field or shortcut recorder.
- **Do** make every control a capsule, radius half its height.
- **Do** keep one filled primary button per pane, bottom right of its section.
- **Do** use standard macOS navigation and controls: sidebar, toggle, pop-up button, segmented control, text field.
- **Don't** put a blurred or frosted panel inside the shell; raised panels are plain fills.
- **Don't** draw the lit top edge on rows, raised panels, buttons or the sidebar.
- **Don't** set secondary text in a neutral grey; use `app-text-secondary`.
- **Don't** use `app-state-done-light` for text; at 4.11:1 it colours icons only.
- **Don't** add another colour of light; ivory is the only light, and mint, amber and soft orange appear only for states.
- **Don't** fade the lit top edge or the status dot between ivory and a state colour; switch at once, as on the pill.
- **Don't** replace a macOS control or the sidebar with a custom one.
