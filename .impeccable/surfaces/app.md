---
version: 1
slug: "app"
primary_target: "app"
related_targets: []
---

# Surface brief: the app (settings window, menu bar popover, first-run setup)

Mode: Operate. The person came to change one setting, check why the mic is off, or grant a permission, then get back to the app they were in. Scanability and native macOS expectations outrank expression.

Job and audience: heavy typists, developers, people who cannot type easily, privacy-minded people; all on their own Mac, often with the pill floating over another app at the same time. Core tasks (start and stop dictation, pick a model, edit word lists, grant Microphone and Accessibility) must work with VoiceOver, Voice Control and Full Keyboard Access and never need long typing or precise pointing.

Scope: the settings window (sidebar: General, Dictation, Models, Cleanup, Words, Permissions), the menu bar popover, and later the first-run permission flow. The recording pill is designed and approved separately on the "Recording pill: Rim (approved)" Figma page and is not touched by this brief.

Source of truth: Figma file 5JcAX6bwl48LqQhqcUuGOJ, pages Tokens, Atoms and Style Guide (the former "D4 · Glass" direction, chosen 23 Oct 2026 from five candidates: Lantern, Typeset, Studio, Glass, Signal).

Open product decisions shown as settings with defaults, not decided here: how dictation starts (shortcut, menu bar, or both), where the app lives (menu bar, Dock, or both), which models ship.

## Direction contract

THESIS: The app is built from macOS's own translucent material and floats over other apps the way the pill does; colour exists only as light caught on edges. It refuses the category default of an opaque grey settings window with one accent colour.

OWN-WORLD: Translucent white (72%) or near-black (72%) shell over a 40 pt background blur; opaque raised surfaces inside; warm-tinted secondary text, never grey; capsule controls everywhere; SF Pro Rounded for titles, sidebar and labels, SF Pro for body. The pill's ivory #FFE4B8 is the only light; mint, amber and soft orange are the state colours, as on the pill. With all content removed it is recognisable by the 1 pt ivory line along the top edge of every panel.

STORY: The visitor sees a standard macOS settings window, finds the row they came for in seconds, and understands from the lit top edge and the status line that the app is listening or ready; they leave trusting that it is one system with the pill.

FIRST VIEWPORT: 720 × 520 window, 184 pt sidebar on the left with six panes, General selected as a capsule; content pane titled "General" with two grouped sections, Dictation (shortcut recorder, show-in pop-up, launch toggle) and Recording pill (size segmented control, position pop-up, a Reduce Motion note); status line "Ready · ⌥ Space" at the sidebar's foot. The primary action on a pane is the one filled capsule button, bottom right of its section. Menu bar popover 280 wide: status row, last transcript, model line, Settings and Quit.

FORM: Chosen direction out of five built candidates (Glass, ranked first by the orchestrator; Lantern the alternate). seed: none (unavailable). Signature interaction: the lit top edge, resting as a faint ivory line, brightening to the pill's four-tone rim with a 2.6 pt halo while the mic is live; motion uses the Motion collection's springs copied from the pill.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance.
