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
  app-section:
    fontFamily: "SF Pro Rounded (system font, rounded design)"
    fontSize: "15px"
    fontWeight: 500
  app-label:
    fontFamily: "SF Pro Rounded (system font, rounded design)"
    fontSize: "13px"
    fontWeight: 500
  app-keycap:
    fontFamily: "SF Pro Rounded (system font, rounded design)"
    fontSize: "11px"
    fontWeight: 500
  app-body:
    fontFamily: "SF Pro (system font)"
    fontSize: "13px"
    fontWeight: 400
  app-transcript:
    fontFamily: "SF Pro (system font)"
    fontSize: "13px"
    fontWeight: 400
  app-detail:
    fontFamily: "SF Pro (system font)"
    fontSize: "12px"
    fontWeight: 400
  app-small:
    fontFamily: "SF Pro (system font)"
    fontSize: "11px"
    fontWeight: 400
rounded:
  bubble-cap: "14px"
  app-capsule: "999px"
  app-window: "16px"
  app-container: "14px"
  app-history-row: "10px"
  app-inner: "8px"
spacing:
  pill-pad-x: "13px"
  bubble-pad-x: "10px"
  bubble-pad-y: "7px"
  bubble-gap: "6px"
  dock-margin: "12px"
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
    padding: "0 10px"
    height: "28px"
  text-field:
    backgroundColor: "{colors.app-raised-light}"
    textColor: "{colors.app-text-primary-light}"
    typography: "{typography.app-body}"
    rounded: "{rounded.app-capsule}"
    padding: "0 12px"
    height: "28px"
  toggle:
    backgroundColor: "{colors.app-action-primary-light}"
    rounded: "{rounded.app-capsule}"
    width: "38px"
    height: "22px"
  sidebar-item:
    backgroundColor: "transparent"
    textColor: "{colors.app-text-primary-light}"
    typography: "{typography.app-label}"
    rounded: "{rounded.app-capsule}"
    padding: "0 8px"
    height: "28px"
  sidebar-item-selected:
    backgroundColor: "{colors.app-selected-light}"
    textColor: "{colors.app-text-primary-light}"
    typography: "{typography.app-label}"
    rounded: "{rounded.app-capsule}"
    padding: "0 8px"
    height: "28px"
  history-row:
    backgroundColor: "transparent"
    textColor: "{colors.app-text-primary-light}"
    typography: "{typography.app-transcript}"
    rounded: "{rounded.app-history-row}"
    padding: "8px 10px"
  history-row-hover:
    backgroundColor: "{colors.app-hover-light}"
    textColor: "{colors.app-text-primary-light}"
    typography: "{typography.app-transcript}"
    rounded: "{rounded.app-history-row}"
    padding: "8px 10px"
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
  first-run-window:
    backgroundColor: "{colors.app-window-light}"
    textColor: "{colors.app-text-primary-light}"
    rounded: "{rounded.app-window}"
    width: "540px"
---

# Design System: Fluidity

All sizes are macOS points; `px` in the frontmatter means points. Sources: the approved "Live words" pill page (claude.ai/artifact/T99ohW8MS4hmonR6swB4C2, its `rim.js` defaults dated 2026-10-21) and the Dynamic Island notes read from the iOS 26.4.1 simulator (`~/Documents/# Dynamic Island look and motion (iOS 26.4 simulator build).md`).

The shipped Swift code is now the authority. App-surface tokens live in `Fluidity/Glass/GlassTheme.swift`; pill values live in `Fluidity/Pill/RimParameters.swift`, `RimSpring.swift`, `RimWords.swift` and `RimWordsBubble.swift`. On 26 Oct 2026 this file was checked against the code and corrected wherever the two disagreed. The settings window, the menu bar popover and the first-run window follow the Glass direction, chosen on 23 Oct 2026, and are documented in the "App surfaces" part of each section. Design source: two Figma files since 26 Oct 2026. The published library "Fluidity -- Design Library" (key 5JcAX6bwl48LqQhqcUuGOJ) holds Tokens, Atoms, Style Guide, the approved pill page and the discovery atoms and components; the screens file "Fluidity -- Screens" (key jQqsc13MjOVaVST36jaxd8) holds every screen as instances of the library and never defines an atom, token or style of its own. Figma names such as `surface/window` and `Glass/Label` are kept so you can find them there. First-run setup now ships, built from the Glass parts, and is documented below.

## Overview

**Creative North Star: "Bright future"**

