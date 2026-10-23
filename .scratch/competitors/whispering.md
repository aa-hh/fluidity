# Whispering (Epicenter Whispering)

- Vendor: Epicenter (Braden Wong; GitHub org `epicenter-md`, formerly `EpicenterHQ` / `epicenter-so`). The founder said on HN that the company went through Y Combinator (https://news.ycombinator.com/item?id=44948607 asks; not confirmed by vendor page).
- Platforms (last release v7.11.0): macOS (Apple Silicon and Intel), Windows, Linux, plus a browser web app without global shortcuts.
- URL: https://whispering.bradenwong.com (returns an empty single-page shell to a fetcher; no readable content). Source: https://github.com/epicenter-md/epicenter/tree/main/apps/whispering
- Date checked: 2026-10-23
- Placement: **minimal to lower-mid.** Free and BYO-key, with a global shortcut, push-to-talk, a voice-activated mode, paste at cursor and chained prompt "Transformations", but no dictionary, no context awareness, no live preview, no per-app rules.

**Status warning.** Two different apps share this name:
1. **v7.11.0** (released 2025-12-27) is the last shipped build and the subject of this inventory. Source read at tag `v7.11.0`.
2. **The current `main` branch** (checked 2026-10-23) is an unreleased rewrite, described as "a development milestone, not a release". It drops system-wide dictation: "System-wide dictation: global shortcuts, push-to-talk, voice-activated recording, and delivering text to the cursor or clipboard automatically" are listed under "What is not supported", along with "On-device transcription models". Text leaves only via Copy buttons. Source: `apps/whispering/README.md` on main. No release has shipped in the 10 months since v7.11.0 (https://github.com/epicenter-md/epicenter/releases).

## Pricing
- Free, open source (AGPL-3.0 per README badge "AGPLv3 License" in v7.11.0 README). No paid tier, no trial, no account.
- BYO key for every cloud service. README cost table (vendor's own figures): Groq `whisper-large-v3-turbo` "$0.04" per hour, Groq `whisper-large-v3` "$0.111", OpenAI `gpt-4o-mini-transcribe` "$0.18", Local "$0.00"; compared with "Traditional Tools" "$15-30/month".
- Founder on HN, 2025-08: "Right now, the pricing is entirely free ... Subscriptions are up to the user right now." https://news.ycombinator.com/item?id=44952815
- Team / education plans: none found.

## Feature inventory
All features free. Sources are files under `apps/whispering/` at tag v7.11.0 unless a URL is given.

### Trigger & capture
- "Recording Mode": "Manual", "Voice Activated", "Upload File" (`src/lib/constants/audio/recording-modes.ts`).
- "Voice Activated" (VAD, voice activity detection): "Press shortcut once → VAD starts listening ... Stop speaking → Recording stops after a brief pause" (README).
- Global shortcuts with defaults (`src/lib/settings/settings.ts`): toggle manual recording `Cmd/Ctrl+Shift+;`, cancel `Cmd/Ctrl+Shift+'`, "pushToTalk" `Cmd/Alt+Shift+D` (hold to talk), open transformation picker `Cmd/Ctrl+Shift+X`, run transformation on clipboard `Cmd/Ctrl+Shift+R`; plus unassigned start/stop manual and toggle/start/stop VAD.
- In-window ("local") shortcuts: Space toggles recording, `c` cancel, `v` VAD, `p` push-to-talk, `t` transformation picker, `r` run on clipboard.
- All shortcuts are rebindable ("Custom Shortcuts", README).
- Known macOS issue: "Global shortcut stops working?" because of App Nap; README advice is to keep the window in the foreground or use Voice Activated mode.
- "Recording Method": "CPAL" (Rust, default), "FFmpeg", "Browser API" (`settings/recording/+page.svelte`), with "Bitrate", "Sample Rate", FFmpeg command builder, output folder.
- Microphone selection per recording method (`ManualDeviceSelector`, `VadDeviceSelector`).
- "Always On Top": "Always", "When Recording and Transcribing", "When Recording", "Never".
- "Launch on Startup" (v7.11.0).
- Sounds: "Manual Recording Sounds", "VAD Recording Sounds", "Completion Sounds" (eight separate toggles).
- Menu bar vs Dock: the app is a normal window; no menu-bar-only mode found.
- System-audio capture: none found. An HN commenter asked for mic plus system audio (https://news.ycombinator.com/item?id=44959904); no response showing it shipped.
- Push-to-talk from other devices: none found.

### Transcription engine
Source: `src/lib/services/isomorphic/transcription/registry.ts` and `local/*.ts`.
- Local (macOS and Linux): "Whisper C++" models "Tiny" 78 MB, "Small" 488 MB, "Medium" 1.5 GB, "Large v3 Turbo" 1.6 GB, or browse for your own model file.
- Local (all platforms): "Parakeet" model "Parakeet TDT 0.6B v3 (INT8)" ~670 MB; "automatically detects the language".
- Local (macOS and Linux): "Moonshine" models "Moonshine Tiny (English)" ~30 MB, "Moonshine Base (English)" ~65 MB.
- Windows ships Parakeet only (v7.11.0 release notes).
- Self-hosted: "Speaches" server (base URL default `http://localhost:8000`).
- Cloud (user key): Groq, OpenAI, ElevenLabs, Deepgram, "Mistral AI"; custom OpenAI-compatible transcription endpoint (v7.9.0). README lists Groq `whisper-large-v3-turbo`, `whisper-large-v3`; OpenAI `whisper-1`, `gpt-4o-transcribe`, `gpt-4o-mini-transcribe`; ElevenLabs `scribe_v1`, `scribe_v1_experimental`.
- "Output Language" picker; the supported-languages file holds 57 two-letter codes (`src/lib/constants/languages/supported-languages.ts`). Vendor gives no language count.
- "Temperature" and "System Prompt" (vocabulary hint, e.g. "This is an academic lecture about quantum physics with technical terms like...") for transcription; System Prompt works with Whisper C++ since v7.10.0.
- Compression before transcription via FFmpeg (v7.4.0), "can strip silence, shrink file sizes".
- Speed: v7.5.4 "enormous speed boost to Parakeet" via a model kept loaded between runs. README: "Local transcription is slower than cloud options".

### Live preview
- None found. Transcription runs after recording stops. An HN commenter named the "lack of real-time visual indication" as a problem for this category (https://news.ycombinator.com/item?id=44949429).

### Cleanup & formatting
- "Transformations": named, chained steps of type "Prompt Transform" (system and user prompt with `{{input}}`, any provider/model) or "Find Replace" (`src/lib/constants/database/transformation-types.ts`).
- One transformation can be selected to run automatically after each transcription ("Save and select it in your recording settings", README; `transformations.selectedTransformationId`).
- README's example "Format Text" prompt covers punctuation, paragraphing, lists, filler removal ("Remove excessive filler words (um, uh)") and "Correct obvious misspeaks". These are user-supplied prompt text, not built-in behavior.
- Providers for transformations: OpenAI, Anthropic, Google Gemini, Groq, OpenRouter, "Custom (OpenAI-Compatible)" for Ollama, LM Studio, vLLM (v7.8.0).
- No built-in filler removal or self-correction without a transformation.
- Context awareness (screen, app name, selected text): none found. Clipboard is used only as input to "run transformation on clipboard".
- Per-app formatting: none found.

### Personalization
- Custom vocabulary: only through the transcription "System Prompt" field.
- Replacements: "Find Replace" transformation steps.
- Snippets, auto-learning, per-app rules: none found.

### Output & editing
- "Transcription output": copy to clipboard (default on), "write to cursor" (paste at cursor, default on), simulate Enter after output (v7.8.0 "Enter After Transcription", default off). Same three options separately for "Transformation output" (paste at cursor default off) (`settings.ts` lines 96-101).
- History: recordings table with search and sort; v7.7.0 stores recordings, transcripts and transformation runs as Markdown files with YAML frontmatter in a folder you can open, grep and back up.
- "Auto Delete Recordings": "Keep All Recordings" or "Keep Limited Number" ("0 Recordings (Never Save)", 5, 10, 25, 50, 100).
- Retry: re-transcribe from a recording row. Edit-before-paste: none found. Undo: none found.

### Voice commands
- None found (no spoken editing or "new line" commands in source or README).

### Beyond dictation
- "Upload File" mode for file transcription (v7.1.0).
- Transform clipboard text: "Interactive picker" (`Cmd+Shift+X`, searchable list, `Cmd+1`, `Cmd+2` to pick) and "Direct command" (`Cmd+Shift+R`) (v7.6.0). This is the closest to rewriting selected text: copy first, then run.
- Translation: via a transformation prompt ("Translate to other languages", README).
- Meeting recording, notes, summaries as built-in features: none found. README: "designed for quick transcriptions, not long recordings."

### Platforms & sync
- macOS Apple Silicon and Intel DMGs, Windows MSI/EXE, Linux AppImage/DEB/RPM (README v7.11.0).
- Web app in the browser, "doesn't have global keyboard shortcuts".
- Browser extension: "temporarily disabled while we stabilize the desktop app."
- Mobile: none. Founder on HN: native mobile is "scary" and he has no bandwidth (https://news.ycombinator.com/item?id=44948531).
- Sync: none (main README lists "sync between devices" as not supported).
- Minimum macOS: not stated.

### Privacy & data
- "Your data is stored locally on your device"; audio goes "directly from your machine to a local provider ... or your chosen cloud provider ... without any middleman" (README).
- Fully offline path with Whisper C++ / Parakeet / Moonshine / Speaches.
- Anonymous usage events through Aptabase; toggle "analytics.enabled" defaults to on (`settings.ts` line 230; `settings/analytics` page).
- SOC 2 / HIPAA: none found.

### Onboarding & permissions
- No guided first run found; README walks through choosing local vs Groq. Microphone permission recovery steps for macOS and Windows are in README. Accessibility permission for paste at cursor: not documented in README (gap).

### Accessibility
- None found beyond "shadcn-svelte ... accessible components" in the tech list.

### Distribution
- GitHub Releases direct download; Homebrew `brew install --cask whispering`; build from source. Not on Mac App Store or Setapp (none found).
- macOS builds show "Unverified developer" / "App is damaged" warnings per README troubleshooting, which suggests the DMG is not notarized (not confirmed).
- License AGPL-3.0.

## Recent changes (last 12 months, 2025-10-23 to 2026-10-23)
Source: https://github.com/epicenter-md/epicenter/releases
- 2025-10-27 v7.5.5: faster Whisper.cpp.
- 2025-10-29 v7.6.0: transform clipboard text with shortcuts (picker and direct command).
- 2025-11-04 v7.7.0: "Local-First File System Storage", data as Markdown files.
- 2025-12-03 v7.8.0: custom OpenAI-compatible transformation provider; "Enter After Transcription".
- 2025-12-09 v7.9.0: sidebar navigation; custom OpenAI-compatible transcription endpoints.
- 2025-12-11 v7.10.0: System Prompt for Whisper C++ (superseded).
- 2025-12-27 v7.11.0: Moonshine engine; Windows Vulkan crash fix (Windows reduced to Parakeet); launch at login.
- 2026: no releases. Main branch rewritten as a voice-notes app with a Git-versioned data folder and no system-wide dictation (main `README.md`).

## User reception
Mostly from the Show HN thread, 2025-08-18, 591 points, 152 comments: https://news.ycombinator.com/item?id=44942731
- "I use it every day" since the start of the year. https://news.ycombinator.com/item?id=44950090
- "VoiceInk is far superior to Whispering in terms of Ux, and clarity of settings". https://news.ycombinator.com/item?id=44952476
- One user left: "the value + glitches and ux failures drove me to gladly pay for Superwhisper". https://news.ycombinator.com/item?id=44950642
- Praise for docs: "upvote for the fantastic readme / installation guide alone." https://news.ycombinator.com/item?id=44952236
- Windows doubts: "all of the whisper 'clones' run poorly, if at all, on windows." https://news.ycombinator.com/item?id=44952735
- Local model download then "the audio didn't work"; browser version "never asks me for permission". https://news.ycombinator.com/item?id=44977265
- Intel Mac users thanked for continued support. https://news.ycombinator.com/item?id=44949378
- Founder acknowledged FFmpeg and notification issues (https://news.ycombinator.com/item?id=44948598) and that transformation prompts sometimes get "short-circuited" (https://news.ycombinator.com/item?id=44963448).

## Gaps I could not verify
- Content of whispering.bradenwong.com (empty to fetcher) and whether the site now promotes the rewrite.
- Whether the project still intends to bring back system-wide dictation.
- Minimum macOS version and notarization status.
- How Accessibility permission for paste at cursor is requested on macOS.
- Any App Store, Product Hunt or Reddit reviews (none found in searches).
