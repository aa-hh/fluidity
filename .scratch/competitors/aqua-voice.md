# Aqua Voice

- Vendor: Aqua Voice, Inc. (Y Combinator company per HN users)
- Platforms: macOS (universal: Apple Silicon and Intel), Windows, iPhone (iOS 17+), Android 10+ (since 2026-10-06). CLI also on Linux.
- URL: https://withaqua.com now serves the site from https://aquavoice.com ; guide https://aquavoice.com/guide ; changelog https://aquavoice.com/changelog
- Date checked: 2026-10-23
- Placement: **full-suite (dictation-focused)**. Cloud dictation on its own speech model ("Avalon") with custom instructions, screen reading ("Deep Context"), voice editing of selected text ("Edit Mode"), live words ("Realtime Mode"), "send it" voice command, MCP server, CLI and a public speech API. No meetings, no notes, no offline mode on desktop. Strongest on technical vocabulary and coding.

## Pricing

Source: https://aquavoice.com/pricing (FAQ text, 2026-10-23). US dollars.

| Tier | Monthly | Annual | What it gates |
|---|---|---|---|
| Free | $0 | $0 | "1,000 free words" (one-time allowance, "about 7 minutes of talking"), "Avalon transcription model". No card. Free can try Realtime Mode within those 1,000 words. |
| Pro | $10/month | $8/month billed annually | "Unlimited words", "Custom Instructions", "Expanded Custom Dictionary". |
| Max | $30/month | $24/month billed annually | Everything in Pro + "See words live with Realtime Mode", "'Send it' voice command", "Early access to new features". |
| Business | $24/seat/month | $228/seat/year ($19/month) | Teams of 2+. Everything in Max + "Centralized billing", "SSO/SAML + SCIM", "Advanced Reporting", "Zero Data Retention", "Team-wide Dictionaries". Over 20 users (FAQ says 100+ seats): contact sales, "active user billing". |

- Students: 70% off Pro and Max (Pro $2.40/mo annual or $3 monthly; Max $7.20/mo annual or $9 monthly); .edu and international academic domains.
- iOS in-app purchases cost more than web: Pro $12.99/mo, Pro Annual $119.00; Max $39.99/mo, Max Annual $374.99. https://apps.apple.com/us/app/aqua-voice-ai-dictation/id6759074969
- Pricing change: "Pro and Team don't include [Realtime Mode], though subscriptions from before the change kept it." https://aquavoice.com/realtime
- Referral: friend gets a free month, referrer gets $10 credit (v0.9.10).
- Avalon API / CLI file transcription: $0.39 per hour of audio, 10-second minimum, first $1.00 free. https://aquavoice.com/docs/cli
- Lifetime: none. Bring-your-own API key: none.

## Feature inventory