Fluidity shows one thing on screen: a small near-black pill, docked 12 pt above the bottom of the visible screen area, so above the Dock when the Dock is shown, that appears only while you dictate. Its edge is a thin ring of ivory light that brightens, drifts and blooms with your voice. Your words appear inside the pill, or in a bubble that splits off above it. When you let go, the light travels inward and becomes one line through the centre while the text is cleaned up. When the paste lands, the line turns mint green, holds for 260 ms, and the pill collapses and is gone.

The shape and motion come from the iPhone's Dynamic Island. The pill's sizes and springs, and the way the bubble splits off and merges back, all use values read from SpringBoard, so it moves like a system part of the Mac rather than an app's window. The body stays the same near-black on any background, and the light is the only colour.

The app around the pill, its settings window, menu bar popover and first-run window, follows the direction the Figma file names "Glass". Its shell is macOS's own translucent material, so it floats over other apps the way the pill does, and its only colour is light caught on edges: a 1 pt lit top edge on every floating panel that brightens to the pill's ivory rim while the mic is live. Type, palette, density, controls and the lit top edge are Fluidity's own; each control still reports to VoiceOver as the macOS control for its job.

**Key Characteristics:**
- One near-black capsule; colour comes only from the light around its edge.
- Ivory light by default; mint for a paste that landed, amber for a problem, soft orange for a retry that failed again.
- Dynamic Island sizes, springs and splitting, not app-style easing.
- On screen only while dictating, then it collapses and disappears.

## Colors

A dark, neutral body with warm ivory light, and three state colours that replace the ivory entirely.

### Primary
- **Ivory light** (`ivory-warm`, `ivory-white`, `ivory-apricot`, `ivory-cream`): the four tones that slide around the rim as bands while you speak. Drawn at 1.4× intensity. This is the only rim colour set; the Ember, Rose quartz and Tide sets in `rim.js` were dropped.
- While the text is processed, the bands are a lightened ivory: OKLab (a colour space that tracks perceived lightness) lightness +0.06 and colour strength ×0.9.

### Secondary
- **Pasted** (`pasted-mint`, `pasted-pale-mint`, `pasted-sea`, `pasted-lime`): replaces the ivory on the centre line and the bubble's ring when a paste lands. It switches at once rather than fading, because a blend from warm to green passes through grey. On the rim and the bubble's ring its tone is capped at 0.82, so it stays mint and never washes to white.

### Tertiary
- **Problem** (`problem-amber`, `problem-gold`, `problem-orange`, `problem-honey`): a lost microphone or a revoked permission. It eases in from ivory over about 0.28 s.
- **Retry failed** (`retry-failed-orange`, `retry-failed-peach`, `retry-failed-coral`, `retry-failed-apricot`): shown for 600 ms when a retried paste fails again. It glides in over about 0.06 s and back to ivory over about 0.22 s; both ends are warm, so the glide does not pass through grey.

### Neutral
- **Pill body** (`pill-body`): the fill of the pill and every bubble, on any background. The value exists only in the pill's shader (`PillShader.swift`).
- **Words** (`words-ivory`): all text in the pill and bubble. Confirmed words at 94% opacity; the newest one or two, which may still change, at 50%. While the AI cleans up, words dim to 60%. `PillWordsView.swift` keeps its own copy of this value, separate from `app-text-primary-dark`, which has the same hex.

### App surfaces
Light and Dark are equals, so every role has a `-light` and a `-dark` key, named after its Figma role (`surface/window` becomes `app-window-light` and `app-window-dark`).
- **Shell** (`app-window`, `app-sidebar`): the fill of the settings window, popover and first-run window, white in Light and the pill's near-black in Dark, both at 72% over macOS's behind-window material. The sidebar lays a second fill on the same shell. The pill body stays `pill-body` in both appearances.
- **Raised panels** (`app-raised`): the grouped rows inside a pane and the fill of most controls. Plain fills with no blur of their own.
- **Hover and selected** (`app-hover`, `app-selected`): fills laid on top of another fill. Hover on rows and buttons; selected on the current sidebar item, a pressed control, a focused words row or history row, keycaps, and the hovered Settings and Quit rows.
- **Lines** (`app-line-rule`, `app-line-strong`): 1 pt. Rule for dividers, panel and shell outlines and resting field outlines; strong for secondary button outlines and a focused field or rules editor.
- **Text** (`app-text-primary`, `app-text-secondary`): secondary text is tinted warm, never a neutral grey.
- **Primary action** (`app-action-primary`, `app-action-on-primary`): the one filled button (Done on the first-run window) and the toggle's on track; near-black in Light, ivory-white in Dark.
- **Live** (`app-live`): the pill's warm ivory, and the only "live" light in the app: the listening status dot and the live lit top edge. The code holds one value (`GlassTheme.live`) for both appearances; the two keys carry the same hex.
- **States** (`app-state-done`, `app-state-attention`, `app-state-destructive`): the Dark done and attention values are the pill's mint and amber; the Light values are darker versions of the same hues. Destructive red marks field errors.
- **Controls** (`app-control-knob`, `app-focus-ring`): the toggle knob when off, and the focus ring (near-black in Light, ivory in Dark).

