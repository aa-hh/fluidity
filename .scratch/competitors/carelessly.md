# "Carelessly": resolved to Voice Type by Careless Whisper Inc.

**Identification.** No app named "Carelessly" exists in searches (standard and extended web search, HN search; carelessly.app does not resolve, checked 2026-10-23). The closest match is **Voice Type: Offline Dictation / Voice Type: Local Dictation** on the Mac App Store, whose in-app purchase is named "CarelessWhisperPurchase", whose support address is support@carelesswhisper.app, and whose site https://carelesswhisper.app is © "Careless Whisper Inc." It launched on HN as "Careless Whisper" (2024-12-19). This file inventories that app. If "Carelessly" meant something else, it was not findable.

- Vendor: Careless Whisper Inc.; App Store seller Saravanan Pitchaimani
- Platforms: macOS only (Apple Silicon and Intel)
- URL: https://carelesswhisper.app ; App Store https://apps.apple.com/us/app/voice-type-local-dictation/id6736525125
- Date checked: 2026-10-23
- Placement: **minimal.** $19.99 one-time, local Whisper, hold-to-dictate into any app, vocabulary, find-and-replace and optional rewrite of selected text; no live preview, no modes, no history found.

## Pricing
- Free download with a 7-day full trial, then $19.99 USD one-time via Mac App Store in-app purchase "CarelessWhisperPurchase". No subscription, no account. https://carelesswhisper.app/pricing
- "App updates without a subscription" included.
- Teams: App Store volume purchasing and enterprise billing by email; no seat prices. Education: none found.
- BYO key: optional, only for cloud rewrite providers.

## Feature inventory
All features in the paid app and trial.

### Trigger & capture
- "System-wide hold-to-dictate hotkey" / "Customizable global shortcut" (App Store description). Toggle or hands-free: none found. Voice activity detection called "experimental" in the 2024 Show HN post (https://news.ycombinator.com/item?id=42460676).
- "input audio selection" (microphone picker) in 1.00.54 (Feb). Automatic input gain leveling (1.01.01 / 1.01.02, Jul). Adaptive noise reduction, external mic and AirPods fixes (1.00.17, 2025-07-22).
- Menu bar app ("cleaner menu", 1.00.54); "Sits in the background" (Show HN).
- System audio, push-to-talk from other devices: none found.

### Transcription engine
- Local Whisper only (whisper.cpp with Metal). Five models: Small, Medium, and Large v3 Turbo in "balanced", "high-accuracy" and "max-accuracy" builds (App Store description). Sizes not published.
- Site banner names a "Cohere Transcribe model"; not in the App Store description. Unverified whether shipped.
- "automatic or manual language selection" (App Store). Dictation language count not stated (the App Store "Languages" list of 35 is UI localization).
- Cloud transcription: none.
- Speed: "Text appears under two seconds after release" (site).

### Live preview
- None. A 2024 App Store reviewer preferred Apple Dictation's real-time display; another says it "seems to bundle up a few seconds of audio".

### Cleanup & formatting
- Automatic punctuation from the model; "Voice punctuation and new paragraphs" (spoken commands) (site).
- "Rewrite Selected text in one keystroke": optional, off by default. Providers: Apple Intelligence (beta in 1.00.55, Apr) and Ollama on-device; other providers with the user's own key (GPT-5 named in 1.00.51 notes). https://carelesswhisper.app/trust
- Filler removal, self-correction, per-app tone, context awareness: none found.

### Personalization
- "Custom vocabulary for names, brands, and acronyms".
- "find-and-replace rules"; "CSV find-and-replace packs" import (1.00.55).
- Snippets, auto-learning, per-app rules: none found.

### Output & editing
- Pastes "in any app with a text cursor" (needs Accessibility permission, per Show HN).
- History, undo, retry, edit-before-paste, clipboard restore: none found.

### Voice commands
- Spoken punctuation and "new paragraphs" (site). Full command list not published. Editing or app-control commands: none found.

### Beyond dictation
- "Transcribe audio and video files offline" (site, App Store).
- "Rewrite Selected text" (see Cleanup).
- Meetings, notes, translation: none found.

### Platforms & sync
- macOS 13.4 or later (App Store; site says "macOS Ventura or later"). Apple Silicon fastest; Intel supported (HN user: small model "fairly quick and accurate on a 9 year old intel Macbook Pro", https://news.ycombinator.com/item?id=42463524).
- No iOS, Windows, Linux, extension or sync.

### Privacy & data
- "Audio is not uploaded"; no accounts, no app analytics, telemetry or crash logs. Network calls: Apple licensing, model downloads from huggingface.co, a static JSON fetch every six hours from files.carelesswhisper.app, and the chosen rewrite provider if enabled. Website uses PostHog. https://carelesswhisper.app/trust
- App Store privacy label "Data Not Collected".
- HIPAA / SOC 2: none claimed.

### Onboarding & permissions
- Requests Accessibility permission (Show HN); onboarding fixes in 1.00.49 (2025-11-05). No further detail found.

### Accessibility
- Origin story is RSI; no VoiceOver or Voice Control claims found.

### Distribution
- Mac App Store only, sandboxed ("Sandboxed app, available through the Mac App Store", Show HN). Closed source; a user asked for source access for paid licensees (https://news.ycombinator.com/item?id=42463421).

## Recent changes (last 12 months)
App Store version history (some entries omit the year; those after 1.00.49 are assumed 2026).
- 1.01.03 Aug 4: "Focus accuracy improvements."
- 1.01.00 to 1.01.02 Jul 21 to 28: improved audio engine, microphone handling, long-dictation stability, automatic input gain leveling.
- 1.00.55 Apr 17: language detection fix, CSV find-and-replace packs, Apple Intelligence rewrite beta.
- 1.00.52 / 1.00.54 Feb 5 / 25: input audio selection, cleaner menu.
- 1.00.51 Jan 10: newer rewrite LLMs added.
- 1.00.49 2025-11-05: onboarding fixes.

## User reception
- Physician on HN: uses it for clinic notes; local processing means "I don’t have to worry about patient data privacy." https://news.ycombinator.com/item?id=42464026
- HN, 2024-12-19: "Just tried it. Works very well." https://news.ycombinator.com/item?id=42463524
- HN, 2026-09-23: "I've used https://carelesswhisper.app/ which is available in the macOS App Store". https://news.ycombinator.com/item?id=49810609
- App Store: "It doesn't mess up my words, and I am able to add my own vocabulary/names." (2024-12-31) https://apps.apple.com/us/app/voice-type-local-dictation/id6736525125
- App Store complaint: whispered dictation captures only the first of five sentences (Jul 30). (same link)
- App Store complaint: criticizes punctuation guessing and the delay before text appears (2025-03-14). (same link)
- App Store complaint: prefers macOS dictation's real-time display and questions paying $20 (2024-12-31). (same link)
- Site claims 50 App Store reviews, 33 five-star; the US listing shows too few ratings to display. Likely aggregated across storefronts (unverified).

## Gaps I could not verify
- That "Carelessly" in the brief means this app.
- Hotkey modes beyond hold; full voice command list; model sizes; dictation language count.
- Whether Cohere Transcribe has shipped.
- Any history or retry features.
