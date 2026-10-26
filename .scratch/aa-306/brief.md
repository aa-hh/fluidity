# AA-306 design discovery: shared brief for the team

Goal (Linear AA-306, https://linear.app/aa-hh/issue/AA-306): explore, then propose, every version 1 screen and state of Fluidity in the Glass system, as labelled explorations on a new Figma page "Discovery · version 1", with a recommended option for each. Alec picks. Nothing goes to Tokens, Atoms or Style Guide. Version 1 is for Alec only; version 2 (friends) screens are out of scope.

Repo (Fluidity worktree, where written output goes): /Users/alechenderson/Projects/Fluidity/.claude/worktrees/design-discovery-v1-screens-842bfb
Read there first: PRODUCT.md, CONTEXT.md (the vocabulary), DESIGN.md, .impeccable/design.json, .impeccable/surfaces/app.md.
Linear decisions to read with get_issue: AA-306 (the spec), AA-296 (features), AA-298 (cleanup), AA-297 (saved data and corrections), AA-301 (Glass system), AA-302 (architecture).
Motion reference: "/Users/alechenderson/Documents/# Dynamic Island look and motion (iOS 26.4 simulator build).md".

## 1. Locked: the recording pill as written in FluidWispr

The overlay to lock onto is the one written for FluidWispr itself, in
/Users/alechenderson/Projects/FluidWispr/Sources/Fluid/UI/RecordingPill/
- RimParameters.swift: every value (the approved tuning, palettes, sizes, timings, springs, bubble geometry, press bump, shake, nudge).
- RimSimulation.swift: `RimState` = idle, listen, think, done, problem, flux (paste failed, transcript waits in a bubble), pasted (retry landed), fixed (permission fix taken).
- RimBubble.swift, RimWords.swift, RimWordsBubble.swift, RimWaveform.swift, RimDrag.swift, RimFluidCollapse.swift, RimSpring.swift, RecordingPillController.swift (states, bubble actions, accessibility labels such as "Open Accessibility settings", "Open Microphone settings", "Fix microphone").
FluidWispr also still carries FluidVoice's old overlays: Sources/Fluid/UI/RecordingView.swift, MeetingRecordingPill.swift, FluidOverlayPrimitives.swift, the Prototypes/OverlayOnboarding folder. Those are NOT the reference. Ignore them.

Locked values (from RimParameters.swift; the pill sections of Fluidity's DESIGN.md say the same):
- Pill body #0E0F13 on every background, no shadow, no border, no fill colour. Colour lives only in the light.
- Light: ivory #FFE4B8 #FFF6EA #FFCFA0 #FFEBD2, the only light. States replace it at once (never a fade, it passes through grey): pasted mint #3EDC8A #9CEFB2 #79EFCF #B4EE62; problem amber #FFB020 #FFCF6A #FF8A00 #FFC24D; retry failed orange #FF9A5C #FFB27E #FF8B57 #FFC196.
- Sizes: Small 86×20, Medium 120×28, Large 156×36 pt. Grows with live words up to 360 pt; two-line 46 pt.
- Rim 1.2 pt (never over 1.5), halo reach 2.6 pt (never over 3), intensity 1.4.
- Timings: snap 130 ms, download/exit 150, appear/enter 180, green hold 260, collapse 340, hide 120, fail flash 600, shortcut flash 320. Reduce Motion: no travel, 130 ms crossfade.
- Springs: size 0.816/0.512 s, collapse 0.816/0.45, words 0.78/0.4, split 0.141/0.222 with 130 ms head start, press bump 1.015×1.03 at 0.694/0.85, shake 8 island pt once.
- Bubbles: paste-failed bubble splits off the right (gap 8 island pt, blob 6.67→3.33); the fix bubble (mic lost, permission revoked) shows a microphone or lock icon at all times; hover = glow + send arrow; click = retry / open the right System Settings page.
- "Can't hear you": a 0.2 s pulse of light after 2 s of silence, every 3 s. Never scale or bounce for this.
- Live words: setting Off / In the pill (default) / Bubble above; waveform inside the pill whenever words are not in it.
- Dock: centred, 12 pt above the bottom edge; six dock spots; drag with a 0.3 s fling.
- Island distances scale by pill height ÷ 36.67.
Figma: Fluidity file 5JcAX6bwl48LqQhqcUuGOJ page "Recording pill: Rim (approved)" (27:2, component set 27:82). NEVER edit it. The FluidWispr Figma file jjO7qOaAWB7xjxTC6jb4kR holds the same pill plus page "Recording pill: Live words (approved)" (70:2, set 70:106); read-only.
FluidWispr notes worth reading: /Users/alechenderson/Projects/FluidWispr/.memory/notes/visual-direction.md, live-words-pill.md, pill-rim-handoff.md, dynamic-island-waveform.md.

Rule for everything else: the app borrows from the pill and never restyles it. Its colours, its control heights (20/28/36), its timings and springs, and three named rules: ivory means live (ivory only where the mic is live), colour is for state (mint, amber, soft orange; a screen at rest is neutral. Red: the Glass atoms already use state/destructive for a field error, see Text field State=Error, so field errors default to red; whether a refused Cerebras key is red or amber is an open question for Alec), switch never fade (ivory to a state colour snaps). Never introduce a second light colour, a new timing, a new spring, a new state colour, a new typeface. If a design needs something the pill doesn't have, that is an open question for Alec, not a decision.

## 2. Also fixed: the Glass app direction (Alec chose it 23 Oct 2026)

Fluidity's DESIGN.md "App surfaces" parts and .impeccable/surfaces/app.md describe it. Figma pages in file 5JcAX6bwl48LqQhqcUuGOJ: Tokens (2008:402: colour roles surface/window, surface/sidebar, surface/raised, surface/selected, surface/hover, line/rule, line/strong, text/primary, text/secondary, action/primary, action/on-primary, state/done, state/attention, state/retry, state/destructive, live, control/knob, focus/ring, each Light and Dark; type styles Glass/Title, Section, Label, Body, Transcript, Detail, Small), Atoms (2007:400: Icon/General, Dictation, Models, Cleanup, Words, Permissions, Chevron up down, Check, Info, Close; Button Primary/Secondary/Quiet × Default/Hover/Pressed/Disabled; Toggle; Text field Default/Focused/Error; Pop-up button Default/Open; Segmented control; Sidebar item Default/Hover/Selected; Section header; Shortcut recorder Idle/Recording/Set; Status row Done/Attention/Retry; Focus ring; Menu bar popover Ready/Listening), Style Guide (2008:403).
The Atoms page carries six panes (General, Dictation, Models, Cleanup, Words, Permissions) and a popover with a model line: those predate the version 1 decisions. Version 1 has four panes (General, Cleanup, Words, Permissions), no model line, and a popover listing the last 20 or so dictations.
Use atoms as instances. When nothing fits, make a new component on the discovery page, named the same way (Family/Variant), rather than overriding an instance. Content in an instance's slots is fine.

NOT a reference: FluidWispr's own window design ("The record": /Users/alechenderson/Projects/FluidWispr/DESIGN.md window sections, Sources/Fluid/Theme/Record/). Fluidity's app is Glass; only the pill crosses over. One candidate worth carrying across, as an option not a decision: FluidWispr's Sources/Fluid/UI/MenuBarGlyph.swift already draws an 18×18 pill-outline menu bar icon with ready / dictating / microphoneProblem / updateWaiting states.

## 3. Product facts for version 1 (do not re-decide)

- Menu bar app, no Dock icon; a popover (280 pt wide), a settings window (720×520, four panes), the recording pill, a first-run check. macOS 26 or later. SwiftUI.
- One customisable key starts dictation, any key including left or right Command or Option on its own. Tap = hands-free until the next tap; hold = talk until release. Escape cancels: nothing is pasted.
- Speech: Parakeet TDT v2 on the Mac. No model picker in version 1.
- Cleanup: Cerebras gpt-oss-120b with the user's key (Keychain), on as soon as a key is entered, editable rules with "restore default", a line saying text goes to Cerebras's US servers which keep nothing. Slow (about 1 s), offline, or fails its output check → fallback: the raw transcript is pasted. States: no key, key invalid, offline.
- Mic stays warm 3 minutes after a dictation (macOS shows its orange dot).
- Popover: status row, then the last 20 or so dictations, each one click to copy or paste again into the app with focus; show which app it went to and when; empty history; Settings and Quit.
- Settings panes: General (shortcut recorder, tap-versus-hold made clear, launch at login), Cleanup, Words (personal word list: add/edit/delete, one word or name per row, workable without long typing or precise pointing), Permissions (Microphone and Accessibility with live granted state and a button opening the right System Settings page). Status line at the sidebar's foot.
- First-run: a bare check of Microphone and Accessibility with a live granted state, then the shortcut. No tour.
- Saving to the Space drive is silent: no training-data UI.
- Out of scope: consent screen, data review, model library, history window, mic picker, floating copy panel, the dictation game.
- Vocabulary (CONTEXT.md), use exactly: live preview, raw transcript, cleaned text, pasted text, final text, fallback, correction, cleanup.

## 4. Rules for every team member

- Figma only for explorations, on the page "Discovery · version 1" (the atoms agent creates it once; everyone else finds it by name). Each exploration is its own frame labelled with the date (2026-10-25), what it tries, and a status (`open` to start; Alec sets `liked`, `rejected`, `chosen`). Light and dark for every screen. Follow Apple's Human Interface Guidelines for macOS; load the `impeccable` skill for ideation and critique (its iOS guidance does not apply). Every core task must work with VoiceOver, Voice Control and Full Keyboard Access, and never need long typing or precise pointing.
- Figma mechanics: load the `figma:figma-use` skill before any use_figma call; call create_session first (fileKey 5JcAX6bwl48LqQhqcUuGOJ, capital Q after "Lq", or every call fails). Never write to Tokens, Atoms, Style Guide or "Recording pill: Rim (approved)". Prefer get_metadata and get_screenshot to see what exists. Verify what you built with get_screenshot.
- Written output goes in /Users/alechenderson/Projects/Fluidity/.claude/worktrees/design-discovery-v1-screens-842bfb/.scratch/aa-306/<your-name>.md. Plain words, no invented terms (if something needs a name, write "I'll call this X" and keep it tentative), no em dashes, no acronyms of your own, use the CONTEXT.md vocabulary.
- You do not decide product scope. AA-306 is the spec; the Linear decisions above are decisions. Where the spec is silent, write it down as an open question for Alec and pick a reasonable default for the exploration, labelled as such.
- Team: `product` (needs and the state inventory), `atoms` (tokens and atoms audit, new atoms), `components` (composed controls), `screens` (every screen and state). Message a teammate with SendMessage to their name when you have a finding they need or a question only they can answer. Do not sit idle waiting for a reply: carry on and reconcile when it arrives. Record every message you sent or received in a "Team messages" section at the end of your file.
- Finish by reporting: files written, Figma node IDs created (page, every frame, every component), open questions for Alec, and anything you could not verify. Say "done" only for what you checked yourself with a screenshot or a read-back.