Every text pair passes 4.5:1 over the blurred desktop in both appearances. The lowest Light pair is secondary text on the sidebar, 4.68:1 (5.04:1 on the window); the lowest Dark pair is 7.27:1. `app-state-done-light` reaches only 4.11:1 on the window, so it colours icons and never text.

## Typography

**Body Font:** SF Pro Text, the macOS system font, regular weight (400), with kerning on.

**Character:** One face at small sizes. The text is read in a glance while you talk, so it stays plain and the light carries the expression.

### Hierarchy
- **Pill words** (400, 13 pt, 17 pt line): one line. Once the line fills it scrolls, and the oldest words fade out at the left edge.
- **Bubble words** (400, 11 pt, 14.5 pt line): up to six lines, then it scrolls up a line at a time. The oldest fade out at the top.

Words arrive in batches every 1 s, 35 ms apart within a batch. Changed words cross-fade and glow briefly: a 5 pt glow in `rgba(255, 238, 214)`, drawn at 0.75 × its strength. Strength is 0.6 for words cleanup inserts, 0.21 for words cleanup changes, 0.3 when a live preview revises a word, and 0.85 when the release light passes a word; newly heard words get no glow. The glow decays with a 0.32 s time constant.

### App surfaces
SF Pro Rounded for anything you click or scan, matching the capsule controls; SF Pro for reading. The Figma text styles carry the `Glass/` prefix. The code sets no line height, so every app style uses the system's default line height.
- **Title** (`app-title`, SF Pro Rounded 600, 22 pt): pane titles.
- **Section** (`app-section`, SF Pro Rounded 500, 15 pt): group headings.
- **Label** (`app-label`, SF Pro Rounded 500, 13 pt): sidebar items, control labels, row titles, button text.
- **Keycap** (`app-keycap`, SF Pro Rounded 500, 11 pt): the shortcut recorder's keycaps.
- **Body** (`app-body`, SF Pro 400, 13 pt): running text and text field values.
- **Transcript** (`app-transcript`, SF Pro 400, 13 pt): the popover's history rows, with 4 pt extra line spacing.
- **Detail** (`app-detail`, SF Pro 400, 12 pt): row descriptions, helper text, field messages.
- **Small** (`app-small`, SF Pro 400, 11 pt): captions and keyboard shortcut hints.

## Layout

- **Dock:** the pill centres horizontally, 12 pt (`dock-margin`, `PillPresenter.dockMargin`) above the bottom of the visible screen area, so above the Dock when the Dock is shown, and grows upward from there.
- **Pill:** 28 pt tall at rest and 120 pt wide, growing with the words up to 360 pt; 13 pt side padding (`pill-pad-x`, `RimWords.padX`).
- **Bubble above:** sits 6 pt above the pill (`bubble-gap`, `RimWordsBubble.gap`), up to 300 pt wide, 10 pt side and 7 pt top and bottom padding (`RimWords.abovePadX`, `abovePadY`).
- **Retry bubble:** when a paste fails, the transcript waits in a round bubble the height of the pill, 8 island points to the right, scaled by the pill's height ÷ 36.67, so about 6.1 pt at the 28 pt pill. The code marks this gap as not yet settled.
- **Scaling rule:** distances copied from the Dynamic Island are in island points and scale by the pill's height ÷ 36.67 (the island's resting height). The retry gap, the shake distance and the merge blur all follow it.