### Trigger & capture
- Hold-to-talk: "Hold your Aqua key and release to finish." Default key not stated on vendor pages (home demo says "Hold Space"; Realtime page shows "fn"; an HN user says "They use right-ctrl"). (free) https://aquavoice.com/dictation-accessibility ; https://news.ycombinator.com/item?id=46279492
- Hands-free: "double-tap the key, say a short passage, and press it again to stop"; separate reassignable "Activate Hands-Free" keybinding. (free) same; https://aquavoice.com/changelog (v0.3.0)
- Activation options: "Realtime always", "Instant always", or Realtime only when hands-free (default). https://aquavoice.com/realtime
- "Keybindings": up to 5 keys per combination, up to 5 activation keys per action ("Add Alternative"), Fn chords, F13–F19, ⌘+Space possible; device-specific, not synced; Aqua keys "will NOT bubble down to your active application". (free) https://aquavoice.com/guide/how-to-add-multiple-activation-keys
- Mouse buttons 3, 4, 5 as shortcuts for dictation, hands-free, paste last transcript (v0.18.6, 2026-07-30). (free)
- "Paste Last Transcript" shortcut: Cmd+Ctrl+V (Mac), Ctrl+Shift+RightArrow (Windows), customisable. (free)
- "Floating Bar" / "pill": Liquid Glass design on macOS 26+ with orb and waveform (v0.20.0); "Keep pill at screen bottom". Menu bar icon; Dock icon can be hidden. https://aquavoice.com/guide/how-to-hide-dock-icon
- "Aqua Pet" (v0.21.0, 2026-10-15): optional animated pet in place of the bar that "throws your words into the text field"; unlockable hats by word count; leaderboards for paid plans. (free; Pro/Max cosmetic extras) https://aquavoice.com/changelog
- Mic selection: microphone picker; blacklist virtual inputs such as BlackHole so Aqua auto-picks another (v0.19.12). Mic startup on Windows cut "from 298 ms to 122 ms" (v0.19.14). Guides: "Recommended Microphones", "How to fix microphone delay".
- "Mute Background Audio" while recording: macOS (v0.7.0, on by default, can be disabled), Windows (v0.11.6). (free)
- iOS: keyboard with mic; "Action Button" start/stop on supported iPhones (copies transcript if the Aqua keyboard isn't open). Android: a small button that slides out beside your existing keyboard; tap or hold; drag to hide 10 minutes, shake to restore. https://aquavoice.com/ios ; https://aquavoice.com/android
- Push-to-talk from other devices: none found.

### Transcription engine
- Cloud only on desktop: "Aqua processes audio in the cloud, where the Avalon model runs; there is no offline mode." https://aquavoice.com/mac
- "Avalon" (in-house speech model, launched 2025-08-21); "Avalon 1.5" enabled for desktop 2026-04-13. "97.4% key-term accuracy on AISpeak-10" vs Whisper Large v3 65.1% (Aqua's own benchmark). "At its October 2025 debut it ranked #1 among proprietary models on the public OpenASR leaderboard." https://aquavoice.com/guide/how-to-use-avalon ; https://aquavoice.com/mac
- Settings → Model: choose "Avalon 1.5" (the guide implies a separate "default model" also exists).
- Language models for cleanup: not named ("our underlying Large Language Models", v0.9.0).
- Local models: none on desktop. iOS release 1.0.37 (2026-09-22) mentions "an incomplete offline model download" and "Interrupted model downloads now resume safely", implying some offline model on iPhone. See Gaps.
- Languages: 49, listed at https://aquavoice.com/guide/languages ; "Auto-Detect" switches between all of them (not available in Realtime Mode). App UI in English, German, Spanish, French, Japanese, Russian.
- Japanese: "33% fewer errors" (2026-10-06).
- Speed claims: "Text starts appearing in under 50ms, final text in about 450ms" (App Store); "up to 230 words per minute"; "5x faster than typing and twice as accurate". https://apps.apple.com/us/app/aqua-voice-ai-dictation/id6759074969 ; https://aquavoice.com
- Web Sandbox: try Aqua in a browser (English only) (v0.2.0).

### Live preview
- "Realtime Mode" (formerly "Streaming Mode"): "Your words appear in the toolbar as you speak, then resolve into clean, punctuated text a beat behind you." Text lands in the app when you finish. You can say "change Thursday to Friday" mid-dictation and "the live text updates before anything is sent". (Max/Business; Free trial within 1,000 words) https://aquavoice.com/realtime
- Desktop only (macOS, Windows): "The iPhone and Android apps insert your text when you finish."
- "Instant" mode (default when holding the key) shows no live words.

### Cleanup & formatting
- Avalon "correct[s] grammar, and preserve[s] every word while refining your text in real time"; removes "ums". https://aquavoice.com
- "Custom Instructions": free-text rules with good/bad examples, e.g. "Never use em-dashes", "Always use UK English", email line breaks, filler removal strictness; Aqua "will also remember the unique way you sign off your emails". (Pro) https://aquavoice.com/guide/custom-intructions
- "Casual Messaging" setting enforces lowercase in Slack, iMessage, Discord (v0.10.4). Slack @-mentions by voice.
- "Inline Text Normalization": casing and spacing matched to the cursor location (v0.10.0).
- Email detection: "Aqua can tell when you are writing an email and formats it like one." https://aquavoice.com/ios
- Self-correction mid-dictation: in Realtime Mode ("change Thursday to Friday"); for Instant mode not documented.
- "Deep Context" (off by default, every plan, macOS and Windows): "takes one screenshot as you start dictating", picks out names, terms and code, "doesn't keep the image"; found words saved with the session (redacted in Privacy Mode). Needs Screen & System Audio Recording permission on Mac. Business admins can force on/off. https://aquavoice.com/deep-context
- "File Tagging" (v0.10.0): spoken file names ("main dot t s") become `@main.ts` in Cursor and Windsurf; not Claude Code, Codex, Cline, VS Code AI sidebar, Antigravity. (free) https://aquavoice.com/guide/file-tagging
- Per-app modes or multiple prompts: none found (one set of Custom Instructions).

### Personalization
- "Custom Dictionary": add names, acronyms, made-up words; bulk-add (v0.14.21); "Expanded Custom Dictionary" on Pro (free limit not stated); dictionary words "recognized by how they sound" (2026-10-06). https://aquavoice.com/guide/dictionary
- "Replacements" (v0.10.8): spoken phrase → saved text (links, prompts, code templates); options "Preserve case", "Strip punctuation" (v0.11.9). https://aquavoice.com/guide/replacements
- "Team-wide Dictionaries" (Business).
- "Setting Sync": dictionary, custom instructions, language, Realtime Mode sync across devices (v0.6.0); keybindings do not.
- Auto-learning from edits: none found.
- Per-app rules: Casual Messaging only; Send It picks a send key per app.

### Output & editing
- Pastes at the cursor in any app; "Clipboard Preservation" restores your clipboard (v0.2.0); "Avoid Clipboard History" toggle (v0.7.0). https://aquavoice.com/changelog
- "History" tab (on device): audio kept 3 days, "Rerun Transcription", thumbs up/down, copy; "Undo AI Edit" returns the base transcript (v0.3.0); audio download. https://aquavoice.com/guide/history
- "Edit Mode" (v0.17.0, 2026-07-20): select text in any app, hold the usual Aqua key, say the change ("Translate to Japanese", "abbreviate", "Change 5pm to 6pm", "Delete that", spell a name); no separate hotkey; selections over 6,000 characters fall back to dictation; not in search fields or address bars. Every edit saved in History. (every plan) https://aquavoice.com/guide/edit-mode
- Undo: no spoken undo; use the app's own Undo.
- Edit before paste: Realtime Mode "Read it before it lands"; "Paste Only" send setting.

### Voice commands
- "Send it" (v0.18.0, 2026-07-26): ends a Realtime dictation and presses the app's send key; only counts as the last thing said; works in English, Japanese, Spanish, French, German, Russian. "Send Command" setting: Auto (Enter in Slack, ⌘/Ctrl+Enter in Gmail/Outlook, none in Notes/Word), Enter, Ctrl+Enter, ⌘+Enter, Paste Only. (Max) https://aquavoice.com/realtime
- Edit Mode spoken instructions on selected text.
- "new line"/"new paragraph": none documented.
- App control: none; accessibility page says "Aqua handles text entry and selected-text editing" only. https://aquavoice.com/dictation-accessibility

### Beyond dictation
- "Aqua MCP": remote MCP server at `https://api.aquavoice.com/mcp` with OAuth; agents (Claude Desktop/Code, ChatGPT, Cursor, Codex, VS Code, Windsurf, Zed) can search past dictations, give feedback, edit dictionary, instructions and settings, switch language. (every plan) https://aquavoice.com/mcp
- "Aqua CLI" (macOS, Windows, Linux): `aqua dict`, `aqua replacements`, `aqua instructions`, `aqua transcribe` (flac/m4a/mp3/mp4/ogg/wav/webm, ≤25 MB, <1 h; text/json/srt/vtt), `aqua setup claude|codex` installs a skill. https://aquavoice.com/docs/cli
- "Avalon API" (OpenAI-compatible) for developers. https://aquavoice.com/avalon-api ; https://aquavoice.com/docs/api
- File transcription: CLI/API only (paid per hour); not in the app UI.
- Translation: via Edit Mode ("Translate to Japanese").
- Meetings, notes, summaries: none found.
- "Aqua Wrapped" year summary (v0.11.0); stats card with WPM and time saved.

### Platforms & sync
- macOS: "One universal Mac download runs natively on both Apple Silicon and Intel Macs." Minimum macOS not stated (Homebrew cask lists none). https://aquavoice.com/mac
- Windows: supported (version requirements not found).
- iOS 17+, iPhone only ("Only for iPhone"), released 2026-04-05.
- Android 10+ phones and tablets, released 2026-10-06 (v0.1.0).
- Linux: CLI only.
- One subscription covers all four platforms; settings sync (see Personalization).

### Privacy & data
- No on-device mode on desktop (see Transcription engine).
- "Privacy Mode": "nothing is stored on our servers at all"; privacy policy: with Privacy Mode disabled, transcript data "may" be stored to improve the product; session metadata still collected. https://aquavoice.com ; https://aquavoice.com/privacy (effective 2026-07-29)
- History is "an on device record"; audio kept locally 3 days.
- Deep Context screenshot not kept; off by default.
- "Zero Data Retention" on Business; org-wide Privacy Mode on Team/Business.
- SOC 2 Type II (renewed annually), ISO 27001, "GDPR and HIPAA compliant"; contact them before using PHI to confirm plans and BAA. Trust Center via Vanta. https://aquavoice.com/guide/soc2
- Privacy policy describes ad attribution cookies (`aqua_aid`, gclid/fbclid) and mobile install attribution. iOS privacy label lists linked Usage and Advertising Data.

### Onboarding & permissions
- Mac: drag to Applications, grant Microphone and Accessibility; Deep Context asks for Screen & System Audio Recording during setup (optional). https://aquavoice.com/mac
- Setup "checks that your microphone and shortcut work before you start dictating"; guided Realtime examples; walks you through first dictation in another app (v0.19.3, 2026-08-25). Edit Mode has an in-app tour ("Try it").
- iOS: enable keyboard, Full Access, microphone; app opens to start a mic session.
- Account required (sign-in with Apple added v0.14.0).

### Accessibility
- "Dictation and accessibility" use-case page: hold, double-tap or mouse-button activation; Edit Mode for corrections; states pairing with Apple Voice Control, Microsoft voice access and screen readers "has not been verified". https://aquavoice.com/dictation-accessibility
- No VoiceOver support claims for the app itself.

### Distribution
- Direct download (Mac zip/DMG from updates.aquavoice.com; Windows installer). https://aquavoice.com/download
- Homebrew cask `aqua-voice` (v0.17.2, behind the current 0.21.4). https://formulae.brew.sh/cask/aqua-voice
- iOS App Store "Aqua Voice: AI Dictation", v1.0.38 (2026-10-01), 4.4 stars from 99 ratings. https://apps.apple.com/us/app/aqua-voice-ai-dictation/id6759074969
- Google Play (Android).
- Mac App Store, Setapp: not listed. Closed source.

## Recent changes (last 12 months)
Source: https://aquavoice.com/changelog

- 2025-10-31 v0.10.4: Casual Messaging (lowercase), Slack @-mentions, better on-screen names with Deep Context.
- 2025-11-13 v0.10.8: "Replacements".
- 2025-12-14 v0.11.0: "Aqua Wrapped"; faster mic start; fewer hallucinations.
- 2026-01-10 v0.11.5: create team and transfer Pro balance; monthly/annual switching.
- 2026-01-23 v0.11.6: better auto-detect; mute background audio on Windows.
- 2026-02-06 v0.11.9: Replacements "Preserve case" / "Strip punctuation".
- 2026-04-05: iOS app released (App Store date).
- 2026-04-13 v0.14.0: "Avalon 1.5" on desktop; better paragraph breaks; Sign in with Apple.
- 2026-06-01 v0.14.17: "Business Plan" (SSO, team dashboard, shared dictionary).
- 2026-06-03 v0.14.21: bulk-add dictionary terms.
- 2026-07-20 v0.17.0: "Edit Mode".
- 2026-07-26 v0.18.0: "Send It"; 2026-07-29 v0.18.5: "Send Command" choices.
- 2026-07-30 v0.18.6: mouse-button activation.
- 2026-08-25 v0.19.3: new setup flow with mic and shortcut checks.
- 2026-08-27 iOS 1.0.31: Action Button dictation.
- 2026-09-04 v0.19.12: microphone blacklist.
- 2026-09-14 v0.19.14: Windows mic startup 298 → 122 ms.
- 2026-09-22 v0.20.0: Liquid Glass floating bar; iOS 1.0.37 offline-model download fixes.
- 2026-10-06: Android app; Japanese 33% fewer errors.
- 2026-10-15 v0.21.0: "Aqua Pet"; 2026-10-17 v0.21.4 pet settings.
- Pricing restructured into Pro / Max with Realtime moved to Max (date not stated). https://aquavoice.com/realtime

## User reception

- Product Hunt 5.0/5 (16 reviews): "I've tried all the competitors, and this one works best by far." https://www.producthunt.com/products/aqua-voice/reviews
- Product Hunt complaints: "Maybe 70% - 80% percent of all transcriptions contain significant errors" (6 months ago); "it doesn't always respond to the shortcut"; "it requires network access on the back end". same link.
- App Store 4.4/5 from 99 ratings: "it works fantastic on my Mac and on my Windows machine." https://apps.apple.com/us/app/aqua-voice-ai-dictation/id6759074969
- Hacker News: "It gets everything, jargon, capitalization, everything." https://news.ycombinator.com/item?id=46889253
- Hacker News: "It can gather screen context so you just say the function name out loud and it capitalizes and spells everything correctly." https://news.ycombinator.com/item?id=47625191
- Hacker News: "Aqua voice does a good job of this with custom dictionary and replacements." https://news.ycombinator.com/item?id=47668181
- Hacker News: praised for "a decent injected technical vocabulary" that commercial tools offer. https://news.ycombinator.com/item?id=48971073
- Hacker News: wanted "to use my API key and store more context locally" (no bring-your-own key). https://news.ycombinator.com/item?id=44945190
- X posts on the vendor site praise "send it" and coding accuracy ("For coding prompting with voice nothing beats @aquavoice"), but they are curated by Aqua. https://aquavoice.com/realtime
- Reddit r/macapps: could not be fetched (blocked to this tool).

## Gaps (not verified)

- Default activation key on Mac and Windows.
- Size of the Free dictionary vs "Expanded Custom Dictionary".
- Whether iPhone has an offline model (changelog mentions "offline model download"; Mac page says "there is no offline mode").
- Minimum macOS and Windows versions.
- Which LLM does cleanup and Custom Instructions.
- Spoken line-break and punctuation commands.
- Business seat threshold for sales (pricing card says 20+ users, FAQ says 100+ seats).
- Whether self-correction ("no wait") is handled in Instant mode.
- Reddit threads (blocked).
