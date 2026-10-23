# Voibe

- **Vendor:** Essence AI Ltd, trading as Voibe (founder Bala, per Show HN). Footer: "© 2026 Essence AI Ltd. Trading as Voibe."
- **Platforms:** macOS (Intel and Apple Silicon), Windows 10/11 64-bit. No iPhone or Android app ("We have not announced a mobile release date")
- **URL:** https://www.getvoibe.com. The brief's URL voibe.app does not resolve (DNS lookup failed, "ENOTFOUND", 2026-10-23). The vendor's own site is getvoibe.com; voibe.net says it is an "independently run companion" site (https://voibe.net/en/). An unrelated open-source Mac app also named "voibe" exists at https://github.com/corlinp/voibe; its author notes "the name has since been taken by a paid service" (https://news.ycombinator.com/item?id=47041793).
- **Date checked:** 2026-10-23
- **Placement:** mid-range (Voibe Dictation), edging to full-suite with Voibe Work. Strong on capture (push-to-talk, hands-free, an editable live draft window), spoken punctuation and privacy (on-device or published zero-retention cloud), plus an IDE extension; but no custom prompts or modes, no editing selected text by voice, no auto-learning, no mobile.

Rename: "Voibe Pro" became "Voibe Dictation" when Voibe Work launched ("If you're on Voibe Pro, your plan is now called Voibe Dictation", Mac v3.0.0, 2026-09-24). https://www.getvoibe.com/release-notes/

## Pricing

Source: https://www.getvoibe.com/pricing (checked 2026-10-23). Page toggles "Monthly", "Annual — Up to 4 months free", "Lifetime — Limited time". Merchant of record: LemonSqueezy.

| Tier | Monthly | Annual | Lifetime (one-time) | Gates |
|---|---|---|---|---|
| Voibe Free | $0 forever | — | — | "Dictation in any app, limited words", "One device", "Spoken punctuation", "Custom vocabulary", "Transcript history"; starts with a 7-day trial of every Voibe Work feature |
| Voibe Dictation | $9.90 per seat | $99 per seat | $199 per seat | "Unlimited dictation", "On-device mode or zero-retention cloud mode", "Memory, custom vocabulary and Developer Mode", "Smart punctuation and formatting", Mac and Windows per seat |
| Voibe Work | $19 per seat | $149 per seat | $399 per seat | Everything in Dictation plus "Meeting notes with no bot in the call", "One-click copy and PDF export", "AI summaries with templates", "Chat with your meetings", transcripts saved on your Mac |
| Enterprise | "Talk to sales" (more than 10 seats) | | | "Team admin features", "Central billing and invoicing", "BAA available on request", "Custom terms" |

