# Superwhisper

- Vendor: Superultra, Inc. (GitHub org `superultrainc`; Android package `com.superultra.superwhisper`)
- Platforms: macOS 14+, Windows 10/11 (x64 and ARM64), iOS (iPhone; App Store build needs iOS 26.0), Android phones. Linux "Coming soon".
- URL: https://superwhisper.com ; docs https://superwhisper.com/docs (index at https://superwhisper.com/docs/llms.txt)
- Date checked: 2026-10-23
- Placement: **full-suite**, power-user flavour. Same breadth as Wispr Flow (modes with custom prompts, context awareness, meetings, file transcription, MCP, coding-agent plugins, Enterprise SSO) plus what Wispr lacks: local models, bring-your-own API key, a lifetime licence, live words while speaking. Setup is more manual.

## Pricing

Sources: https://superwhisper.com (page's structured price data and pricing block), https://superwhisper.com/docs/billing/plans.md (checked 2026-10-23). US dollars.

| Plan | Price | Notes |
|---|---|---|
| Free | $0 | Unlimited dictation with local Whisper models, up to 2 modes with no AI processing, custom vocabulary, replacements. "Meetings (Mac only)" using trial words only. |
| Pro Monthly | $8.49/month | All Pro features. |
| Pro Annual | $84.99/year | "2 months free" (docs: save about 17%). |
| Pro Lifetime | $249.99 once | Same features; "Top choice". Keys never expire. |
| Enterprise | Custom | SOC 2 Type II, centralized billing and authentication, "Model access control", "Use Enterprise hosted models", volume discounts. |

- Free trial: "3,000 words of free access to all Pro features, including Meetings", then falls back to Free (changed to 3,000 words in v2.18.2, 2026-08-26).
- 30-day refund on all plans.
- One licence covers unlimited Macs and Windows PCs plus iPhone and Android.
- Students, educators and non-profits: 40% off (email request before purchase; not on App Store purchases).
- iOS in-app purchases are the same numbers: Pro Monthly $8.49, Pro Annual $84.99, Pro Lifetime $249.99 (App Store, 2026-10-23). Docs say store prices are "Higher price due to Apple's fees", but the listed amounts match.
- Bring your own API keys: yes (Pro).

## Feature inventory

