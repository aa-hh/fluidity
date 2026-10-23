# Voicetypr

- Vendor: Ideaplexa (repo `ideaplexa/voicetypr`, formerly `moinulmoin/voicetypr`)
- Platforms: macOS 14+ (Apple Silicon full, Intel "legacy/best-effort", Whisper only), Windows 10 build 19041+ / 11 (direct installer and Microsoft Store)
- URL: https://voicetypr.com ; source https://github.com/ideaplexa/voicetypr (AGPL-3.0, 738 stars)
- Date checked: 2026-10-23 (repo cloned at main, pushed 2026-10-16; latest release v2.0.9, 2026-10-09)
- Placement: **upper mid.** One-time licence with local Whisper and Parakeet, five cloud transcription providers, AI "Polish" (including through Claude Code / Codex subscriptions), per-app styles, live preview, history, file transcription with speaker labels, LAN "Network Sharing" and a command-line tool for AI agents.

## Pricing
Source: https://voicetypr.com/pricing (checked 2026-10-23).
- "Pay once. Keep forever." Device options 1, 2 or 4 activations. Official page shows $69 for the default 2-device option only.
- Third-party listing (ToolQuestor, not vendor): 1 device $39, 2 devices $69, 4 devices $99 (https://toolquestor.com/tool/voicetypr). Single-device price unverified on vendor site.
- Trial: 3 days, no card. Code tracks `trial_days_left`. Refund: 7-day money-back.
- Teams: 5+ seats via support@voicetypr.com. Education: none found.
- Tiers differ only in device count. BYO key for all cloud speech and AI providers; "a lifetime license keeps local models unmetered" (README).

## Feature inventory
All features in any licence and the trial. Sources: repo README, `CHANGELOG.md`, `src/components/sections/*`, `src/components/polish/*`, and voicetypr.com.

### Trigger & capture
- "Global hotkey, push-to-talk, toggle modes"; "Tap to lock, hands-free" (site). Recording modes in code: `push_to_talk`, `toggle`.
- One "Hold to talk" checkbox on the "Dictation shortcut" (v2.0.0 removed the earlier mode picker and double-tap selector).
- Shortcut can be a bare side-specific modifier ("hold Right-⌥"), a single non-typing key (function keys, numpad), or a combo (v2.0.0, v2.0.2).
- Extra bindable shortcuts for history, Polish, Home, and "Toggle AI formatting" (`ShortcutsSection`).
- "Microphone" picker with level meter; "Pause media during recording".
- "Recording pill" overlay: "Show" Never / Always / While recording; "Position"; "Detail" "Level only" / "Level + timer"; "Edge offset".
- Sounds: "Recording started", "Transcript ready", "Paste completed".
- Tray (menu bar) icon; "Launch at Startup".
- "Network Sharing": "Use another Voicetypr device on your network without copying audio to the cloud" (send audio to your own desktop for transcription).
- System-audio capture: none found.

### Transcription engine
- Local (`src-tauri/src` display names): Whisper "Base (English)", "Small (English)", "Large v3", "Large v3 Turbo" (plus tiny.en file); Parakeet "Parakeet V2 (English)", "Parakeet V3", "Parakeet Unified (English)", "Nemotron Multilingual", "Cohere Transcribe" on Apple Silicon via a Swift sidecar. Sizes not read.
- Cloud (user key): Soniox ("Soniox v5"), OpenAI ("GPT Transcribe", "GPT-4o mini Transcribe"), Groq ("Whisper Large v3 Turbo", "Whisper Large v3"), Deepgram ("Nova 2", "Nova 3"), Cohere (v2.0.0).
- "Remote Voicetypr" as a third source next to "Local" and "Cloud".
- "Spoken language" picker; site: "99" languages "with automatic detection".
- "Speed mode": "Faster transcription (flash attention); pairs best with Large v3 Turbo." Windows "Acceleration" GPU / CPU / Auto.

### Live preview
- "Live preview" toggle in Models settings, shown "when capabilities support streaming" (`parakeet-eou-live-preview` model id). Where the words appear (pill or elsewhere) and whether they change after: not verified.

### Cleanup & formatting
- "Polish": "AI cleans up fillers, false starts and punctuation. Your words stay yours."
- "Keep my words": "Only fix punctuation, fillers and stutters — never reword."
- Providers: "Cloud API" (OpenAI, Anthropic, Gemini, custom OpenAI-compatible; catalog of "~94 models" from models.dev) or "Local Agents" ("Experimental"): Claude Code, Codex, OpenCode, pi, oh-my-pi command-line tools, which lets Polish run on an existing Claude or ChatGPT subscription. v2.0.9 adds per-model reasoning effort and an optional "Fast mode".
- "Default style" plus "Modes" with "You said" / "You get" examples; site says "6 formatting modes" (labels seen in code include "Default", "Message", "Notes", "Code").
- "Per-app styles" ("Add override") and site "Per-app rules".
- "Final text language": "Same as transcript" or "Specific language" ("Translation requires Polish").
- Deterministic fallback when Polish fails; raw dictation preserved on any CLI failure.
- Context awareness (screen or selected text): none found. History stores the target app "for opted-in dictation".

### Personalization
- "Dictionary": "Teach Voicetypr your names and words. Works with every engine, with or without Polish." Entry fields "Canonical", "Spoken" (optional), "Language".
- "Corrections": "Match" to "Replace".
- "Snippets": spoken trigger (e.g. "my signature") inserts "Saved text". Snippets are not sent to cloud providers.
- Auto-learning from edits: none found.

### Output & editing
- "Paste automatically" ("Type the text where your cursor is") and "Keep in clipboard" ("Also copy it, so you can paste again").
- "Searchable local transcript history" with source / app / date filters, per-entry detail, "Show original / Show formatted", copy, save, "re-transcribe" (README, v2.0.0).
- "Transcript history cleanup" and "Save recording audio" settings.
- Undo, edit-before-paste: none found.

### Voice commands
- Snippet triggers only. Spoken "new line" or editing commands: none found.

### Beyond dictation
- "Audio and video file transcription"; cloud speaker diarization for files (Deepgram, Soniox), saved as .txt / .md (v2.0.0).
- "CLI & Agent API": `voicetypr transcribe --file note.wav --json`, `voicetypr record --until-silence --json`, installed from Settings → Advanced.
- Translation via Polish.
- Meetings, notes, AI chat: none found.

### Platforms & sync
- macOS 14+, Windows 10/11. No iOS, Android, Linux, or extension. Sync: none; "Network Sharing" shares transcription, not data.

### Privacy & data
- README data-flow table: local mode keeps audio and text on device; cloud mode sends audio to the chosen provider; AI formatting sends the transcript; Network Sharing sends audio to your own server.
- "Anonymous sharing": "Share anonymous crash reports and usage numbers" toggle; first-run "PrivacyConsentDialog".
- SOC 2 / HIPAA: none found.

### Onboarding & permissions
- Onboarding warms the chosen model, shows an example sentence to read, an editable transcript box and "Skip for now" (v2.0.0). Troubleshooting page with "Permissions", "Refresh permission status", "Quick fixes", "Reset".

### Accessibility
- None found.

### Distribution
- Direct download (signed and notarized), GitHub Releases, Microsoft Store; Stable / Beta "Update channel". Open source AGPL-3.0. Mac App Store, Setapp, Homebrew: none found.

## Recent changes (last 12 months)
Source: https://github.com/ideaplexa/voicetypr/releases and `CHANGELOG.md`.
- 2026-10-09 v2.0.9: new Polish models; reasoning effort control; Fast mode; local CLIs default to Claude Haiku.
- Unreleased (main): hardened Claude Code / pi / oh-my-pi subscription Polish; licence outage handling.
- 2026-09-27 v2.0.6 / v2.0.7; 2026-08-02 v2.0.5: fixes.
- 2026-07-01 v2.0.4: pre-warmed cloud connections.
- 2026-06-30 v2.0.2: unified hotkey engine with bare-modifier holds.
- 2026-06-25 v2.0.0: five cloud speech providers; Rust-native Polish; model catalog; diarization; rich history; CLI; Microsoft Store; single-key push-to-talk.
- 2026-06 v1.12.x to v1.13.0; 2025-10 v1.9.0 era.

## User reception
Thin; no Reddit or App Store reviews found.
- GitHub issue: "not working nothing happens after i speak" (11 comments, 2025-10-17). https://github.com/ideaplexa/voicetypr/issues/26
- GitHub issue: "Two much punctuation when using Soniox, possible VAD issue?" https://github.com/ideaplexa/voicetypr/issues/36
- GitHub issue: model download verification "Repair/Remove loop" on Windows v2.0.4. https://github.com/ideaplexa/voicetypr/issues/122
- GitHub issue: "Flash of powershell window at the start of the recording" (Windows). https://github.com/ideaplexa/voicetypr/issues/48
- HN launch post (2025-10-24) drew no comments. https://news.ycombinator.com/item?id=45696921

## Gaps I could not verify
- Vendor-stated 1-device and 4-device prices.
- The six formatting mode names.
- Live preview placement and whether text is revised.
- Model download sizes.
