# Shared brief for competitor researchers

Context: we are building Fluidity, a native macOS dictation app. Hold a key (or similar), speak, the text is pasted at the cursor in whatever app has focus. Local speech models by default; optional cloud cleanup with the user's own API key; user word lists. Benchmark competitor: Wispr Flow. Today is 2026-10-23.

Goal of the whole study: map the gamut of "press-key-and-talk, text lands in any app" dictation tools from full-suite to minimal, down to the exact feature, so the owner can decide what a mid-range and a high-range offering must include.

## What to produce (per product)
Write ONE markdown file per product at the path you are given. Each file has:

1. Header: product name, vendor, platforms, URL, date checked, your one-line placement on the gamut (minimal / mid / full-suite) with a one-sentence reason.
2. Pricing: every tier, price, billing period, what each tier gates, free-tier limits (words/minutes per week, trial length), lifetime/BYO-key options, team/education plans. Exact numbers and currency.
3. Feature inventory, using the vendor's OWN names for features (quote them), grouped under these fixed headings so results merge across researchers:
   - Trigger & capture: hotkey style (hold / toggle / double-tap / hands-free), configurable keys, menu bar vs Dock, mic selection, system-audio handling, push-to-talk from other devices.
   - Transcription engine: local models offered (names, sizes), cloud models offered (names, providers), languages count, auto language detection, model switching UI, speed/latency claims.
   - Live preview: are words shown while speaking? Where (floating pill/overlay/inline)? Can they change after?
   - Cleanup & formatting: filler removal, self-correction handling ("no wait, I meant"), punctuation, paragraphing, lists/numbers formatting, per-app formatting/tone, custom prompts or "modes", context awareness (reads screen / selected text / clipboard / app name).
   - Personalization: custom dictionary/vocabulary, text snippets/expansions, auto-learning from edits, replacements, per-app rules.
   - Output & editing: paste into any app, clipboard fallback, undo, transcript history/search, edit-before-paste, retry.
   - Voice commands: editing by voice, "new line/paragraph", command mode, app control.
   - Beyond dictation: file transcription, meeting/system-audio recording, notes, summaries, translation, AI chat/rewrite of selected text.
   - Platforms & sync: macOS / Windows / iOS / Android / Linux / browser extension; cross-device sync; minimum OS; Apple Silicon vs Intel.
   - Privacy & data: on-device only mode, what leaves the machine, retention, training opt-out, SOC2/HIPAA claims, encryption.
   - Onboarding & permissions: how Microphone and Accessibility prompts are handled, first-run tutorial.
   - Accessibility: VoiceOver / keyboard-only / Voice Control claims.
   - Distribution: direct download, Mac App Store, Setapp, Homebrew, open source (license).
   Under each heading list every feature as its own bullet, with "(free)" / "(Pro)" / "(tier name)" gating tags, and a source URL. If a heading has nothing, write "none found" and say where you looked.
4. Recent changes: anything shipped or announced in the last 12 months (changelog/release notes/blog), with dates.
5. User reception: 5 to 10 bullets of what reviewers and users praise and complain about (App Store, Reddit r/macapps, Hacker News, Product Hunt, X). Quote short, link each.
6. Gaps you could not verify: list them plainly. Never guess a feature exists.

## Rules
- Primary sources first: the vendor's site, docs, changelog, pricing page, App Store listing, GitHub README. Reviews only for the reception section.
- Use WebSearch (standard mode first, extended when thin) and WebFetch. Fetch the actual pricing and feature pages; do not rely on a search snippet.
- Exact feature names, exact prices, exact limits. "Has AI formatting" is useless; "'Auto-edits' removes filler words and fixes self-corrections (Pro, $12/mo)" is what we need.
- Record a URL for every claim. Record the date the page was checked.
- Do not invent features, numbers or quotes. If unsure, put it under "Gaps".
- Do not start your own subagents.
- Think at medium effort. Thoroughness beats speed, but stop once every heading is filled or marked "none found".
- When all files are written, reply with: the list of files written, a 3-line placement summary per product, and the 5 features that most surprised you across your set. Keep the reply under 400 words; the detail lives in the files.
