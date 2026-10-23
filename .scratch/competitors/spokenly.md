# Spokenly

- **Vendor:** Spokenly (App Store seller "Vadim Akhmerov"); contact admin@spokenly.app
- **Platforms:** macOS, Windows, Linux (deb, rpm, AppImage), iPhone/iPad. Android: "not yet available" (waitlist)
- **URL:** https://spokenly.app (full docs in one file: https://spokenly.app/llms-full.txt)
- **Date checked:** 2026-10-23
- **Placement:** full-suite for power users. Free unlimited local dictation, bring-your-own-key for about 15 dictation and 13 AI providers, per-mode models and prompts, a small on-device cleanup model, agentic actions, MCP and CLI for coding agents, meeting and file transcription, on four platforms with MDM-enforceable offline mode. Weaker on polish: no auto-learning dictionary, no editing selected text by voice, cleanup quality depends on what you configure.

## Pricing

Source: https://spokenly.app/pricing, https://spokenly.app/team, https://spokenly.app/students (checked 2026-10-23)

| Tier | Price | What it gates |
|---|---|---|
| Free | $0 forever, "No account needed" | "Unlimited use", "Whisper & Parakeet models", "Works completely offline", "Bring your own API keys" (OpenAI, Deepgram, Groq, etc.), "Real-time transcription"; AI cleanup via Apple Intelligence or your own LLM key |
| Local+ | $29 once | "Notch and Capsule styles", "Sync settings across devices", "Priority support". "For cloud models and AI, you will need your own API keys." |
| Pro | $9.99/month or $99.99/year (shown as "$8.33 /month, Billed $99.99 per year") | "High-accuracy cloud models" (GPT-4o Transcribe, Deepgram Nova 3, Soniox), "AI text cleanup & polish", "Real-time cloud streaming", "Agent Mode" hosted, "Works out of the box", plus everything in Local+ |
| Team | $6.99 per seat/month or $69.99 per seat/year (30% off forever) | Minimum 2 seats; each seat is full Pro; seats managed in the Polar customer portal |
| Student | $4.99/month or $49.99/year (50% off Pro) | verify with an academic email |

- BYOK: "Spokenly charges nothing on top. You pay the provider directly." https://spokenly.app/pricing
- Refund: 14-day money-back for website purchases; App Store via Apple. Same.
- Referral: "Invite friends to earn free Pro" (macOS 2.21.5). https://spokenly.app/appcast.xml
- Free-tier word or minute caps: none ("no word caps, no trial clock"). App Store reviews mention "out of free use" on iOS cloud usage (see reception).

## Feature inventory

### Trigger & capture
- Hold-to-talk by default: "Hold a shortcut to start, speak naturally, then release". Default Mac shortcut "Right Command" (Free). https://spokenly.app/docs, https://spokenly.app/dictation-for-mac
- Per-mode shortcuts with "activation style (automatic, toggle, push-to-talk, or double-tap)"; several shortcuts per mode (2.31.3). https://spokenly.app/docs/modes, https://spokenly.app/appcast.xml
- Shortcuts from modifier keys alone with left/right variants (2.27.13); mouse buttons and trackpad gestures (2.24.0). Appcast.
- "MacBook Taps": tap the case two, three or four times to start/stop (website build only, 2.29.3). https://spokenly.app/docs/macos/macbook-taps
- Remap the MacBook dictation key with `hidutil`. https://spokenly.app/docs/macos/dictation-key
- Custom Cancel Recording shortcut (2.28.3). Appcast.
- Deeplinks `spokenly://start`, `stop`, `toggle`, `switch?mode_id=`. https://spokenly.app/docs/macos/deeplinks
- Recording displays: Panel, "Notch" and "Capsule" ("a compact pill with live text", 2.30.8) (Notch and Capsule need Local+ or Pro). Pricing; appcast.
- Menu bar app; "Cmd+Q keeps the app running in the menu bar" (2.18.2). Appcast.
- Mic: "Use system default" (2.18.5); quiet mic audio boosted for local models (2.28.0); automatic media pausing (2.18.6). Appcast.
- System audio: meeting recording with system audio and microphone (2.29.0, Mac). Appcast.
- iOS "Background Dictation": start from an Apple Shortcut via Action Button, Back Tap or AssistiveTouch, insert with the Spokenly keyboard or copy to clipboard. https://spokenly.app/docs/ios/background-dictation
- Linux: hotkeys need a udev rule. https://spokenly.app/docs/linux-hotkey-permissions
- Push-to-talk from other devices: none found beyond iOS triggers.

