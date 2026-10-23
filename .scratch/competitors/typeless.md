# Typeless

- **Vendor:** Typeless (App Store seller name "Simply LLC"); founders described as "Stanford University alumni and serial entrepreneurs" (about page text)
- **Platforms:** macOS (Apple Silicon and Intel builds), Windows, Linux, iOS, Android
- **URL:** https://www.typeless.com
- **Date checked:** 2026-10-23
- **Placement:** full-suite for cloud AI writing, with no local engine. Dictation plus "Translate", "Ask anything" (edit or question selected text, web answers, quick actions), "Help me write", style learning and auto-learned dictionary on five platforms with an Enterprise admin tier. It has no file transcription, no meeting capture and no on-device speech model found.

Note: typeless.com renders its help and release-note lists in the browser. Text below was read from the page data embedded in each page and from the individual release-note articles listed in https://www.typeless.com/sitemaps/dynamic-route-sitemap-1.xml.

## Pricing

Source: https://www.typeless.com/pricing (checked 2026-10-23)

| Tier | Price | What it gates |
|---|---|---|
| Free | $0 USD / member / month | "Limited words", "Standard accuracy", "Standard access during high demand". Includes "Messy thoughts → Clear writing", "Translate", "Ask anything", "Personalized writing style and tone", "Personal dictionary", "Support for 100+ languages", "Different tones for each app", "Whisper mode" |
| Pro | $12 USD / member / month, billed yearly ($144/yr); "$30 when billed monthly" | "Unlimited words", "Enhanced accuracy", "Priority access during high demand", "Cloud Sync across devices", "Team member management", "Centralized billing and invoices", "Team usage analytics", plus "Prioritized feature requests", "Early access to new features" |
| Enterprise | "Custom pricing" | "Single sign-on (SSO)", "SCIM user provisioning", "Domain verification & capture", "Audit logs with configurable retention", "Enforced HIPAA controls", BAA, "Volume discounts", "Flexible invoicing and payment terms", "Priority support", JIT provisioning |

