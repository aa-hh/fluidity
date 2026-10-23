# VoiceInk

- Vendor: Prakash Joshi Pax ("Pax"), indie developer (GitHub `Beingpax`)
- Platforms: macOS (Apple Silicon only), iOS / iPadOS (separate app, free during beta)
- URL: https://tryvoiceink.com , source https://github.com/Beingpax/VoiceInk
- Date checked: 2026-10-23 (repo cloned at commit dated 2026-10-20, latest tag v2.22, 2026-10-01)
- Placement: **upper mid, close to full-suite.** One-time $25 to $49, yet it ships per-app "Modes", screen/clipboard/selected-text context, 16 cloud transcription providers, an on-device cleanup model, auto-learning dictionary and a chat assistant. It lacks meeting recording and cross-device sync.

## Pricing

Source: https://tryvoiceink.com/buy (checked 2026-10-23). Currency shown as "$" (not named; assume USD).

| Tier | Price | Devices | Gates |
|---|---|---|---|
| Solo | $25 one-time | 1 Mac | Same features as other tiers |
| Personal | $39 one-time | up to 2 Macs | badges "Most picked" / "Best value" |
| Extended | $49 one-time | up to 3 Macs | badge "More room" |

- Tiers differ only in device count. All include "lifetime access", "lifetime updates", "14-day money-back guarantee" ("no questions asked").
- A "50% Off" banner is on the page with no terms; it is unclear whether $25/$39/$49 are the discounted prices. Third-party reviews quote earlier prices of $29 / $49 / $69 (https://www.getvoibe.com/resources/voiceink-review/).
- Free trial: **7 days**, full features. Source code: `private let trialPeriodDays = 7` in `VoiceInk/Features/Licensing/State/LicenseViewModel.swift`. After expiry `canUseApp` returns false and the app shows "Your trial has ended. Upgrade to VoiceInk Pro at tryvoiceink.com/buy". The paid state is called "Licensed (Pro)" in code.
- Build-from-source is free (GPL-3.0); the compiled version adds Sparkle auto-updates and priority support (README).
- BYO key: every cloud transcription and cloud cleanup provider uses the user's own API key; no hosted VoiceInk cloud plan exists.
- iOS: App Store listing shows Free, no in-app purchases listed (https://apps.apple.com/us/app/voiceink-ai-dictation/id6751431158). Site says "Free during beta. One-time purchase after." (https://tryvoiceink.com/ios). iOS price not published.
- Team / education plans: none found on /buy.

## Feature inventory

All features are included in any paid tier and in the 7-day trial unless marked otherwise. "(trial/Pro)" below means "any paid licence or trial"; there is no free tier after the trial.

### Trigger & capture
- Shortcut modes per shortcut: "Toggle", "Push to Talk", "Hybrid", "Double Tap" (trial/Pro). `RecordingShortcutManager.Mode` in `VoiceInk/Features/Shortcuts/Coordination/RecordingShortcutManager.swift`. Double tap added in 2.21.
- "Primary Shortcut" plus optional "Secondary Shortcut" ("Add Second Shortcut"), each with its own mode. "Supports keyboard combinations and mouse buttons." Mouse shortcuts added in 2.20. Source: `VoiceInk/Features/Settings/Views/SettingsView.swift`.
- "Cancel Recording" shortcut; default is double-Escape.
- During recording, "press Option + 1-9 to switch modes quickly" (`VoiceInk/Features/Modes/Views`).
- "Hide Dock Icon" toggle (menu-bar-only), "Launch at Login".
- Recorder look: "Recorder Style" picker with "Notch" and "Mini" (`RecorderPanelStyle` in `VoiceInk/Features/Recording/Presentation/RecorderUIManager.swift`).
- Microphone: "Microphone Mode" with "Selected Microphone" or a "Priority Order" list ("Add microphones in the order VoiceInk should try them."), "Input Channel" picker, "Refresh Microphones". Source: `VoiceInk/Features/AudioSettings/Views`.
- "Mute Audio While Recording", "Pause Media While Recording" with "Resume Delay" (uses MediaRemoteAdapter).
- "Recording Sounds": "Start Sound" / "Stop Sound" with custom sound picker.
- Clamshell (lid closed) microphone routing fixes in 2.11 and 2.13.
- System-audio capture: none found (no system-audio option in AudioSettings).
- Push-to-talk from another device: none found. An HN user remaps a Bluetooth media button via Karabiner (https://news.ycombinator.com/item?id=50045019); not a built-in feature.

### Transcription engine
Source: `VoiceInk/Features/ModelLibrary/Models/TranscriptionModelRegistry.swift`, `TranscriptionModel.swift`, `Infrastructure/Providers/Transcription/Cloud/`.
- Local models (download in app, "Model Library"):
  - "Apple Speech" (native Apple Speech framework, "Requires macOS 26")
  - "Parakeet V2" 474 MB (English only)
  - "Parakeet V3" 494 MB ("English and 25 European language support")
  - "Parakeet Ultra" 640 MB ("Parakeet V3 post-trained by Moondream"), added 2.21
  - "Parakeet Unified" 1.2 GB (English, "native realtime transcription support")
  - "Nemotron Latin" 620 MB and "Nemotron Multilingual" 672 MB (NVIDIA streaming models)
  - "Cohere Transcribe" 1.56 GB (multilingual, experimental since 2.11)
  - "SenseVoice Small" 241 MB ("Fast CJK and English")
  - Whisper (whisper.cpp): "Tiny" 75 MB, "Tiny (English)" 75 MB, "Base" 142 MB, "Base (English)" 142 MB, "Large v2" 2.9 GB, "Large v3" 2.9 GB, "Large v3 Turbo" 1.5 GB, "Large v3 Turbo (Quantized)" 547 MB
  - Custom local GGUF models via transcribe.cpp (README acknowledgments)
- Cloud transcription providers (user's API key): Groq ("Whisper Large v3 Turbo"), ElevenLabs ("Scribe V2", "Scribe V2 Medical"), Deepgram ("Nova 3", "Nova 3 Medical"), Mistral ("Voxtral"), Gemini ("Gemini 3.5 Transcribe"), Soniox ("Soniox V5"), Speechmatics, AssemblyAI ("Universal-3.6 Pro", "Universal-3.5 Pro", "Universal-2"), xAI ("Grok Voice Transcribe 2.0"), Cartesia ("Ink 2"), OpenRouter (2.21), and "Custom" OpenAI-compatible endpoint with a connection tester. There is a `Streaming` folder for realtime cloud providers.
- Language selection per mode ("Language" picker in Mode settings); per-model language lists in `LanguageDictionary.swift`. Total language count not stated by vendor.
- Model switching: per-mode "selectedTranscriptionModelName" plus a global default; onboarding recommends Parakeet V3 ("Fast multilingual transcription that runs locally on Mac.").
- Speed claims: site "Lightning Fast", "5× faster for email replies"; README "99% accuracy, almost instantly". No latency figure.

### Live preview
- "Live Text Display" toggle: "Shows live text while recording with realtime models." (`SettingsView.swift`). Shown in the recorder panel (Notch or Mini).
- Per-mode "Real-time" toggle (`isRealtimeTranscriptionEnabled` in `ModeConfigDraft.swift`).
- Whether live words are replaced by the final pass: not verified.

### Cleanup & formatting
- "AI Enhancement" toggle per mode with a selected "Prompt" (trial/Pro). Built-in prompt templates: "Default", "Chat", "Email", "Rewrite", "Assistant" (`Features/Enhancement/Templates/PromptTemplates.swift`). The "Default" prompt turns spoken enumerations into numbered lists (example in the prompt text).
- Custom prompts: users can write their own (prompt list in Mode editor; "Custom AI enhancement model IDs" in 2.21).
- "Remove Filler Words" with an editable list ("Add Filler Word"), separate from AI (`FillerWordsSettingsView.swift`, `FillerWordManager.swift`).
- "Paragraph breaks" / text formatting toggle per mode (`isTextFormattingEnabled`).
- Self-correction handling: built into the shared AI system instructions, so it applies only when AI Enhancement is on: "For clear self-corrections, remove the rejected wording and correction signal, keeping only the final intended wording. Correction signals may include “wait”, “wait no”, “actually”, “sorry”" (`VoiceInk/Core/Enhancement/AIPrompts.swift` line 14, with examples like "Thursday. Actually, wait, Friday morning"). Not a separately named feature.
- Skip short transcriptions: "automatically skip AI enhancement for brief responses like 'yes'" (v1.72 release notes).
- Context awareness ("VoiceInk is context-aware."), per mode, three switches: "Selected Text", "Clipboard", "Screen" (`useSelectedTextContext`, `useClipboardContext`, `useScreenCapture`). "Screen" takes a screenshot and runs Apple Vision text recognition on it (`VNRecognizeTextRequest` in `Infrastructure/SystemIntegration/ScreenCapture/ScreenCaptureService.swift`). Needs Screen Recording permission.
- Cleanup providers (user key unless local): Cerebras, Groq, Gemini, Anthropic, OpenAI, OpenRouter, Mistral, ElevenLabs, Deepgram, Soniox, Speechmatics, AssemblyAI, "VoiceInk Refine", Ollama, "Local CLI", Custom (`AIProvider` enum in `Features/Enhancement/State/AIService.swift`).
- "VoiceInk Refine": on-device cleanup model downloaded from Hugging Face repo `beingpax/VoiceInk-Refine-V1`, run in a separate helper process (`VoiceInkRefineXPC`). Added 2.11 ("private, on-device transcription enhancement").
- "Local CLI" provider: pipes text through a local command-line tool (`Infrastructure/Providers/Enhancement/LocalCLI`).
- Per-app tone: done through "Modes" (see Personalization).

### Personalization
- "Modes" (formerly "Power Mode"): "Intelligent app detection automatically applies your perfect pre-configured settings based on the app/ URL you're on" (README). Each mode stores: name, icon, apps, websites, trigger groups, "trigger words", AI on/off, prompt, transcription model, real-time on/off, language, formatting, the three context switches, AI provider and model, output mode, "Auto Send" key, custom command, "Set as default" (`ModeConfigDraft.swift`).
- Starter modes: "Dictation", "Enhancement", "Email", "Rewrite", "Assistant" (`StarterModeTemplate.swift`). Trigger templates: "AI", "Email", "Messaging", "Writing" (`TriggerTemplateCatalog.swift`).
- Trigger words: saying a mode's trigger word in the dictation switches to that mode (`ModeTriggerWordDetectionService.swift`).
- Website triggers read the browser URL; Dia browser added 2.1.
- Mode duplication, reorder ("drag to reorder"), context menu (2.21).
- Dictionary ("Custom words", "Your dictionary"): vocabulary list for model and cleanup ("Add word to vocabulary"; comma-separated paste).
- "Word Replacements" / "Smart Replace": "Original text (use commas for multiple)" to "Replacement text", e.g. "my email" to "support@tryvoiceink.com".
- "Quick Add to Dictionary" shortcut.
- "Auto-Learn Dictionary" (2.20): watches the text field after paste through the Accessibility API, diffs the user's edits against what was pasted, sends proposed corrections to a chosen AI provider/model for review, then queues them under "Review corrections" ("Corrections to review" count). Local CLI support added 2.21. Source: `Features/Dictionary/AutoLearn/` ("Reads editable text through macOS Accessibility only... no keyboard event tap or Input Monitoring is involved.").
- "Export Dictionary" / "Import Dictionary" with "Merge" or replace (2.20).
- Settings "Export" / "Import" backup with per-category import.

### Output & editing
- Paste into any app ("Works Across All Apps"). "Paste Method": "Default" (Cmd+V), "AppleScript", "Direct Typing" (types without clipboard) (`PasteMethod.swift`).
- "Keep Clipboard Content" with "Restore Delay" 250ms / 500ms / 1s / 2s / 3s / 4s / 5s (default 2s).
- "Auto Send": after pasting, presses "None", "Return (⏎)", "Shift + Return (⇧⏎)" or Command+Return. Pressing Return while recording stops and delivers. Global since 2.21.
- Output modes per mode: "Paste", "Respond" (assistant answer), "Custom Command" (shell script receives `$VOICEINK_TRANSCRIPT`). Command templates: "Paste and Press Tab", "Lowercase and Paste", "Remove Trailing Period and Paste", "Append to Journal", "Search Web" (`CustomCommandTemplate.swift`).
- Additional shortcuts: "Paste Last Transcription (Original)", "Paste Last Transcription (Enhanced)", "Retry Last Transcription".
- History: searchable ("Search transcriptions..."), "Export", "Quick History" popup with its own shortcut (2.20), transcription detail with info panel, "History analysis" / "productivity insights" (2.0).
- History retention: "Auto-delete Transcript History" after Immediately / 1 hour / 1 day / 3 days / 7 days; "Auto-delete Audio Files" with "Keep Audio For" up to 14 / 30 days.
- Edit-before-paste: none found.
- Undo: none found beyond the app's own Cmd+Z in the target app.

### Voice commands
- Mode trigger words (spoken word switches mode).
- "Rewrites selected text": select text, speak an instruction, text replaced in place (site).
- "new line" / "new paragraph" spoken commands: none found (grep of source for these strings returned nothing).
- App control by voice: none found, except "Custom Command" scripts.

### Beyond dictation
- File transcription: "AudioImport" feature (`Features/AudioImport/Views/AudioTranscribeView.swift`); iOS 1.35 adds sharing audio/video into the app.
- "VoiceInk Assistant" (2.0): "conversational follow-ups and contextual responses"; README "Built-in voice assistant mode for a quick chatGPT like conversational assistant". Output mode "Respond".
- "Adds quick notes to your journal": timestamped notes to a Markdown journal (site; "Append to Journal" command).
- Meeting / system-audio recording: none found.
- Translation: not found as a named feature (possible via custom prompt). Gap.

### Platforms & sync
- macOS 15.0+ per README and Xcode `MACOSX_DEPLOYMENT_TARGET = 15.0`; website and /buy say "macOS 14.4 or later". The website is stale against the code.
- Apple Silicon only; "8GB RAM recommended" (site).
- iOS / iPadOS 17.0+ app "VoiceInk: AI Dictation" (App Store). Features listed: "Local AI Transcription", "Cloud AI Services", "Customizable Modes", "Searchable History", "Multi-Provider Support", "Privacy-First Design"; 1.35 notes mention swipe typing and optional autocorrection, which implies a keyboard (not confirmed on vendor page).
- Mac to iPhone sync: none found.
- UI localization: German, Simplified Chinese (2.0), French (2.20).

### Privacy & data
- "100% Private"; "Your data never has to leave your device" (onboarding screen `OnboardingTrustScreen.swift`).
- Local transcription and local cleanup (VoiceInk Refine, Ollama, Local CLI) give a fully on-device path.
- With a cloud provider selected, audio (cloud transcription) or text (cloud cleanup) goes to that provider under the user's key. Site FAQ: Cloud Enhancement sends only text.
- Screen context sends OCR text of the screen to the cleanup provider when "Screen" is on.
- Retention controls as in Output & editing. Training opt-out, SOC 2, HIPAA: none found (not applicable, no vendor cloud).

### Onboarding & permissions
Onboarding screens (`Features/Onboarding/Views`): Trust ("VoiceInk is private by default"), Experience, Microphone (lists "Available Microphones"), Permissions, Context Awareness ("Restart VoiceInk after enabling Screen Recording."), Model (downloads Parakeet V3), API ("Get API key", "Test the connection to continue.", "Set It Up Later"), License. "Reset Onboarding" in settings.

### Accessibility
- v2.0 notes: "Refreshed the interface with cleaner navigation and improved accessibility". No VoiceOver or Voice Control claims found on site or README.

### Distribution
- Direct download with Sparkle updates (https://tryvoiceink.com).
- Homebrew: `brew install --cask voiceink` (README).
- Open source, GPL-3.0 (`LICENSE`). "This project is **not accepting pull requests**."
- Mac App Store: none found. Setapp: none found.
- iOS on App Store (id6751431158).

## Recent changes (last 12 months)
Source: https://github.com/Beingpax/VoiceInk/releases and `release-notes/`.
- 2026-10-01 v2.22: diagnostic prerelease for "Parakeet transcription failures and hangs".
- 2026-09-28 v2.21: Parakeet Ultra; OpenRouter transcription; GPT-6 Luna / Sol enhancement models; custom enhancement model IDs; double-tap shortcuts; global Auto Send; mode duplication; Local CLI for Auto Learn.
- 2026-09-19 v2.20: Dictionary Auto Learn; dictionary import/export; Quick History; mouse shortcuts; Grok Voice Transcribe 2.0; Gemini 3.8 Flash and Qwen 3.8 27B; French UI.
- 2026-08-27 v2.13: Gemini 3.5 Transcribe; SenseVoice Small.
- 2026-08-12 v2.11: VoiceInk Refine (on-device cleanup); Cohere Transcribe.
- 2026-07-27 v2.1: Dia browser URL triggers.
- 2026-07-16 v2.0: "Modes" redesign, VoiceInk Assistant, new providers, insights, redesigned onboarding, German and Chinese UI.
- 2026-03-19 v1.72: per-shortcut Toggle / Push to Talk / Hybrid; Power Mode auto-send key; skip short transcriptions; AppleScript paste returns.
- 2025-11 to 2026-05: v1.62 to v1.79 maintenance releases.
- 2025-09-25: iOS app launched (`announcements.json`).

## User reception
- HN, 2026-10-11: "it's been working flawlessly for the three people that use it now for dictating consultation notes." https://news.ycombinator.com/item?id=50044360
- HN, 2026-10-11: user dictates "pretty much ... exclusively by voice now" with VoiceInk plus a remapped Bluetooth button. https://news.ycombinator.com/item?id=50045019
- HN, 2026-10-11: one developer "got annoyed by various UI and other things in tools like VoiceInk, Handy" and wrote their own. https://news.ycombinator.com/item?id=50049269
- iOS App Store, 4.2 from 37 ratings: "Just as good as the paid AI dictation apps." https://apps.apple.com/us/app/voiceink-ai-dictation/id6751431158
- iOS App Store complaint: "Parakeet, doesn't seem to work well for multi-language use." (same link)
- iOS App Store complaint: "The voice recognition doesn't work as well as the one on macOS" and the app is buggy. (same link)
- AlternativeTo comment: "amongst the best whisper apps on macOS I've tried". https://alternativeto.net/software/voiceink/about/
- r/macapps thread (mirror): value and regular updates praised, but commenters suggested cheaper or faster options such as Spokenly and MacWhisper. https://reddit.birdcat.cafe/r/macapps/comments/1ktbhgn/misleading_voicetype_post
- Reliability signal: v2.22 shipped only to diagnose "Parakeet transcription failures and hangs". https://github.com/Beingpax/VoiceInk/releases

## Gaps I could not verify
- Whether $25 / $39 / $49 are sale prices under the "50% Off" banner, and the undiscounted prices.
- iOS final price, and whether the iOS app works as a system keyboard.
- Total supported language count.
- Whether live preview words are replaced by the final transcript.
- Translation as a feature; VoiceOver support.
- Reddit threads directly (search returned mirrors and directories only).