### Transcription engine
- Local models (Free): Whisper (incl. "Whisper Large V3 Turbo" on the Neural Engine), NVIDIA Parakeet (incl. "Parakeet Unified", "Parakeet Ultra", "Parakeet Redux"), "Apple Speech Analyzer", "Nemotron 3.5", "Cohere Transcribe Q4" ("top accuracy for 14 languages"), "Phonon-2" (English, compact), "Bark 3.0" (English), Qwen3-ASR (listed on the Android page). https://spokenly.app/docs/modes, appcast 2.22.0–2.33.0, https://spokenly.app/android
- Local server support: any OpenAI-compatible server on localhost (e.g. Speaches). https://spokenly.app/docs/local-only-mode
- "Spokenly Cloud" models (Pro): "GPT-4o Transcribe, Deepgram Nova 3, and Soniox", "GPT Transcribe" (2.27.2). https://spokenly.app/pricing, appcast
- BYOK dictation providers (Free): "Groq, OpenAI, ElevenLabs, OpenRouter, Google Gemini, Deepgram, Mistral AI, AssemblyAI, Cartesia, Cohere, Fireworks AI, Sarvam AI, Straico, xAI, and any server with an OpenAI-compatible API. Mac and iPhone also have Corti and Volcengine." https://spokenly.app/docs/models
- Dictionary-capable models named: ElevenLabs Scribe, Soniox Realtime/Async, Microsoft MAI-Transcribe 2, GPT Transcribe, GPT-4o (mini) Transcribe, AssemblyAI Universal 3.5 Pro, Gemini 3.5 Transcribe. https://spokenly.app/docs/custom-dictionary
- Languages: "100+ languages with automatic detection", "mix two mid-sentence". https://spokenly.app
- Model switching UI: "AI Models" screen with tabs "Spokenly Cloud", "Local Models", "Your API Keys"; "Browse" model lists; "Test & Save"; per-mode dictation model and fallback text model. https://spokenly.app/docs/models
- "Keep dictating when a transcription provider goes down" (2.27.0); recordings still transcribed when streaming fails to start (2.32.0). Appcast.
- Speed: "Whisper Large V3 Turbo runs on the Neural Engine with sub-second latency"; uses "about 1 to 2GB of RAM". https://spokenly.app/dictation-for-mac
- Audio trimmed before upload to cloud for speed (2.18.8); VAD trimming toggle (2.18.9). Appcast.

### Live preview
- "Live — words appear as you speak. Streaming engines tuned from ultra-fast to maximum accuracy" (Free with real-time models or BYOK). https://spokenly.app
- Capsule display shows live text; Notch shows words live with realtime models (2.30.4, 2.30.8). Appcast.
- "New switch to hide the live transcript preview" (2.31.2). Appcast.
- Whether streamed words can change after appearing: not documented.

### Cleanup & formatting
- "Local Model Cleanup" with model "Spokenly Cleanup 1": removes filler and repeats, "applies corrections you say out loud" ("send the report to john no wait to maria" → "Send the report to Maria"), fixes punctuation and capitals, numbers as digits, emails and URLs; tones Formal / Casual / Very casual / Auto (follows text before cursor); 768 MB download, about 0.2 s for 1–2 sentences on Apple silicon; English best, plus German, Spanish, French, Chinese, Russian, Japanese; off by default; Mac (Apple silicon, macOS 15+), Windows, Linux (2.31.0, 2026-10-11). https://spokenly.app/docs/local-model-cleanup
- "Modes" with "AI Instructions": translation, cleanup and formatting all driven by your instructions; per-mode AI provider, temperature, reasoning effort, custom system prompt (Free with BYOK or Apple Intelligence; hosted with Pro). https://spokenly.app/docs/modes
- Included context per mode: "clipboard, focused app, text around the cursor, active browser URL". Same.
- Auto-activation of modes per app or website (2.23.0); trigger words ("email hey John" runs the Email mode) (2.25.2). Same; appcast.
- "Smart Paragraphs": breaks long dictation at 45 words or 4 sentences, on-device, off by default. https://spokenly.app/docs/macos/smart-paragraphs
- "Smart Spacing" and "Smart Capitalization": reads characters around the cursor through Accessibility, on by default. https://spokenly.app/docs/macos/smart-spacing
- Pre-AI and Post-AI "Bash Scripts" in each mode (`/bin/zsh`, stdin to stdout). https://spokenly.app/docs/modes/bash-scripts
- Ready-made mode recipes: translation, clean-up, spoken punctuation, Google search query. https://spokenly.app/docs/modes

