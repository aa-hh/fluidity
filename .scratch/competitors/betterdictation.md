# BetterDictation

- Vendor: BetterDictation (founder posts on HN as the creator, https://news.ycombinator.com/item?id=43638808); company name not stated on site.
- Platforms: macOS, Apple Silicon only. Windows "soon" with a "Notify me" waitlist.
- URL: https://betterdictation.com
- Date checked: 2026-10-23
- Placement: **minimal.** Hold-or-toggle local Whisper dictation into any app plus an optional $2/month OpenAI cleanup prompt; no dictionary, history, context awareness or per-app rules are documented.

## Pricing
Source: https://betterdictation.com/#pricing (checked 2026-10-23). Currency shown as "$", not named.

| Tier | Price | Devices | Gates |
|---|---|---|---|
| Basic | $39 lifetime | 1 | "lifetime basic transcription", "regular updates" |
| Flex ("Most Popular") | $49 lifetime, then $2/mo for Pro, billed annually | 3 | basic transcription; "3 free months of Pro"; stammer correction, automatic formatting, AI post-processing |
| Studio | $149 lifetime, then $2/mo per device for Pro, billed annually | 10 | basic transcription; "dedicated account manager"; 3 free months of Pro |
| Enterprise | Contact sales | unlimited | volume discounts, custom onboarding, bespoke feature development |
| Pro add-on | $2/month billed annually ($24/yr) | per device on Studio | "Stammer Correction", "Automatic Formatting", "Post-processing using OpenAI prompts" |

- No free tier and no trial of the base app: "BetterDictation is a paid product"; a licence key is needed before installing (https://betterdictation.com/install).
- Pro can be tried free per the pricing section; Flex and Studio include 3 months of Pro.
- Refund: 14-day money-back guarantee via support@betterdictation.com.
- BYO API key: none found; Pro uses the vendor's OpenAI access.
- Education plan: none found. AlternativeTo lists a price range "$24 to $399" (https://alternativeto.net/software/betterdictation/about), which does not match the current site.

## Feature inventory
Gating: "(Basic)" means every licence; "(Pro)" means the $2/month add-on.

### Trigger & capture
- "Push-to-Talk Mode": hold the shortcut, release to transcribe; marked recommended (Basic). https://betterdictation.com/help
- "Toggle-to-Talk": press once to start, again to stop; FAQ recommends it for long dictation (Basic). https://betterdictation.com/
- Default shortcut: the homepage shows "⌥ Space"; the user guide says "press and hold Control V". The two pages disagree. Whether the shortcut is rebindable: not stated.
- "Control Shift L" cycles model presets (one per language) and, for Pro, saved prompts. https://betterdictation.com/help
- Menu bar app; preferences open from the menu bar icon; "Listening..." shows on screen while recording.
- "Dim Audio": lowers system output by 90% during recording, then restores it (Basic).
- "Launch at login" (Basic).
- Microphone selection: none in app; the guide says to change the system default microphone in System Settings.
- System-audio capture: none found. Push-to-talk from other devices: none found.

### Transcription engine
- Local only for transcription: OpenAI Whisper "whisper-large-v3-turbo" running "on Apple's Neural Engine" (FAQ, https://betterdictation.com/). The guide refers to "larger models" and "English-only models" as selectable presets but no model list is published.
- Cloud transcription models: none.
- Languages: "100+" / "over 100 languages".
- Language handling: set the language per model preset in preferences; auto language detection not stated.
- Speed claim: "4× faster than typing"; "no cloud round-trips".

### Live preview
- None found. Text appears "when you release the keys" (help page).

### Cleanup & formatting
- Automatic punctuation without spoken commands (Basic). https://betterdictation.com/
- "Stammer Correction": "automatically removes stammers, filler words, and repeated phrases"; the example turns "three.. I mean two weeks" into the corrected phrase, so self-correction is handled (Pro). https://betterdictation.com/pro
- "Automatic Formatting": e.g. a rambling grocery list becomes a grouped bulleted list (Pro).
- "Grammar Correction" / "Grammar Improvements" (Pro).
- Editable prompt in preferences with a `{{TRANSCRIPTION}}` placeholder; save several prompts and cycle with Control Shift L (Pro). https://betterdictation.com/help
- Context awareness: none found. A Wispr Flow comparison page says it "lacks context-aware corrections" (competitor source, https://wisprflow.ai/comparison/betterdictation-alternative).
- Per-app tone: none found.

### Personalization
- Custom dictionary, snippets, replacements, auto-learning, per-app rules: none found on home, /pro or /help.
- Saved prompts (Pro) and per-language model presets are the only personal settings documented.

### Output & editing
- Types into any app ("System-wide use"; "Works in Any App"). Paste method and clipboard handling not documented.
- History, retry, undo, edit-before-paste: none found. Privacy policy says audio and transcripts are "never stored".

### Voice commands
- None found. Punctuation is automatic, "without spoken commands".

### Beyond dictation
- None found (no file transcription, meetings, notes, translation or rewrite of selected text).

### Platforms & sync
- macOS Sonoma 14.4 or later (help page); Apple Silicon M1 or newer; Intel not supported.
- Windows: announced, not shipped as of 2026-10-23.
- iOS / Android / Linux / browser extension: none. Sync: none.

### Privacy & data
- Basic: "operates fully offline"; "no audio recordings or transcriptions are sent to our servers" (https://betterdictation.com/privacy, effective January 2025).
- Telemetry for all users: application performance data and crash reports; provider not named.
- Pro: text (not audio) goes to OpenAI's API.
- Training use: not addressed. SOC 2 / HIPAA / GDPR: not mentioned.

### Onboarding & permissions
- First launch runs a tutorial that asks for the licence key, Accessibility permission and Microphone permission; the tutorial can be reopened from the menu bar. https://betterdictation.com/help

### Accessibility
- None found.

### Distribution
- Direct download from https://betterdictation.com/install after purchase. Mac App Store, Setapp, Homebrew: none found. Closed source.
- Affiliate programme at /affiliate.

## Recent changes (last 12 months)
- None found. No changelog or version number on the site; blog posts stop at 2025-06-10 (https://betterdictation.com/blog). Windows is still "soon".

## User reception
Public reviews are scarce.
- AlternativeTo, 2024-10-16, 5 stars: "Easy implementation of local whisper models into the system so you can do really accurate dictation anywhere." https://alternativeto.net/software/betterdictation/about
- HN, 2023-12-13: "I've been using this product for whisper". https://news.ycombinator.com/item?id=38630643
- HN, 2025-01-17: a user who uses it ("which tbf I do use") calls it an example of "wrapping hf endpoints/embeds in dodgy SaaS offerings" and questions the testimonial avatars. https://news.ycombinator.com/item?id=42734773
- G2: "not enough reviews" to show insights. https://www.g2.com/sellers/betterdictation
- No Reddit or Product Hunt listings found.

## Gaps I could not verify
- Which default shortcut is current (⌥ Space vs Control V) and whether it is customizable.
- The list of selectable local models and their sizes.
- Auto language detection.
- Paste method (simulated typing vs clipboard) and clipboard restore.
- Any release in the last 12 months; current version number.
- Pro trial length for Basic buyers.
