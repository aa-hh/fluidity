# Handy

- Vendor: CJ Pais (solo maintainer, many community contributors), sponsored by Wordcab, Epicenter, Bolt AI, Canty Digital
- Platforms: macOS (Apple Silicon and Intel), Windows (x64 and ARM64), Linux (deb, rpm, AppImage; x86_64 and aarch64)
- URL: https://handy.computer, source https://github.com/cjpais/Handy
- GitHub: 34,384 stars, MIT licence, last commit 2026-10-21 ("fix: stop blocking the main thread during paste (#2302)"), latest release v0.9.8 on 2026-10-03
- Date checked: 2026-10-23
- Placement: minimal, drifting toward mid. The site pitch is "One tool, one job. Transcribe what you say and put it into a text box", and it is free with no account, but it now ships a 76-model catalog, a live streaming preview and bring-your-own-key AI cleanup.

## Pricing

- Free. No paid tier, no account, no word or minute limits. Site: "Accessibility tooling belongs in everyone's hands, not behind a paywall." (https://handy.computer)
- Donations only: Stripe donation link, GitHub Sponsors (https://github.com/sponsors/cjpais). (https://handy.computer)
- Bring-your-own API key for optional cloud cleanup (see Cleanup). Handy itself charges nothing for it. (src-tauri/src/settings.rs)
- No team or education plans found.

## Feature inventory

Source abbreviations: "strings" = English UI strings file https://github.com/cjpais/Handy/blob/main/src/i18n/locales/en/translation.json ; "settings.rs" = https://github.com/cjpais/Handy/blob/main/src-tauri/src/settings.rs ; "catalog" = https://github.com/cjpais/Handy/blob/main/src-tauri/src/catalog/catalog.json ; "README" = https://github.com/cjpais/Handy/blob/main/README.md. Everything is free.

### Trigger & capture

- "Transcribe Shortcut": default Option+Space on macOS, Ctrl+Space on Windows and Linux. Rebindable. (free) (settings.rs, strings)
- "Shortcut Behavior" with three options: "Auto" ("Hold to record or tap to toggle", the default), "Hold" ("Records while you hold the shortcut"), "Toggle" ("Tap the shortcut to start recording, tap again to stop"). (free) (strings, settings.rs `ShortcutActivation`)
- "Hold Threshold" (Debug menu): in Auto mode, how long the key must be held before it counts as a hold. Default 300 ms. (free) (strings, settings.rs)
- fn / Globe key works as a shortcut on macOS since v0.7.0 (2026-01-20), but only on Apple keyboards; README explains third-party keyboards never send an fn event. (free) (https://github.com/cjpais/Handy/releases/tag/v0.7.0, README)
- "Cancel Shortcut": default Escape. (free) (settings.rs)
- "Post-Processing Hotkey": a second shortcut that always runs AI cleanup. Default Option+Shift+Space on macOS. (free) (strings, settings.rs)
- "Keyboard Implementation" (Debug): choose the shortcut backend (Tauri's or Handy's own "HandyKeys"). (free) (strings, settings.rs)
- "Keyboard Diagnostic" (Debug): 10-second test that checks whether key events reach Handy and whether macOS Secure Input (a mode password fields turn on that blocks other apps from seeing keystrokes) is blocking them, naming the app holding it. Tray shows "⚠ Shortcuts blocked by Secure Input". (free) (strings)
- Menu bar / tray icon ("Show Tray Icon"), "Start Hidden", "Launch on Startup". (free) (strings)
- "Microphone" picker, "Input Channel" picker for multi-input audio interfaces ("Average all channels" or "Channel n"). (free) (strings)
- "Clamshell Microphone": a separate mic to use when the laptop lid is closed. (free) (strings)
- "Always-On Microphone": keep the mic open for faster start. "Keep Mic Open Between Transcriptions": keeps it open 30 s after each recording. (free) (strings)
- "Extra Recording Buffer": keep recording N ms after key release to catch trailing words. (free) (strings)
- "Mute While Recording": mutes system audio during recording. (free) (strings)
- "Audio Feedback" start/stop sounds, "Sound Theme" Marimba / Pop / Custom, "Output Device", "Volume". (free) (strings, settings.rs)
- "Voice Activity Detection" (filters silence), backend "Silero" or experimental "Earshot". (free) (strings)
- Remote triggers: command-line flags `--toggle-transcription`, `--toggle-post-process`, `--cancel` sent to the running app; Linux also accepts SIGUSR2. (free) (https://github.com/cjpais/Handy/blob/main/src-tauri/src/cli.rs, README)
- Raycast extension (community, by mattiacolombomc): "start/stop recording, browse transcript history, manage dictionary, switch models and languages". (free) (README)
- System-audio capture: none found (checked strings and settings.rs).
- Push-to-talk from other devices (phone, watch): none found.

### Transcription engine

- All transcription is local, through Handy's own engine transcribe.cpp built on ggml (since v0.9.0, 2026-07-01). (free) (https://github.com/cjpais/Handy/releases/tag/v0.9.0, strings)
- Catalog of 76 entries; 29 marked curated (shown by default), including: "Parakeet Unified English 0.6B" (618M parameters, ~731 MB, "Best all-around choice for English dictation", streaming), "Nemotron Streaming 3.5" (638M, 32 language codes, streaming), "Canary 180M Flash" (189M, ~218 MB, 4 languages, translates), "Cohere Transcribe" (2.0B, ~2.4 GB, 14 languages), "Whisper Medium" (764M, 99 languages), "Voxtral Mini 4B Realtime" (4.4B, ~4.7 GB, streaming), "Parakeet Ultra" and "Parakeet TDT 0.6B v3" (25 European languages), "Parakeet TDT 0.6B v2" (English), "Qwen3-ASR 0.6B" and "1.7B" (30 languages), "Fun-ASR Nano" and "Fun-ASR Nano Multilingual", "Canary 1B v2", "Canary-Qwen 2.5B", "Cohere Transcribe Arabic", "GigaAM v3" (Russian), "Granite Speech 5.0 470M TurboCTC", "Granite Speech 4.1 2B", "MedASR" (105M, "For clinicians dictating notes"), "Parakeet TDT-CTC 110M" ("virtually instant even on CPU"), "Parakeet Multitalker English", "SenseVoice Small", "Voxtral Mini 3B", "Whisper Small", "Whisper Large v3 Turbo", "Breeze-ASR-25", "Whisper Large v3". Non-curated extras include Moonshine Tiny/Base (27M–62M) in several languages, Whisper Tiny/Base, and "Voxtral Small 24B" (~25.8 GB). All quantised Q8_0. (free) (catalog)
- Custom Whisper GGML models can be dropped into the models folder; "Rescan" picks up models added to the folder or the Hugging Face cache. (free) (README, strings)
- Cloud speech models: none. Cloud is only used for text cleanup.
- "Language": searchable list with "Auto" (default `auto`). Auto detection uses a shared "VoxLingua107 Language ID" model (107 languages) for models that cannot detect language themselves. (free) (strings, settings.rs, catalog)
- Language count: up to 100 languages on Whisper Large v3 entries; varies per model. Model cards show "{{total}} languages" and filters "All Languages", streaming, translation. (catalog, strings)
- "Translate to English": automatic translation during transcription, on supporting models. (free) (strings)
- "Hardware Acceleration": "Auto uses the GPU when available and falls back to the CPU"; GPU device list. (free) (strings)
- "Unload Model": Never / Immediately / 2, 5, 10, 15 min / 1 hour. Tray "Unload Model". (free) (strings)
- "Long Audio Chunking": splits long recordings at pauses. (free) (strings)
- "Chinese Script": As Transcribed / Simplified / Traditional. (free) (strings)
- Model switching UI: Models page with "Downloaded Models" and "Available to Download", accuracy and speed bars per model card, search box; tray "Model" submenu. (free) (strings)
- Speed claims: v0.8.0 notes say Whisper got ">2x as fast on my Mac". No published latency number found. (https://github.com/cjpais/Handy/releases/tag/v0.8.0)

### Live preview

- "Overlay" setting: "None", "Minimal" (compact pill), "Live" ("shows transcription in real time as you speak", streaming-capable models only). Default Live on macOS and Windows, None on Linux. (free) (strings, settings.rs)
- "Overlay Position": Bottom (default) or Top. (free) (strings)
- Streaming models are labelled "Streaming" / "Shows live transcription as you speak" in the model picker. (free) (strings)
- Whether live words change after first display: not verified.

### Cleanup & formatting

- "Remove Filler Words": on by default, removes hesitation words, no AI involved. (free) (strings, settings.rs)
- "Post Processing" ("Enable AI-powered text refinement after transcription"), off by default. Providers: OpenAI, Z.AI, OpenRouter, Anthropic, Groq, Cerebras, "Apple Intelligence" (on-device, Apple Silicon Macs on macOS 26 Tahoe or later with Apple Intelligence on), "AWS Bedrock (Mantle)", and "Custom" (any OpenAI-compatible or Anthropic Messages endpoint, default base URL `http://localhost:11434/v1`, which is Ollama). Each takes "API Key", "Base URL", "Model" with "Refresh models". (free, BYO key) (settings.rs, strings)
- "Prompt": user-editable prompt templates with "Create New Prompt", using `${output}` for the transcript. One built-in prompt, "Improve Transcriptions": fixes spelling, capitalisation and punctuation, converts number words to digits ("twenty-five → 25, ten percent → 10%, five dollars → $5"), replaces spoken punctuation ("period → ."), removes filler, keeps the original language, and tells the model not to answer questions in the transcript. (free) (settings.rs)
- Self-correction handling ("no wait, I meant"): none found outside what a user's own prompt asks for.
- Per-app formatting or tone: none found.
- Context awareness (screen, selected text, clipboard, app name): none found in settings or strings.
- "Append Trailing Space" (Debug). (free) (strings)

### Personalization

- "Custom Words": "Help supported models recognize names and specialized terms. Fuzzy correction is currently limited to words using A–Z and numbers." Fuzzy match sensitivity is "Word Correction Threshold", default 0.18. (free) (strings, settings.rs)
- Text snippets / expansions: none found.
- Auto-learning from edits: none found.
- Per-app rules: none found.
- Replacement list: an HN reply from the author (Jan 2026) said a text-replacement pull request was in progress; not found in current settings strings. (https://news.ycombinator.com/item?id=46630226)

### Output & editing

- "Paste Method": "Clipboard (Cmd+V)", "Clipboard (Ctrl+Shift+V)", "Clipboard (Shift+Insert)", "Direct" (simulated typing; dropped from the macOS UI in v0.9.4), "None" (only history/clipboard), "External Script" (path to your own script). (free) (strings, https://github.com/cjpais/Handy/releases/tag/v0.9.4)
- "Clipboard Handling": "Don't Modify Clipboard" (restores old clipboard) or "Copy to Clipboard". Non-text clipboard content is preserved since v0.9.5. (free) (strings, https://github.com/cjpais/Handy/releases/tag/v0.9.5)
- "Paste Delay (Before)" and "(After)", default 60 ms each; "Reliable Paste (Beta)" restores the clipboard only after the target app reads it. (free) (strings, settings.rs)
- "Auto Submit": send Enter / Cmd+Enter / Super+Enter / Ctrl+Enter after pasting. (free) (strings)
- History page: copy, "Save transcription" (pin), delete, play back audio, "Re-transcribe" (retry with the current model), "Open Recordings Folder". Recordings are kept even if transcription fails (since v0.8.0). (free) (strings, https://github.com/cjpais/Handy/releases/tag/v0.8.0)
- "History Limit": default 5 entries. "Auto-Delete Recordings": Never / "Keep latest N" (default) / 3 days / 2 weeks / 3 months. (free) (strings, settings.rs)
- Tray "Copy Last Transcript". (free) (strings)
- History search: none found in strings.
- Edit before paste: none found.
- Undo: none found beyond the target app's own undo.

### Voice commands

- None found. No "new line", command mode or editing-by-voice strings in the UI strings file or settings.rs.

### Beyond dictation

- Headless file transcription from the command line: `handy --transcribe-file x.wav` (16 kHz mono WAV), with `--model`, `--list-models`, `--json`, `--repeat`. No file transcription in the GUI found. (free) (https://github.com/cjpais/Handy/blob/main/src-tauri/src/cli.rs)
- "Translate to English" (see engine). (free)
- Meeting recording, notes, summaries, AI chat on selected text: none found. A "Parakeet Multitalker English" model exists "For overlapping speakers in meetings", and a speaker-separation model ("Streaming Sortformer 4-Speaker") is in the catalog, but no meeting feature in the UI. (catalog)

### Platforms & sync

- macOS: Apple Silicon (`aarch64.dmg`) and Intel (`x64.dmg`) builds in every release; `minimumSystemVersion` 10.15 in tauri.conf.json. (https://github.com/cjpais/Handy/releases/tag/v0.9.8, https://github.com/cjpais/Handy/blob/main/src-tauri/tauri.conf.json)
- Windows x64 and ARM64 (exe, msi); Linux deb, rpm, AppImage on x86_64 and aarch64. (release assets)
- Apple Intelligence cleanup only on Apple Silicon with macOS 26+. (strings)
- iOS / Android: none. Reviewers list "no mobile app" as a con. (https://spokenly.app/blog/handy-review)
- Sync across devices: none found.
- UI translated into many languages (Turkish, Dutch, Hindi, Danish, Swedish, Bulgarian, Hebrew and more added in the last year). (release notes)

### Privacy & data

- "Your voice stays on your computer. Get transcriptions without sending audio to the cloud." (https://handy.computer)
- No telemetry: "Handy does not contain advertising, behavioral analytics, or user-tracking telemetry." (https://handy.computer/privacy)
- Off-device traffic: update checks to GitHub Releases (on by default, can be turned off; also blockable by `HANDY_DISABLE_UPDATER`), model downloads from Hugging Face with fallback `blob.handy.computer`, and opt-in cloud cleanup straight to the chosen provider. (https://handy.computer/privacy, strings)
- Local history and settings are not encrypted by Handy. (https://handy.computer/privacy)
- Release signatures verifiable with minisign. (README)
- SOC 2 / HIPAA: none (no server side to certify).

### Onboarding & permissions

- First run: pick a model ("To get started, choose a transcription model", with "Recommended" tag), then a "Permissions Required" screen with "Microphone Access" and "Accessibility Access" cards, each with "Grant Permission" and a live "Waiting..." / "Granted" state, ending "All set!". (free) (strings)
- "Show What's New" release notes after updates. (strings)
- Tutorial beyond this: none found.

### Accessibility

- Positioned as accessibility tooling ("Accessibility tooling belongs in everyone's hands") and built after the author broke a finger. (https://handy.computer, https://spokenly.app/blog/handy-review)
- VoiceOver, keyboard-only or Voice Control claims: none found.

### Distribution

- Direct download from handy.computer and GitHub Releases. (README)
- Homebrew cask `brew install --cask handy` and winget `cjpais.Handy`, both community-maintained. (README)
- Not on the Mac App Store or Setapp (none found).
- Open source, MIT. Built with Tauri (Rust back end, React/TypeScript front end).

## Recent changes (last 12 months)

- v0.6.0, 2025-11-07: LLM post-processing added, hidden in the Debug menu at first. (https://github.com/cjpais/Handy/releases/tag/v0.6.0)
- v0.7.0, 2026-01-20: fn key on macOS, "Copy Last Transcript" tray action, automatic filler word removal, settings reorganised with "Experimental" toggle. (https://github.com/cjpais/Handy/releases/tag/v0.7.0)
- v0.8.0, 2026-03-23: Whisper ">2x as fast", recordings saved even when transcription fails. v0.8.2 (2026-04-02) added Cohere Transcribe. (https://github.com/cjpais/Handy/releases/tag/v0.8.0, /v0.8.2)
- v0.9.0, 2026-07-01: own engine transcribe.cpp, streaming models and the live overlay, "a ton of new models". (https://github.com/cjpais/Handy/releases/tag/v0.9.0)
- v0.9.4, 2026-07-21: "Direct" paste removed from macOS UI. v0.9.5 (2026-08-08): keeps non-text clipboard content. v0.9.7 (2026-09-18): "stop losing tail audio", experimental Earshot silence detector, "auto push to talk mode". v0.9.8 (2026-10-03): bug fixes. (release pages)

## User reception

- HN, Jan 2026 (247 points): "It works really well compared to the commercial competitors but with a local model." (https://news.ycombinator.com/item?id=46629199)
- HN: "It's incredibly fast on my MacBook m1 air and more accurate that the native speech to text." (https://news.ycombinator.com/item?id=46630363)
- HN: "Huge fan! Parakeet v3 works great with it… at least as good [as Monologue, Superwhisper, Aqua]." (https://news.ycombinator.com/item?id=46635172)
- HN complaint: on an M4 MacBook Air "there was always a 1-2sec delay before it would actually start transcribing". (https://news.ycombinator.com/item?id=46629690)
- HN: missing dictionary was a blocker to leaving Wispr Flow; another user pointed to "Custom Words" and to cleanup being hidden in the Debug menu. (https://news.ycombinator.com/item?id=46629201, https://news.ycombinator.com/item?id=46644765)
- HN: "Crashes on Tahoe 26.3 Beta 1". (https://news.ycombinator.com/item?id=46629611)
- Spokenly review cons: no mobile app, raw verbatim output with no AI cleanup by default, 2–5 s delay, occasional clipped first word. (https://spokenly.app/blog/handy-review) Voibe review also flags first-word clipping, 7.5/10. (https://www.getvoibe.com/resources/handy-review/) Both are competitor-written.
- Product Hunt users call it fast, private, free; one compares it favourably with SuperWhisper's paywalled features such as re-running a transcription. (https://www.producthunt.com/products/handy-4)

## Gaps I could not verify

- Whether live overlay words are revised after first display.
- Whether the `fn` key works for hold mode on non-Apple keyboards via any workaround (README says no).
- Actual end-to-end latency numbers.
- Whether the text-replacement feature mentioned in Jan 2026 shipped under another name.
- Any VoiceOver support for Handy's own settings window.
