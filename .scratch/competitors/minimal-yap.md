# Yap (by Frigade)

- Vendor: Frigade (a company that sells in-product onboarding tools; Yap is a free side project)
- Platforms: macOS 26 Tahoe or later, Apple Silicon only
- URL: https://frigade.com/yap, source https://github.com/FrigadeHQ/yap
- GitHub: 459 stars, MIT, created 2026-07-23, last commit 2026-10-16 ("Bump version to 0.1.14"), latest release v0.1.14 on 2026-10-16
- Show HN 2026-07-27: "Yap – OSS on-device voice dictation for macOS with no model to download", 104 points, 44 comments (https://news.ycombinator.com/item?id=49073834)
- Date checked: 2026-10-23
- Placement: minimal, by design. It ships no speech model: it is a 4 MB, ~3,000-line Swift wrapper around Apple's on-device `SpeechAnalyzer` (the speech engine macOS 26 provides to apps), with a toggle shortcut, live preview and paste. README: "Most feature ideas make an app like this worse."

Why it matters for Fluidity: it shows the floor a native Mac app can reach on macOS 26 with zero model download, and it uses Apple Intelligence's on-device model for optional cleanup, so "free, local, with AI cleanup" now costs a developer almost nothing.

## Pricing

- Free. No account, no API key, no paid tier. README: "Some cost money, which is a lot to ask for something that's now built into your OS for free." (https://github.com/FrigadeHQ/yap/blob/main/README.md)
- No team, education or lifetime plans (nothing to buy).

## Feature inventory

Source abbreviations: "README" = https://github.com/FrigadeHQ/yap/blob/main/README.md ; "settings src" = https://github.com/FrigadeHQ/yap/blob/main/Sources/Views/SettingsView.swift ; "releases" = https://github.com/FrigadeHQ/yap/releases. Note: the README's feature list is older than the code; settings src and releases are the more current sources. Everything is free.

### Trigger & capture

- "Toggle dictation": "Press once to start, again to stop." Default shortcut ⌘⇧D, rebindable. (settings src, https://github.com/FrigadeHQ/yap/blob/main/Sources/Services/HotkeyManager.swift)
- "Single modifier key": "Tap a modifier on its own, like Right Shift." A held modifier is ignored ("Clean tap means pressed and released quickly on its own"). (settings src, https://github.com/FrigadeHQ/yap/blob/main/Sources/Services/ModifierHotkeyMonitor.swift)
- "Function-row key": "Press an F-key, or the mic key, on its own." Binding the Mac's dictation (mic) key opens Yap instead of macOS Dictation (v0.1.4, 2026-07-28). (settings src, releases)
- Hold-to-talk: none. Toggle only (no push-to-talk code path found).
- Cancel: "Press escape twice to discard a dictation in progress". (README)
- Microphone: no picker; "Yap uses your system default input automatically", follows changes mid-session. Bluetooth headsets released as soon as dictation ends (v0.1.12). (settings src, README, releases)
- Audio captured before the speech engine is ready is buffered "so the first word of a sentence is never clipped". (README)
- "Sound feedback": "Play a cue when recording starts and stops." (settings src)
- "Show in Dock" and "Show in menu bar" toggles; can run on the shortcut alone with neither. "Launch at login" (off by default). (settings src, releases v0.1.11)
- System audio, other-device push-to-talk: none.

### Transcription engine

- Only Apple's on-device `SpeechAnalyzer` / `SpeechTranscriber` (macOS 26). No bundled model, nothing to download in the app; Apple's OS manages the model. (README)
- No fallback to Apple's servers: since v0.1.5 the older `SFSpeechRecognizer` path was removed because it "could send audio to Apple's servers"; "If `SpeechAnalyzer` can't handle your language on device, dictation stops". (README, releases)
- Cloud models: none.
- "Dictation language": "Dictate in a language other than your system's", default "System default"; lists only languages Yap can transcribe fully on device (v0.1.3). README still says it follows the system locale (stale). Auto-detect: none. (settings src, releases)
- Accuracy claim (third-party benchmark cited in README): Apple's model at 2.12% word error rate on clean audio and 4.56% on noisy, vs 3.74% and 7.95% for Whisper Small, "about three times faster", over 5,559 LibriSpeech clips. (README, https://get-inscribe.com/blog/apple-speech-api-benchmark.html)
- Footprint: "4 MB app", "idles around 60 MB of memory". (README)

### Live preview

- "Live waveform and partial transcript while you speak" in a small window near the bottom of the screen, on the screen of the app you're dictating into (v0.1.12). Partial words come from Apple's "volatile results", which revise as you keep talking. (README, releases)
- Text is pasted only when you press the shortcut again, so "you can cancel a bad take before it inserts". (README)

### Cleanup & formatting

- Filler removal, always on, no AI: strips "uhhh, uhh, uhm, umm, mmm, hmm, ehh, uh, um, hm, mm, mh" and re-capitalises sentences (v0.1.8). (https://github.com/FrigadeHQ/yap/blob/main/Sources/Services/FillerRemoval.swift, releases)
- "Clean up transcripts" (optional, v0.1.6): "Fix punctuation, format lists, and apply spoken corrections with Apple Intelligence, on-device." Uses Apple's Foundation Models framework. Prompt rules: remove fillers and false starts; fix punctuation and capitalisation; for "scratch that" or "no wait", keep only what the speaker settled on; three or more enumerated items become a list (numbered if the speaker said "first", "second"). Skipped for transcripts over 6,000 characters; 30 s timeout; any failure pastes the raw text. Requires Apple Intelligence enabled. (settings src, https://github.com/FrigadeHQ/yap/blob/main/Sources/Services/TranscriptCleanupService.swift)
- Punctuation without cleanup: from Apple's engine.
- Per-app tone, custom prompts, modes, context awareness: none. Accessibility permission is used only "To see which app you are typing into" for pasting. (README)

### Personalization

- "Dictionary" (v0.1.7): "Teach Yap names and words it often gets wrong. It leans toward these when it hears them, and fixes first-letter slips like 'brigade' to 'Frigade' on device. With Clean up transcripts on, it also fixes messier mishearings." Three layers: biasing the transcriber, a first-letter fix for single words of four or more letters, then the AI pass. (https://github.com/FrigadeHQ/yap/blob/main/Sources/Views/DictionaryView.swift, https://github.com/FrigadeHQ/yap/blob/main/Sources/Services/DictionaryCorrection.swift)
- Snippets, replacements list, auto-learning, per-app rules: none.

### Output & editing

- Pastes via clipboard plus ⌘V sent through System Events, then restores the previous clipboard after a delay tuned for Chromium and Electron apps (v0.1.10, v0.1.13). (README, releases)
- History: "Local transcript history with search, copy, and delete", stored in SwiftData; "Clear all". No retention limit or off switch found; one HN user asked for history to be optional. (README, https://news.ycombinator.com/item?id=49081301)
- Undo, retry, edit before paste: none (cancel-before-paste is the only pre-paste control).

### Voice commands

- None. One HN commenter asked for custom voice commands to open apps; not added. (https://news.ycombinator.com/item?id=49080858)

### Beyond dictation

- None. No file transcription, meetings, notes or AI chat.

### Platforms & sync

- macOS 26+ on Apple Silicon only. Intel support dropped on purpose in v0.1.5; Intel users can stay on 0.1.4, which "will send API calls to Apple". (README)
- No Windows, Linux, iOS. No sync.

### Privacy & data

- "No account, no network calls, no telemetry." "There is no network code in the app at all." (README)
- History kept locally in SwiftData, not encrypted by the app (no encryption mentioned).
- Cleanup uses the on-device Apple Intelligence model only. (TranscriptCleanupService.swift)
- An HN commenter pointed out that working offline does not prove nothing is ever sent. (https://news.ycombinator.com/item?id=49082261)

### Onboarding & permissions

- First launch asks for four permissions with a reason each: Microphone ("To hear you"), Speech Recognition ("To transcribe on device"), Accessibility ("To see which app you are typing into"), Automation ("To paste the result into it"). Settings shows "Some permissions are missing … Review permissions." Local builds get a "Reset and re-grant" button. (README, settings src)
- No tutorial beyond the empty-history hint "Press your shortcut and start talking." (https://github.com/FrigadeHQ/yap/blob/main/Sources/Views/HistoryView.swift)

### Accessibility

- None claimed.

### Distribution

- Direct DMG from https://frigade.com/yap and GitHub Releases, signed and notarised; Homebrew `brew install --cask frigadehq/tap/yap`. (README)
- Open source, MIT, Swift 6, SwiftUI, uses the KeyboardShortcuts package.

## Recent changes (last 12 months)

All since launch on 2026-07-24 (releases page):

- v0.1.0 (2026-07-24): first release, on-device transcription, global shortcut, paste, local history.
- v0.1.3–v0.1.5 (2026-07-28): language picker; Show in Dock; F-key and mic-key triggers; on-device only, Apple Silicon only.
- v0.1.6 (2026-07-30): optional "Clean up transcripts" with Apple Intelligence.
- v0.1.7 (2026-07-31): custom Dictionary. v0.1.8 (2026-07-31): automatic filler stripping.
- v0.1.10–v0.1.14 (2026-08-12 to 2026-10-16): device-switch crash fixes, "Show in menu bar", Bluetooth headset release, multi-monitor waveform, Electron terminal paste fix.

## User reception

- HN: "how is this different from just using the built in Mac OS dictation feature?" Author: built-in Dictation "still executes parts of it online"; Yap "makes zero network calls". (https://news.ycombinator.com/item?id=49078891, https://news.ycombinator.com/item?id=49079055)
- HN: Parakeet TDT v2 "still best, but look like apple is not far behind"; would switch "if you add parakeet support". (https://news.ycombinator.com/item?id=49078914)
- HN: requests to drop the Dock icon, add ⌘, for Settings, allow F13, and not log history at all ("It has no utility"). Author replied he is "Trying to keep the amount of settings to a minimum". (https://news.ycombinator.com/item?id=49081110, https://news.ycombinator.com/item?id=49081162)
- HN: Handy user says Yap is "quite similar in terms of features, except that is uses Apple's APIs"; another says Apple's engine handles mixed German/English badly. (https://news.ycombinator.com/item?id=49081264, https://news.ycombinator.com/item?id=49083984)
- HN: on a macOS 27 beta, "nothing happens after I finish speaking". (https://news.ycombinator.com/item?id=49081291)
- HN: Homebrew tap missing at launch, fixed same day. (https://news.ycombinator.com/item?id=49078875)

## Gaps I could not verify

- How many languages the "Dictation language" picker lists (depends on Apple's on-device locales; not enumerated).
- Whether history has any size or age limit.
- Real-world latency figures (none published by Frigade).
- Website frigade.com/yap content (not fetched; README used instead).