### Personalization
- "Dictionary" = model "Keyterms" (e.g. ElevenLabs, first 50 terms in live transcription). https://spokenly.app/docs/custom-dictionary
- "Whisper Prompting" for local Whisper (last 224 tokens, about 900 characters). https://spokenly.app/docs/whisper-prompting
- "Word Replacements": case-insensitive, comma-separated variants, regex with capture groups, run before or after AI; JSON import/export; CLI and deeplink access. https://spokenly.app/docs/word-replacements
- Per-app and per-website modes (above).
- Auto-learning from edits: none found.
- Snippets: no dedicated feature; Word Replacements can expand a phrase.

### Output & editing
- Output action per mode: "auto-insert, paste and press Enter, copy to clipboard, or save to history only". https://spokenly.app/docs/modes
- "Quick Send": press Return (or swipe right on trackpad) while recording to insert and send. https://spokenly.app/docs/macos/quick-send
- Floating insertion panel "when no field is focused" (2.26.0); can be hidden (2.27.5). Appcast.
- History: "Search past dictations, replay the audio, and export anything"; shows paste destination and app search (2.25.0); pipeline stages "with diffs" (2.23.0); retranscription; recent transcriptions from the menu bar. https://spokenly.app, appcast
- Interrupted streaming dictations keep audio for retranscription (2.21.3). Appcast.
- Edit-before-paste: none found (output can go to history only).
- Mac App Store build can't auto-paste: dictation stops and pastes when you press ⌘V. https://spokenly.app/docs/mac-app-store

### Voice commands
- Spoken punctuation: automatic with "Apple Speech Analyzer", or via a mode with AI Instructions on "Real-time Nova-3". https://spokenly.app/docs/punctuation-commands
- "Agentic Actions" (macOS, per mode): Google Search, YouTube Search, Open Website, Ask ChatGPT, Ask Claude, Launch Apps, Close Apps, Apple Shortcuts, Shell Command, Press Keys. https://spokenly.app/docs/modes/agentic-actions
- Mode trigger words (above).
- Editing selected text by voice: none found.

### Beyond dictation
- Meeting recording on Mac: microphone plus system audio, no bot, saved to History, transcribed afterwards; meeting detection in Safari (2.30.2); speaker echo removed (2.29.6). https://spokenly.app/llms.txt, appcast
- File transcription: "Drop audio or video files … batch transcription with subtitle export"; speaker labels with ElevenLabs Scribe or local Pyannote (2.18.13, 2.27.0); separate stereo channels (2.25.4). https://spokenly.app/dictation-for-mac, appcast
- "Voice for Agents (MCP)": local server `http://localhost:51089`, tool `ask_user_dictation` for Claude Code, Codex, Cursor; also a file-transcription MCP tool (website build). https://spokenly.app/docs/macos/voice-for-agents
- `spokenly` CLI: `transcribe` (text, SRT, VTT, Markdown, JSON), `ask` (spoken answers for agents), `replacements`; ready-made agent skill file. https://spokenly.app/docs/macos/cli
- "Voice journal" and iOS share extension for audio files, lock screen widget. https://spokenly.app/android
- Translation: via mode instructions only.
- Summaries / notes: none found beyond voice journal mention.

### Platforms & sync
- macOS: sideload build minimum macOS 13.3 (since 2.27.8; was 14.6 and 14.0 before). https://spokenly.app/appcast.xml
- Apple Silicon native; Intel supported (Intel crash fixes in 2.18.11, 2.30.0); Local Model Cleanup needs Apple silicon.
- Windows 10 and 11 64-bit, v1.2.0 (October 2026), Microsoft Store or direct installer. https://spokenly.app/windows
- Linux: deb, rpm, AppImage, ARM64 builds. https://spokenly.app/llms.txt, https://spokenly.app/docs/local-model-cleanup
- iOS: App Store id6740315592, min iOS 16.4, version 1.15.0 (2026-10-21), 4.35 from 65 US ratings (iTunes lookup API, 2026-10-23); custom keyboard.
- "Sync Settings" (Pro or Local+): Word Replacements, Modes, Model Settings, API Keys; not history or audio. https://spokenly.app/docs/sync
- App UI translated into more languages (Italian, Brazilian Portuguese, 2.30.6; three more in 2.33.0). Appcast.

### Privacy & data
- "Local Only Mode": blocks all network traffic except model downloads and localhost; disables sync and analytics. https://spokenly.app/docs/local-only-mode
- Enforce Local Only Mode via MDM profile (`app.spokenly`, `localOnlyMode`) or Windows Group Policy/Intune ADMX (2.30.6). Same.
- Cloud audio "immediately discarded once the result returns. We don't store your audio files or transcripts on our servers." Same.
- Anonymous analytics (e.g. which models you select) unless Local Only Mode is on. Same.
- Synced data, including API keys if chosen, stored on Spokenly servers. https://spokenly.app/docs/sync
- SOC 2 / HIPAA claims: none found.

