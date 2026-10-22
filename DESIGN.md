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
rounded:
  bubble-cap: "14px"
spacing:
  pill-pad-x: "13px"
  bubble-pad-x: "10px"
  bubble-pad-y: "7px"
  bubble-gap: "6px"
  retry-bubble-gap: "8px"
  dock-margin: "12px"
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
---

# Design System: Fluidity

All sizes are macOS points; `px` in the frontmatter means points. Source: the approved "Live words" pill page (claude.ai/artifact/T99ohW8MS4hmonR6swB4C2, its `rim.js` defaults dated 2026-10-21) and the Dynamic Island notes read from the iOS 26.4.1 simulator (`~/Documents/# Dynamic Island look and motion (iOS 26.4 simulator build).md`).

This covers the dictation pill only. The settings window, menu bar menu and first-run setup have no design yet; don't extend these values to them without a design pass.

## Overview

**Creative North Star: "Bright future"**

Fluidity shows one thing on screen: a small near-black pill, docked 12 pt above the bottom edge of the screen, that appears only while you dictate. Its edge is a thin ring of ivory light that brightens, drifts and blooms with your voice. Your words appear inside the pill, or in a bubble that splits off above it. When you let go, the light travels inward and becomes one line through the centre while the text is cleaned up. When the paste lands, the line turns mint green, holds for 260 ms, and the pill collapses and is gone.

The shape and motion come from the iPhone's Dynamic Island. The pill's sizes and springs, and the way the bubble splits off and merges back, all use values read from SpringBoard, so it moves like a system part of the Mac rather than an app's window. The body stays the same near-black on any background, and the light is the only colour.

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

## Typography

**Body Font:** SF Pro Text, the macOS system font, regular weight (400), with kerning on.

**Character:** One face at small sizes. The text is read in a glance while you talk, so it stays plain and the light carries the expression.

### Hierarchy
- **Pill words** (400, 13 pt, 17 pt line): one line by default; two lines when the user picks that setting, after which it scrolls a line at a time. The oldest words fade out at the left edge once the line scrolls.
- **Bubble words** (400, 11 pt, 14.5 pt line): up to six lines, then it scrolls up a line at a time. The oldest fade out at the top.

Changed words cross-fade and glow briefly (`text-shadow` 5 pt in `rgba(255, 238, 214)`, strength 0.6 for new words, 0.21 for revised ones). Words arrive in batches every 0.6 s, 35 ms apart within a batch.

## Layout

- **Dock:** the pill centres horizontally, 12 pt above the bottom edge of the screen, and grows upward from there.
- **Pill:** 28 pt tall at rest and 120 pt wide, growing with the words up to 360 pt; 13 pt side padding. Two-line layout: 46 pt tall at the full 360 pt.
- **Bubble above:** sits 6 pt above the pill, up to 300 pt wide, 10 pt side and 7 pt top/bottom padding.
- **Retry bubble:** when a paste fails, the transcript waits in a round bubble the height of the pill, 8 pt to the right of it.
- **Scaling rule:** distances copied from the Dynamic Island are in island points and scale by the pill's height ÷ 36.67 (the island's resting height).

## Elevation & Depth

No drop shadow. Depth comes from light: the rim is a 1.2 pt line of light with a soft halo reaching 2.6 pt outward. The rim width never exceeds 1.5 pt and the halo never exceeds 3 pt, including the extra glow on hover.

When the bubble splits off or merges back, the shapes are blurred together and cut at an opacity threshold so they melt into one outline, as the Dynamic Island does. The blur radius is 6.67 pt, easing to 3.33 pt as the bubble settles.

## Shapes

- **Pill:** a full capsule, corner radius half its height, with Apple's continuous corner curve.
- **Bubble above:** corner radius half its height, capped at 14 pt, continuous curve.
- **Retry bubble:** a circle.

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
