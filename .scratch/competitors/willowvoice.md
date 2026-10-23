# Willow Voice

- Vendor: Willow Care, Inc. (YC-backed per a secondary review)
- Platforms: macOS, Windows, iPhone. Android "Coming soon" on the pricing page.
- URL: https://willowvoice.com ; help centre https://help.willowvoice.com/en/ ; old changelog https://willowvoice.featurebase.app/changelog
- Date checked: 2026-10-23
- Placement: **full-suite (lighter than Wispr Flow)**. Same shape as Wispr Flow: cloud dictation with cleanup, per-app styles, a dictionary, voice snippets, an AI rewrite/compose hotkey ("Willow Scribe"), team sharing, SOC 2 / HIPAA. No meetings, no file transcription, no notes app, no MCP. Adds an offline mode that Wispr lacks.

## Pricing

Sources: https://willowvoice.com/pricing (page text, 2026-10-23); https://help.willowvoice.com/en/articles/12854184-willow-pricing-plans-overview ; App Store. US dollars ("$"; currency code not stated). Monthly/annual toggle, "Save 20%" on annual.

| Tier | Monthly | Annual | What it gates |
|---|---|---|---|
| Basic (Free) | $0 | $0 | "Unlimited weaker speech-to-text model (Frontier Mini)", "Limited personalization", "20 Scribe uses per week", "Works anywhere you type". Comparison table also says "Word limit". 5 minutes per dictation. |
| Pro | $15/user/mo | $12/user/mo ($143.99/yr on iOS) | "Unlimited smartest speech-to-text model (Frontier Pro)", "Faster, more accurate, priority transcription", "Smart memory of your writing style", "Unlimited Scribe usage", "Increased dictation length" (8 minutes per dictation). Help article adds "Offline dictation". |
| Business | $35/mo | $28/mo | "Enforced privacy mode (zero data retention)", "SOC 2 Type II compliance", "Enforced HIPAA compliance", "Advanced admin and team controls". |
| Enterprise | Custom | Custom | Invoice/PO billing, SSO/SAML, MSA & DPA, "Advanced usage dashboards and API", dedicated support. Self-serve for 1–50 seats in the app; 50+ seats via sales. |

- Help article (older) lists a "Team Pro Plan" at "$12 per user/month (minimum 3 seats, 20% off annually)" with shared dictionary, shared shortcuts, team dashboard. The current pricing page shows "Business" at $35/$28 instead. The two pages disagree. https://help.willowvoice.com/en/articles/12854184-willow-pricing-plans-overview
- Free tier word limit: pricing page says "Unlimited" Frontier Mini but also "Word limit"; App Store says "Start free with a weekly word limit"; reviewers cite "2,000 words a week" (Product Hunt, 6 months ago). No number on any vendor page. See Gaps.
- Dictation length: Free 5 minutes, paid 8 minutes per dictation. https://help.willowvoice.com/en/articles/12772803-how-to-change-your-dictation-time-limit-in-willow
- Trial: none stated; "No credit card needed."
- Discounts: 30% off Pro for students, educators, non-profit staff, active military and veterans (email with proof). The pricing FAQ mentions the same groups. https://help.willowvoice.com/en/articles/10877048-discount-promo-codes-students-educators-non-profits-military
- Referral and affiliate programme. https://help.willowvoice.com/en/articles/12855717-how-willow-referrals-and-affiliates-work
- Lifetime: none. Bring-your-own API key: none.

## Feature inventory

