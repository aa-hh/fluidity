# Ghost Pepper

- Vendor: Matt Hartman (solo developer, with contributors such as @obra)
- Platforms: macOS 14.0+ on Apple Silicon (M1+) only
- URL: https://github.com/matthartman/ghost-pepper (no separate website found; downloads from GitHub)
- GitHub: 3,212 stars, MIT per README (GitHub's licence detector shows none), created 2026-03-20, last commit 2026-07-27 ("Merge pull request #154 … add-mlx-streaming-asr-models"), latest release v2.4.4 on 2026-07-27. No commits for nearly three months as of the check date.
- Show HN 2026-04-06: "Ghost Pepper – Local hold-to-talk speech-to-text for macOS", 467 points (https://news.ycombinator.com/item?id=47666024)
- Date checked: 2026-10-23
- Placement: launched minimal (hold Control, local Whisper, paste), now mid to full-suite in feature count but free: local AI cleanup, screen-text context, learning from your edits, meeting transcription with speaker recognition, and an AI chat. Included here because it is the best-known "hold key, local Whisper, paste" launch of 2026; strictly minimal alternatives found had under 200 stars (see Gaps).

## Pricing

- Free, MIT. README: "Free & open source". (https://github.com/matthartman/ghost-pepper/blob/main/README.md)
- Optional cloud add-ons need the user's own keys: "Zo AI chat, Trello integration, Granola meeting import"; meeting Q&A uses an Anthropic key with "live cost display" (v2.4.0). (README, https://github.com/matthartman/ghost-pepper/releases/tag/v2.4.0)
- No paid tier, team or education plan.

## Feature inventory

Source abbreviations: "README" as above; "settings src" = https://github.com/matthartman/ghost-pepper/blob/main/GhostPepper/UI/SettingsWindow.swift ; "releases" = https://github.com/matthartman/ghost-pepper/releases. Everything is free unless marked BYO key.

### Trigger & capture

- "Hold Control to talk — release to transcribe and paste into any text field" (default). (README)
- Two configurable shortcuts, "Hold to Record" and "Toggle Recording": "Push to talk records while the hold chord stays down. Toggle recording starts and stops when you press the full toggle chord." Shortcuts are key chords caught with a system event tap. (settings src, https://github.com/matthartman/ghost-pepper/blob/main/GhostPepper/Input/HotkeyMonitor.swift)
- "Context Bundler (hold to speak)": a third hold shortcut that sends your question plus screen context to an AI chat. (settings src)
- "Microphone" picker with "Detect available microphones"; mic choice no longer changes the system default (v2.1.2). (settings src, releases)
- "Play sounds" toggle. "Record a short sample with your current microphone and speech model without leaving Settings." (settings src)
- Menu bar app, "no dock icon, launches at login" (launch at login on by default). (README)
- System audio: captured only for meeting transcription, needs Screen Recording permission. (settings src)
- Other-device push-to-talk: none found.

### Transcription engine

- Local models only, downloaded once from Hugging Face (README table): "Whisper tiny.en" (~75 MB), "Whisper small.en" (default, ~466 MB), "Whisper small (multilingual)" (~466 MB), "Parakeet v3 (25 languages)" (~1.4 GB, via FluidAudio), "Qwen3-ASR 0.6B int8 (50+ languages)" (~900 MB, macOS 15+), "Nemotron Speech Streaming 0.6B 8-bit" (~633 MB, "Low-latency English streaming"), "Nemotron 3.5 ASR Streaming 0.6B 8-bit" (~721 MB, multilingual streaming). Runtimes: WhisperKit, FluidAudio, MLX Audio. (README)
- An Apple SpeechAnalyzer backend exists in source (`AppleSpeechAnalyzerBackend.swift`); not listed in the README. (https://github.com/matthartman/ghost-pepper/tree/main/GhostPepper/Transcription)
- "Speech Model" picker: "Ghost Pepper uses this model for speech recognition everywhere in the app." "Language" picker (English, Arabic, Chinese, Dutch, French, German, Hindi, Italian, Japanese, Korean, Portuguese, Russian, Spanish shown) with a warning if an English-only model is selected. README badge "50+ Languages". (settings src)
- Cloud speech models: none.
- Auto language detection: not verified.
- "Model Experiment" pane: "Paste prompts and context to test local model behavior." (settings src)

### Live preview

- Not verified. Streaming Nemotron models were added in v2.4.4 ("Low-latency … streaming"), and History shows a "Raw stream", but no setting or doc describing words shown while speaking was found. (README, settings src)

### Cleanup & formatting

- "Smart cleanup — local LLM removes filler words and handles self-corrections". (README)
- Cleanup models (local, via LLM.swift): "Qwen 3.5 0.8B" (default, ~535 MB, "Very fast (~1-2s)"), "Qwen 3.5 2B" (~1.3 GB, ~4-5 s), "Qwen 3.5 4B" (~2.8 GB, ~5-7 s). (README)
- "Cleanup prompt" editable, "Reset to Default"; "Add an example to the cleanup prompt" with "Input (what was said)" / "Output (what it should be)". (settings src)
- "Use frontmost window OCR context": "Ghost Pepper uses high-quality OCR on the frontmost window and adds the result to the cleanup prompt." Uses Apple's Vision framework on device; needs Screen Recording. (settings src, README)
- Per-app tone or modes: none found.

### Personalization

- "Commonly misheard" ("Misheard as:" → "Should be:") and "Preferred transcriptions": "If a word is consistently misheard, add it here. Correction hints are added to the cleanup prompt; they are not applied as regexes or deterministic substitutions. Preferred transcriptions are also forwarded into OCR custom words." (settings src)
- "Learn from manual corrections after paste": about 15 seconds after pasting, Ghost Pepper re-reads the field with OCR and, if you changed up to two words, learns the correction. (settings src, https://github.com/matthartman/ghost-pepper/blob/main/GhostPepper/Cleanup/PostPasteLearningCoordinator.swift)
- Snippets, per-app rules: none found.

### Output & editing

- Pastes via simulated keystrokes into the focused field; v2.4.4 restored Accessibility API access "to detect focused input fields". (README, releases)
- "History" pane ("Saved recordings, reruns, and cleanup experiments"): play recording, "Rerun transcription", "Rerun cleanup", "Rerun speaker tagging", search, "Clear History". Can be turned off ("Voice-to-text history is off. Audio from dictation is not saved to disk."). (settings src)
- Undo, edit before paste: none found.

### Voice commands

- None found for editing or app control. The Context Bundler sends spoken requests to an AI chat (Zo) or to Trello. (settings src)

### Beyond dictation

- "Meeting transcription" (on by default since v2.3.0): detects Zoom, Teams, FaceTime, Meet and others; records mic plus system audio; Notes, Transcript and Summary tabs; summaries from the local cleanup model; saved as Markdown in date folders; "Detect" button reads meeting name and attendees from window title and video tiles by OCR; Google Calendar connection for titles and attendees. (README, settings src, releases v2.1.0, v2.3.0)
- "Recognized Voices": speaker labels and "this is me" voice prints across recordings (v2.2.0, FluidAudio models only). (settings src, releases)
- "Agentic meeting Q&A" across all meetings with an Anthropic backend (BYO key), People/topic "Indexing & dossiers" (v2.4.0). (releases)
- Granola and Airtable meeting import (v2.1.1). (releases, source tree)
- "Pepper Chat" / "Context Bundler": hold a key, ask a question, answer in a floating window, screen OCR included; send to Zo, Trello or clipboard (v2.0.0, BYO keys). (settings src, releases)
- File transcription, translation: none found (a user asked for transcribing a played video; the author suggested the mic picks it up). (https://news.ycombinator.com/item?id=47667099)

### Platforms & sync

- macOS 14+, Apple Silicon only. No Windows, Linux or iOS. No sync ("no cloud sync"). (README)

### Privacy & data

- "100% private … No cloud APIs, no data leaves your machine" for core features; README has a "Privacy audit" table "verified by AI code review" and `PRIVACY_AUDIT.md` with the audit prompt. (README)
- Telemetry: "Local-only usage counters (UserDefaults) power the in-app Usage report panel. No Firebase, Mixpanel, Sentry, or any tracking SDK." (README)
- API keys stored in macOS Keychain. Optional cloud features off by default. (settings src, README)
- MDM: IT can pre-approve Accessibility with a Privacy Preferences Policy Control payload. (README)

### Onboarding & permissions

- Microphone and Accessibility required; Input Monitoring and Screen Recording requested for some features. Onboarding window with model download readiness (v2.4.1). A "What's New" dialog on updates. (README, settings src, releases)
- Gatekeeper: README tells Sequoia users to click "Open Anyway" if "Apple could not verify" appears. (README)
- At launch the mic permission prompt did not appear because signing stripped an entitlement; fixed in v2.0.1. (releases, https://news.ycombinator.com/item?id=47667016)

### Accessibility

- None claimed.

### Distribution

- GitHub Releases DMG (signed, notarised from v2.4.4 notes), Sparkle updates. Not on Homebrew (none found), Mac App Store or Setapp. Open source, MIT.

## Recent changes (last 12 months)

All since v1.0.0 on 2026-03-20 (releases):

- v2.0.0 (2026-04-06): Pepper Chat with screen OCR context.
- v2.1.0 (2026-04-09): experimental meeting transcription. v2.1.1 (2026-04-14): Granola import.
- v2.2.0 (2026-04-21): speaker identity. v2.3.0 (2026-04-22): meeting transcription on by default, meeting name and attendee detection.
- v2.4.0 (2026-05-21): agentic meeting Q&A, indexing and dossiers.
- v2.4.1–v2.4.4 (2026-07-18 to 2026-07-27): onboarding fixes, Keychain prompt fix, MLX streaming speech models, paste fix.

## User reception

- HN launch, 467 points: most top comments ask how it compares with Handy and Hex; "Handy is the one that made me stop looking for local open source alternatives to Wispr Flow." (https://news.ycombinator.com/item?id=47668925)
- HN: "Parakeet is significantly more accurate and faster than Whisper if it supports your language." (https://news.ycombinator.com/item?id=47666292)
- HN: "Sadly the app doesn't work. There is no popup asking for microphone permission." (https://news.ycombinator.com/item?id=47667016)
- HN: "the killer feature to me will be one that fine tunes the model based on your own voice"; author pointed to the corrections feature. (https://news.ycombinator.com/item?id=47667271, https://news.ycombinator.com/item?id=47667306)
- HN: a user finds macOS built-in dictation "better than all the 3rd party, local apps I tried". (https://news.ycombinator.com/item?id=47667502)

## Gaps I could not verify

- Live words while speaking with the streaming models.
- Whether the Apple SpeechAnalyzer backend is selectable in the release build.
- Exact default chord for "Toggle Recording".
- Strictly minimal alternatives checked and rejected for low traction: FastWord (35 stars), Megaphone (176 stars, Apple SpeechAnalyzer + Foundation Models), Wordbird (9 stars), Murmur (0 stars, BYO OpenAI key). FnScribe (36 HN points, Aug 2026) repository now returns 404.