### Trigger & capture
- "Toggle Recording": press to start/stop, default ⌥ Space. (free) https://superwhisper.com/docs/get-started/essential-settings.md
- "Push to Talk": hold to record, release to stop; a quick tap acts as toggle. Default key on new installs is Right ⌘. (free) same; https://superwhisper.com/docs/get-started/quickstart.md
- "Cancel Recording": Esc; recordings under 30 s cancel at once, longer ones ask to confirm. https://superwhisper.com/docs/get-started/interface-rec-window.md
- "Change mode": hold ⌥ ⇧ K to cycle modes, before or during a dictation; number-key mode shortcuts (v2.7.0). (free)
- Per-mode push-to-talk and toggle shortcuts (v2.12.0, 2026-04-08). https://superwhisper.com/changelog
- "Mouse shortcut": quick click toggles, hold acts as push-to-talk; includes scroll-wheel click (v2.6.0). (free)
- Menu bar icon with coloured status dot (yellow loading, red recording, blue processing, green done); "Start Recording on Menubar Click"; optional "Show in Dock". https://superwhisper.com/docs/get-started/interface-menu-bar.md
- Recording window: large window with waveform, mode name, stop and cancel; "Mini recording window" can stay on screen as an indicator; "Recording window" style setting including None. https://superwhisper.com/docs/get-started/interface-rec-window.md
- Mic selection: microphone button on Home/Configuration/Sound pages and menu bar; "Use system default"; automatic input device selection (v2.10.0); favourite and exclude inputs (v2.16.4); "Automatically increase microphone volume"; lid-closed and no-audio mic warnings. (free)
- "Sound while recording": "Keep Playing", "Pause" (default), "Mute", "Lower", "Muffle" (low-pass filter on other apps' audio; needs macOS 14.2+ and System Audio Recording permission). Settable per mode. (free) https://superwhisper.com/docs/get-started/essential-settings.md
- "Record from system audio" per mode (Pro). https://superwhisper.com/docs/modes/modes.md
- "Silence removal" and "Dynamic normalization" audio processing (silence removal on by default since v2.18.3). https://superwhisper.com/docs/get-started/settings-advanced.md
- Deep links: `superwhisper://record`, `record/start`, `record/stop`, `mode?key=…`, `settings`; Raycast and Alfred integrations; Apple Shortcuts sample. https://superwhisper.com/docs/modes/switching-modes.md
- CLI `record`/`start`/`stop`/`switch` (macOS). https://superwhisper.com/docs/get-started/cli.md
- Push-to-talk from other devices: none found.
- iOS: custom keyboard with a record button; Android: "floating bubble". https://superwhisper.com/docs/get-started/ios.md ; https://superwhisper.com/docs/get-started/android.md

### Transcription engine
Source: https://superwhisper.com/docs/models/voice.md

Local voice models:
- Whisper (via whisper.cpp), all free: Large v3 Turbo (1.6 GB), Large v3 Turbo (Chinese), Large v3 (3 GB), Large (3 GB), Medium (1.5 GB), Medium English, Small (500 MB), Small English, Base (150 MB), Base English, Tiny (75 MB), Tiny English. "All local Whisper models free on macOS" since v2.18.2.
- "Cohere Transcribe" (Pro): 1.3 GB, 14 languages, "the most accurate local model", 8.4% word error rate on Apple M4, MLX 4-bit; GA in v2.17.0 (2026-07-29). Needs Apple Silicon.
- "Parakeet" (English, 476 MB) and "Parakeet Multilanguage" (24 languages, 494 MB) (Pro), Nvidia models via Argmax WhisperKit on Mac, ONNX on Windows; "Parakeet Japanese" on iOS; "Parakeet Realtime" (v2.9.0); Windows "Parakeet Real-time" experimental (2.4 GB).
- On iPhone the app uses Apple's SpeechAnalyzer (per HN user https://news.ycombinator.com/item?id=48899585; not in vendor docs).

Cloud voice models (Pro):
- "S1-Voice" (Superwhisper's own; "lowest word error rate on our benchmarks, 6.6%"; 100+ languages).
- Deepgram "Nova 3", "Nova 2", "Nova Medical".
- ElevenLabs "Scribe" (Scribe v2, realtime).

Language (cleanup) models (https://superwhisper.com/docs/models/language.md):
- Local: "S1-mini" (462 MB, English only, Message and Mail modes only; Pro). Meeting summaries locally: "Tiny Aya 3B", "Qwen 3.5 2B".
- Cloud: "S1-Language" (default), Anthropic Sonnet 5 / 4.6 / 4.5, Haiku 4.5; OpenAI GPT-5.6 Luna, 5.4 mini/nano, 5.2, 5.1, 5, 5 mini, 5 nano; Google Gemini 3.7 Flash, 3.5 Flash Lite, 3.0 Flash; Groq Llama 3.1 8B. All included in the licence (Pro), no keys needed.
- "Bring your own key": Settings → Models library; custom OpenAI/Anthropic models, Opus 4.6/4.7, GPT 5.5 via BYOK (Pro). Enterprise: Amazon Bedrock, Azure OpenAI, self-hosted endpoints.
- Languages: "100+ languages and dialects". Automatic language detection (setting "Automatic"; Cohere auto-detect since v2.17.1). "Translate any language to English" (Pro; via Whisper translate or a custom mode).
- Model switching UI: per-mode "Voice Model" and "Language Model" dropdowns; "Model Library" with favourites, comparison, search, filters (v2.8.0, redesigned v2.12.0). "Voice model active duration" controls how long a local model stays in memory.
- Speed claims: "write up to 5x faster" (App Store); public benchmark leaderboard https://superwhisper.com/benchmarks ; "Paste latency reduced by 300ms" (v2.16.2). FAQ: "Intel Macs work best with Cloud models."

### Live preview
- "Realtime transcription": "the window shows your words as you speak" in the recording window. Needs Pro and a streaming model (Nova, Scribe, Parakeet); not with Whisper, Cohere or S1-Voice. https://superwhisper.com/docs/common-issues/realtime.md ; https://superwhisper.com/docs/get-started/interface-rec-window.md
- "Realtime streaming UI" shipped v2.10.0 (2026-02-23).
- Whether streamed words change after the AI step: the final pasted text is the AI result; the docs do not describe the preview updating. See Gaps.
- Meetings show a live transcript with speaker labels.

### Cleanup & formatting
- Modes (Superwhisper's own term). Built-in presets: "Message" (removes fillers, fixes grammar and punctuation, keeps tone), "Super" (adapts to the app on screen, fixes names, formats spoken URLs and emails), "Mail" (greeting, paragraphs, sign-off), "Note" (structure, bullet points, action items), "Voice to Text" (no AI), "Meeting" (Windows only). AI modes are Pro. https://superwhisper.com/docs/modes/built-in.md
- Older preset names on the home page: Voice, Message, Email, Formal, Casual, Legal, Chat. https://superwhisper.com
- "Tone" slider Casual→Formal on Message, Mail and Note (v2.17.3). https://superwhisper.com/docs/modes/modes.md
- "Custom Mode": your own "Custom instructions" prompt, plus example pairs ("Spoken input" → "AI Output"); prompt can reference `User Message`, `Application Context`, `Selected Text`, `Clipboard Context`. (Pro for AI; Free allows 2 modes without AI) https://superwhisper.com/docs/modes/custom.md
- Context awareness (Pro): "Application" (active app, text in the current field, window title), "Selected text" (captured at record start), "Copied text" (clipboard copied within 3 s before or during dictation). With Application context, also sends date and time, your full name, computer name. History shows exactly what was sent. https://superwhisper.com/docs/common-issues/context.md
- Per-app rules: "Activate for apps" / "Add apps and sites" auto-switches modes by app or website. https://superwhisper.com/docs/modes/modes.md
- "filler word removal" (v2.11.0); "smart capitalization on paste" (v2.8.0); per-mode autocapitalize toggle; "British English spelling transform" (v2.10.0).
- Self-correction ("no wait, I meant"): not named as a feature; left to the AI mode's instructions. See Gaps.
- Lists: Note mode "Creates lists and bullet points".

### Personalization
- "Vocabulary": words sent as recognition hints to the voice model; docs warn "Use vocabulary sparingly". (free) https://superwhisper.com/docs/get-started/interface-vocabulary.md
- "Replacements": exact find-and-replace after transcription, case-insensitive match, keeps your casing; recommended for symbols ("at sign" → @) and snippets ("my work email" → address). (free)
- "Import CSV" for vocabulary (v2.14.0); "very large vocabulary lists" (v2.16.0); CLI `vocab` and `snippets` commands.
- Auto-learning from edits: none found (looked in vocabulary, history, changelog).
- Snippets: done through Replacements (CLI calls them `snippets`).
- Per-app rules: mode auto-activation per app/site.
- "Optimizing Superwhisper with AI": use a coding agent plus the CLI to tune vocabulary and build modes from your history. https://superwhisper.com/docs/get-started/optimizing-with-ai.md

### Output & editing
- "Paste result text" at the cursor; off = clipboard only. "Simulate keypresses" for apps that block paste (Mac only). "Hold shift to auto-send after paste" presses Return (Mac only). https://superwhisper.com/docs/get-started/settings-advanced.md
- "Clipboard content": "Keep what I have copied" (default; restores your clipboard) or "Replace with dictation". "Clipboard history" toggle for Maccy/Paste/Alfred.
- "Close after transcription": if no paste was detected the window can stay open so you can copy.
- Per-mode auto-paste override (v2.9.0).
- History: audio, transcript and AI result for every dictation; "Search history" (full-text, original transcript only); "Reprocess" with any mode; segmented playback; multi-select delete; "Report issue". (free) https://superwhisper.com/docs/get-started/history.md
- "Keep recordings for": Forever (default), 1 day, 1 week, 2 weeks, 1 month, 6 months, 1 year.
- Stats: words per minute, words, apps, time saved; share card.
- Undo: none found beyond the target app's own undo.
- Edit before paste: none found.

### Voice commands
- Super Mode "Commands" on selected text: transformation and formatting such as "Make this text title case", "Format my selected text as bullet points"; docs say summarise/expand/rewrite "Doesn't work well". (Pro) https://superwhisper.com/docs/modes/built-in.md
- Custom Mode can act on selected text with any instruction.
- "new line" / "new paragraph" spoken commands: none found in docs.
- App control: coding agents only (answer questions, approve tool calls by voice). https://superwhisper.com/docs/get-started/coding-agents.md

### Beyond dictation
- "File transcription" (Pro): menu "Transcribe File...", Finder "Open With", CLI `transcribe`; MP3, MP4, MOV, WAV, Opus (Windows); runs through the active mode. https://superwhisper.com/docs/get-started/transcribe-files.md
- "Meetings" (macOS, Superwhisper 3.0, 2026-10-15; Pro): records mic and system audio, no bot, live transcript, speaker labels (on-device diarization, ~150 MB model), summaries with templates, meeting detection for Zoom/Meet/Teams/Slack huddles ("Off"/"Notify"/"Auto"), calendar reminders with "Join & Record", share links (30 days), fully local option. https://superwhisper.com/docs/meetings/overview.md ; https://superwhisper.com/docs/meetings/offline.md
- "Identify Speakers" in any mode (Pro).
- "CLI and MCP server" (macOS): full-text search, export (jsonl/markdown), meetings, vocab, snippets; `superwhisper mcp install claude-code|codex|claude-desktop|cursor`. https://superwhisper.com/docs/get-started/cli.md
- Coding agent plugins: Claude Code, OpenCode, Codex, Cursor, Pi, Grok, DeepSeek; pops up when the agent needs input, voice approvals, done notifications (macOS). https://superwhisper.com/docs/get-started/coding-agents.md
- Translation: to English (Pro); other directions via custom mode.
- Free web tools: mic test, voice recorder, transcribe audio, typing speed test. https://superwhisper.com

### Platforms & sync
- macOS 14 or later (raised from 13 in v2.16.2, 2026-07-06); Apple Silicon recommended for local models; MLX voice models hidden on Intel. https://superwhisper.com/docs/get-started/quickstart.md
- Windows 10/11 x64 and ARM64; local models need Vulkan (ARM limited to Parakeet Multilanguage and cloud). Windows lacks Filesync, Simulate Keypresses, Hold Shift, coding agents, CLI, Meetings. https://superwhisper.com/docs/get-started/windows.md
- iOS: keyboard; docs say iPhone only; App Store build requires iOS 26.0; v2.26.1 adds "iPhone Duo compatibility". Modes and vocabulary don't sync from Mac ("Cloud sync is planned").
- Android phones only (no tablets).
- "Filesync": syncs configuration (modes, settings) between Macs on the same licence; not transcripts or audio. https://superwhisper.com/docs/get-started/settings-advanced.md
- Settings live in `~/superwhisper`; folder can be moved and backed up. https://superwhisper.com/docs/get-started/backing-up-settings.md
- Light/dark/system theme (v2.16.0).

### Privacy & data
- Fully on-device possible: local voice model plus S1-mini or no AI ("no audio or text ever leaves your machine"). Free plan: "Nothing you dictate leaves your device." https://superwhisper.com/docs/security/sensitive-data.md ; https://superwhisper.com/docs/billing/plans.md
- Cloud: zero-data-retention API terms with Anthropic, OpenAI, Deepgram, Groq and its own S1 models; "Superwhisper does not train on your data".
- History stored locally only; Filesync carries config only. Vocabulary words go to the cloud voice provider when a cloud model is used.
- SOC 2 Type II (Enterprise card; report under NDA via https://trust.superwhisper.com). Self-serve DPA and BAA signing. GDPR via DPA. https://superwhisper.com/docs/security/compliance.md
- Enterprise: disable hosted cloud models, approved custom models, recording retention policy, "Allow system audio recording", usage analytics with data inventory. https://superwhisper.com/docs/enterprise/configuration.md
- iOS App Store privacy label: "Data Not Linked to You" only (Device ID, diagnostics).

### Onboarding & permissions
- macOS: welcome → Microphone → Accessibility → optional System audio → mic test with waveform → pick shortcut (Right ⌘) → practice message. First mode is a cloud Message mode. Onboarding model download can be skipped (v2.9.0); onboarding toasts (v2.13.0). No account needed except Enterprise. https://superwhisper.com/docs/get-started/quickstart.md
- Windows: microphone prompt then wizard for language, model, microphone.
- iOS: add keyboard, "Allow Full Access". Android: Floating bubble, Text insertion, Microphone, optional Notifications.
- Licence activation by key or QR code. https://superwhisper.com/docs/billing/activate.md

### Accessibility
- None found (no accessibility page in the docs index; App Store text silent).

### Distribution
- Direct download (DMG / zip from builds.superwhisper.com; Windows installer). https://superwhisper.com/download
- Homebrew cask `superwhisper` v3.0.2, macOS 14+. https://formulae.brew.sh/cask/superwhisper
- iOS App Store "Superwhisper - AI Dictation", v2.26.1 (2026-10-20), 4.4 stars from 845 ratings. https://apps.apple.com/us/app/superwhisper-ai-dictation/id6471464415
- Google Play. Mac App Store: not listed. Setapp: not listed (setapp.com/apps/superwhisper is a generic article).
- MDM silent deployment (Jamf, Intune). https://superwhisper.com/docs/enterprise/mdm-deployment.md
- Closed-source app; open-source plugins and CLI release binaries on GitHub (`superultrainc/*`). An S1-mini model is on Hugging Face (https://huggingface.co/superwhisper/s1-mini).

## Recent changes (last 12 months)
Source: https://superwhisper.com/changelog (macOS entries; mobile not in the changelog)

- 2025-10-15 v2.6.0: mouse-button recording, Claude Haiku 4.5, selected text in all apps and custom modes.
- 2025-10-22 v2.6.2: Parakeet vocabulary support.
- 2025-11-26 v2.7.0: stats and typing test, mini mode selector, number-key mode shortcuts, GPT 5.1, Opus 4.5 for BYOK.
- 2026-01-02 v2.8.0: new History (full-text search, reprocess with any mode), Model Library, smart capitalization, pause media by default.
- 2026-01-23 v2.9.0: "Parakeet Realtime" offline, Gemini and Grok cloud models, per-mode auto-paste override, speaker name editing.
- 2026-02-23 v2.10.0: "Realtime streaming UI", British spelling transform, automatic input device, ElevenLabs Scribe (experimental).
- 2026-03-12 v2.11.0: Scribe v2 realtime, recording retention setting, filler word removal.
- 2026-04-08 v2.12.0: Enterprise login, per-mode shortcuts, S1 Voice and Language stable.
- 2026-04-24 v2.13.0: new Modes design, Claude Code and OpenCode agents, app/site activation UI, new Vocabulary & Replacements.
- 2026-05-15 v2.14.0: Codex hooks, coding agent plugin install, vocabulary CSV import.
- 2026-06-09 v2.16.0: themes, experimental S1-Mini local model, very large vocabulary lists.
- 2026-07-06 v2.16.2: paste latency cut by 300 ms; requires macOS 14.
- 2026-07-29 v2.17.0: Cohere Transcribe GA.
- 2026-08-19 v2.18.0: S1-mini on-device with tone control.
- 2026-08-26 v2.18.2: all local Whisper models free; trial changed to 3,000 words.
- 2026-09-03 v2.18.3: silence removal and clipboard preservation on by default; macOS 27 fixes.
- 2026-10-02 v2.19.0: "Muffle" sound option.
- 2026-10-15 v3.0.0: "Meetings" (recording, speaker identification, summaries, notifications, local or cloud).
- 2026-10-20 v3.0.2: faster Cohere Transcribe, Grok Bot meetings agent.
- 2026-08-20 (HN post by the team): S1 model family announced; "soon Android" (Android now live). https://news.ycombinator.com/item?id=49375266

## User reception

- App Store 4.4/5 from 845 ratings, lower than Wispr's 4.8. https://apps.apple.com/us/app/superwhisper-ai-dictation/id6471464415
- App Store praise: "Finally, transcriptions that just work" (2025-05-27). Complaint: wants the iOS app to have "the same range of advanced Speech-to-Text options as the macOS version". same link.
- Product Hunt 4.9/5 (22 reviews): "the transcription accuracy blows me away every time"; complaints "The mobile app could use some love", "it occasionally does not register the recording". https://www.producthunt.com/products/superwhisper/reviews
- Hacker News: "I found Superwhisper to be slow. Willow is almost instantaneous." https://news.ycombinator.com/item?id=44432703
- Hacker News: "Try Superwhisper you can give it custom vocabulary and replace rules easily" https://news.ycombinator.com/item?id=49749767
- Hacker News: user runs Parakeet inside Superwhisper; "Parakeet is the gold standard" https://news.ycombinator.com/item?id=50010166
- Hacker News: "Lifetime subscriber" comment shows the lifetime plan is a draw. https://news.ycombinator.com/item?id=48915263
- Review roundups say setup "feels built for developers and technical users" and audio is saved to disk by default (competitor-written; treat with care). https://www.getvoibe.com/resources/superwhisper-review/ ; https://makerstack.co/reviews/superwhisper-review/
- Reddit r/macapps: could not be fetched (blocked to this tool).

## Gaps (not verified)

- Whether realtime words on screen get replaced when AI cleanup finishes, or the AI result simply pastes.
- Spoken "new line"/"new paragraph" commands and explicit self-correction handling: not documented.
- Accessibility (VoiceOver, keyboard-only) claims: none found.
- iOS: docs say iPhone only, App Store lists iPad devices and needs iOS 26.0; actual iPad support unclear.
- iOS and Android feature parity details (which models run on phone) beyond the iOS/Android setup pages.
- Enterprise per-seat price.
- Whether store prices are actually higher than web (listed numbers are the same).
- Reddit threads (blocked).