### Trigger & capture
- Hold-to-talk: default Fn on Mac; release to paste. A "small floating bar" appears. (free) https://help.willowvoice.com/en/articles/10876920-dictating-with-willow-voice
- "No Hands Mode" / "Hands-Free Mode": double-tap the hotkey, press again to stop; or a dedicated Hands-Free hotkey. (free) same; https://help.willowvoice.com/en/articles/10876257-hotkey-settings
- "Hotkey Binding": up to four dictation hotkeys; single key or combination with at least one modifier (examples fn+Ctrl, Cmd+D). Separate hotkeys for "Willow Assistant" and Hands-Free Mode. (free) hotkey article.
- Scribe hotkey: Fn+Control (Mac), Left Windows+Left Shift (Windows). https://help.willowvoice.com/en/articles/15043797-introduction-to-scribe-in-willow
- "Hey Willow" voice activation and F4/F5 bindings were announced 2025-07-15; current help pages do not mention "Hey Willow". https://willowvoice.featurebase.app/changelog/introducing-custom-hotkeys-hey-willow-improvements-v1213
- Esc resets a stuck dictation (v1.6.3–1.6.5, 2025-10-07). https://willowvoice.featurebase.app/changelog
- "the Bar": floating icon/bar, can be dragged to any corner or edge; "Enable Notch View" setting. https://help.willowvoice.com/en/articles/13706888-how-do-i-get-rid-of-the-floating-app-icon-or-the-bar
- Dock icon can be hidden. https://help.willowvoice.com/en/articles/10878381-how-do-i-hide-willow-voice-from-the-dock
- Mic selection: Settings → Microphone; keeps the chosen mic even when AirPods connect; recommends built-in mic. https://help.willowvoice.com/en/articles/10876169-microphone-settings
- System-audio handling (mute/pause music): none found.
- Push-to-talk from other devices: none found.
- iOS: keyboard with a mic button ("press the microphone, talk once"); a yellow mic indicator/"On" island explained in help. https://help.willowvoice.com/en/articles/12855770-why-do-i-see-the-yellow-microphone-indicator-or-floating-island-that-says-on-when-i-use-willow-on-ios

### Transcription engine
- Cloud by default: "Willow uses cloud-based AI models"; servers in the United States. https://help.willowvoice.com/en/articles/12854269-how-willow-protects-your-data-and-privacy ; https://willowvoice.com/security
- Models: "Willow Frontier Pro" (paid) and "Willow Frontier Mini" (free). Described as dictation edit models trained "from scratch" on top of unnamed "best-in-class ASR"; replaced "Willow Atlas 1". Post shows Jul 7, 2026 (metadata says Oct 20, 2026). https://willowvoice.com/blog/introducing-willow-frontier-pro
- "Offline mode": "Dictate without an internet connection, powered entirely by your device." (Pro per help article). Local model name and size not given. https://willowvoice.com ; a competitor review says Mac and iOS only (https://www.getvoibe.com/resources/willow-voice-review/).
- Languages: "100+ languages" (home, pricing, App Store); the older dictation article says "50 languages". "Preferred Language" setting plus automatic detection that adapts "in real time" when you switch mid-dictation. https://help.willowvoice.com/en/articles/10878926-how-do-i-dictate-in-another-language
- Model switching UI: none; model depends on plan.
- Speed claims: "3x more accurate than built-in dictation, with text appearing in as little as 200ms"; "4x faster writing"; "Even Willow Frontier Mini beat every comparison tool on output latency." https://willowvoice.com
- "Whisper mode": handles background noise, whispering, fast speakers. https://willowvoice.com

### Live preview
- None documented. Home page: "Let go. Perfectly formatted text appears where your cursor is." The Frontier post measures latency after you stop speaking. See Gaps.