### App surfaces
- **Settings window:** 720 × 520 pt. The sidebar (`app-size-sidebar`, `GlassTheme.sidebarWidth`) has 12 pt padding at the sides and bottom and 52 pt at the top, which leaves room for the system window buttons. Four panes sit 2 pt apart (General, Cleanup, Words, Permissions), each a 28 pt capsule with a 16 pt SF Symbol (`gearshape`, `sparkles`, `book`, `lock`), an 8 pt gap and 8 pt side padding. At its foot, the status line: an 8 pt status dot, the short status in `app-label`, then the dictation key's name in `app-small` secondary text at the right, 8 pt gaps and side padding; it becomes a button with a hover capsule when a fix exists. The content pane has 20 pt padding and 16 pt between the title and each group. Switching panes is a 130 ms cross-fade; Command-1 to 4 and the up and down arrows change pane.
- **Groups:** a section header (title, then description 2 pt below, both inset 4 pt), then a raised panel 8 pt below holding the rows. The Cleanup pane has no section header.
- **Rows:** at least 44 pt tall (`app-size-row-min`, `GlassTheme.rowMinHeight`), 8 pt top and bottom and 12 pt side padding, 12 pt between the text and the control at the right end, a 1 pt rule between rows. Title and detail sit 2 pt apart. A row may carry a 20 pt leading status icon 12 pt before the text, and an error line between the title and detail.
- **Controls:** 28 pt tall (`app-size-control-m`, `GlassTheme.controlHeight`); toggles 38 × 22 pt; the General pane's rows are Dictation key, Paste last transcript, Live words and Launch at login. The settings panes have no filled button; the only primary button is Done on the first-run window.
- **Menu bar popover:** 280 pt wide. Top to bottom: the status row, at least 38 pt tall with 16 pt side and 8 pt top and bottom padding and 8 pt gaps, with an optional detail line and an optional secondary fix button, both inset 16 pt; a rule; the history, up to 20 dictations in a list at most 400 pt tall, inset 6 pt, each row with 10 pt corners and 10 pt side, 8 pt top and bottom padding, or when empty a message with 16 pt padding; a rule; then the Settings… and Quit rows as 28 pt capsules with 10 pt side padding, inset 6 pt. No model line. The panel opens 4 pt below the menu bar button, centred on it, and is kept 8 pt inside the screen.
- **First-run window:** 540 pt wide and as tall as its content; 20 pt side, 44 pt top and 20 pt bottom padding, 16 pt between blocks. Top to bottom: the title, a one-line body 4 pt below; one raised panel of three rows (Microphone, Accessibility, Speech model, the last with a progress bar inset 44 pt left, 12 pt right and 10 pt from the bottom); the dictation key group at 40% opacity until both permissions are allowed; the Done button at the right.
- **Spacing:** there is no spacing scale in code; gaps are bare numbers. Most are 8, 12 or 16 pt; inner insets and message gaps are 6 pt, the popover rows and quiet buttons use 10 pt, icon buttons are 24 pt, and words rows are at least 36 pt.
- **Other sizes:** the Cleanup key field is 254 pt wide with 12 pt inner padding; the cleanup rules editor is 140 pt tall with 8 pt padding; the shortcut recorder is 160 pt wide with 5 pt inner padding and 4 pt gaps.

## Elevation & Depth

No drop shadow. Depth comes from light: the rim is a line of light 1.2 pt wide at rest that widens by up to 0.95 pt where voice lands (about 2.15 pt at most), with a soft halo reaching 2.6 pt outward, 3.0 pt on hover. During the collapse the halo widens with the melt blur, to about 5.65 pt at the 28 pt pill.

When the bubble splits off or merges back, the shapes are blurred together and cut at an opacity threshold so they melt into one outline, as the Dynamic Island does. The blur radius is 6.67 island points, easing to 3.33 as the bubble settles: about 5.1 pt to 2.5 pt at the 28 pt pill.

