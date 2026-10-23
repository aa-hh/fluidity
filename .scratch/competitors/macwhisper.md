# MacWhisper

- **Vendor:** Good Snooze (Jordi Bruin), Amsterdam, Netherlands
- **Platforms:** macOS (direct download "MacWhisper"; Mac App Store edition named "Whisper Transcription"); iPhone/iPad ("Whisper Transcription")
- **URL:** https://www.macwhisper.com (docs: https://docs.macwhisper.com, same content as https://macwhisper.helpscoutdocs.com)
- **Date checked:** 2026-10-23
- **Placement:** full-suite for audio transcription, mid-range for dictation. It bundles file, YouTube, podcast, meeting and live-caption transcription with a huge local and cloud model list, but dictation is one feature among many: no editing by voice, no documented push-to-talk detail, and dictation is missing entirely from the App Store edition.

Note: the site's dedicated pages https://www.macwhisper.com/dictation, /transcription and /meeting-recording are unfinished templates ("Feature A … Placeholder text if we would like to expand on the title above"), checked 2026-10-23. Facts below come from the homepage pricing table, the help docs and the official release notes at https://macwhisper-site.vercel.app/release_notes.html (versions are listed without dates; dates below come from the aggregator https://releasebot.io/updates/macwhisper where marked).

## Pricing

Source: https://www.macwhisper.com/#pricing, https://docs.macwhisper.com/article/40-macwhisper-whisper-transcription-difference

