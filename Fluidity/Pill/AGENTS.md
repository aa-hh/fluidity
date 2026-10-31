# Pill

## Purpose

The recording pill: a click-through panel docked at the bottom centre of the
screen, a Metal rim, live words drawn as text over it, and the bubbles that
split off it. `PillPresenter` maps `PillState` onto the rim's own states; it
holds no dictation logic.

## Rules

- **Every spring, timing, colour, size and shader constant here is approved.**
  The files were ported from the pill Alec tuned for FluidWispr. Change a
  value only on Alec's word, and check it against `DESIGN.md` (Pill, Bubble
  above, Retry bubble, Motion, Reduce Motion); if the two disagree, ask.
- **`RimUniform` offsets and the `#define`s at the top of `PillShader` are
  one table.** Moving a slot in one without the other draws garbage, with no
  compile error.
- **The panel never takes a click.** Only `PillBubbleTarget`'s own small
  panel does, while a bubble waits; making the pill's panel clickable would
  swallow clicks meant for the app underneath.
- **`PillPresenter.feed` runs off the main actor** and from one task at a
  time: `RimAudioAnalyzer` keeps its filter state unlocked for speed.

## Map

- `PillPresenter` → `PillState` to rim states, frames, placement.
- `PillWindow` → the panel and its two views.
- `PillRenderer`, `PillShader` → Metal drawing of the rim.
- `PillWordsView` → live words as text layers.
- `PillBubbleTarget` → hover and click on the waiting bubble.
- `RimSimulation` → the rim's per-frame state and shader values.
- `RimBubble`, `RimWordsBubble` → bubble beside the pill, bubble above it.
- `RimWords` → live words layout, scroll and cleanup diff.
- `RimAudioAnalyzer`, `RimFeatureExtractor` → microphone audio to voice bands.
- `RimParameters`, `RimSpring` → approved values and the island spring.
- `PillPreview` → shows one state from `FLUIDITY_PILL_PREVIEW`, to check by eye.
- `PillSampleView` → scripted pill drawn inside the settings window.
