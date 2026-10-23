# Monologue

- **Vendor:** Every Media Inc ("Every"), sold alone or inside the Every bundle
- **Platforms:** macOS, iPhone, iPad, Apple Watch. No Windows or Android ("no date has been announced")
- **URL:** https://www.monologue.to (docs: https://www.monologue.to/docs, machine-readable: https://www.monologue.to/llms.txt and https://www.monologue.to/docs/llms-full.txt)
- **Date checked:** 2026-10-23
- **Placement:** full-suite, Apple-only. Dictation with app/website-aware "Modes", screen-reading "Deep context", an in-house model ("mono-1"), offline local transcription on Mac, plus Voice Notes, bot-free meeting capture with speakers and summaries, and MCP/API/CLI access to notes. Missing: Windows/Android, auto-learning from edits, editing selected text by voice (only a beta "Compose").

## Pricing

Source: https://www.monologue.to/pricing.md (last updated 2026-08-06), https://www.monologue.to (checked 2026-10-23)

| Tier | Price | What it includes |
|---|---|---|
| Free trial | $0 | "1,000 dictation words", "10 recorded notes", "offline transcription", "context-aware formatting", "100+ languages". Allowance is a one-time trial, not weekly |
| Monologue Pro | $15/month billed monthly, or $144/year ($12/month equivalent, "save 20%") | "Unlimited dictation", "Unlimited recorded notes", "Bot-free meeting notes", Mac, iPhone, iPad and Apple Watch apps |
| Every Bundle | price not on Monologue site | "Monologue Pro is also included in Every's bundle with Cora, Spiral, Proof, and Sparkle" |
| Team | price not listed | "Team: Your organization gives you Pro access"; team admin handles billing. https://www.monologue.to/docs/account-and-privacy/account-and-billing |

- Currency USD; sales tax may be added by billing address. https://www.monologue.to/docs/account-and-privacy/sales-tax
- Purchase sources: Apple App Store, direct (billing portal), Every, Team. https://www.monologue.to/docs/account-and-privacy/account-and-billing
- Free accounts see "lifetime usage, remaining quota" (macOS v1.0.45, 2025-09-15). https://www.monologue.to/changelog
- Lifetime, BYO key, education plans: none found.
- Monologue's own comparison: "Teams | Centralized billing; personalization remains user-level". https://www.monologue.to/compare/wispr-flow.md

## Feature inventory

### Trigger & capture
- "Push to talk": hold, release to finish; default right-side Option; can bind "a different modifier, key combination, function key, or supported mouse button"; left/right modifiers distinguished (Free trial and Pro). https://www.monologue.to/docs/dictation/shortcuts
- "Hands-free dictation": tap once to start, again to finish; separate bindings, keyboard or mouse button. Same.
- "Cancel dictation" shortcut; "Paste last transcript" shortcut. Same.
- "Mode picker": tap right Shift while dictating, choose with arrow keys or 1–9 (macOS v1.0.66, 2026-03-06). Same; changelog.
- Default push-to-talk binding can be removed (v1.5.1, 2026-09-28). https://www.monologue.to/changelog
- URL scheme to trigger recording from other apps (v1.0.38, 2025-08-11). Changelog.
- Recording indicator: "Classic" (screen edge), "Mini" (near the text), "None"; and "Dot", "a new recorder that stays close to where you're writing and moves with you" (v1.5.0, 2026-08-24); earlier "Following Cursor mode" (v1.2.0, 2026-05-25). https://www.monologue.to/docs/dictation/mac-preferences, changelog
- Menu bar app, with optional "Show dock icon". https://www.monologue.to/docs/dictation/mac-preferences
- Mic selection: automatic, or "arrange connected microphones in priority order", live level meter. https://www.monologue.to/docs/dictation/microphones-and-audio
- Other audio: "Keep other audio playing, mute it temporarily, or pause and resume it", set per output device (v1.4.2, 2026-08-07). Same; changelog.
- "Prevent sleep" during recordings. https://www.monologue.to/docs/dictation/mac-preferences
- System audio: for Voice Notes on Mac only, needs Screen Recording permission. https://www.monologue.to/docs/voice-notes/record-a-note
- iPhone: custom keyboard; "Quick Dictation" from Action Button ("Dictation to Clipboard" shortcut), Apple Shortcuts, Control Center, Live Activities. https://www.monologue.to/docs/iphone-and-ipad/action-button-and-shortcuts
- Apple Watch: records Notes and syncs them (changelog iOS v1.0.5, 2026-04-20). Changelog.