### Cleanup & formatting
- "Smart formatting": removes filler words, fixes punctuation, formats automatically. (free) https://willowvoice.com
- "Smart correct & formatting" (pricing table row, all tiers).
- Automatic lists (numbered from "One… Two…", bullets from "Bullet, …"), quotes, paragraphs. https://help.willowvoice.com/en/articles/13183983-voice-commands-and-automatic-formatting-guide
- "Backtracking & Editing Mid-Dictation": "No wait, actually, 5 p.m." replaces the earlier time. same article.
- "Automatic Formatting for Emails": greeting, body, closing on separate lines.
- "Style-matching" / "Personalization": presets per context: Casual messaging (Default, Gen Z, Casual Lowercase, Casual), Work messaging (Default, Casual Lowercase, Casual Standard, Excited), Email (Default, Casual Friendly, Excited), Note-taking & other (Casual Punctuation, Hypercasual, Casual Friendly, Excited). https://help.willowvoice.com/en/articles/12864746-personalization-and-style-matching
- "Smart memory of your writing style": learns from your writing over time (Pro).
- "Context awareness" (optional toggle): reads "small bits of text around your cursor"; not stored, not linked to account. Pricing table: "Personal + shared" on paid tiers. https://help.willowvoice.com/en/articles/12854269-how-willow-protects-your-data-and-privacy
- "Willow Scribe": speak your intent and it writes the message; three uses: "Scribe from scratch", "Respond with Scribe" (reads what's on screen to write a reply), "Edit with Scribe" (select text and say "Make this more formal", "Rewrite this in Spanish"). Uses saved shortcuts as facts (e.g. calendar link). Free: 20 uses/week; Pro unlimited. iOS: pencil icon on the keyboard. https://help.willowvoice.com/en/articles/15043797-introduction-to-scribe-in-willow
- iOS "AI Rewrite": "One tap to tighten, expand, change tone, or fix grammar after dictating." https://apps.apple.com/us/app/willow-dictation-ai-keyboard/id6753057525
- "Willow Assistant" hotkey exists; its function is not described beyond "activate Willow's assistant mode". hotkey article.
- Custom prompts or user-defined modes: none found.

### Personalization
- "Dictionary" / "Personal Terms": add names, products, acronyms. (free) https://help.willowvoice.com/en/articles/13183918-using-personal-dictionary-and-shortcuts
- "Auto-learning dictionary": "Remembers names, product terms, and abbreviations". https://willowvoice.com
- "Shortcuts": say the phrase followed by "shortcut" (e.g. "meeting link shortcut") to insert saved text. (free) same help article.
- Team "Collaboration" page: shared terms and shortcuts; new teammates' names auto-added as shared terms. (Team/Business) https://help.willowvoice.com/en/articles/13959267-using-collaboration-features-for-your-team
- Replacements (wrong spelling → right spelling): none found as a separate feature.
- Per-app rules: style presets by app category only.
- Dictionary and shortcuts sync across devices. iOS dictionary article: https://help.willowvoice.com/en/articles/12864717-using-dictionary-terms-on-ios

### Output & editing
- Inserts at the cursor in any app (Accessibility on Mac; "Input / typing permissions" on Windows). https://help.willowvoice.com/en/articles/10876111-install-and-setup-willow-voice-mac-windows
- "Transcript history": stored on device only; used for "re-transcription"; not carried to a new device. (free) https://help.willowvoice.com/en/articles/12854269-how-willow-protects-your-data-and-privacy
- Clipboard fallback, undo, history search, edit before paste: none found.

### Voice commands
- "New line", "Next line", "New paragraph"; spoken punctuation ("exclamation mark", "question mark", "quote … quote", commas, periods, dashes, em-dashes); "Bullet". https://help.willowvoice.com/en/articles/13183983-voice-commands-and-automatic-formatting-guide
- Editing by voice: through "Edit with Scribe" on selected text.
- App control: none found.

### Beyond dictation
- iOS "Capture ideas as quick notes and expand them later with AI" (App Store).
- Translation: through Scribe edits ("Rewrite this in Spanish"); no standalone feature.
- File transcription, meetings, system-audio recording: none found (looked at home, pricing, help centre lists).
- "Advanced usage dashboards and API" (Enterprise) – API scope not described.

### Platforms & sync
- Mac (minimum macOS 14 per Homebrew cask), Windows (launched January 2026 per secondary review), iPhone iOS 18.0+ (launched 2025-11-10 per App Store first release date). App Store says "Only for iPhone" though release notes mention 13" iPad Pro layout fixes.
- Android: "Coming soon" (pricing table). A Product Hunt reviewer (15 days ago): "I can't fully switch until it's available on Android."
- Linux: none.
- Same account on all devices; dictionary and shortcuts sync; transcripts do not. https://help.willowvoice.com/en/articles/13208038-why-isn-t-my-account-or-subscription-syncing-between-devices
- Apple Silicon vs Intel: not stated.

### Privacy & data
- "Private Mode" (default; also called "Privacy Mode"): "No dictated text is collected", no transcript or context data saved on Willow servers, "No audio is stored". https://help.willowvoice.com/en/articles/12854269-how-willow-protects-your-data-and-privacy
- "Help Willow Improve" (opt-in): anonymised transcript text collected for training; no audio.
- Enterprise/Business can enforce Privacy Mode org-wide. https://willowvoice.com/security
- "Offline mode" runs on device (Pro).
- SOC 2 Type II (Security criteria; report under NDA), HIPAA with BAA ("Enable HIPAA Support in Willow"), GDPR/CCPA "alignment", TLS in transit, encryption at rest with cloud key management. https://help.willowvoice.com/en/articles/13668493-compliance-certifications-and-security-standards ; https://help.willowvoice.com/en/articles/13668518-data-security-and-encryption ; https://help.willowvoice.com/en/articles/13668475-enable-hipaa-support-in-willow
- Marketing says "end-to-end encryption"; the help article describes only TLS plus at-rest encryption, which is not end-to-end in the usual sense.
- iOS App Store privacy label: "Data Used to Track You: Usage Data"; linked data used for "Third-Party Advertising".

### Onboarding & permissions
- Mac: create account → Microphone → Accessibility; "ready to dictate in under a minute". Windows: Microphone and "Input / typing permissions". https://help.willowvoice.com/en/articles/10876111-install-and-setup-willow-voice-mac-windows
- iOS: keyboard access, "Full Access", microphone. https://help.willowvoice.com/en/articles/12845807-setting-up-permissions-on-ios-keyboard-access-full-access-microphone
- macOS v1.8.4 caused Keychain prompts and an "improperly signed update" (help articles). https://help.willowvoice.com/en/articles/13414438-macos-improperly-signed-update-v1-8-4
- First-run tutorial: none described.

### Accessibility
- App Store: "A faster, lower-effort way to write for anybody with mobility, vision, or RSI needs." No VoiceOver or keyboard-navigation claims found.

### Distribution
- Direct download from willowvoice.com (Mac DMG, Windows installer). https://willowvoice.com/download
- Homebrew cask `willow-voice` v2.6.9 (downloads from a GitHub releases repo `LiuLawrence45/stt-sparkle-update`), macOS 14+. https://formulae.brew.sh/cask/willow-voice
- iOS App Store "Willow Dictation & AI Keyboard", v2.13.0 (2026-10-15), 4.6 stars from 1,069 ratings, 379 MB. https://apps.apple.com/us/app/willow-dictation-ai-keyboard/id6753057525
- Mac App Store, Setapp: not listed. Closed source.

## Help centre article inventory (2026-10-23)

Getting Started (11): Install and Setup Willow Voice (Mac + Windows); Microphone Settings; Hotkey Settings; Dictating with Willow Voice; Setting Up Permissions on iOS: Keyboard Access, Full Access, & Microphone; Using Dictionary Terms on iOS; Personalization and Style Matching; Using Personal Dictionary and Shortcuts; Voice Commands and Automatic Formatting Guide; Using Collaboration Features for Your Team; Introduction to Scribe in Willow.

Troubleshooting and FAQs (16): Submitting a Bug or Feedback; How do I hide Willow Voice from the Dock; How do I dictate in another language; Dictation Quality or Transcription Failure Problem; How to Change Your Dictation Time Limit in Willow; Why am I taken back to the Willow iOS app before I can dictate?; Why do I see the yellow microphone indicator or floating island that says "On" when I use Willow on iOS?; Why does Willow's keyboard autocorrect feel different from the iOS keyboard?; Why isn't the Willow iOS keyboard showing up during in Settings onboarding; Why did my Willow iOS keyboard disappear; Crashing or Unexpected Shutdown with Willow Voice; Why isn't my account or subscription syncing between devices; macOS Permissions & Keychain Prompts in v1.8.4; macOS Improperly Signed Update v1.8.4; Dictation appears in the wrong language; How do I get rid of the floating app icon or the Bar.

Subscription & Billing (11): Upgrading to Willow Pro; Discount Promo Codes (Students, Educators, Non-Profits, Military); Finding your receipts and invoices; Managing or Canceling Your Willow Subscription; Willow Pricing Plans Overview; How to access your Willow Pro subscription between Mac and iOS; How Willow Referrals and Affiliates Work; Getting Started with Team Plans; How to Manage Your Team or Enterprise Billing; How to Configure SSO for Your Organization; Getting Started with the Enterprise Plan.

Privacy & Security (4): How Willow Protects Your Data and Privacy; Enable HIPAA Support in Willow; Compliance Certifications and Security Standards; Data Security and Encryption.

(Titles taken from article URL slugs and page headings.)

## Recent changes (last 12 months)

The featurebase changelog stops at 2025-10-07; no newer public changelog found. Items below come from the App Store, Willow's blog, and one secondary review.

- 2025-10-07: v1.6.3–1.6.5 "Stability, Control, and More Personalization" (Esc resets pipeline, Notifications tab). https://willowvoice.featurebase.app/changelog
- 2025-11-10: iOS app first released (App Store release date). https://apps.apple.com/us/app/willow-dictation-ai-keyboard/id6753057525
- 2026-01: Windows release (secondary). https://www.getvoibe.com/resources/willow-voice-review/
- 2026-02: "Willow for Developers" with Cursor / AI IDE support (secondary; developer page exists at https://willowvoice.com/developers).
- 2026-03: "Willow for Teams" (secondary).
- 2026-07-07 (or 2026-10-20 per page metadata): "Introducing Willow Frontier Pro" and Frontier Mini models. https://willowvoice.com/blog/introducing-willow-frontier-pro
- 2026: pricing reshaped to Basic / Pro / Business / Enterprise; Scribe introduced (help article ID suggests recent). https://willowvoice.com/pricing
- 2026-10-15: iOS v2.13.0 ("Performance optimizations and stability improvements").

## User reception

- App Store 4.6/5 from 1,069 ratings. Praise: "It lets you pause to formulate your thoughts and keeps your output as you intended." Complaint: "crashes constantly despite frequent updates". https://apps.apple.com/us/app/willow-dictation-ai-keyboard/id6753057525
- App Store complaint (2025-11-18): "the app wants to be always recording audio in the background". same link.
- Product Hunt 4.8/5 (13 reviews): "Willow by far has been fast and accurate"; "probably saves me at least two hours every day". https://www.producthunt.com/products/willow-voice/reviews
- Product Hunt complaints: "it will sometimes translate the language in which you dictate to English"; "I can't fully switch until it's available on Android"; "The free tier is 2,000 words a week." same link.
- Hacker News: "I found Superwhisper to be slow. Willow is almost instantaneous." https://news.ycombinator.com/item?id=44432703
- Hacker News: lists Willow among dictation apps that are "user hostile, buggy or have limited feature set", citing default Context awareness. https://news.ycombinator.com/item?id=48531184
- Hacker News: "willow voice did do extensive finetuning to improve the quality and speed". https://news.ycombinator.com/item?id=47030967
- Hacker News: price complaint: "Willow ($144/year)" as a subscription for something "that could run on my Mac". https://news.ycombinator.com/item?id=45923353
- Reddit r/macapps: could not be fetched (blocked to this tool).

## Gaps (not verified)

- Free-tier weekly word limit number (2,000/week only from reviewers).
- Current team pricing: help article "Team Pro $12, min 3 seats" vs pricing page "Business $35/$28".
- Offline mode: which local model, which platforms, which plan (help article says Pro).
- Live preview while speaking.
- What the "Willow Assistant" hotkey does, and whether "Hey Willow" still exists.
- Whether Context awareness is on or off by default (help says "optional").
- Windows launch date and the dated 2026 releases (all from one competitor-written review).
- macOS minimum version (only from the Homebrew cask) and Intel support.
- Language count (100+ vs 50 on different vendor pages).
- Reddit threads (blocked).
