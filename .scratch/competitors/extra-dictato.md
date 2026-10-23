# Dictato (dicta.to)

- Vendor: listed as "Obsidian IT Consulting SRL" on AlternativeTo (https://alternativeto.net/software/dictato/about); some directories say "Dicta AI". Not confirmed on vendor page.
- Platforms: macOS 14 (Sonoma)+, Apple Silicon (M1+) only
- URL: https://dicta.to
- Date checked: 2026-10-23
- Placement: **mid.** €19.99 one-time, fully on-device: four swappable speech engines, on-device cleanup and "Tones" rewriting with a local model, per-app and per-website "Profiles", a preview window, searchable history. No cloud option at all.

## Pricing
Source: https://dicta.to/ (checked 2026-10-23).
- 19.99 € one-time, "lifetime", VAT included. "Once. That is the whole pricing page."
- One Mac at a time; licence can move up to 3 times per 30 days.
- Trial: 7 days, full app, no card, "no locked features". Refund: 14 days, no questions asked.
- A directory lists "$9.99 for a two-year license" (https://www.voiceaispace.com/tool/dictato and search summary); conflicts with the vendor page; treat as stale.
- No BYO-key options (no cloud services). Team / education: none found.
- Price note: €19.99 sits at the bottom edge of the $20 to $60 band.

## Feature inventory
All features in the paid app and trial. All from https://dicta.to/ unless noted.

### Trigger & capture
- Hold the hotkey to dictate, or set recording mode to "Toggle" in Settings.
- Does not stop after 30 seconds of silence (contrast with Apple Dictation).
- "Quick Settings": a shortcut opens a panel over the current app to toggle auto-correct, auto-translate, vocabulary boosting, voice commands, profiles and paste directly.
- Pauses Spotify or Apple Music (needs Automation permission).
- Microphone selection, system audio, remote push-to-talk: none found.

### Transcription engine
- "Parakeet": default on macOS 14/15 (and macOS 26 without Apple Intelligence), ~485 MB, 24 languages, mostly European.
- "Whisper": 99 languages, 245 MB to 3.1 GB depending on model (WhisperKit per the founder's Show HN post).
- "Qwen3": macOS 15+, ~600 MB, 26 languages (Qwen3-ASR 0.6B; founder says better with Chinese, Japanese, Korean).
- "Apple SpeechAnalyzer": macOS 26 with Apple Intelligence; no download.
- Switch engines "in one click"; per-profile engine and language.
- Cloud engines: none. Language count on page stats "25+".
- Latency claim "as low as 80 milliseconds" (directory listing quoting vendor).

### Live preview
- "Preview" window shows the transcript before pasting; "Paste directly" skips it. Words shown while speaking: not stated.

### Cleanup & formatting
- "Proofread" / "auto-correct": punctuation, capitals, paragraph breaks, filler removal, spoken amounts and dates ("twenty five euros" to "25 €"). On-device; needs Apple Intelligence on macOS 26 or Dictato's downloaded model; macOS 14/15 get rule-based cleanup.
- "Tones": rewrite in one of nine built-in styles or a custom one, using Gemma (3.4 GB one-time download).
- Proofreading level set per profile.
- Self-correction handling: not stated. Context awareness beyond app/website: none found.

### Personalization
- "Vocabulary": Whisper uses a "Context" field; Parakeet uses "vocabulary boosting".
- "Voice Commands": map a spoken phrase to an exact replacement or emoji (this is the snippet/replacement feature).
- "Profiles": per-app rules, and per-website rules in Safari, Chrome, Brave, Edge, Arc, Vivaldi, Opera (Firefox app-level only); each sets tone, proofreading level, engine and language.
- Auto-learning: none found.

### Output & editing
- Pastes at the cursor via clipboard save and restore of all pasteboard types, then simulated Cmd+V (Show HN, https://news.ycombinator.com/item?id=47137329).
- "History": local, never synced; full-text search; raw and cleaned versions; audio playback; audio saving can be off; entries deletable.
- Edit-before-paste via the Preview window.

### Voice commands
- Phrase-to-text "Voice Commands" only. Editing or "new line" commands: not stated.

### Beyond dictation
- "Auto-translate" via Apple's Translation framework (macOS 26).
- File transcription: explicitly not supported ("does not transcribe existing audio files").
- Meetings, notes, AI chat: none.

### Platforms & sync
- macOS 14+, Apple Silicon only. No other platforms, no sync.

### Privacy & data
- Audio and text processed on the Mac and "never leave it". App contacts app.dicta.to for licence checks, update checks, and, during the trial, anonymous usage counters (can be turned off). Models from huggingface.co.
- "Not HIPAA-certified, and no BAA is offered."

### Onboarding & permissions
- Microphone and Accessibility required; Automation only for website rules or media pausing. First-run flow not described.

### Accessibility
- None found.

### Distribution
- Direct download from dicta.to. Mac App Store, Setapp, Homebrew: none found. Closed source.

## Recent changes (last 12 months)
- 2026-02-24: Show HN launch (https://news.ycombinator.com/item?id=47137329) with four engines and Apple Intelligence post-processing.
- Since then the site adds Gemma-based "Tones" and Dictato's own cleanup model for macOS 14/15 (dates not given). No changelog page (dicta.to/changelog returns 404).

## User reception
Very thin.
- Show HN, 2026-02-24: founder post; no substantive comments retrieved. https://news.ycombinator.com/item?id=47137329
- FeedBagel review verdict: "Worth a glance, not a chew." https://feedbagel.com/post/dictato-local-voice-to-text-software-for-mac-with-on-device-processing
- AlternativeTo: no comments or reviews. https://alternativeto.net/software/dictato/about

## Gaps I could not verify
- Vendor legal name.
- Release history and dates.
- Whether words appear live while speaking.
- Microphone selection; full list of nine tones.