### Transcription engine
- "mono-1": in-house dictation model, introduced 2026-09-23. "7.22% word error rate" on WildSpeech-Bench (second-lowest tested; GPT-4o Transcribe 6.68%), "median raw-transcription response time was 109 ms", "about 55% fewer estimated edits" (13.64 → 6.21 per 100 words) and "3× faster" than the previous API pipeline (vendor-run benchmarks). https://www.monologue.to/blog/introducing-mono-1
- "Remote transcription is the recommended default and generally provides the best accuracy." https://www.monologue.to/docs/dictation/languages-and-models
- Local on Apple-silicon Macs: "Local" under Settings → Dictation → Transcription source; Parakeet v3 "on-device transcription across 25 languages" (v1.0.50, 2025-10-24); "full Whisper language support" (v1.2.1). Docs; changelog.
- Local limits: "Smart cleanup and context-aware formatting still use Monologue's online service." Docs.
- "Blazing Fast": skips smart post-processing for a raw transcript, can auto-activate for chosen apps/sites (v1.0.68, 2026-03-27). https://www.monologue.to/docs/personalize/modes-and-instructions
- Languages: "100+ languages", "switch languages in the middle of a sentence"; "Auto Detect" or "select up to three languages". https://www.monologue.to/docs/dictation/languages-and-models
- Model switching UI: Transcription source (Remote/Local); mode picker picks Default / Blazing Fast / custom modes.
- Enterprise API: private-beta batch and realtime WebSocket dictation API for approved organizations (powers Sandbar's "Stream" ring). https://www.monologue.to/docs/enterprise-api

### Live preview
- iOS: "Real-time dictation is now the default for a faster writing experience" (iOS v1.1.2, 2026-08-15). Changelog.
- Mac: changelog mentions a "floating transcript panel" (v1.0.65, 2026-03-03). Whether it shows words as you speak is not documented.
- "For longer smart dictations, Monologue now prepares screen context and mode instructions before you stop speaking" (v1.5.1). Changelog.

### Cleanup & formatting
- Cleans "punctuation, casing, filler words, and false starts according to your selected mode". https://www.monologue.to/docs/getting-started/first-dictation
- Self-correction: "Let's meet at six, actually six thirty" → "Let's meet at 6:30" (illustrative). https://www.monologue.to/blog/introducing-mono-1
- Spoken formatting: "new paragraph" handled inside dictation; spoken lists become lists (illustrative). Same.
- "Modes": "tell Monologue how you want a dictation rewritten", e.g. messaging, email, project-update modes; custom instructions. https://www.monologue.to/docs/personalize/modes-and-instructions
- Per-app/website activation: "a mode can activate automatically for selected apps or websites … `chatgpt.com`"; "Override default". Same.
- "Dictation instructions": global custom instructions, e.g. regional spelling. https://www.monologue.to/docs/personalize/australian-or-british-english
- "Auto enter": simulate a send key after processing. https://www.monologue.to/docs/personalize/modes-and-instructions
- Coding mode: "a dedicated coding mode preserves technical identifiers, code, and commands". https://www.monologue.to/dictation.md
- Context awareness: "Deep context" (also "DeepContext") uses on-screen content via optional Screen Recording; "Fullscreen OCR" (v1.0.65); text-context support in Firefox, Zen, Citrix (v1.0.66); app and URL detection. https://www.monologue.to/docs/account-and-privacy/permissions-and-privacy, changelog
- "Smart spacing now responds to the cursor context" (v1.0.55, 2025-12-02). Changelog.
- "About Me" (up to 10,000 characters) for note summaries and names. https://www.monologue.to/docs/voice-notes/organize-edit-and-share

### Personalization
- "Dictionary": add words and replacements for "spoken form and written form". https://www.monologue.to/docs/personalize/dictionary
- Dictionary import "from Aqua Voice, Wispr Flow, Superwhisper, and Willow Voice". Same.
- Dictionary and modes sync "across signed-in Macs" (v1.0.60, 2026-02-06) and are said to sync across Apple devices (dictation.md). One iOS reviewer says they don't sync to iOS (see reception).
- Auto-learning from edits: "Not automatically from your edits" (vendor comparison). https://www.monologue.to/compare/wispr-flow.md
- Snippets / text expansion: none found.

### Output & editing
- Inserts into the active app; if the app or field changed, leaves text on clipboard and shows "Copied" or "App changed". https://www.monologue.to/docs/dictation/history
- "Leave transcript on clipboard" option; "Support non-standard keyboards" compatibility paste. https://www.monologue.to/docs/troubleshooting/dictation-and-pasting, https://www.monologue.to/docs/dictation/mac-preferences
- "Paste last transcript" without replacing clipboard (v1.0.43, 2025-09-08). https://www.monologue.to/docs/dictation/history
- History ("Dictations"): copy, play source audio, retry, delete, reveal file, thumbs feedback. Same.
- Insertion at the start location even if you switch apps while recording (Dot, v1.5.0). Changelog.
- Edit-before-paste: none found.

### Voice commands
- "Compose Beta: Use your voice to write or edit text with Compose, available when Beta Mode is enabled" (v1.5.1, 2026-09-28). Changelog.
- Spoken formatting phrases ("new paragraph") inside normal dictation (illustrative, mono-1 post).
- Command mode / app control: none found.

### Beyond dictation
- "Voice Notes": long recordings with pause/resume, transcripts, summaries, speaker separation, tags with "Automatic note tagging", search, public share links, web app. https://www.monologue.to/docs/voice-notes/record-a-note
- "Bot-free meeting notes" (Pro): microphone plus system audio, "Meeting detection" for calling apps including FaceTime, Phone, Google Meet Chrome apps. Docs; changelog.
- Recording length options for Notes: 30 min up to 6 hours (v1.5.0, v1.5.1). Changelog.
- Save original audio of a note (v1.5.0). Changelog.
- MCP server `https://api.monologue.to/mcp` (read-only `notes:read`), CLI, public Notes API, webhooks where enabled. https://www.monologue.to/docs/integrations/choose-a-connection
- iOS 27 Siri AI, Spotlight and Shortcuts for notes (iOS v1.2, 2026-10-02). Changelog.
- File transcription (importing audio files): none found.
- Translation: none found (mixed-language dictation only).
- AI rewrite of selected text: only via Compose Beta.

### Platforms & sync
- Mac, iPhone, iPad, Apple Watch; web app for Notes. https://www.monologue.to/docs/getting-started/platform-availability
- "Local transcription is available only on Apple silicon Macs"; Intel Macs run the app (Intel crash hotfix v1.0.72). Docs; changelog.
- iOS App Store id6755956193, min iOS 17.6, version 1.2, 4.81 from 298 US ratings (iTunes lookup API, 2026-10-23).
- Sync: Notes stored server-side to sync; dictionary and modes sync; Stable or Beta update channels on Mac. Changelog.
- Minimum macOS: not found.

### Privacy & data
- "Dictation audio and transcripts are not stored on Monologue's servers"; AI providers process "under zero data retention"; Notes stored to sync. https://www.monologue.to
- Data & Privacy settings: delete local transcripts; "Choose whether to share dictation transcripts with Monologue to improve dictation quality". https://www.monologue.to/docs/account-and-privacy/permissions-and-privacy
- Local mode does not make every step offline (formatting is online). https://www.monologue.to/docs/dictation/languages-and-models
- Compliance: "Public SOC 2, ISO 27001, SSO, and HIPAA details are not currently listed" (vendor's own comparison). https://www.monologue.to/compare/wispr-flow.md

### Onboarding & permissions
- In-app setup guide; Microphone (required), Accessibility ("Yes for automatic pasting"), Screen Recording (optional, "Not now" allowed). https://www.monologue.to/docs/getting-started/mac
- Redesigned onboarding with tutorial, demo, model selection, live shortcut hints (v1.0.39, v1.0.41, v1.0.45). Changelog.
- Sign in with email code, Google, Apple, or Every; browser-based sign-in (v1.5.1). Docs; changelog.
- iOS: add keyboard, "Allow Full Access". https://www.monologue.to/docs/iphone-and-ipad/keyboard-and-full-access

### Accessibility
- None found (no VoiceOver or Voice Control claims).

### Distribution
- Direct Mac download https://www.monologue.to/download; iOS App Store. Mac App Store, Setapp, Homebrew, open source: none found.
- "Creator mode" keeps a "Dictated with monologue.to" attribution visible. https://www.monologue.to/docs/dictation/mac-preferences

## Recent changes (last 12 months)

Source: https://www.monologue.to/changelog
- 2025-10-24 macOS v1.0.50: Parakeet v3 local model (25 languages); share-to-improve toggle; delete all local transcripts.
- 2025-12-02 v1.0.55: Google and Every sign-in; dictionary import from SuperWhisper, Aqua Voice, Wispr Flow; ChatGPT Atlas support.
- 2026-02-06 v1.0.60: dictionary and modes sync across Macs; Sign in with Apple.
- 2026-02-16 iOS v1.0: iPhone, iPad, Apple Watch launch.
- 2026-03-06 v1.0.66: right-Shift mode picker.
- 2026-03-27 v1.0.68: "Blazing Fast" mode.
- 2026-04-18 v1.1.0: "Monologue Notes" (long recordings, system audio, speakers, MCP/CLI/API).
- 2026-05-25 / 06-22 v1.2.0–1.2.1: "Following Cursor" indicator.
- 2026-07-13 iOS v1.1: up to three languages or auto-detect; About Me; webhooks.
- 2026-08-07 v1.4.2: "Mini" indicator; per-output-device media behaviour.
- 2026-08-24 v1.5.0: "Dot" recorder.
- 2026-09-23: "mono-1" in-house model.
- 2026-09-28 v1.5.1: "Compose Beta", faster paste, 4- and 6-hour note limits.
- 2026-10-02 iOS v1.2: Siri AI, Spotlight, Shortcuts on iOS 27.

## User reception

- Praise: "Best macOS Dictation App, Finally on iOS!" (5 stars, 2026-02-19). https://apps.apple.com/us/app/id6755956193
- Praise: Modes per app or site: "The ability to create Modes with rules for different apps or websites is amazing" (2026-03-22). Same link.
- Complaint: tone flattening, "makes everything sound like a polite old lady" (3 stars, 2026-04-25). Same link.
- Complaint: new model and migration: "Doesn't work nearly as well" (1 star, 2026-10-02, after mono-1). Same link.
- Complaint: iOS dictionary "not saving" and not shared with desktop (3 stars, 2026-10-17). Same link.
- Complaint: iOS keyboard missing or unreliable in some apps (2026-02-18, two reviews). Same link.
- Blog: Matthew Cassinelli's "Letter of Recommendation – Monologue for Mac and iOS". https://matthewcassinelli.com/?p=37937
- Third-party summary: Mac rating "4.9/5 from 172 ratings", free trial "roughly 8 minutes of speech, one-time", cloud Deep context concern for NDA work (competitor-written). https://www.getvoibe.com/resources/monologue-review/

## Gaps you could not verify

- Whether Mac dictation shows words while speaking.
- Every bundle price and Team plan price.
- Minimum macOS version; whether Intel Macs get full dictation.
- Whether "Whisper mode" (a discreet low-voice mode) exists; it appears only in a Hacker News comment summarising the iOS launch (https://news.ycombinator.com/item?id=47050385).
- Default state of the "share dictation transcripts" toggle.
- What Compose Beta can do beyond "write or edit text".
- Whether dictionary sync reaches iOS (docs say yes, a reviewer says no).
- Which cloud providers ran the pre-mono-1 "API-based pipeline".