### App surfaces
Depth comes from one translucent shell and the lit top edge.
- **Shell:** `app-window` over macOS's behind-window material (`NSVisualEffectView` with `.underWindowBackground`, a view that blurs whatever is behind the window). The system sets the blur; there is no fixed radius. A 1 pt `app-line-rule` outline sits inside the edge. The shadow is the system window shadow. The settings window, the popover and the first-run window use the shell.
- **Inside the shell:** raised panels and controls are plain fills with no blur. One small shadow, shared by the toggle knob and the selected segment of a segmented control (SwiftUI shadow radius 1, offset 1 pt down, black at 22%).
- **Lit top edge, resting:** a 1 pt line along the top edge of every floating panel (the window, the popover, the first-run window, a focused text field or shortcut recorder), a gradient of `ivory-white` from transparent at both ends to full at the centre. It is inset 16 pt from each end of a shell and 14 pt on a field.
- **Lit top edge, live:** while the mic is live it brightens to the pill's four-tone rim: a 1.2 pt line of `ivory-warm`, `ivory-white`, `ivory-apricot` and `ivory-cream`, the four tones repeating three times along the width, over a 2.6 pt band of the same gradient at 70% opacity, blurred 4 pt. The band runs along and below the edge and does not reach outward.
- **Focus ring:** a 2 pt ring drawn 1 pt outside the control's edge in `app-focus-ring` (SwiftUI padding −3, then a 2 pt stroke), no blur. Capsule controls get a capsule ring; icon buttons a circle; the history row's text an 8 pt (`app-inner`) rounded rectangle; the rules editor an 11 pt rounded rectangle. Words list rows draw a 2 pt rectangle inside the row instead, since the panel clips anything outside it. Every window root turns the system focus ring off, so a control shows no focus until it opts in.
- **Listening status dot:** `app-live` fill, a 1 pt `app-line-strong` outline and an `app-live` glow (SwiftUI shadow radius 3).

## Shapes

- **Pill:** a full capsule, corner radius half its height, with Apple's continuous corner curve.
- **Bubble above:** corner radius half its height, capped at 14 pt (`RimWordsBubble.cornerCap`), continuous curve.
- **Retry bubble:** a circle.

### App surfaces
- **Capsules** (`app-capsule`, SwiftUI `Capsule()`): buttons, text fields, the Cleanup key field, the shortcut recorder, toggles, the segmented control's track and segments, sidebar items, the Settings and Quit rows, and the status line's hover fill.
- **Window, popover and first-run window** (`app-window`, `GlassTheme.windowRadius`): 16 pt corners.
- **Raised panels** (`app-container`, `GlassTheme.containerRadius`): 14 pt corners.
- **History rows** (`app-history-row`): 10 pt corners.
- **Keycaps and the cleanup rules editor** (`app-inner`, `GlassTheme.innerRadius`): 8 pt corners.
- **Circles:** status dots (8 pt), status icons (20 pt), the shortcut recorder's clear button (18 pt) and the key field's eye button (20 pt).
- **Menu bar icon:** an 18 × 18 pt template image (macOS tints it for the menu bar) holding a 16 × 9 pt pill outline drawn at 1.5 pt.

## Components