| Tier | Price | Billing | Notes |
|---|---|---|---|
| MacWhisper (Free) | €0 | "Free forever" | Local transcription from mic and files, system-wide dictation with Whisper, .srt/.vtt/.txt export |
| MacWhisper Pro | €64 | "Pay Once … / license", "Includes lifetime updates" | Everything in the Free/Pro table below; sold via Gumroad (https://goodsnooze.gumroad.com/l/macwhisper) |
| Volume licenses | not priced publicly | one-time | "5, 10, 20 or 50-license packs. More available on request" |
| Student / Journalist / Nonprofit | 25% off | on request | email support |
| Whisper Transcription (Mac App Store) | prices not published on the web | "Weekly / Monthly / Yearly subscription" plus optional "Assistant Subscription" | no license-key entry; dictation not included |
| Whisper Transcription (iOS) | free | optional Assistant subscription for cloud transcription and AI summaries | "On iOS, there's no Pro Unlock — all local models are available without a purchase as well as the option to bring your own API key" |

- License covers personal devices "with a soft limit of 3"; licenses can be auto-disabled when resale abuse is detected (December 2025 update). https://docs.macwhisper.com/article/39-licensing
- BYO API key: supported for cloud transcription and AI (the "Bring your own API keys to connect to AI providers" row is ticked for Free; the named provider list and custom endpoints are Pro-only, per the homepage table).
- Docs repeatedly show an "Upgrade now with 20% off" link (promotion, no terms given). https://docs.macwhisper.com/article/16-global
- Team plan: none beyond volume packs and MDM deployment.

Free vs Pro table (homepage, desktop layout, read from the tick and cross icons on 2026-10-23):

| Row (vendor wording) | Free | Pro |
|---|---|---|
| Record from your Mac Microphone | yes | yes |
| Supports mp3, wav, m4a, ogg, opus, mov and mp4 | yes | yes |
| Supports 100 different languages | yes | yes |
| Export subtitles to .srt & .vtt | yes | yes |
| App Audio | no | yes |
| YouTube and online videos | no | yes |
| Podcasts | no | yes |
| Batch transcription | no | yes |
| Automatic Speaker Recognition | no | yes |
| Translate into another language | no | yes |
| System wide dictation with Whisper | yes | yes |
| Automatic spelling and grammar improvement | no | yes |
| Dictate with AI Prompts | no | yes |
| App-specific Prompts | no | yes |
| Generate subtitles in .srt and .vtt format | yes | yes |
| Inline videoplayer with subtitles | no | yes |
| Translate subtitles automatically | no | yes |
| Automatically record meetings in Zoom, Teams, Webex, Skype, Chime, Discord and more | no | yes |
| Automatic meeting start and end detection | no | yes |
| Bring your own API keys to connect to AI providers | yes | yes |
| OpenAI, Anthropic, Groq, xAi, Azure, Deepseek, Google and OpenRouter | no | yes |
| Support for custom OpenAI compatible endpoints | no | yes |
| Use local AI models with Ollama and LM Studio | no | yes |
| Watched Folders | no | yes |
| Workflow (Notion, Zapier, Obsidian, n8n, Make.com, custom webhook) | no | yes |
| CLI | no | yes (but the CLI doc says txt/srt/vtt/csv output is "available to everyone") |

A second, mobile-width copy of the list also names "System wide high quality dictation" with no tier marker.

## Feature inventory

### Trigger & capture
- "Dictation": "You configure a keyboard shortcut in settings and after that you can just use this shortcut anywhere" (Free). Only in the direct-download build: "Dictation is only available in MacWhisper sold on www.macwhisper.com, not on the App Store version." https://docs.macwhisper.com/article/14-how-to-use-the-dictation-feature
- Toggle-style dictation exists: "If you cancel a toggled dictation by pressing Escape you can now start a new dictation by hitting the dictation key just once" (13.4). https://macwhisper-site.vercel.app/release_notes.html
- Fn key can be the dictation key ("extra guidance … if you chose the Fn key without setting it up correctly in macOS settings", 13.6). Same source.
- Hold-to-talk versus toggle choice: not documented (see Gaps).
- "Global" feature: shortcut opens a floating "Global overlay" to record and transcribe on top of other apps, with "Auto Start", "Auto copy", "Always on Top" (Pro: "The Global feature requires a Pro license or subscription"). https://docs.macwhisper.com/article/16-global
- Dictation indicator positions: "center top, center bottom, textfield location or hidden" (13.14). Release notes.
- Menubar microphone picker (14.2). Release notes.
- Audio muting during dictation, improved for Bluetooth and external mics (13.12, 13.19.2). Release notes.
- Menu bar presence plus a main window ("toggle the app visibility mode through the menubar", 13.4). Release notes.
- System audio: "App Audio" recording of any app (Pro); on macOS 26+, captured "through CoreAudio instead of ScreenCaptureKit, so it only needs the System Audio Recording permission" (15.4). Homepage; release notes.
- Push-to-talk from other devices: none found (looked at homepage, docs index, release notes).

### Transcription engine
- Local engines: Whisper (whisper.cpp, "Whisper C++"), "WhisperKit" ("The Turbo model is a great choice"; M-series only), NVIDIA "Parakeet" (v2 English-only, then "Parakeet v3 supports multilingual transcribing in 25 languages, in the same transcription or dictation"), Apple Speech models (13.0), "Qwen3-ASR" ("local transcription in 30 languages … Requires Pro and an Apple Silicon Mac with an M2 chip or newer running macOS 26", 15.1; opt-in on M1 since 15.8). https://docs.macwhisper.com/article/29-switching-to-a-whisperkit-model, release notes
- Original Parakeet launch note: "can transcribe at up to 300 times real speed on the latest Macs … (Pro)". Release notes.
- "Dictating with a Parakeet model is now 30% faster" (13.2). Release notes.
- "You can now use a different model for dictation and transcription" (13.0). Release notes.
- Cloud transcription (BYO key): "OpenAI, Groq, ElevenLabs, DeepGram and custom OpenAI compatible providers" with file limits (OpenAI and Groq 25 MB; ElevenLabs and Deepgram 1 GB). https://docs.macwhisper.com/article/18-cloud-transcription
- Cloud providers added since: Gladia "(Pro)" (14.1), AssemblyAI, xAI (Grok), Rev AI (14.3), Voxtral Mini Transcribe 2 (14.4.1), OpenAI gpt-transcribe, Avalon, OpenRouter, Volcengine, Cartesia, Corti (14.5), Cohere Transcribe, Speechmatics (14.7.1), Gemini 3.5 Transcribe (14.8.1), OpenAI 4o-diarize (13.0). Release notes.
- "Assistant Cloud Transcription": vendor's own servers (Groq, moving to ElevenLabs), subscription on App Store/iOS builds. https://docs.macwhisper.com/article/22-assistant
- Languages: "Supports 100 different languages"; per-engine subsets (Parakeet v3: 25; Qwen3-ASR: 30). Homepage; release notes.
- Auto language detection: "Select transcription language (or use auto detect)" (iOS doc); Live Captions "detect it automatically when set to Auto" (15.3). https://docs.macwhisper.com/article/33-macwhisper-for-ios
- "Match Keyboard Language": dictation follows the active keyboard language (14.7). Release notes.
- Model switching UI: model picker top right of home screen, "Manage Models" screen, "Redesigned model picker showing your 3 most recently used models" (14.5). Docs; release notes.
- Speed claims: Parakeet "300 times real speed"; "~10% due to improvements in macOS Tahoe" (13.0). Release notes.
- Hardware note: "To use the Medium and Large models your Mac should have more than 8GB of RAM." Homepage footnote.

### Live preview
- Dictation live preview: none found. The homepage calls it "Real-time dictation" but no doc says words show while speaking.
- "Realtime Captions" / "Live Captions" (13.11): "instantly show captions straight from the microphone", with live translation via Apple's translation service (13.12) and system/app audio as a source. Separate from dictation. Release notes.
- "Live meetings (Beta)": live meeting transcript with speaker identification (15.0.1, Pro); on by default since 15.2.1. Release notes.

### Cleanup & formatting
- "Automatic spelling and grammar improvement" (Pro). Homepage table.
- "Dictate with AI Prompts" (Pro): run dictation through an AI prompt, e.g. "cleaning up your dictated text", "Translating your dictated text", "Expanding … into a full customer support email". Needs Pro plus your own AI key. https://docs.macwhisper.com/article/14-how-to-use-the-dictation-feature
- Dictation prompts can use Apple's on-device Foundation Models (13.0, 13.23.1, 15.2.1). Release notes.
- "App-specific Prompts" (Pro): pick a prompt per app. https://docs.macwhisper.com/article/31-app-specific-dictation-prompts
- Prompt tester in dictation settings (13.0). Release notes.
- "Auto cleanup" / "Automatically remove filler words like 'um' and 'uh'" (homepage; tier unclear).
- Punctuation setting for dictation (13.17). Release notes.
- Context awareness: on-screen context is used during dictation ("On-screen context no longer joins separate words together during dictation", 15.6). How it is captured and whether it is optional: not documented.
- Self-correction handling ("no wait, I meant"): none found, beyond what a custom AI prompt might do.

### Personalization
- Dictation dictionary: "Dictation dictionary entries now retain spaces, punctuation, numbers, and capitalization" (15.6); "Add multiple dictionary entries at once by pasting a list" (15.0.1). Release notes.
- "Global Replace" (find and replace for all new transcriptions), case-sensitive and whole-word options, JSON import/export. https://docs.macwhisper.com/article/37-find-and-replace-in-transcriptions
- App-specific prompts (above).
- Snippets / text expansion: none found.
- Learning from edits: none found.

### Output & editing
- Pastes into the focused text field; checks for an active text field, override with "Allow dictation everywhere" (Settings > Advanced). https://docs.macwhisper.com/article/44-dictation-not-working-in-specific-apps
- Clipboard restored after paste: "the previous clipboard comes back as soon as the dictation is pasted, and only if nothing else has changed it since" (15.5). Release notes.
- Chromium apps: "MacWhisper now types the text in directly instead of pasting it" (15.8). Release notes.
- Dictation history: "View, playback and copy your dictation history from the main app" (13.0); shows target app (13.2); errors shown in history (13.17); "copy your 10 most recent dictations from the menubar" (14.1); export dictation audio (14.8, multiple at once in 15.8). Release notes.
- Full transcript editor, search, favourite rows, speakers. https://docs.macwhisper.com/article/28-keyboard-shortcuts
- Edit-before-paste: none found.
- Retry: retranscribe recordings with another model (13.0, 14.3). Release notes.

### Voice commands
- None found (looked at docs dictation category, release notes). No "new line"/command mode documentation.

### Beyond dictation
- File transcription by drag and drop; formats mp3, wav, m4a, ogg, opus, mov, mp4 (Free). Homepage.
- Batch transcription and transcription queue (Pro). Homepage; 13.0.
- YouTube and media URL transcription (Pro). https://docs.macwhisper.com/article/51-how-to-transcribe-youtube-videos
- Podcasts with one file per speaker (Pro). Homepage.
- Speaker recognition (Pro): Nemotron 3 Diarization (Sortformer v3, up to 8 speakers) or Pyannote (15.2, 15.3). Release notes.
- Meeting recording (Pro): auto-detects Arc, Brave, Chime, Chrome, Discord, Edge, Firefox, Safari, Skype, Slack, Teams, Telegram, Webex, WhatsApp, Zoom; "FaceTime is not available"; no bots. https://docs.macwhisper.com/article/30-record-meetings
- Summaries, AI chat with transcripts, custom prompts; AI titles and short summaries (13.0). Homepage; release notes.
- Translation of transcripts and subtitles (Pro). Homepage.
- Video player with subtitles; .srt/.vtt generation. Homepage.
- Watched Folders (Pro). Homepage.
- Integrations: Notion, Zapier, Obsidian, n8n, Make.com, webhooks (Pro). Homepage.
- CLI `mw transcribe` (formats json/md/html/avid need Pro). https://docs.macwhisper.com/article/57-macwhisper-command-line-tool
- macOS 27 Shortcuts, Spotlight and Siri actions (15.0.1). Release notes.
- AI rewrite of selected text in other apps: none found.

### Platforms & sync
- macOS: direct build. "MacWhisper 15.0 requires macOS 15 or later. Users on macOS 14.x can continue using the versions up to 14.8.1" (15.0.1). Parakeet needs macOS 14.4+. Release notes.
- Apple Silicon vs Intel: WhisperKit is M-series only; Intel "significantly slower", cloud recommended. https://docs.macwhisper.com/article/34-transcription-is-slower-than-expected
- iOS/iPad: "Whisper Transcription" app, local model needs iPhone 15 or newer, share extension. https://docs.macwhisper.com/article/33-macwhisper-for-ios
- iOS dictation keyboard: one App Store review describes starting dictation from an iOS keyboard (https://apps.apple.com/us/app/id1668083311); not in vendor docs.
- Windows, Android, Linux, browser extension: none found.
- Cross-device sync: none found. One App Store review says Mac and iOS subscriptions are separate.

### Privacy & data
- Local models by default: "Process sensitive content locally without data ever leaving your Mac." Homepage.
- Cloud transcription and Assistant send files to third parties or vendor servers. https://docs.macwhisper.com/article/22-assistant
- Deepgram "Model Improvement Program" opt-out added, "enabled by default" (14.7.1). Release notes.
- Option to keep AI titles and summaries on a local model (13.0). Release notes.
- Licensing: "I want to know as little as possible about how / where people use the app". https://docs.macwhisper.com/article/39-licensing
- SOC 2 / HIPAA claims: none found.

### Onboarding & permissions
- Guided dictation setup from the home screen ("this will also guide you through the setup process"). https://docs.macwhisper.com/article/14-how-to-use-the-dictation-feature
- Meeting recording requires Screen Recording and Microphone permission (System Audio Recording only, on macOS 26+). Docs; 15.4.
- Accessibility prompt handling: not documented.

### Accessibility
- None found (no VoiceOver or Voice Control claims on homepage, docs or release notes).

### Distribution
- Direct download via Gumroad (license key). https://goodsnooze.gumroad.com/l/macwhisper
- Mac App Store as "Whisper Transcription" (no dictation, no meeting detection, fewer AI providers). https://docs.macwhisper.com/article/40-macwhisper-whisper-transcription-difference
- iOS App Store: id1668083311, rating 3.91 from 171 US ratings, version 5.2.1 (2026-10-21), min iOS 18.0 (iTunes lookup API, 2026-10-23).
- MDM deployment supported. https://docs.macwhisper.com/article/27-deploying-macwhisper-with-mdm
- Setapp, Homebrew, open source: none found.

## Recent changes (last 12 months)

Release notes carry no dates. 13.0 is the macOS Tahoe redesign ("embraces Liquid Glass"), so roughly autumn 2025. Releasebot first saw 14.2 to 15.6 on 2026-10-14, 15.7 on 2026-10-20 and 15.8 on 2026-10-22.

- 13.0: Liquid Glass redesign, full history with search, dictate while a transcription runs, separate dictation model, prompt tester, dictation history, Apple Speech models, Apple Foundation Model support.
- 13.2: Parakeet dictation 30% faster; history shows target app.
- 13.11 / 13.12: Realtime Captions; live translation; system or app audio as captions source.
- 13.14: dictation indicator positions.
- 14.1: Gladia cloud (Pro); copy 10 recent dictations from menubar.
- 14.2: menubar mic picker.
- 14.3 to 14.8.1: many cloud providers added (AssemblyAI, xAI, Rev AI, gpt-transcribe, Cohere, Speechmatics, Gemini 3.5 Transcribe); CLI upgrades; "Match Keyboard Language"; export dictation audio.
- 15.0.1: requires macOS 15; "Live meetings (Beta)" (Pro); bulk dictionary paste; macOS 27 Shortcuts/Spotlight/Siri.
- 15.1: Qwen3-ASR local model (Pro, M2+, macOS 26).
- 15.2 / 15.3: Nemotron diarization (8 speakers); live meeting transcription on by default.
- 15.5: clipboard restored after dictation paste.
- 15.6: app UI in Spanish, French, Japanese, Simplified Chinese, Swedish, Finnish; dictionary entries keep formatting; meeting auto-stop.
- 15.8: Chromium apps get typed text; any keyboard layout; Qwen3-ASR opt-in on M1.
Source for all: https://macwhisper-site.vercel.app/release_notes.html

## User reception

- Praise (App Store): "the accuracy and speed are really surprisingly great", plus privacy approach (5 stars, 2026-09-14). https://apps.apple.com/us/app/id1668083311
- Complaint: App Store edition lacks dictation, "even though it literally says 'Voice, Speech, Audio Dictation' in the subtitle" (1 star, 2026-09-29). Same link.
- Complaint: free tier blocks export and copy ("The free version is useless. No export, no copy transcript", 2026-09-28). Same link.
- Complaint: engine sprawl hurt reliability; "the only one that works somewhat reliably is Parakeet v3" (2 stars, 2026-06-24). Same link.
- Complaint: Intel Macs miss features such as speaker detection (2026-06-18). Same link.
- Complaint: transcripts come out as "one massive paragraph" without breaks (2026-05-20). Same link.
- Forum: dictation pastes output but doesn't also copy it to the clipboard (MacPowerUsers). https://talk.macpowerusers.com/t/macwhisper-so-fast-so-helpful/41147
- r/macapps thread notes "several other more affordable, fast and accurate alternatives" while the poster still uses MacWhisper daily (mirror). https://reddit.birdcat.cafe/r/macapps/comments/1ktbhgn/misleading_voicetype_post
- Hacker News launch thread "MacWhisper: Transcribe audio files on your Mac", 240 points (2023-08-22). https://news.ycombinator.com/item?id=37228821

## Gaps you could not verify

- Whether dictation supports hold-to-talk as well as toggle; default hotkey.
- Which local models are free versus Pro (13.10.1 mentions "pro-only models"; the original Parakeet note says "(Pro)").
- Whether cloud transcription with your own key is free or Pro (Gladia is marked Pro; others are not marked).
- What "System wide high quality dictation" means versus "System wide dictation".
- Whether dictation shows words while speaking.
- How "on-screen context" is captured and whether it is optional.
- Mac App Store subscription prices for Whisper Transcription, and the Assistant subscription price.
- Exact release dates for 13.0 to 15.8.
- USD pricing on Gumroad (site shows €64 only).
- The FAQ answers on the homepage (System Requirements, Refund policy, Data Privacy, etc.) render only as headings in fetched HTML.