- Free limit: "limited words" only; no number published.
- Free plan on Windows v2.0.0: "The free plan covers dictation, Dictionary and spoken punctuation. AI clean-up and new Memory entries now come with a paid plan." https://www.getvoibe.com/release-notes/
- Trial: 7 days, no credit card, no auto-charge. https://www.getvoibe.com/pricing
- Refund: "no-questions-asked 30-day refund guarantee". Same.
- Lifetime "includes everything in its plan, including Cloud Mode and future app updates". Same.
- Seat: one person, "one active Mac at a time" plus a Windows PC. Same.
- BYO API key: none ("No API keys to bring"). https://www.getvoibe.com/cloud-ai-privacy
- Older prices on other getvoibe.com pages: "$7.50/mo, $59/yr, $149 lifetime" (cited in search results of https://www.getvoibe.com/resources/voibe-review/); Macworld deal "$49.99" lifetime (https://www.macworld.com/article/3126964/voibe-turns-your-mac-into-a-private-offline-dictation-machine-for-50.html). Treat the pricing page above as current.
- Education discount: none found. Affiliate program and in-app "Personal Offers" with discount codes exist (v3.1.0).
- Transcription API: separate "minute packs" on https://platform.getvoibe.com (prices not checked).

## Feature inventory

### Trigger & capture
- "Push-to-Talk Mode": hold a single key (e.g. Fn, Right Option), release to insert (all plans). https://www.getvoibe.com/help/dictation-modes
- "Hands-Free Mode": press once to start, again to stop; trigger is double-tap a key (default "double-tap Fn"; "Fn+Space" also) or a key combination like ⌘ + H (v2.14.0, 2026-02-17). Same; release notes.
- "Live Dictation Mode (Mac only)": press to start and end, words appear in a floating draft (see Live preview). No default hotkey. https://www.getvoibe.com/help/dictation-modes
- Hotkey shows left or right side; function keys F1/F2 allowed; single modifier can be shared between modes (v2.20.0). Same; release notes.
- Windows default "Right Ctrl" (Windows v1.0.5). Release notes.
- Cancel with Esc ("Cancel a Dictation Instantly", v2.20.0). Release notes.
- Session length: "up to 5 minutes per session in both Push-to-Talk and Hands-Free" (v2.16.0); Live Dictation "No session limit". Release notes; dictation-modes help.
- Menu bar app with "Show Dashboard", "Install IDE Extension", "Paste Last Transcript", "Microphone ›" picker, "Check for Updates", "Quit"; Windows system tray. https://www.getvoibe.com/help/menu-bar
- "Hide from Dock" (v2.17.0). Release notes.
- "Mute Audio While Dictating"; "Smarter Pause Other Audio" using the System Audio Recording permission (v2.17.0, v2.24.0). Release notes.
- System-audio capture: Voibe Work meeting recording from the Mac (Work plan).
- Push-to-talk from other devices: none found.

### Transcription engine
- "On-Device" engine on Apple Silicon (M1 or later), runs on the Neural Engine, "uses the latest Whisper AI models" (exact model name not given). https://www.getvoibe.com/help/how-on-device-works, FAQ on https://www.getvoibe.com
- "Speed vs Accuracy Modes": "Voibe recommends the best model for your Mac's hardware, or you can choose the most accurate model manually" (v2.14.0). Release notes.
- "Cloud" engine: "Whisper Large Turbo, an open-source model running on Groq or Cloudflare"; Intel Macs and Windows use cloud only. https://www.getvoibe.com/cloud-ai-privacy, https://www.getvoibe.com/help/system-requirements
- "Automatic Fallback to Local": if the connection drops, switches to a local model mid-session (v2.25.0, 2026-07-08). Release notes.
- Engine chosen at onboarding, switchable in Dashboard → Settings → Dictation Engine. https://www.getvoibe.com/help/how-on-device-works
- Languages: "over 100 languages" (v2.14.0); Mac "Primary Language" selector; Windows language choice added in Windows v2.0.0 (2026-10-06), though the languages help page still says Windows has none (stale doc). https://www.getvoibe.com/help/languages, release notes
- Auto language detection: not documented; help advises picking Primary Language before each dictation.
- Speed: "Instant on-device. Cloud runs on Groq & Cerebras low-latency inference"; "Faster First Dictation" warm-up (v2.24.0). https://www.getvoibe.com

### Live preview
- "Live Dictation" (Mac only, v2.20.0, 2026-05-21): "watch your words appear on screen in real time"; "The overlay is a real text box, not a preview. Fix a word, delete a line, or reword without stopping, and your edits stay in the final text"; click into earlier lines; Return adds a line break; Esc discards; draft window can be moved and resized; text lands in the app where you started. https://www.getvoibe.com/help/dictation-modes, release notes
- Push-to-Talk and Hands-Free: text appears only after you stop.

### Cleanup & formatting
- "Smart Formatting" / "AI text formatting": punctuation, capitalisation, filler removal, inferred bullet and numbered lists, numbers, times; "Does not paraphrase", "Does not generate content" (Dictation plan). https://www.getvoibe.com/help/smart-formatting
- AI text formatting runs in the cloud ("GPT-OSS 120B … running on Cerebras") even when speech is transcribed on-device; turn it off for fully offline use. https://www.getvoibe.com/cloud-ai-privacy, https://www.getvoibe.com/help/smart-formatting
- "Tuned separately for push-to-talk, hands-free, and Live Dictation" (v2.25.0). Release notes.
- "Cloud AI Formatting for Live Dictation": optional pass after text lands, off by default (v2.24.0). Release notes.
- Self-correction handling: not documented ("Does not rewrite your words").
- Per-app formatting, tone, custom prompts or modes: none found.
- Context awareness: none, explicitly: "Voibe does not read the contents of other apps … does not take screenshots." https://www.getvoibe.com/help/permissions
- Developer Mode reads workspace file and symbol names (see Personalization).

### Personalization
- "Custom Vocabulary" / dictionary: names, terms; "Bulk Edit for Custom Dictionary" (v2.18.0) (Free and paid). Release notes.
- "Memory": spoken key → typed value ("my calendly" → link), for misheard words, boilerplate and prompts; "Does not learn automatically", "Does not work across devices", exact match only, stored locally (Dictation plan for new entries on Windows). https://www.getvoibe.com/help/memory
- "Developer Mode": IDE extension for Cursor, VS Code, Windsurf sends file paths, folder paths and symbols (not contents) so names resolve; spoken "file login dot t s x" attaches files in AI chat panes (Dictation plan). https://www.getvoibe.com/help/developer-mode
- Auto-learning from edits: none ("This is a saved replacement, not automatic learning from edits"). https://www.getvoibe.com/help/memory
- Per-app rules: none found.

### Output & editing
- Inserts via the macOS accessibility API into the focused field; Windows needs no extra permission. https://www.getvoibe.com/help/how-on-device-works, https://www.getvoibe.com/help/permissions
- "Paste Last Transcript" ⌃⌥V (customisable). https://www.getvoibe.com/help/menu-bar
- "Complete Dictation History" stored locally, one-click copy (v2.16.0); "Save transcript history" toggle (v2.19.0). Release notes.
- Edit before paste: Live Dictation draft (Mac).
- Clipboard fallback and undo: not documented.
- Retry: none found.

### Voice commands
- "Spoken Punctuation & Symbols": comma, period/full stop, question mark, colon, semicolon, em/en dash, brackets, quotes, @, &, %, #, /, math signs with "sign", currency ($ € £ ₹), email and web addresses; on by default, runs on the Mac; English only (v2.23.0, 2026-06-06). https://www.getvoibe.com/help/spoken-punctuation
- "Structure By Voice": "new line", "new paragraph", "bullet point", "start numbered list", "next item", "end list" (and synonyms). Same.
- Explicitly not supported: "spoken edits ('delete that', 'select this') or styling ('all caps', 'bold')". Same.
- Developer Mode file/folder phrases. https://www.getvoibe.com/help/developer-mode
- Command mode / app control: none found.

### Beyond dictation
- "Voibe Work" (Work plan): meeting notes with no bot in Zoom, Teams, Meet, Webex, Slack huddles; prompts "Take notes" when a meeting starts; "Full Transcript With Speakers" with timestamps and renameable speakers; summary templates and restyling; "Ask Your Meetings" with cited quotes; copy and PDF export; consent reminder; Mac v3.0.0 (2026-09-24), Windows v2.0.0 (2026-10-06). Release notes; https://www.getvoibe.com/help/meeting-notes
- Meeting audio is processed in the zero-retention cloud; notes stored on the device. https://www.getvoibe.com/pricing
- "Transcription API and MCP server": send a recording, get speaker-labelled transcript, timestamps, summary; MCP at `https://api.getvoibe.com/mcp`. https://www.getvoibe.com/llms.txt
- File transcription inside the app, translation, rewrite of selected text, AI chat outside meetings: none found.

### Platforms & sync
- macOS 14.4 Sonoma or later, Intel and Apple Silicon; on-device needs M1 or later. https://www.getvoibe.com/help/system-requirements
- Windows 10 (1809+) or 11, 64-bit, cloud only, needs internet. Same; release notes v2.0.0.
- Live Dictation is Mac-only.
- Sync: none. Memory is per machine; "Cloud Mode … does not enable synchronization." https://www.getvoibe.com/help/memory
- iOS, Android, Linux, browser extension: none.

### Privacy & data
- "On-Device" engine with AI text formatting off: every step local, audio held in RAM only, "no file was ever written". https://www.getvoibe.com/help/how-on-device-works
- Cloud: providers published (Groq, Cloudflare for speech; Cerebras for formatting), "Audio deleted instantly", "Text never stored", "We only use open-weight AI models". https://www.getvoibe.com/cloud-ai-privacy
- Network use besides dictation: licence checks, usage analytics (counts, no content), crash reports, updates. https://www.getvoibe.com/help/how-on-device-works
- "BAA available on request", including solo practitioners; GDPR and "HIPAA-friendly" help pages. https://www.getvoibe.com/pricing, https://www.getvoibe.com/help/hipaa-friendly
- SOC 2 / ISO 27001: none published (vendor review lists this as a con, per search summary of https://www.getvoibe.com/resources/voibe-review/).
- Never used for training. https://www.getvoibe.com

### Onboarding & permissions
- Mac needs Microphone (auto prompt) and Accessibility (manual toggle, "macOS does not auto-prompt"); Windows needs only Microphone. https://www.getvoibe.com/help/permissions
- Engine choice screen at setup "with the recommended option pre-selected for their Mac" (v2.25.0). Release notes.
- Sign in with emailed 6-digit code; plan links by email. https://www.getvoibe.com/pricing
- Clear alerts when no microphone is found (Windows v1.0.5). Release notes.
- In-app Help Center and support requests (v2.17.0). Release notes.

### Accessibility
- None found (no VoiceOver or Voice Control claims).

### Distribution
- Direct DMG download (Mac) and Windows installer, from the vendor site. https://www.getvoibe.com/help/windows-setup
- One-click in-app updates (Windows v1.0.6). Release notes.
- Mac App Store, Microsoft Store, Setapp, Homebrew, open source: none found.

## Recent changes (last 12 months)

Source: https://www.getvoibe.com/release-notes/
- 2025-09-25: Show HN launch (https://news.ycombinator.com/item?id=45374283).
- 2026-02-17 Mac v2.14.0: Hands-Free Mode, Speed vs Accuracy modes, 100+ languages, Custom Vocabulary, Developer Mode.
- 2026-03-27 v2.16.0: redesign, Complete Dictation History, 5-minute sessions, Paste Last Transcript.
- 2026-04-03 v2.17.0: Memory, microphone choice, mute while dictating, hide from Dock.
- 2026-04-24 v2.19.0: Save transcript history toggle.
- 2026-05-21 v2.20.0: Live Dictation; Esc to cancel.
- 2026-06-06 v2.23.0: Spoken Punctuation and Structure by Voice.
- 2026-06-29 v2.24.0: Cloud AI Formatting for Live Dictation (opt-in).
- 2026-07-08 v2.25.0: Cloud engine (Whisper large), Intel Mac support, automatic fallback to local, Smart Formatting in the cloud.
- 2026-07-18 Windows v1.0.0: Voibe for Windows.
- 2026-09-24 Mac v3.0.0: Voibe Work meeting notes; Voibe Pro renamed Voibe Dictation; needs macOS 14.4.
- 2026-09-26 v3.1.0: in-app personal offers.
- 2026-10-06 Windows v2.0.0: Voibe Work on Windows; free plan loses AI clean-up and new Memory entries.

## User reception

Independent reviews are scarce; most "reviews" online are on getvoibe.com itself.
- Product Hunt: 4.8/5 from 6 reviews, all positive: "Stayed because it is stupidly fast" (jackson fernandez). https://www.producthunt.com/products/voibe/reviews
- Product Hunt: "the deep integration with Cursor and VS Code is a game-changer" (Anietie Effiong). Same link.
- Product Hunt: "runs locally which is a big plus for privacy" (Rakesh Reddy). Same link.
- Hacker News: Show HN drew 1 point and no discussion (2025-09-25). https://news.ycombinator.com/item?id=45374283
- Hacker News comment: "I have been using Voibe, also local and Whisper based" (2026-03-17). https://news.ycombinator.com/item?id=47413269
- Vendor-cited customer: workers' compensation attorney Stewart Reubens, "Dragon is nowhere near as good as Voibe!" (vendor testimonial). https://www.getvoibe.com
- Vendor claim: "20M words spoken … Trusted by 4,000+ professionals". https://www.getvoibe.com
- No App Store listing exists, so no store reviews.

## Gaps you could not verify

- Free-tier word limit (only "limited words").
- Exact on-device Whisper model names and sizes.
- Whether automatic language detection exists.
- Whether text falls back to the clipboard when paste fails.
- Transcription API minute-pack prices.
- Any Reddit discussion (Reddit search blocked; web search found none).
- Whether Windows now has a language selector (release note says yes, help page says no).
