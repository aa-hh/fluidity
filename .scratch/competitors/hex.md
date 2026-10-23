# Hex (HEX)

- Vendor: Kit Langton (solo developer); new repository under the anomalyco GitHub organisation
- Platforms: macOS (Apple Silicon only, macOS 15+); Windows 10/11 beta (x64, ARM64); Linux beta (x86_64 Arch, glibc 2.44+, X11 and wlroots Wayland); iOS prototype in source only
- URL: https://hex.kitlangton.com, source https://github.com/anomalyco/hex (current Rust app) and https://github.com/kitlangton/Hex (original Swift app, archived)
- GitHub: anomalyco/hex 527 stars, MIT, created 2026-07-17, last commit 2026-10-23 ("feat: add read-only history and meetings CLI for agents"), latest app release app-v2.3.1 on 2026-10-21. kitlangton/Hex (Swift) 2,899 stars, MIT, archived, last commit 2026-10-14, last release v0.8.5 on 2026-08-27.
- Date checked: 2026-10-23
- Placement: mid, moving up from minimal. Defaults are still minimal (hold Option, local model, paste), but the Rust 2.x rewrite added per-app Modes, an AI rewrite path, local voice commands, and local meeting recording with Apple Intelligence summaries, all off until switched on.

Note: the Swift app (v0.x) and the Rust app (2.x) are different programs with different bundle IDs (`com.kitlangton.hex2` for Rust). Settings and history do not migrate. This file describes the Rust app unless marked "Swift". (https://github.com/anomalyco/hex/blob/main/README.md)

## Pricing

- Free. No paid tier, no account, no limits found on the site or in the README. (https://hex.kitlangton.com, https://github.com/anomalyco/hex)
- AI rewriting ("OpenCode" features) uses the separately installed OpenCode V2 beta and whatever model provider the user configures in it. Hex charges nothing; provider costs are the user's. (README)
- No donation link, team, or education plan found.

## Feature inventory

Source abbreviations: "README" = https://github.com/anomalyco/hex/blob/main/README.md ; "map" = https://github.com/anomalyco/hex/blob/main/docs/features/README.md ; "dictation doc" = https://github.com/anomalyco/hex/blob/main/docs/features/dictation.md ; "settings src" = https://github.com/anomalyco/hex/blob/main/src/rune_ui/settings.rs ; "models src" = https://github.com/anomalyco/hex/blob/main/src/transcription_models.rs ; "modes src" = https://github.com/anomalyco/hex/blob/main/src/rune_ui/modes.rs. Everything is free.

### Trigger & capture

- Default shortcut: hold Option on macOS ("Hold Option, speak, then release"), Ctrl+Space on Windows. (README)
- "Shortcut mode": "Hold" (default, "Hold to dictate, release to transcribe") or "Toggle" ("Press to start dictating, press again to transcribe"). Toggle added in 2.3.0 (2026-10-19). (settings src, https://github.com/anomalyco/hex/blob/main/docs/releases/2.3.0.md)
- "Double-tap to lock" ("Double-tap the shortcut for hands-free dictation"), then press once to finish. "Double-tap only" ("Wait for two complete shortcut taps before recording") disables single hold. (settings src, dictation doc)
- Taps shorter than 300 ms are discarded so ordinary Option chords do not start recording. (dictation doc)
- Shortcut can be modifier-only, modifier plus key, standalone Fn/Globe, or a standalone function key; side-specific modifiers (left vs right) supported. (dictation doc, https://github.com/anomalyco/hex/blob/main/docs/releases/2.1.0.md)
- Other shortcuts: "Cancel dictation" (Escape), "Paste last dictation" (Option-Shift-V), "Voice Action" (Option-Command), Meetings shortcut Option-Control-V. (README, settings src, https://github.com/anomalyco/hex/blob/main/docs/features/meetings.md)
- "Microphone": "Automatic" or a saved device. Automatic avoids a Bluetooth headset mic when a built-in mic exists, to stop the headset dropping to call quality. (map)
- "Microphone mode": "Keep ready (fast)" ("Keeps the microphone open for instant start and pre-roll", meaning audio from just before the press is kept) or "Release when idle" ("Opens only while holding the shortcut. Disables pre-roll and commands."). (settings src)
- "While dictating": Mute / Pause media / Do nothing. (map)
- Recording keeps 200 ms after release so the last word is not cut (2.2.0). (https://github.com/anomalyco/hex/blob/main/docs/releases/2.2.0.md)
- Start sound plays about 50 ms after the press (fixed in 2.3.1; previously ~345 ms). "Sound volume"; zero turns tones off. (dictation doc, https://github.com/anomalyco/hex/blob/main/docs/releases/2.3.1.md)
- Prevents Mac idle sleep while recording. (map)
- Menu bar hexagon icon; "Show Dock icon" preference. (README, map)
- Linux: `hex dictation start` / `stop` / `toggle` commands to bind in the window manager. (README)
- Spoken start: "dictate start" / "dictate stop" / "dictate send" / "dictate cancel" when Voice Commands are on. (https://github.com/anomalyco/hex/blob/main/docs/features/commands.md)
- System audio: captured only for Meetings (see Beyond dictation). Not mixed into dictation.
- Experimental "Hex microphone" (macOS, hidden behind `HEX_EXPERIMENTAL_MIC=1`): installs a virtual microphone driver so other apps on a call hear a muffled or muted version of your voice while you dictate; modes "Muffled (default), Muted, Quiet, Normal, Chipmunk, Robot, Walkie, Underwater, Far". (map)
- Push-to-talk from another device: none found.

### Transcription engine

- All dictation is local. Models are GGUF files downloaded from Handy's Hugging Face repositories (`handy-computer/...`) and run on Metal (macOS) or Vulkan (Windows x64, Linux). (models src, dictation doc)
- Models offered, with Hex's own speed and error-rate labels: "Parakeet Unified English" (default for new installs, ~731 MB, "~163x" realtime, 1.60% on an English benchmark, streams), "Parakeet v2" (~730 MB, ~55x, 1.69%), "Parakeet v3" (~740 MB, ~33x, 1.94%, 25 languages), "Whisper large-v3-turbo" (~886 MB, ~19x, 2.01%, 100 languages), "Qwen3-ASR 0.6B" (~850 MB, 30 languages), "SenseVoice Small" (~253 MB, 5 languages), "Cohere Transcribe" (~2.4 GB, "73x", 1.27%, 14 languages), and "Apple Speech" (Apple's on-device engine, "System locales"). (models src)
- Picker tags: "Recommended", "Fastest", "Most accurate", "Recognition hints", "Streams". (models src, 2.3.0 notes)
- Swift app: Parakeet TDT v3 through FluidAudio and Whisper models through WhisperKit. (https://github.com/kitlangton/Hex/blob/main/README.md)
- Cloud speech models: none.
- Language is chosen per model; "Each model remembers its last selected language and, for Whisper, recognition hints." Switch models from "menu bar > Transcription Model" without opening Settings. (README)
- Auto language detection: supported by Whisper, Qwen3-ASR and SenseVoice entries (`supports_language_detection: true`); default language is "en". (models src)
- Speed claims: 2.3.0 streams every dictation so "releasing the shortcut finishes in about a tenth of a second, however long you talked"; "A 2-minute dictation finishes in 0.1 s instead of … 2.8 s on a MacBook Air M4". (2.3.0 notes)
- Falls back to whole-clip transcription if streaming fails, produces no text, or takes over 1.5 s to finish. (dictation doc)
- Skips silent captures "instead of pasting phantom text such as 'thank you'" (2.2.0). An open issue (#193, 2026-10-22) reports Whisper still inventing text on silence. (2.2.0 notes, https://github.com/anomalyco/hex/issues/193)

### Live preview

- None. The dictation doc states "Nothing is shown or pasted until the final text exists", even though the model streams internally. (dictation doc)
- "Recording indicator": the dictation pill at top or bottom of the screen, or hidden (2.3.0). It shows recording and processing state, not words. (settings src, 2.3.0 notes)
- An open Swift-repo request, "Live transcription preview while speaking" (#237). (https://github.com/kitlangton/Hex/issues/237)
- Meetings floating indicator offers "Copy new" and "Copy all" for the transcript so far (2.3.1). (2.3.1 notes)

### Cleanup & formatting

- "Modes": text-processing profiles picked by the frontmost app ("Switch when an app is frontmost") or, in Brave Browser only, by website host. "Global" is the fallback ("Used unless a more specific mode matches"). Example app targets in the UI: Chat, Slack, Terminal, Visual Studio Code, WezTerm, Firefox. (modes src, README)
- Each mode runs in order: "Corrections" → "OpenCode transformation" (optional AI rewrite with "System instructions for rewriting dictation in this mode" and a "Deadline" in seconds) → "Transformations" (ordered text chain) → paste. If a stage fails, its input is kept. (map, modes src)
- Built-in transformations: "Smart punctuation" ("Curly quotes, dashes, and ellipses"), "Normalize links", Lowercase, SpongeBob case, "No trailing punctuation". (modes src, map)
- "Custom transformations": user TypeScript functions in a managed Bun workspace. (modes src, README)
- AI rewrite sends the transcript, the foreground app name and the Brave website hostname to the user's OpenCode provider. (README)
- Filler-word removal, self-correction handling, number/list formatting: none found as named features; only possible through a user's OpenCode instructions.
- Avoids "stray periods where you paused mid-sentence" (2.2.0). (2.2.0 notes)
- Context awareness: foreground app name and Brave URL host for mode selection; selected text only for Voice Action. No screen reading found.

### Personalization

- "Corrections" (also called text replacements): "Spoken phrase (e.g. open code)" → "Replacement (e.g. OpenCode)", global or per mode. Open issue: replacements never match Chinese/Japanese text (#177). (modes src, https://github.com/anomalyco/hex/issues/177)
- "Recognition hints": "Names and terms to prime the speech model", Whisper only. (settings src, models src)
- Per-app rules: Modes (above).
- Snippets / text expansion: none found as a named feature (a Correction could act as one).
- Auto-learning from edits: none found.

### Output & editing

- Pastes at the current focus through the clipboard and Cmd+V; dictated text is marked transient so clipboard managers skip it (2.2.0). Chromium browsers get a 150 ms pause before Cmd+V to work around a Chrome 155 bug. (map, 2.2.0 notes)
- "Terminal paste": "Paste with Ctrl+Shift+V so terminals accept it" (Linux/Windows setting). (settings src)
- "Paste last dictation" (Option-Shift-V, also in the menu). (README)
- "dictate send" voice control pastes then presses Enter. (commands doc)
- History: inspect, search, copy, delete; text only, no audio. Retention seven days by default, capped at 10,000 entries and 16 MiB; "Keep: Off" and "Clear all". (README, map)
- Command line: `hex history --since 3d --app … --grep … --json` reads history while the app runs. (README)
- Edit before paste, undo, retry/re-transcribe: none found. Open requests for keeping the text on the clipboard after paste (#200) and a copy popup when paste fails (#192). (https://github.com/anomalyco/hex/issues/200, /192)

### Voice commands

- "Voice commands" (macOS, experimental, off by default): continuous local listening with a separate Moonshine command model downloaded from `download.moonshine.ai`. (README)
- Sleep and wake: "go to sleep" / "stop voice control" to sleep; "voice control" / "wake up" / "start voice control" to wake. (commands doc)
- The "Commands" pane lists built-in phrases filtered by global, app and Brave-website scope. Phrases seen in code tests include "press enter", "go back", "open slack", "search amazon for …"; the full shipped list was not extracted. (commands doc, https://github.com/anomalyco/hex/blob/main/src/commands.rs)
- Personal commands in `~/.config/hex/hex.config.ts` (TypeScript, needs Bun), with an "Edit Config" action, a prompt to paste into a coding agent, and an installable agent skill `npx skills add anomalyco/hex --skill hex-personal-commands`. (README)
- "Voice Action" (off by default): hold Option-Command, describe what you want; Hex sends the instruction, selected text, foreground app and Brave hostname to OpenCode and pastes the result. (README)
- "New line" / "new paragraph" dictation commands: none found.

### Beyond dictation

- "Meetings (beta)", off by default, macOS only (2.2.0, 2026-10-16): offers to record when Zoom, Meet, Slack, Teams, FaceTime or a browser call uses the mic (never starts on its own); records system audio and mic as separate tracks; transcribes locally into Markdown with "You" and "Them" turns; removes your speakers' echo from your track; saves to `~/Documents/Hex Meetings`; "Never offer" list per app or site. (https://github.com/anomalyco/hex/blob/main/docs/features/meetings.md, 2.2.0 notes)
- "Summarize with Apple Intelligence" (on by default inside Meetings): on-device title and short summary. (meetings doc)
- Meetings pane: search, rename, delete, Markdown export. (2.2.0 notes)
- `hex mcp`: read-only MCP server (Model Context Protocol, the standard AI agents use to call tools) so agents can read meeting transcripts; `hex meetings list/show/search` CLI. (README, meetings doc)
- TypeScript SDK `@kitlangton/hex` on npm for local transcription in other apps (native helper not yet published). (README)
- File transcription in the app, translation, AI chat: none found (Voice Action is the closest to AI rewrite of selected text).

### Platforms & sync

- macOS 15+ on Apple Silicon only; the website disables the Intel download with "needs Apple silicon". (README, map)
- Windows beta: Windows 10 and 11, x64 (needs Vulkan driver) and ARM64 (CPU only); not code-signed, so SmartScreen warns. No voice commands or meetings. (README)
- Linux beta: x86_64 Arch with glibc 2.44+, X11 and wlroots Wayland; no voice commands or meetings. Nix/NixOS packaging. (README)
- iOS: "Native prototype, not the distributed macOS product" with a keyboard extension; not shipped. (https://github.com/anomalyco/hex/blob/main/ios/README.md)
- Interface languages: English, Chinese, German, Japanese, Polish, Spanish, or follow system (2.3.0). (2.3.0 notes)
- Cross-device sync: none. A meetings mirror for "Another Mac's Meetings" works by copying the folder with rsync. (meetings doc)

### Privacy & data

- "Speech transcription and command recognition run locally." (README)
- "HEX does not save dictation audio by default." History stores text and "limited application and timing metadata", never audio, full URLs or window titles. (README)
- Local diagnostic logs can contain transcript text and app names, are not uploaded, and are "currently unbounded on disk". (README, map)
- Off-device traffic: model downloads (Hugging Face, Moonshine), signed updates through Sparkle from `downloads.hex.kitlangton.com`/`.dev`, and OpenCode features to the user's provider. (README)
- Managed Macs can turn off updates with `defaults write com.kitlangton.hex2 DisableUpdates -bool true`. (README)
- SOC 2 / HIPAA: none.

### Onboarding & permissions

- Setup asks for Microphone, Input Monitoring (to see the shortcut globally) and Accessibility (to paste); the user drags the HEX tile into the macOS lists. Then a model download. (README)
- Guided first run "with a short practice dictation" in a focused practice field, skippable (2.3.1). (2.3.1 notes, map)
- Missing model shows "a prominent notice with a model-picker action" (2.1.0). (2.1.0 notes)
- Meetings asks for "System Audio Recording Only" permission only when turned on. (meetings doc)
- Open bug: dragging HEX into the Accessibility list has no effect (#196, 2026-10-22). (https://github.com/anomalyco/hex/issues/196)

### Accessibility

- VoiceOver, keyboard-only or Voice Control claims: none found in README or feature map.

### Distribution

- Signed DMG from https://hex.kitlangton.com and GitHub releases (`app-v…` tags). (README)
- Homebrew: `brew install --cask anomalyco/tap/hex` (Rust); `brew install --cask kitlangton-hex` (Swift). (README, Swift README)
- Windows Setup.exe per user without admin; Linux `curl … | sh` installer. (README)
- Not on the Mac App Store or Setapp (none found).
- Open source, MIT. Rust with its own "Rune" UI layer; Swift app used the Composable Architecture.

## Recent changes (last 12 months)

- Swift app v0.8.3 (2026-07-09) to v0.8.5 (2026-08-27): last Swift releases. Repository archived with "Archived: legacy Swift Hex app" on 2026-10-14. (https://github.com/kitlangton/Hex/releases)
- Rust repository created 2026-07-17. 2.0: "language-first local transcription model selection", first-run setup, Sparkle updates. (https://github.com/anomalyco/hex/blob/main/release-notes/2.0.0.md)
- 2.1.0: new bundle ID, default model Parakeet Unified English 0.6B, side-specific shortcuts, Paste Last, Voice Action, Modes, text replacements, text-only History. (2.1.0 notes)
- 2.2.0 (2026-10-16): faster transcription ("long dictations that took several seconds now finish in under two"), 200 ms release tail, silent-capture skipping, transient clipboard, Dvorak-QWERTY ⌘ fix, Meetings beta with Apple Intelligence summaries and `hex mcp`. (2.2.0 notes)
- 2.3.0 (2026-10-19): Windows beta, streaming on every platform, Shortcut mode Hold/Toggle, Recording indicator top/bottom/hidden, interface languages, Chrome 155/156 paste fix. (2.3.0 notes)
- 2.3.1 (2026-10-21): instant start tone, Slack/Chromium call detection, meeting floating indicator, guided first run with practice dictation. (2.3.1 notes)
- 2026-10-23 commit: read-only history and meetings CLI for agents. (https://github.com/anomalyco/hex/commits/main)

## User reception

- HN, Jan 2026: "Hex — Feels the leanest (& cleanest) free options mentioned for Mac in this thread", but "Hex seems to be upset about me installing all the others… lots of restarting". (https://news.ycombinator.com/item?id=46637040)
- HN, Jul 2026: uses Hex "for near instant transcription with Parakeet V3. This is how I speak to Code agents at least 80% of the time"; switched from Handy because of "stuttering and other issues". (https://news.ycombinator.com/item?id=48968577)
- Most-upvoted Swift issues: crash on launch from a keyboard-monitor deadlock (#258, #254 on macOS 26.5.1), hotkey not working on M1 Sequoia (#126), toggle instead of hold (#108, since shipped in 2.3.0), live preview while speaking (#237), add space after recording (#68). (https://github.com/kitlangton/Hex/issues)
- Rust app issues in its first week: shortcut stops working after a few minutes on macOS 26.6.1 (#195), meeting transcription always English (#182), request to use the F5 Dictation key as the shortcut (#181), red indicator not visible (#179). (https://github.com/anomalyco/hex/issues)
- No App Store, Product Hunt or r/macapps reviews of the Rust 2.x app found; it is two weeks old as a public release.

## Gaps I could not verify

- Full list of built-in voice command phrases (only test examples seen).
- Whether the Swift app had a word list or filler removal (its settings source was not read; it is archived).
- Real-world latency of the 2.3 streaming path outside the developer's own numbers.
- Whether Modes and OpenCode rewriting work without the separate OpenCode V2 beta installed (README implies they need it).
- Website-aware modes in browsers other than Brave (docs say only Brave today).