### Onboarding & permissions
- "Improved Getting Started flow" (2.26.0). Appcast.
- Accessibility needed for auto-paste; false Accessibility hint fixed (2.28.3). Appcast; https://spokenly.app/docs/mac-app-store
- No account needed for Free. https://spokenly.app/pricing
- Must download a local model before offline use. https://spokenly.app/llms.txt

### Accessibility
- "Improved accessibility for VoiceOver" (2.20.5, 2026-05-13). https://spokenly.app/appcast.xml
- Student page: "Students with RSI, dyslexia, or other conditions that make typing difficult use Spokenly as an accessibility tool." https://spokenly.app/students

### Distribution
- Website sideload build with Sparkle auto-update (main Mac channel). https://spokenly.app/changelog
- Mac App Store: "no longer being updated but is still available to download"; no auto-paste, no MacBook Taps, sandboxed shell actions. Same; docs.
- iOS App Store; Microsoft Store and direct Windows installer; Linux packages.
- Payments via Polar (merchant of record). https://spokenly.app/team
- Open source: none found.

## Recent changes (last 12 months)

Source: https://spokenly.app/appcast.xml (macOS)
- 2026-03-12 2.18.2: "Voice for AI Agents" MCP server.
- 2026-04-06 2.18.13: Spokenly CLI; MCP file-transcription tool; local Pyannote speaker ID.
- 2026-05-09 2.20.0: Smart Paragraphs, Smart Capitalization, Deepgram Flux, browser URL as mode context.
- 2026-05-21 2.21.2: send with Return in any app.
- 2026-06-04 2.22.0: on-device Nemotron 3.5 and Cohere models.
- 2026-06-18 2.23.0: modes per website and multiple apps; history pipeline diffs; Parakeet Unified.
- 2026-07-03 2.24.0: trackpad and mouse triggers, swipe-to-send.
- 2026-07-15 2.25.0 / 2.25.2: settings sync; mode trigger words.
- 2026-07-24 2.26.0: floating insertion panel; live transcription with ElevenLabs Scribe; AssemblyAI Universal 3.5 Pro.
- 2026-08-01 2.27.8: macOS 13.3 support.
- 2026-09-05 2.29.0: meeting recording with system audio.
- 2026-09-12 2.29.3: MacBook Taps.
- 2026-10-02 2.30.6: MDM-enforced Local Only Mode.
- 2026-10-05 2.30.8: Capsule display with live text.
- 2026-10-11 2.31.0: Local Model Cleanup.
- 2026-10-20 2.32.0: unified AI Models screen.
- 2026-10-22 2.33.0: Bark 3.0 local model; "Spokenly AI Smart" model.
- Windows v1.2.0 (October 2026) per https://spokenly.app/windows; Mac App Store edition frozen (date not given).

## User reception

- Praise: "No need to pay for Whisper Flow … it's free" (5 stars, 2026-09-27). https://apps.apple.com/us/app/id6740315592
- Praise: fair model, "Its BYOK options are free, and so is local processing" (5 stars, 2026-07-25). Same link.
- Praise: real-time models, "sometimes I ramble so I like seeing what I said already" (5 stars, 2026-04-14). Same link.
- Complaint: iOS opens the Spokenly app to reach the mic unless the mic stays on, which drains battery (2 stars, 2026-08-04; similar 2026-03-28). Same link.
- Complaint: spoken punctuation, "'hyphen, parentheses' I spoke those words & it spells them out" (4 stars, 2026-07-08). Same link.
- Complaint: "Offline mode doesnt work and its not free" (1 star, 2026-09-12) and dropped 1–2 minute inputs then "out of free use" (1 star, 2026-06-19). Same link.
- Hacker News: "I use Spokenly, offline-only mode with the Nvidia model. All local, totally free." (2026-07-13). https://news.ycombinator.com/item?id=48895596
- Hacker News: it "deals with slow provider responses very poorly" with local LLMs (2026-10-12). https://news.ycombinator.com/item?id=50061918
- Product Hunt commenter: about 40 MB RAM with Groq, "best value for money" (via search summary). https://www.producthunt.com/products/spokenly
- Vendor claims "100,000+ active users" and "4.8 App Store rating" (US store shows 4.35 from 65). https://spokenly.app

## Gaps you could not verify

- Whether streamed live words can be revised before insertion.
- Exact sizes of local models other than the cleanup model.
- iOS free usage limits on Spokenly Cloud (reviews mention running out; no vendor number).
- Windows and Linux feature parity in detail (Windows page says it "covers the core dictation and transcription flows").
- Minimum Windows build and Linux distro support.
- What "Spokenly AI Smart" is.
- Reddit reception (Reddit search blocked; web search found none).
