# Apple Dictation (built into macOS)

- Vendor: Apple
- Platforms: macOS (and iOS, iPadOS, watchOS, visionOS). Current release macOS 27 "Golden Gate", released 2026-09-14, Apple Silicon only; macOS 26 Tahoe was the last release for Intel Macs. (https://www.macrumors.com/roundup/macos-27/)
- URL: https://support.apple.com/guide/mac-help/use-dictation-mh40584/mac
- Date checked: 2026-10-23
- Placement: minimal baseline. Every Mac has it for free with one shortcut, live words at the cursor and spoken punctuation, but no word list, history, per-app behaviour or AI cleanup inside Dictation itself.

## Pricing

- Free, included with macOS. No tiers, no limits on text length ("text of any length without a timeout"). (https://support.apple.com/guide/mac-help/use-dictation-mh40584/26/mac/26)
- The improved macOS 27 dictation model is free but gated by hardware: "Improved dictation and custom Siri voice require an M3 or later chip and at least 12GB RAM", English only. (https://www.macrumors.com/roundup/macos-27/, https://www.apple.com/apple-intelligence/)

## Feature inventory

Source abbreviations: "guide 27" = https://support.apple.com/guide/mac-help/use-dictation-mh40584/mac (macOS 27); "guide 26" = https://support.apple.com/guide/mac-help/use-dictation-mh40584/26/mac/26 ; "commands" = https://support.apple.com/guide/mac-help/commands-for-dictating-text-mh40695/mac ; "availability" = https://www.apple.com/macos/feature-availability/ . Everything is free.

### Trigger & capture

- Turn on in System Settings > Keyboard > Dictation. (guide 27)
- Microphone key (F5 on recent Mac keyboards): press and release starts Dictation; press and hold activates Siri "(Siri must be enabled)". (guide 27)
- "Shortcut" pop-up with preset shortcuts, for example "Press Fn (Function) Key Twice" and pressing Control twice, or "Customize" to set your own (example Option-Z). (guide 27, guide 26; Control-twice from https://discussions.apple.com/thread/256225431)
- This is a toggle: tap to start, tap again (or Escape, or the shortcut) to stop. No hold-to-talk mode found in Apple's guide. (guide 27)
- Auto-stop: "Dictation stops automatically when no speech is detected for 30 seconds." (guide 26)
- "Microphone source" pop-up; "Automatic" picks "the device you're most likely to use for Dictation". (guide 27)
- Typing while dictating: "On a Mac with Apple silicon, you can still use the keyboard while you speak; there's no need to stop dictation." (guide 26)
- Menu bar vs Dock: system feature, no separate app. A microphone/language indicator sits next to the cursor. (guide 26)
- System audio capture, push-to-talk from other devices: none found.

### Transcription engine

- Apple's own speech models. On-device for 48 languages ("Dictation: On-Device and Modeless Dictation", speech models must be downloaded); server processing for others. Keyboard settings show whether input is "processed on your device and not sent to Siri servers." (availability, guide 27)
- Languages: 63 language/region entries for Dictation overall. (availability)
- Language switching: "Edit" next to Languages to add several; switch mid-dictation by clicking the language next to the cursor or pressing the Globe key. No automatic language detection found. (guide 27)
- macOS 27: a second, larger on-device model ("AFM 3 Core Advanced" per 9to5Mac) "delivers even higher accuracy for system-wide dictation" and is "much more precise in capturing what you say from spelling to punctuation and capitalization". English only; Mac with M3 or later and at least 12GB unified memory. Not available on M1/M2 Macs. (https://developer.apple.com/videos/play/wwdc2026/101/, https://www.apple.com/apple-intelligence/, https://9to5mac.com/2026/09/14/macos-27-golden-gate-now-available-here-is-everything-new/)
- No model choice or model switching UI.
- Developer engine: macOS 26 added the SpeechAnalyzer / SpeechTranscriber API for apps; a MacStories test reported a 34-minute video transcribed in 45 s vs 1 min 41 s with Whisper Large v3 (via Gigazine). This powers third-party apps, not the Dictation feature directly. (https://gigazine.net/gsc_news/en/20250619-apple-speech-analyzer)

### Live preview

- Words appear inline at the cursor as you speak (live streaming text). Not stated in Apple's guide; described by users, e.g. "The MacOS built-in dictation streams in real time and also does some cleanup". (https://news.ycombinator.com/item?id=46969306)
- Words can change after display, and "Ambiguous text is underlined in blue"; click it to choose an alternative. (guide 26)

### Cleanup & formatting

- "Auto-punctuation": inserts commas, periods and question marks; can be turned off; 33 languages. (guide 26, availability)
- Spoken punctuation and symbols: "comma", "period"/"point"/"dot"/"full stop", "question mark", "exclamation mark", brackets, quotes, "ellipsis", "at sign", "hashtag", currency signs, maths signs, "copyright sign", emoticons ("smiley face"). (commands)
- Formatting commands: "new line", "new paragraph", "numeral", "roman numeral", "no space on/off", "tab key", "caps on/off" (Title Case), "all caps", "all caps on/off". (commands)
- Emoji by name ("heart emoji"), 33 languages. (guide 27, availability)
- macOS 27: improved capitalisation, punctuation and formatting from the new model (M3+, English). (WWDC26 keynote)
- macOS 27 "Apple Intelligence now automatically proofreads for you" as you type system-wide, "including most third-party apps"; separate from Dictation. (WWDC26 keynote)
- Writing Tools (Apple Intelligence, macOS 15+, M1+): select text and rewrite, proofread, change tone. A manual step after dictating, not part of Dictation. (https://www.macrumors.com/roundup/macos-26/)
- Filler removal ("um"), self-correction handling, per-app tone, custom prompts: none found in Apple docs. The WWDC26 keynote does not mention filler words. (WWDC26 keynote)
- Context awareness inside Dictation: none documented. Siri may receive contact names and installed app names from allowed apps. (https://www.apple.com/legal/privacy/data/en/ask-siri-dictation/)

### Personalization

- Custom vocabulary for Dictation: none. The "custom vocabulary" Apple documents (up to 1,000 terms) is for Voice Control only. (https://support.apple.com/en-au/guide/mac-help/mchl3eb7b79a/mac)
- Spelling: "Dictation supports spelling, so you can spell out names if necessary" (macOS 26). (https://www.macrumors.com/roundup/macos-26/)
- Text Replacements (Keyboard settings) exist system-wide; whether they apply to dictated text was not verified. (Gap)
- Auto-learning from edits, per-app rules: none found.

### Output & editing

- Inserts directly into the focused text field "anywhere you can type"; general text Dictation does not work in search boxes per the guide. (guide 27)
- Correction by clicking blue-underlined words. (guide 26)
- Undo: the app's own Undo. No transcript history or search on Mac. Siri & Dictation request history can be deleted (iPhone path Settings > Siri > Siri & Dictation History). (https://www.apple.com/legal/privacy/data/en/ask-siri-dictation/)
- Clipboard fallback, retry, edit before paste: none.

### Voice commands

- In Dictation: the punctuation and formatting commands above. (commands)
- Full editing and app control live in Voice Control (Accessibility), a separate mode: "Delete", "Uppercase", "Replace cat with dog", "Show numbers", "Show grid", "Drag"; custom commands; 20 languages. "When Voice Control is on, you use Voice Control to dictate text; standard macOS Dictation isn't available." (https://support.apple.com/guide/mac-help/use-voice-control-mh40719/mac, availability)

### Beyond dictation

- macOS 26: Phone app calls "can be saved as audio recordings with transcriptions in the Notes app" (Apple Intelligence required); Live Translation in Messages, FaceTime captions and Phone. (https://www.macrumors.com/roundup/macos-26/)
- Live Translation: 33 languages in Messages, 12 in Phone and FaceTime. (availability)
- Shortcuts can call Apple's on-device and cloud models; macOS 27 examples "Dictate and translate to Spanish", "Dictate my idea and save it to the clipboard". (https://www.macrumors.com/roundup/macos-26/, https://9to5mac.com/2026/09/14/macos-27-golden-gate-now-available-here-is-everything-new/)
- Notes and Voice Memos transcription exist in Apple apps; not part of Dictation.
- Meeting recording of other apps' audio, file transcription inside Dictation: none.

### Platforms & sync

- macOS, iOS, iPadOS, watchOS, visionOS; same feature name across Apple devices.
- macOS 27 requires Apple Silicon; "It is not available for Intel Macs." Apple Intelligence on Mac needs M1 or later; the improved macOS 27 dictation needs M3+ with 12GB+. (https://www.macrumors.com/roundup/macos-27/, https://www.apple.com/newsroom/2026/06/apple-unveils-next-generation-of-apple-intelligence-siri-ai-and-more/)
- Settings sync of Dictation preferences or vocabulary: none found.

### Privacy & data

- On-device processing for 48 languages; Keyboard settings say whether yours is on-device. Otherwise audio goes to Apple's servers. (availability, guide 27)
- Server requests are linked to "a random, device-generated identifier that rotates multiple times per hour"; Apple "may retain and use this data for up to two years"; "your audio data is not stored by Apple" unless you opt in. (https://www.apple.com/legal/privacy/data/en/ask-siri-dictation/)
- "Improve Siri & Dictation" opt-in (Privacy & Security > Analytics & Improvements) lets Apple store and review audio; a reviewed subset may be kept beyond two years. (guide 27, privacy page)
- Siri AI in macOS 27 runs "on device and on servers using Private Cloud Compute"; per-request indicator not announced. (https://www.getvoibe.com/resources/siri-ai-dictation-wwdc-2026/, competitor-written)
- SOC 2 / HIPAA claims: none for Dictation.

### Onboarding & permissions

- No Microphone or Accessibility prompt; it is a system feature. Turning it on shows an "Enable" confirmation, then a prompt to "Share Audio Recordings" or "Not Now". (guide 27)
- Speech model download happens on first use for on-device languages. (availability)
- First-run tutorial: none.

### Accessibility

- Voice Control (separate) is Apple's full hands-free control and dictation, with custom vocabulary of up to 1,000 terms. (https://support.apple.com/guide/mac-help/use-voice-control-mh40719/mac, https://support.apple.com/en-au/guide/mac-help/mchl3eb7b79a/mac)
- Dictation works with VoiceOver (system feature); specific VoiceOver claims for Dictation not found in the guides read.

### Distribution

- Built into macOS. Closed source.

## Recent changes (last 12 months)

- macOS 26 Tahoe (released Sept 2025; point releases through 2026): "Dictation supports spelling"; Phone app call recording with transcripts in Notes; Live Translation; Shortcuts can use Apple Intelligence models; SpeechAnalyzer API for developers. A beta tester reported the "press Fn twice" shortcut stopped working in beta 1. (https://www.macrumors.com/roundup/macos-26/, https://www.applevis.com/forum/apple-beta-releases/macos-tahoe-26-beta-1-released)
- 2026-06-08 WWDC26: "a big update to system-wide dictation with a major boost in accuracy", powered by "a second, even more powerful version of our on-device model"; system-wide automatic proofreading as you type. (https://developer.apple.com/videos/play/wwdc2026/101/)
- 2026-09-14 macOS 27 Golden Gate released: improved Dictation on M3+ Macs with 12GB+, English only; no Intel support. Reports of Apple Intelligence using 30GB+ of disk on some Macs. (https://www.macrumors.com/roundup/macos-27/, https://www.macrumors.com/2026/09/23/apple-intelligence-30gb-some-macs-macos-27/)

## User reception

- HN, Jan 2026, comparing with Handy: "more accurate that the native speech to text". (https://news.ycombinator.com/item?id=46630363)
- HN: "MacOS built in dictation is OK, but struggles with technical language." (https://news.ycombinator.com/item?id=46631101)
- HN, Apr 2026: "The macOS built-in TTS (dictation) seems better than all the 3rd party, local apps I tried in the past". (https://news.ycombinator.com/item?id=47667502)
- HN, Oct 2026, MacBook Neo: "We had to turn OFF Siri so that the F5 button would enable dictation… coach him on the difference between tapping F5 to toggle". (https://news.ycombinator.com/item?id=49967800)
- Apple Community, macOS 26.2: "It looks like a bug because it works well one minute, but stops working"; a disabled user said dictation has worsened with each update. (https://discussions.apple.com/thread/256225431)
- HN, Jun 2026: M2 Mac Studio owner "dismayed" that improved dictation is M3-and-later only. (https://news.ycombinator.com/item?id=48452916)
- Competitor-written reviews list: 30-second silence cutoff, no custom vocabulary, no history, plain text only, some server fallback. (https://www.yaps.ai/blog/macos-tahoe-dictation-review-2026, written by the Yaps vendor)

## Gaps I could not verify

- Full list of presets in the macOS 27 "Shortcut" pop-up.
- Whether macOS 27's new dictation removes filler words or resolves self-corrections (Apple says nothing either way).
- Whether system Text Replacements apply to dictated text.
- Whether the 30-second silence cutoff changed in macOS 27.
- An Apple-published "what's new in Dictation" page for macOS 26 Tahoe (none found; Tahoe changes come from MacRumors).