### Pill
- **Listening:** the rim light reacts to your voice through eight bands that lift with loudness; contrast rises from 0.16 when quiet to 1 when speaking. If no speech is heard for 2 s, a 0.2 s pulse of light repeats every 3 s. The pill never changes size for this.
- **Waveform:** 14 points read from the 8 speech bands, laid low to high from left to right and mirrored about the centre line; it holds no history of past sound. Fill runs from `rgba(255, 228, 196, 0.18)` at its top and bottom edges to `rgba(255, 247, 236, 1)` on the centre line, with a glow in `rgba(255, 222, 184, 0.55)` of 1.5 pt spread, all at 95% opacity. Its tallest is 0.85 × (half the pill's height − 5.5 pt), its ends feather over 16%, and each point settles on a 0.22 s spring that does not bounce. It shows when the Live words setting is Off or Bubble above; In the pill, the default, puts the words there instead.
- **Processing:** on release the light travels inward over 150 ms into a line along the centre. The line's brightness falls off from its middle on a bell curve (Gaussian) with a 1 pt spread, about 2.35 pt wide at half brightness, widened by up to 55% with bloom, with an inner glow of 3.2 pt spread at strength 0.1. It is half the pill's width long, but no longer than the pill's straight part allows, and its ends feather over 32%. The line carries the lightened ivory bands. The rim dims to 38% while the line shows. When live words are in the pill, no line is drawn, the rim dims to 60%, and a read-through light 34 pt wide passes over the words once every 0.9 s × √(number of lines).
- **Pasted:** the line turns mint, holds 260 ms, then the pill swells to 1.08 (words 1.05) and collapses over 340 ms, height leading width by 80 ms, fading from 120 ms in. The rim stays at 38% until the hold ends.
- **Appear and hide:** the pill grows from a point over 0.18 s, through a 1.2 pt line, to full height. Hidden without a paste, it leaves in 0.12 s. The swell before the collapse rises in 0.09 s.
- **Words:** each word appears on a spring (damping 0.816, response 0.28 s) with a 2.2 pt rise; leaving words shrink to 0.82 on a 0.45 s spring. Words that would move more than 48 pt on cleanup fade out and back in instead of sliding. Edge fades: 14 pt at the left once the line scrolls (2 pt before), 4 pt at the right, 4 pt at the top of the bubble above. Every word size and distance scales with the pill's height ÷ 28.

### Bubble above
- Splits off the top of the pill while you talk, using the island's size spring, from an 18 pt seed, and grows to fit the words. Its ring is the same light as the pill's rim at 60% brightness; it fades in over the first 15% of the travel, and the text shows from 55%. Its blur runs on a spring of damping 0.816, response 0.3 s.
- When you stop talking it is pulled back into the pill, draining to 9 pt, in mint for a paste, or before the retry bubble splits off for a failed one. On the merge its height responds at 0.36 s, leading the width. When the pill is docked at the top of the screen, the bubble splits off below instead.

### Retry bubble
- Splits off the right of the pill using the island's split spring (damping 0.141, response 0.222 s, 130 ms head start). The bubble scales 1.16 × 1, then 1.12 × 1.08, then 1, with sideways nudges of 2.33, 1.67 and 0.33 island points. The pill swells to 1.08, then 1.11 × 1.10 with a 4 island-point recoil away from the bubble, then settles. The split starts 0.04 s after the state change, or 0.13 s when coming out of processing.
- Hover eases in over 0.09 s and out over 0.16 s: ring tone +0.12, light ×1.4, halo ×1.9, halo reach +0.4 pt. The icon is a 1.6 pt stroke with round caps, in three kinds: send arrow, crossed-out mic, lock. The send arrow shows only on hover; the mic and lock rest at 0.72 and reach 1 on hover.
- A click fires 0.12 s after the press bump starts: a failed paste retries, a lock opens System Settings. A retry that fails again shows soft orange for 600 ms and shakes once by 8 island points (about 6.1 pt) on the shake spring. The paste-last-transcript shortcut flashes the hover look for 0.32 s. VoiceOver reads it as a button: "Paste transcript", "Open Accessibility settings" or "Open Microphone settings".

### Motion
All motion uses the Dynamic Island's springs: mass 1, stiffness (2π ÷ response)², damping ratio × 4π ÷ response.
- **Size changes** (the pill growing with words, shrinking after cleanup): damping 0.816, response 0.512 s.
- **Words sliding into their cleaned-up place:** damping 0.78, response 0.4 s.
- **Removed words leaving, bubble merging back:** damping 0.816, response 0.45 s.
- **Recombine:** damping 0.6, response 0.222 s.
- **Press bump on the bubble:** scale 1.015 × 1.03, damping 0.694, response 0.85 s.
- **Shake:** damping 0.35, response 0.18 s.
- **Words appearing:** damping 0.816, response 0.28 s.
- **Bubble above blur:** damping 0.816, response 0.3 s.

### Reduce Motion
No travel, wobble, bump or shake; sizes jump instead of springing. The retry bubble fades in and out in place over 0.2 s. The bubble above appears at full ring opacity at once, and fades out over its merge while its position resets at once. The band slide stops, bloom no longer spreads and its strength drops to ×0.7, words appear 1.6× faster with no rise, the read-through light is off, and waveform points ease over 0.2 s instead of springing.

### App surfaces
Each control is drawn by the app in Glass colours and reports to VoiceOver as the native control for its job; the toggle keeps a hidden native toggle for VoiceOver. The frontmatter components use the Light keys; in Dark each takes the `-dark` key of the same role. Disabled controls drop to 40% opacity.

#### Buttons
- 28 pt tall, text in `app-label`. Primary and secondary have 16 pt side padding, quiet 10 pt. All three lay `app-hover` over their fill on hover and `app-selected` when pressed.
- **Primary** (`button-primary`): `app-action-primary` fill. Only Done on the first-run window uses it.
- **Secondary** (`button-secondary`): `app-raised` fill with a 1 pt `app-line-strong` outline.
- **Quiet** (`button-quiet`): no fill or outline at rest.

#### Text field
- `text-field`: `app-raised` fill, 1 pt `app-line-rule` outline, value in `app-body`. The placeholder is not styled and takes the system placeholder colour.
- **Focused:** the outline turns `app-line-strong`, the focus ring appears and the field gets a resting lit top edge.
- **Error:** the outline turns `app-state-destructive`. A message under a field is an SF Symbol (`exclamationmark.circle`, `checkmark` or `info.circle`) 6 pt before `app-detail` text, red for errors and secondary text otherwise, 6 pt below the field (8 pt under the Cleanup key field). The shortcut recorder's error shows in its row, between title and detail, instead.

#### Cleanup key field
- A 254 pt capsule with the text field's look, hidden as a password field by default, with a 20 pt eye button to show the key once the field has text and an `app-state-done` checkmark once the key is accepted. The outline turns red only when the key is refused.
- Messages: checking (info), accepted (done), refused (error), offline (info). The key is submitted on Return or when focus leaves.

#### Cleanup rules editor
- 140 pt tall, 8 pt padding, `app-raised` fill, 8 pt corners, 1 pt `app-line-rule` outline or `app-line-strong` when focused, focus ring at 11 pt radius, no lit top edge. A quiet "Restore Default" button above it becomes "Undo" after use.

#### Toggle
- `toggle`: 38 × 22 pt capsule, 2 pt padding, 18 pt knob, 1 pt outline when off. On: `app-action-primary` track, `app-action-on-primary` knob. Off: `app-selected` track with an `app-line-rule` outline, `app-control-knob` knob. Drawn as a button, with a hidden native toggle for VoiceOver.

#### Segmented control
- A 28 pt capsule track on `app-hover` with a 1 pt `app-line-rule` outline, 2 pt top and bottom and 3 pt side padding, 2 pt between segments. Segments are equal-width capsules 24 pt tall with 12 pt side padding, labels in `app-label`: the selected one on `app-raised` with a 1 pt `app-line-strong` outline and the knob shadow, its label in primary text; the others' labels in secondary text. Selection moves over 130 ms. Each segment takes the capsule focus ring. VoiceOver reads it as a native picker. Used for Live words (Off, In the pill, Bubble above) on the General pane.

#### Sidebar
- `sidebar-item` and `sidebar-item-selected`: 28 pt tall, 8 pt side padding, 16 pt icon, 8 pt gap, label in `app-label`. Hover adds `app-hover`; the selected pane is an `app-selected` capsule. The fill changes with no animation.
- The sidebar itself is a column of buttons (a SwiftUI `VStack`), not a system sidebar list: `app-sidebar` fill over the shell, a 1 pt `app-line-rule` on its right edge.

#### Section header
- Title in `app-section`, description 2 pt below in `app-detail` secondary text.

#### Shortcut recorder
- 160 × 28 pt capsule with the text field's look, 5 pt inner padding, 4 pt gaps. Idle: `app-line-rule` outline, "Record Shortcut" in secondary text. Recording: `app-line-strong` outline, focus ring and resting lit top edge, "Type a shortcut…" in primary text. Set: the key's name on a keycap, 18 pt tall in `app-keycap` with 6 pt side padding on `app-selected`.
- Only the paste-again shortcut has a clear button: an 18 pt circle on `app-hover` with an 8 pt bold `xmark`.
- Click, Space or Return starts recording. VoiceOver value: "Recording. Press the key to use.", the key's name, or "Not set".

#### Status marks
- **StatusIcon:** a 20 pt circle with a 10 pt bold glyph in `app-action-on-primary`. Done: `app-state-done` with a checkmark. Attention: `app-state-attention` with an exclamation mark. Info: `app-text-secondary` with an i.
- **StatusDot:** 8 pt. Neutral: `app-text-secondary`. Attention: `app-state-attention`. Hollow: a 1 pt `app-text-secondary` ring, used for "mic kept ready". Live: as in Elevation & Depth.

#### Status row
- 8 pt top and bottom and 12 pt side padding, 12 pt gaps: a status icon, then a title in `app-label` and detail in `app-detail` secondary text. Attention rows carry a secondary button at the right. Used in the Permissions pane and on first run.

#### Words list
- Rows at least 36 pt tall with 12 pt side padding, the word in `app-body`, and a 24 pt trash button that is always present (secondary text colour, primary on hover or focus). Row fill: `app-selected` when focused, `app-hover` on hover. Delete removes a row; the arrows move between rows. After a delete, a "Deleted" line shows with a quiet Undo button.
- At the top of the panel, inset 6 pt: the add field and a secondary Add button.

#### Menu bar popover
- `popover`: shell material, system shadow, resting lit top edge; the edge goes live while the mic is live.
- Status row: 8 pt dot, status in `app-label`, hint in `app-small` secondary text at the right ("Let go to paste" while holding, "Tap <key> to stop" hands-free, "Tap or hold <key>" when ready), then the optional detail line and fix button.
- History row (`history-row`): the transcript in `app-transcript`, at most 2 lines; a meta line "<App> · <time>" in `app-detail` secondary text, kept to one line (cut in the middle when too long) so the row never changes height; a "Click to paste" tooltip on the row; an optional note in `app-small` ("Not pasted", "Raw transcript · …"). A 24 pt copy button is always visible and shows an `app-state-done` checkmark for 260 ms after a copy. Fill: `app-hover` on hover (`history-row-hover`), animated over 130 ms, `app-selected` when focused. Arrows move, Return pastes, Command-C copies.
- Settings… (⌘,) and Quit Fluidity (⌘Q) rows: 28 pt capsules, shortcut in `app-small` secondary text, `app-selected` on hover with no animation.
- The panel closes at once, with no animation.

#### Menu bar icon
- An 18 × 18 pt template image: a 16 × 9 pt pill outline at 1.5 pt with round caps. Ready: the outline alone. Recording: the pill filled. Mic kept ready: an inner 9.5 × 3.5 pt capsule. Cleanup off: a 6.5 pt dot at the lower right with 1.25 pt of clear space around it. Permission missing: a diagonal slash with 1.25 pt of clear space on each side.
- Each state has its own VoiceOver description, such as "Fluidity, listening".

#### Settings window
- `settings-window`: shell material, system shadow, resting lit top edge; the edge goes live while the mic is live. The title bar is transparent, the title hidden, and the window drags by its background.

#### First-run window
- `first-run-window`: laid out as in Layout, on the shell with a system shadow and a resting lit top edge that goes live while the mic is live.
- The Speech model row's icon is info while downloading, done when ready and attention on error.
- The dictation key group is disabled until both permissions are allowed. Done is the default button for Return.

#### Motion
- 130 ms ease-in-out for hover, press, the toggle and the pane cross-fade (`GlassTheme.snap`); 260 ms hold for the copy checkmark (`GlassTheme.hold`).
- Sidebar items and the Settings and Quit rows change fill with no animation; the popover closes with none. No other durations or springs exist in the app surfaces, and the app windows do not read Reduce Motion.

### Designed in Figma, not yet in code
These are in the published Figma library and were not built for version 1:
- Pop-up button and its open menu: 28 pt, 12 pt left and 8 pt right padding, 16 pt chevron; the menu opens 4 pt below on the shell with 14 pt corners and a resting lit top edge, 24 pt capsule items, a 16 pt check column.
- Two-line pill: 46 × 360 pt.
- The Elevation/Float shadow: 0 8 pt 24 pt, black at 16%.
- The spacing scale 2, 4, 8, 12, 16, 20 pt.
- The Motion collection's enter 180 ms, exit 150 ms and collapse 340 ms, and its 130 ms Reduce Motion cross-fade.
- The popover's model line, and the Dictation and Models panes (version 2).

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
- **Don't** widen the rim past 1.2 pt plus 0.95 pt of voice, or its halo past 3 pt outside the collapse.
- **Don't** scale or bounce the pill to say it can't hear you; pulse the light instead.
- **Don't** keep the pill on screen when the user isn't dictating.
- **Don't** blend ivory into mint; switch at once. Amber eases in over 0.28 s and orange over 0.06 s, and no change may pass through grey.

### App surfaces
- **Do** build the shell of the window, the popover and the first-run window from one material: `app-window` over macOS's behind-window material, with no fixed blur.
- **Do** draw the lit top edge on floating panels only: the window, the popover, the first-run window, a focused text field or shortcut recorder.
- **Do** make every control a capsule, except history rows (10 pt corners) and the rules editor and keycaps (8 pt).
- **Do** make every control the app draws report to VoiceOver as the native control for its job.
- **Do** opt every focusable control into the Glass focus ring; the system ring is off.
- **Do** keep at most one filled button per window.
- **Don't** put a blurred or frosted panel inside the shell; raised panels are plain fills.
- **Don't** draw the lit top edge on rows, raised panels, buttons, the sidebar or the rules editor.
- **Don't** set secondary text in a neutral grey; use `app-text-secondary`.
- **Don't** use `app-state-done-light` for text; at 4.11:1 it colours icons only.
- **Don't** add another colour of light; ivory is the only light, and mint and amber appear only for states.
- **Don't** fade the lit top edge or the status dot between ivory and a state colour; switch at once.
- **Don't** add a drop shadow of your own; the system window shadow is the only one.
