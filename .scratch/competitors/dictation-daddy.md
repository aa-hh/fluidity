# Dictation Daddy (DictationDaddy)

- Vendor: Dictation Daddy (support contact rahul@dictationdaddy.com, per https://dictationdaddy.com/help)
- Platforms: macOS, Windows, Android (keyboard app), Chrome extension, browser trial at /try. iPhone "coming soon".
- URL: https://dictationdaddy.com
- Date checked: 2026-10-23
- Placement: **mid, aimed at professionals replacing Dragon.** Cloud-only dictation into any app with spoken punctuation commands, text templates, vocabulary, medical/radiology modes and SpeechMike/PowerMic support, at $8 to $12/month; no local models, no custom prompts.

## Pricing
Source: https://dictationdaddy.com/pricing (checked 2026-10-23). Currency shown as "$", not named.

| Plan | Monthly | Annual | Gates |
|---|---|---|---|
| Solo (1 user) | $8/mo (struck-through $15) | $99/year | "Unlimited transcription with BYOK"; "All modes: Standard, Enhanced, Medical, Ultra"; "Templates & Custom Vocabulary"; "All platforms: Mac, Windows, Android, Chrome"; "File upload transcription"; "AI Cleanup & Enhancement"; "Whisper / Discreet mode"; "24/7 email support" |
| Team (per user) | $12/mo (struck-through $18) | $149/year | "Everything in Solo, plus:" "Per-user pricing"; "Shared Dictionary" (Soon); "Shared Snippet Library" (Soon); "Priority email support" |
| Enterprise | custom | custom | "Custom user & transcription limits"; "Dedicated support"; "Industry-specific terminology"; "Compliance options (HIPAA, SOC 2) on request"; "Custom integrations" |

- A "5 Year" billing tab appears with no price.
- Free trial: 7 days on every plan, "No Credit Card". The changelog shows the trial is usage-capped: "Trial limit raised from 20 to 30" (v0.6.13, May 2026); the unit (dictations or minutes) is not stated. v0.10.5 fixes "upgrade links typed into documents at the free limit", so a free limit exists.
- BYOK: connect your own Groq API key ("recommended"); "Support for OpenAI Whisper keys is coming soon" on pricing, though the changelog says own OpenAI key shipped in v0.5.2 / v0.5.3 (Jan to Feb 2026). Pricing page is stale against the changelog.
- Whether transcription without BYOK is metered: not stated ("Unlimited transcription with BYOK" implies a cap without it).
- Lifetime deal: none on pricing, but v0.5.2 mentions "Streamlined onboarding for lifetime deal users", so one existed earlier.
- Homepage claims "Under 100 dollars per year". Cancel anytime; refund policy not stated. "Gift A Friend" (three gifts) referral (v0.6.4).
- Education plan: none found.

## Feature inventory
Gating: all listed features are in Solo unless tagged "(Team)" or "(Enterprise)".

### Trigger & capture
- Global hotkey: Cmd+Shift+Space (Mac), Ctrl+Shift+Space (Windows) per help page; changelog v0.6.15 says "Right Option as default" on Mac. The two disagree.
- "Double-tap mode" (v0.2.2, Dec 2024; "Looser double-tap timing" v0.10.5).
- "Hands-free mode" (v0.2.3), with external mics (v0.6.7) and "Hands-free practice" in onboarding (v0.10.1/0.10.2).
- "Custom shortcuts, including mouse buttons" (v0.8.0). "Click to record" (v0.6.1). "Tray quick shortcuts" (v0.9.0).
- "Pro Hardware": Philips SpeechMike, PowerMic 4, RecMic; FORWARD/REWIND buttons move between fields (v0.7.0, v0.8.2); "Browser/Gamepad mode" (v0.6.12).
- Microphone selection: Settings > Audio (help page). "Microphone status awareness" (v0.5.1).
- Background music muting (v0.2.3); start sound.
- Bottom bar (floating bar) with right-click menu; "Show bottom bar" or hide it completely (v0.6.12, v0.9.0).
- System-audio capture: none found. Push-to-talk from phone: none found.

### Transcription engine
- Cloud only. "Whisper and Soniox speech models" (homepage FAQ). Groq or OpenAI with user's own key.
- Offline: "Offline Support" is under "Exploring" on the roadmap (https://dictationdaddy.com/roadmap). If the network drops, audio is saved locally and retried (v0.3.9 "local audio backup"; comparison page).
- Model picker modes: pricing names "Standard, Enhanced, Medical, Ultra"; v0.6.14 renamed modes to "General dictation", "Medical notes", "Raw transcript", "Highest accuracy" and retired Ultra; v0.9.0 added "Radiology". Pricing page is stale.
- Languages: "50+ languages" (v0.5.2); "Auto-detect language" (v0.5.3); "English (US)", "English (UK)", "English (Australia)" labels (v0.10.0); "Hinglish support" (v0.3.9). Roadmap: "Seamless Language Switching" (in progress), "Mixed Language Support" (planned).
- Speed: "Sub-500ms Latency" in progress on roadmap; "Faster transcription with pre-warming" (v0.5.0). Accuracy claims "96 to 98 percent" (home) and "98-99%" (comparison page).

### Live preview
- None found. v0.6.12 mentions "Cancelled streaming recordings", so audio may stream, but no on-screen live text is documented.

### Cleanup & formatting
- "Auto Formatting": "Punctuation, paragraphs, and lists, done for you"; removes filler words (homepage).
- "AI Cleanup & Enhancement" (Solo). Enhanced mode fixes in several releases.
- "Output Style picker" existed ("Style options" v0.4.0) and was removed in v0.10.4.
- Medical mode: "repairs misheard clinical words" (v0.10.5), medical number and date formatting, "personal medicine list" (v0.10.2).
- Email handling: "Email signature" toggle (v0.4.2), "Greeting line handling in email" (v0.10.0), "window-context email dictation" (v0.3.8).
- "Context-aware dictation" on Windows and Mac (v0.7.0, June 2026). What context it reads is not documented.
- Spoken email addresses converted; letter-spelled names joined (v0.10.4). "Request-like dictations typed verbatim" (so it does not answer questions dictated).
- Self-correction handling ("no wait"): none found.
- Custom prompts: none found. A G2 reviewer wants adjustable refinement levels (search summary of https://www.g2.com/products/dictation-daddy/reviews; page returned 403 to direct fetch).

### Personalization
- "Custom Vocabulary" at Settings > Custom Vocabulary ("Dictionary" renamed "Vocabulary" in v0.4.2); "Custom Words token counter"; bulk CSV import (v0.6.4); syncs across devices (v0.4.2).
- Vocabulary replacements that sync and back up (v0.4.1).
- "Templates": a spoken trigger phrase inserts saved text ("Say 'my calendar link' and it types the link"). Changelog calls them macros: "Rich-text macros" (v0.6.8), "In-place macro editing" (v0.10.1); sidebar "Vocabulary & Macros".
- "Team-prepared vocabulary and macros applied at first sign-in" (v0.10.1) (Team). "Shared Dictionary" and "Shared Snippet Library" marked "Soon" (Team).
- Auto-learning from edits: none found. Per-app rules: none found.

### Output & editing
- Types at the cursor in any app ("Works Across All Apps"). "Smart paste" (v0.6.1). Paste fixes for Citrix, Cerner and legacy EHR systems (v0.6.9, v0.6.13). "Trailing space option" (v0.3.8).
- Automatic retry and "Backup-service retry for failed transcriptions" (v0.10.5).
- "Store Audio Locally" toggle (v0.8.0).
- History, undo, edit-before-paste: none found.

### Voice commands
From https://dictationdaddy.com/help/voice-commands:
- "period" / "full stop", "question mark", "exclamation point" / "exclamation mark", "colon", "semicolon", "ellipsis".
- "new paragraph" / "next paragraph"; "new line" (v0.10.4); "next line" in Medical mode.
- "open paren" ... "close paren", "open bracket" ... "close bracket".
- "all caps" (next word), "no caps"; v0.10.4 adds "in all caps", "caps on" / "caps off", "quote unquote"; "bullet point" in Medical mode (v0.9.0).
- Editing commands (delete, select, undo): none. "Command Mode" is "Planned" on the roadmap.

### Beyond dictation
- "File Transcription": drop audio or video files (.mp3, .mov, .m4a), up to 500MB (v0.5.1).
- Free web tools: microphone test, typing speed test, speaking time calculator (comparison page).
- Meeting recording, notes, translation, AI chat: none found.

### Platforms & sync
- Mac (Electron app; "macOS 13 or later required" since v0.10.0, after v0.10.1 "restored macOS 12 support"; the latest stated minimum is unclear), Intel Macs supported (v0.9.1 fix).
- Windows, Android keyboard app (launched v0.3.3, April 2025), Chrome extension, browser /try.
- iOS: "coming soon" / roadmap "Planned".
- Sync: vocabulary and replacements sync across devices (account-based).

### Privacy & data
- Cloud transcription, needs internet.
- Privacy policy (https://dictationdaddy.com/privacy-policy): by default audio is "stored on our servers after transcription for quality and reliability purposes"; with "Private Mode" it is "processed for transcription and immediately discarded". "We never use your audio data to train AI models." Analytics via PostHog. Transcription subprocessors not named.
- Marketing comparison page says "No audio stored, discarded after transcription", which conflicts with the policy's default.
- Compliance: privacy policy says "Our Enterprise plan is HIPAA compliant with SOC 2 certification"; pricing says "HIPAA, SOC 2 on request"; roadmap lists "HIPAA Compliance" under "Exploring". Three different statements.

### Onboarding & permissions
- Mac Accessibility permission via System Settings > Privacy & Security > Accessibility (help); "Clearer accessibility dialog" (v0.5.2); macOS 12 Accessibility guidance (v0.10.1).
- Onboarding steps for shortcut and mode (v0.6.14); first-dictation walkthrough, email and clinical note demos, hands-free coaching (v0.10.5). Windows: run as Administrator if text is not typed.

### Accessibility
- None found (no VoiceOver or Voice Control claims).

### Distribution
- Direct download from /download; auto-update with "Install Now" / "Skip this version". Not on Mac App Store, Setapp or Homebrew (none found). Closed source.

## Recent changes (last 12 months)
Source: https://dictationdaddy.com/changelog (months only; no day dates).
- Oct 2026 v0.10.5: "Plan and Billing" sidebar; first-dictation walkthrough; full-length formatting for long dictations; backup-service retry; Medical mode fixes.
- Oct 2026 v0.10.4: caps commands, "quote unquote", "new line", spoken email addresses; Output Style picker removed; simpler Settings.
- Sep 2026 v0.10.0 to v0.10.3: English UK/Australia; macOS 13 minimum; team-prepared vocabulary; backup server.
- Aug 2026 v0.9.0 to v0.9.2: "Radiology" mode; drop audio files; "new paragraph"; Intel Mac shortcut fix.
- Jun to Jul 2026 v0.6.14 to v0.8.2: mode renames; "Context-aware dictation"; custom and mouse shortcuts; "Store Audio Locally"; SpeechMike/PowerMic navigation.
- May 2026 v0.6.8 to v0.6.13: external dictation devices; rich-text macros; trial limit 20 to 30.
- Mar to Apr 2026 v0.6.1 to v0.6.7: Team plans with pooled quota; smart paste; CSV vocabulary import; hands-free with external mics.
- Nov 2025 to Feb 2026 v0.5.0 to v0.5.3: pre-warming; 500MB files; own OpenAI key; 50+ languages; auto-detect language.

## User reception
- Trustpilot 3.5/5 from 13 listed reviews (page 1). https://www.trustpilot.com/review/dictationdaddy.com
- Praise, Aug 2026: "easily understands complex medical and legal words." (same link)
- Praise, Mar 2026: "You practically never have to edit the text generated by the app" (same link)
- Dragon replacement, Apr 2026: "Works well for medical dictation." (same link)
- Complaint, Apr 2026: "It does not work half the time"; misses words, likely dialect. (same link)
- Complaint, Feb 2026: bought on 9 February and "still can't use the transcription facility." (same link)
- Complaint, May 2026: "has potential but needs a lot of work." (same link)
- Mixed, Apr 2026: "It has its foibles though!", changes "my spouse and I" to "my spouse and me". (same link)
- G2 4.6 from 10 reviews; accuracy drops with strong accents and background noise; sometimes detects the wrong language (search summary; G2 blocked direct fetch). https://www.g2.com/products/dictation-daddy/reviews
- HN Show HN posts (2024-08-02, 2025-08-17) got no comments. https://news.ycombinator.com/item?id=41137081

## Gaps I could not verify
- Trial unit (30 what) and the free limit size.
- Whether Solo without BYOK has a usage cap.
- Current default Mac shortcut.
- What "Context-aware dictation" reads, and what "Whisper / Discreet mode" does (name only on pricing).
- Live preview behavior.
- Current minimum macOS.
- Real compliance status (three conflicting statements).
- Android keyboard and Chrome extension feature parity.