- Free word limit: the pricing page says only "limited words each week". A Typeless comparison block embedded in the site says "2,000 free words/week across all platforms" and "3-day Pro trial for new users" (site page data, https://www.typeless.com/pricing). App Store reviewers report the free allowance was cut from 8,000 to 2,000 words per week around September 2026 (https://apps.apple.com/us/app/id6749257650).
- Trial: "New customers get a 3-day Pro trial"; banner promo "US$20 off annual plans" (site page data).
- Students: "50% off Typeless Pro … Valid for Desktop checkout only", for users who have not yet subscribed; bulk university licensing on request. https://www.typeless.com/students
- Referral: "$5 Typeless Pro credit for each friend you invite once they dictate 2,000 words. Available for Individual Plan subscribers only." Gift cards exist. (site page data)
- Teams: Pro supports multiple members; seats prorate; "Seats left available during the current billing cycle are not refunded". https://www.typeless.com/pricing
- Lifetime or BYO-key options: none found.
- Payment: Visa, Mastercard, Amex, Discover; Enterprise invoicing. https://www.typeless.com/help/billing

## Feature inventory

### Trigger & capture
- "Dictate" shortcut: "Press the keyboard shortcut for Dictate once (default: Fn on macOS, Right Alt on Windows) … Press the keyboard shortcut again when you are done" (toggle) (Free). https://www.typeless.com/help/quickstart/dictate
- Hold style also referenced: "Hold your Hotkey (e.g., Fn). Speak a command" (v0.9.0 note). https://www.typeless.com/help/release-notes/macos/personalized-smarter
- Separate shortcuts: "Translate" (default Fn + Left Shift on macOS, Right Alt + Right Shift on Windows) and "Ask anything" (Fn + Space; Right Alt + Space). https://www.typeless.com/help/quickstart/translate, https://www.typeless.com/help/quickstart/ask-anything
- Configurable keys, plus "Add another" shortcut "for external keyboards". https://www.typeless.com/help/quickstart/settings
- "Voice bar" appears while recording. https://www.typeless.com/help/quickstart/dictate
- Mic selection: "Auto-detect" or a specific microphone, with level test. https://www.typeless.com/help/quickstart/settings
- "Mute when dictating" (pauses other audio); "Interaction sounds". Same source.
- Menu bar icon ("top-right corner of your screen … Click the Typeless icon") and optional "Show app in dock". https://www.typeless.com/help/troubleshooting/check-for-updates, settings page
- Per-dictation limit: "The current limit for each dictation is 9 minutes", 60-second countdown from minute 8, auto-saved to History. https://www.typeless.com/help/troubleshooting/dictation-limit
- Mobile: "Speak" button on the Typeless keyboard; iOS "Picture in picture" mode to "skip app switching" (V1.9.0, 2026-06-08). https://www.typeless.com/help/release-notes/ios/picture-in-picture
- System-audio capture: none found.
- Push-to-talk from other devices: none found.

### Transcription engine
- Engine and model names: none published on current pages (checked homepage, pricing, help).
- Cloud processing only: "Your audio is processed securely in real time and never stored in the cloud" (site page data); "Ask anything needs an internet connection because the AI runs on secure servers" (site FAQ text). No local or offline speech model found.
- Languages: "100+ languages", "automatically detects your language", mixing languages. https://www.typeless.com
- "Language variants" for English, Chinese, Spanish, French, Portuguese (macOS V0.8.1, 2025-12-16). https://www.typeless.com/help/quickstart/dictate, https://www.typeless.com/help/release-notes/macos/more-language-variants-supported
- Accuracy tier: Free "Standard accuracy", Pro "Enhanced accuracy" (what differs is not explained). https://www.typeless.com/pricing
- Speed claims: "4x faster than typing"; mobile "6× faster than typing" (site page data).
- Model switching UI: none found.

### Live preview
- None found. Docs describe the "Voice bar" and the finished text appearing "where you began dictating" but never words appearing while speaking. https://www.typeless.com/help/quickstart/dictate

### Cleanup & formatting
- "Removes filler words" ("um," "uh," and "you know") (Free). https://www.typeless.com
- "Removes repetition" (Free). Same.
- "Auto-edits when you change your mind": "recognizes when you correct yourself mid-sentence and keeps only your final intended message" (Free). Same.
- "Auto-formats": "organizes spoken lists, steps, and key points into clean, structured text"; "Output is formatted to match the active input field" (Free). Same; site page data.
- "Find the perfect words" / "Understands your intention": rewrites phrasing for clarity (Free). https://www.typeless.com/help/release-notes/macos/introducing-typeless-macos-app-beta
- "Different tones for each app" (Free). https://www.typeless.com
- "Personalized style and tone": learns formal/casual and concise/detailed habits, with a "Personalization progress" report; can be turned off in Settings > Personalization (V0.9.0, 2025-12-24). https://www.typeless.com/help/quickstart/personalization
- "Context Awareness": "reads text on screen, links, and window titles" so dictation matches the field's format; Enterprise admins can switch it off org-wide (Enterprise admin text in site page data).
- Web search + Markdown in commands (V0.9.0). https://www.typeless.com/help/release-notes/macos/personalized-smarter
- Custom prompts or user-written modes: none found.

### Personalization
- "Personal dictionary": "Auto-added" words when "you correct a word after dictating", plus "Manually-added"; CSV bulk import (max 3,000 words at a time per site error text) (Free). https://www.typeless.com/help/quickstart/history-and-dictionary
- Personalization style learning (above).
- Snippets / text expansion: none found.
- Replacement rules: none found.
- Per-app rules: tone per app is automatic; user-set per-app rules not found.

### Output & editing
- Inserts at the cursor via Accessibility in "any text field". https://www.typeless.com/help/installation-and-setup
- History: filter "All, Dictations, or Ask anything"; "Copy transcript"; "Give feedback"; "Retry … with the same audio"; delete one or all. https://www.typeless.com/help/quickstart/history-and-dictionary
- "Keep history": Forever, 1 year, 1 month, 1 week, 24 hours, or Never; stored on device. Same source.
- "Cloud Sync" of History across devices (Pro) (macOS V2.4.0, iOS/Android V2.5.0, 2026-08-26). https://www.typeless.com/help/release-notes/macos/keep-your-history-synced
- Missing-paste recovery: "find your recent transcription in your History". https://www.typeless.com/help/troubleshooting/missing-transcript
- Undo or edit-before-paste: none found.

### Voice commands
- "Speak to edit selected text": "Select any text and speak your command. Instantly make it shorter, longer, change its tone". Desktop via Ask anything shortcut; mobile via "Speak to edit" button (iOS V0.2.0, 2025-12-31). https://www.typeless.com/help/quickstart/ask-anything, https://www.typeless.com/help/release-notes/ios/speak-to-edit
- "Speak to ask about selected text": summary, explanation or translation of read-only text, answer shown without changing the selection. Same.
- "Quick answers & actions": web answers in a pop-up card; opens Google, YouTube, Amazon, GitHub searches. Same.
- "Help me write": spoken instructions become a full email/post (macOS V2.8.0; iOS/Android V2.7.0; 2026-09-22). https://www.typeless.com/help/release-notes/macos/use-help-me-write-desktop
- Spoken punctuation / "new line": none documented.
- App control beyond opening web searches: none found.

### Beyond dictation
- "Translate": speak in one language, insert another; multiple preset "Translation targets" switchable from the Voice bar or by swiping up on mobile (Free). https://www.typeless.com/help/quickstart/translate
- "Whisper mode" (Free, listed on pricing table; no description found).
- Mobile "Swipe-to-type" keyboards for quick edits (iOS/Android V1.5.0, 2026-05-08). https://www.typeless.com/help/release-notes/ios/swipe-to-type
- File transcription: none found.
- Meeting / system-audio recording: none found.
- Notes / summaries of recordings: none found (summaries only of selected text).

### Platforms & sync
- macOS (Apple Silicon and Intel, separate downloads per chip), Windows, Linux, iOS, Android. https://www.typeless.com/help/faqs, https://www.typeless.com/pricing
- iOS: App Store id6749257650, min iOS 16.1, version 2.9.0 (2026-10-22), 4.52 from 769 US ratings (iTunes lookup API, 2026-10-23).
- Android: version 2.1.0 seen on APKMirror (2026-07-14); store listing not checked. https://www.apkmirror.com/apk/typeless/typeless-ai-voice-keyboard/typeless-ai-voice-keyboard-1-8-0-release/
- Interface in 58 languages. https://www.typeless.com/help/quickstart/settings
- Sync: History via Cloud Sync (Pro). Dictionary sync: not documented.
- Minimum macOS / Windows versions: not found.

### Privacy & data
- "Zero cloud data retention", "Never trained on your data", "On-device history storage", "No audio stored in the cloud", "Encrypted across devices". https://www.typeless.com
- "Typeless is ISO 27001 certified, GDPR compliant, and HIPAA compliant." Pricing table lists "HIPAA-ready" for all and "Enforced HIPAA controls" and BAA for Enterprise. https://www.typeless.com/pricing
- Personalization claims to learn "general patterns only". https://www.typeless.com/help/quickstart/personalization
- Enterprise controls: history retention cap, Cloud Sync off for org, Context Awareness off, "Zero Data Retention" toggle in audit log, IP allowlist (site page data).
- Trust center https://trust.typeless.com (subprocessor page blocked by a bot check on 2026-10-23).
- On-device-only mode for speech: none found. A third-party review says the app is cloud-only and cites audio routing to AWS us-east-2 (https://www.getvoibe.com/resources/typeless-review/, competitor-written, unverified).

### Onboarding & permissions
- Sign in with Google, Apple, email, or SSO for Enterprise. https://www.typeless.com/help/installation-and-setup
- In-app permission prompts for Accessibility and Microphone, with "Quit & Reopen" handling and manual fallback steps. Same.
- Microphone test with level bars. Same.
- Guided tutorial: confirms shortcuts, then walks through Dictate, Translate and Ask anything examples. Same.

### Accessibility
- None found (no VoiceOver or Voice Control claims).

### Distribution
- Direct download (Typeless.dmg) from https://www.typeless.com/download. https://www.typeless.com/help/installation-and-setup
- iOS App Store; Android (store not verified).
- Mac App Store, Setapp, Homebrew, open source: none found.

## Recent changes (last 12 months)

Source: articles under https://www.typeless.com/help/release-notes/
- 2025-10-22: Windows app beta V0.1.0.
- 2025-12-04: macOS V0.7.0 "Translation mode".
- 2025-12-16: macOS V0.8.1 language variants.
- 2025-12-24: macOS V0.9.0 Personalization, web search + Markdown in commands.
- 2025-12-31: iOS V0.2.0 "Speak to edit".
- 2026-05-08: iOS/Android V1.5.0 "Swipe-to-type".
- 2026-06-08: iOS V1.9.0 "Picture in picture" (skip app switching).
- 2026-07-08: iOS/Android V2.0.0 multiple translation targets (desktop article also exists, undated in fetch).
- 2026-07-28: iOS V2.2.0 explains when app switching happens (outlined vs solid mic icon).
- 2026-08-26: "Cloud Sync" for History (macOS V2.4.0, iOS/Android V2.5.0).
- 2026-09-22: "Help me write" (macOS V2.8.0, iOS/Android V2.7.0).
- About September 2026: free allowance reduced to 2,000 words/week (per App Store reviews, not a vendor note).

## User reception

- Praise: "the best voice app I've ever tried … Aqua Voice, Whisper Flow, Super Whisper, Willow Voice. They don't even come close" (5 stars, 2026-09-04). https://apps.apple.com/us/app/id6749257650
- Complaint: free cut, "The limit was8000 words per week, now it's 2000 words" (3 stars, 2026-09-28). Same link.
- Complaint: over-editing, "overly aggressive at trying to polish your words, often completely changing the in[tent]" (2 stars, 2026-08-30); another titled "PARAPHRASES WHAT YOU WANT TO SAY" (2026-09-07). Same link.
- Complaint: iOS app blocks Auto-Lock and drains battery after summer 2026 updates (several reviews 2026-08-02 to 2026-08-31). Same link.
- Complaint: upgrade pop-ups "interrupted me mid-session" (1 star, 2026-09-17). Same link.
- Complaint: iOS app switching to reach the mic (1 star, 2026-10-21). Same link.
- Blog: "Typeless can indeed boost your efficiency significantly" for quick replies, but the author feels it is "stripping away my thought process" (2026-07-30; HN repost). https://en.astrian.lol/think-dont-speak/, https://news.ycombinator.com/item?id=49108215
- Third-party summary cites Product Hunt 5.0, Google Play 3.9 (1,335+ reviews) and Trustpilot 2.6, and calls monthly pricing the steepest among major apps (competitor-written). https://www.getvoibe.com/resources/typeless-review/

## Gaps you could not verify

- Exact free-tier word limit on the vendor's pricing page (only "limited words"); 2,000/week comes from an embedded comparison block and user reviews.
- What "Whisper mode" does.
- Which speech and language models are used, and where processing runs.
- Whether any offline or on-device dictation exists.
- Whether words show while speaking.
- Minimum macOS, Windows, Linux and Android versions.
- Whether the dictionary syncs across devices.
- What "Enhanced accuracy" changes in Pro.
- Android store listing and rating (only APKMirror build history seen).
- Whether hold-to-talk and toggle are both supported on desktop for normal dictation (docs show toggle; one note says hold).
