# Wispr Flow

- Vendor: Wispr AI, Inc.
- Platforms: macOS, Windows, iOS (iPhone only), Android. No Linux, no iPad.
- URL: https://wisprflow.ai
- Help centre: https://docs.wisprflow.ai (8 collections, about 170 articles)
- Date checked: 2026-10-23
- Placement: **full-suite**. Cloud-only dictation with AI cleanup, per-app styles, voice editing of selected text ("Command Mode"), rewrite shortcuts ("Transforms"), a notes editor ("Scratchpad"), a meeting recorder ("Notetaker"), an MCP server (a standard way for AI chat apps such as Claude and ChatGPT to read Flow's data), team admin, SSO and HIPAA, on four platforms.

## Pricing

Source: https://wisprflow.ai/pricing and https://docs.wisprflow.ai/articles/9559327591-flow-plans-and-what-s-included (both checked 2026-10-23). US dollars; 24 currencies have their own fixed prices.

| Tier | Monthly billing | Annual billing | Notes |
|---|---|---|---|
| Free | $0 | $0 | Weekly word limit (below). No card needed. |
| Pro | $15/user/mo | $144/user/yr ($12/mo) | "Unlimited dictations". Individuals and teams, no seat minimum. |
| Growth, Dictation only | $23/user/mo | $216/user/yr ($18/mo) | Adds SAML SSO, HIPAA BAA, admin controls. Self-serve since 2026-08-28. |
| Growth with Notetaker | $33/user/mo | $312/user/yr ($26/mo) | Adds Notetaker, "Ask Wispr" about meetings, MCP. (Pricing page shows $33/$26 struck through next to $23/$18, which is confusing.) |
| Enterprise | Custom | Annual only | SCIM, MDM, audit logs, domain capture, training always off, invoicing. |

iOS in-app purchases (App Store, checked 2026-10-23): Pro Weekly $4.49, Pro Monthly $15.00, Pro Annual $143.99, Monthly Student $7.49, Annual Student $72.00. https://apps.apple.com/us/app/wispr-flow-ai-voice-keyboard/id6497229487

Free tier limits (https://docs.wisprflow.ai/articles/4760791189-free-tier-weekly-word-cap-and-bonus-words-remove-desktop-trial-experiment):
- Mac and Windows: notice at 2,000 words/week; new dictations blocked only above 5,000 words/week.
- iOS: slows after about 550 words, blocked at 750.
- Android: slows after about 1,000 words, blocked at 1,500. Mobile platforms share one pooled count.
- Weekly window, resets Sunday 23:45 UTC (some in-app text says "Sunday 12 a.m. PT"; the help article says that wording is wrong). Unused words do not carry over. Notetaker meetings do not count.
- "Allowances vary by account and can change without an app update."
- Free tier on pricing page also includes "Limited Notetaker access" (weekly meeting cap; recordings under 5 minutes don't count).

Trials: 14 days standard, 30 days via referral, 90 days for students, 14-day team trial for every invited teammate. 3-day grace period after a trial. Desktop trials can earn up to 7 extra days by dictating 100 words a day during a 7-day challenge.

Education and non-profit: pricing page says "Flow is free for students" and education emails get "50% off Pro"; non-profits get "a discounted rate" (no figure). Student plan needs a recognised .edu address. Promotions: CRED (10 months Pro free), Zepto (3 months Pro free).

Lifetime licence: none found. Bring-your-own API key: none found.

## Feature inventory

### Trigger & capture
- "Push to talk (hold to dictate)": Mac default Fn; Windows default Ctrl+Win (new setups may start on Caps Lock). (free) https://docs.wisprflow.ai/articles/2612050838-supported-unsupported-keyboard-hotkey-shortcuts
- "Hands-free (press to start/stop)": Mac Fn+Space (Ctrl+Opt+Space without Fn), Windows Ctrl+Win+Space. Double-tapping push-to-talk within 0.5 s also starts hands-free. Clicking the Flow Bar also starts it. (free) https://docs.wisprflow.ai/articles/6391241694-use-flow-hands-free
- Session length: desktop warns at 19 minutes and stops at 20 ("20-Minute Dictations", shipped 2026-03-31); Android stops at 5 minutes. (free) same source; https://docs.wisprflow.ai/articles/4841123325-longer-dictation-sessions-now-up-to-20-minutes
- Configurable keys: up to 3-key combos that must include a modifier; up to 4 shortcuts per action; Caps Lock allowed alone for push-to-talk / hands-free; single letters rejected; some system combos blocked. (free) hotkey article above.
- Mouse buttons as triggers ("Mouse Flow", 2026-03-31): Middle Click, Mouse 4/5, Aux buttons, Logitech MX; Mouse 6–10 Mac only; not left/right click, not Magic Mouse or trackpad. Mouse-only "Press Enter" action. (free) hotkey article; https://wisprflow.ai/whats-new
- Cancel: Escape. Paste last transcript: Cmd+Ctrl+V (Mac), Shift+Alt+Z (Windows). Copy last transcript: Cmd+Ctrl+C / Shift+Alt+X. (free) hotkey article.
- Menu bar icon (Mac) / system tray (Windows), plus the floating "Flow Bar". https://docs.wisprflow.ai/articles/3152211871-setup-guide
- "Flow Bar": floating indicator showing resting / recording / processing; follows the display your cursor is on; avoids the Dock and menu bar; "Hide for 1 hour"; "Show Flow Bar at all times" toggle; "Put the Flow Bar wherever works best for you" (2026-07-09). https://docs.wisprflow.ai/articles/1790396454-move-and-dock-the-flow-bar-on-desktop ; "Snooze the Dictation Bubble" https://docs.wisprflow.ai/articles/3400534884-snooze-the-dictation-bubble
- Mic selection: choose input in setup and settings; "Let Flow pick the right microphone automatically" (Desktop v1.5.751, 2026-06-24); "Dictate Through Any Mic, Including Virtual Ones" such as Krisp, NVIDIA Broadcast, BlackHole (v1.6.580, 2026-08-21); "Keep dictating when you dock your laptop (clamshell mode)". https://docs.wisprflow.ai/articles/8884408990-connect-and-set-up-external-audio-devices ; https://wisprflow.ai/whats-new
- System audio handling: "Mute all audio while dictating" (Settings → System → Sound; off by default on Mac, on by default on Windows) mutes the whole output device; "Pause music while dictating" (Settings → Experimental, needs subscription or trial) pauses media instead. Desktop only. https://docs.wisprflow.ai/articles/7231650589-auto-mute-music-while-dictating-on-macos-how-audio-detection-works
- "Whisper": dictate quietly in shared spaces. (free) https://wisprflow.ai/features
- No-sound warning: "Flow warns you when your mic picks up no sound" (2026-10-19). https://wisprflow.ai/whats-new
- Push-to-talk from other devices: none found (looked in hotkey and hands-free articles).
- Android: floating "Flow Bubble" over text fields instead of a keyboard; adjustable bubble opacity; shake gesture. iOS: a third-party keyboard ("Flow Keyboard") with a mic button; no hotkeys or hands-free. https://docs.wisprflow.ai/articles/6391241694-use-flow-hands-free ; https://wisprflow.ai/whats-new

### Transcription engine
- Cloud only. "Wispr Flow processes dictated audio in the cloud to turn speech into text." Data processed and stored in the US. https://docs.wisprflow.ai/articles/3467817258-security-and-compliance-faq
- "Canto": "the first speech model Wispr built in-house", rolled out to everyone 2026-09-17. Vendor claims noisy-environment errors fell from about 30% to 5–10% (secondary report of the launch post). https://wisprflow.ai/whats-new ; https://benchlm.ai/voice-benchmarks/wispr-canto-launch-evaluation
- Provider redundancy added 2026-06-04 "so a single provider outage doesn't take Flow down", implying several third-party speech/AI providers behind it; none named. https://releases.sh/release/rel_wl_vQDF65hOMzd51cVTqQ-provider-redundancy-added-auto-cleanup-rollback-in-testing
- Local models: none.
- Languages: "100+ languages". Auto-detect on Mac, Windows, iOS (not Android); picks one language per dictation, not per word. Regional variants include British and Canadian English, Swiss German, Simplified/Traditional Chinese, Cantonese, Hinglish. Urdu, Hebrew, Ukrainian need to be selected alone. https://docs.wisprflow.ai/articles/3191899797-use-flow-with-multiple-languages
- Language switching UI: Settings → General → Languages. "Language Picker in the Flow Bar" shipped 2026-03-31 per changelog, but the languages help article says the Flow Bar has no language picker (conflict, see Gaps). "Speaking a different language?" prompt and "Flow offers to add a language you speak" (2026-09-28, 2026-10-19).
- Model switching UI: none found; users cannot pick a model.
- Speed claims: "4× faster than typing" / "Talk 4x faster" (typing comparison, not latency). https://wisprflow.ai/features . A Baseten case study reports under 700 ms p99 end-to-end. https://www.baseten.co/resources/customers/wispr-flow/

### Live preview
- Flow Bar shows only state (resting, recording, processing); the help article does not describe live words. https://docs.wisprflow.ai/articles/1790396454-move-and-dock-the-flow-bar-on-desktop
- Product Hunt reviewer (2 months ago): "Would love to see streaming output". https://www.producthunt.com/products/wisprflow/reviews
- iOS v1.62 (2026-06-17) added "Always-On Live Dictation Timer" (a timer, not words).
- Notetaker has "The live transcript in Notetaker" for meetings. https://docs.wisprflow.ai/articles/4091106439-the-live-transcript-in-notetaker-beta
- No evidence of live words for dictation. Text appears after release.

### Cleanup & formatting
- "Auto Cleanup" levels (Mac, Windows; Beta; shipped 2026-04-24): "None" (raw transcript), "Light" (default: removes filler words, fixes grammar), "Medium" (may reword for clarity and brevity). "High" removed; users on it now see Medium. https://docs.wisprflow.ai/articles/4283510616-auto-cleanup-control-how-much-flow-edits-your-dictation-beta
- "Smart Formatting": filler words, grammar, punctuation, capitalization; on by default; Android always on. https://docs.wisprflow.ai/articles/5373093536-how-do-i-use-smart-formatting-and-backtrack
- "Backtrack": removes self-corrections. "Let's do coffee at 2 actually 3" becomes "Let's do coffee at 3." Cue words "actually", "scratch that", "never mind" help. (free) same source.
- "Remove fillers", "Auto punctuation" (from pauses and tone), spoken punctuation ("comma", "question mark", "em dash", etc.). https://wisprflow.ai/features
- "Numbered lists": "one… two…" or "first… second…" becomes a list. same sources.
- "Flow Styles" per app category (Personal messaging, Work messaging, Email, Other): "Formal.", "Casual", "very casual" (Personal only), "Excited!". Email category adds greetings, sign-offs and line breaks. English only. Launched 2025-10-29 (desktop, as "Personalized Styles"), now on all four platforms. https://docs.wisprflow.ai/articles/2368263928-how-to-setup-flow-styles
- "Context Awareness" (on by default, Mac/Windows; limited on iOS): reads text before/after/selected at the cursor, on-screen text such as email recipients, app name and website, file and variable names in code editors, and conversation history in messaging apps. "works from text and does not take screenshots." Used for name spelling, matching casing and punctuation, picking the Style, tagging files. Password, numeric and banking fields excluded. Toggle in Settings → Data and Privacy; Enterprise admins can force off. With it off, the app name and website domain are still sent. https://docs.wisprflow.ai/articles/4678293671-feature-context-awareness
- Developer features: "File tagging" (spoken file names become tagged files in Cursor and Windsurf), "Syntax awareness" (keeps camelCase, snake_case, CLI commands), "Dev jargon". https://wisprflow.ai/features ; https://docs.wisprflow.ai/articles/6434410694-use-flow-with-cursor-vs-code-and-other-ides
- "Transforms" (Beta, Mac/Windows/iOS; desktop shipped 2026-05-01): rewrite selected text with a shortcut. Built-in "Polish" (Opt+1), "Prompt Engineer" (Opt+2, turns rambling into an AI prompt), "View Diff" (Opt+O). Up to 8 custom prompts, each with its own shortcut and up to 5 writing samples of 50–500 words. "Auto Apply After Dictation" runs a chosen transform before paste. 1–3,000 words. Plan gating not stated. https://docs.wisprflow.ai/articles/8068950331-how-to-use-transforms-beta
- Capitalization control article: https://docs.wisprflow.ai/articles/4518230910-why-flow-capitalizes-words-mid-sentence-and-how-to-control-it

### Personalization
- "Dictionary": manual entries; "auto-learn words" adds words you correct after paste (Mac/Windows only). "Correct a misspelling" turns an entry into a replacement (wrong spelling → right spelling). 60-character cap. Bulk import up to 1,000 items / 3 MB. Syncs across devices. (free) https://docs.wisprflow.ai/articles/4052411709-teach-flow-your-words-with-the-dictionary ; https://docs.wisprflow.ai/articles/8955301725-how-do-i-bulk-import-for-dictionary-and-snippets
- "Snippets": spoken trigger phrase (up to 60 chars) inserts saved text (desktop up to 4,000 chars). Rich text (bold, italic, lists, links) since v1.6.288 (2026-07-29). No dynamic variables such as dates. Longest matching trigger wins. Personal snippets on every plan. https://docs.wisprflow.ai/articles/5784437944-create-and-use-snippets
- "Shared dictionary and snippets" for teams (Pro); org-wide and department-wide dictionary words (2026-09-04). Admins can turn Dictionary or Snippets off. https://wisprflow.ai/pricing
- "Spells names right" from context. https://wisprflow.ai/features
- "Voice Profile": an "Insights" report unlocked at 2,000 desktop words, updated at milestones up to 662,000 words. Described as a report; no claim it changes accuracy. https://docs.wisprflow.ai/articles/7470830521-voice-profile-updates-when-the-update-your-voice-profile-notification-appears
- Per-app rules: only the four Style categories; no per-app custom prompt found.

### Output & editing
- Pastes into the focused text field in any app. Fix-it article: https://docs.wisprflow.ai/articles/7971211038-fix-text-not-pasting-after-dictation
- "Paste last transcript" and "Copy last transcript" shortcuts (copy is plain text). https://docs.wisprflow.ai/articles/2503460374-retry-failed-transcriptions
- Undo: Cmd+Z right after paste; "Undo AI edit" in the Home tab restores the raw transcript (audio kept 14 days). https://docs.wisprflow.ai/articles/4283510616-auto-cleanup-control-how-much-flow-edits-your-dictation-beta
- History in the Home tab; "Audio Playback in Dictation History" for 14 days (v1.6.399, 2026-08-05). History search: not described.
- "Retry" and "Recover" for failed transcriptions; audio kept 14 days; "Recover dictations after quitting" (2026-05-01); iOS "One-Tap Retry for Failed Transcripts" (2026-06-17). https://docs.wisprflow.ai/articles/2503460374-retry-failed-transcriptions
- Edit before paste: none found for normal dictation (Scratchpad is the place to draft).
- Remote desktops, terminals, notification reply boxes and browser address bars have their own articles. https://docs.wisprflow.ai/articles/7336156466-use-flow-with-remote-desktops-citrix-rdp-vdi ; https://docs.wisprflow.ai/articles/6478598909-using-flow-with-linux-wsl-and-terminal-applications

### Voice commands
- Spoken "new line", "next line", "line break", "skip a line", "new paragraph", "start a new paragraph"; spoken punctuation names. Work even with Smart Formatting off. https://docs.wisprflow.ai/articles/5373093536-how-do-i-use-smart-formatting-and-backtrack
- "Command Mode" (Mac/Windows; off by default, enable in Settings → Experimental; hold Fn+Ctrl): speak an instruction to edit the selected text or text box, draft replies, search the web (opens Perplexity), or "build apps" (opens in browser). Spoken trigger phrases English only. Paid only: free accounts get "only available on Flow Pro". (Pro) https://docs.wisprflow.ai/articles/4816967992-how-to-use-command-mode
- App control (open apps, click, etc.): none found.

### Beyond dictation
- "Scratchpad" (Beta, Mac/Windows; 2026-05-01): tabbed rich-text notes editor, Opt+S, up to 5 tabs per window, images, pinning, search, version history, syncs with iPhone notes. https://docs.wisprflow.ai/articles/9618237082-using-the-scratchpad-to-save-and-edit-notes
- iOS "Quick capture notes" / "Quick Dictation to Notes shortcut" (iOS v1.52). App Store listing.
- "Wispr Flow Notetaker" (Mac 2026-08-05, Windows 2026-09-15): records mic and system audio, speaker names, live transcript, "Flow Summaries" with action items, pre-meeting briefs, calendar (Google, Outlook), "Ask Wispr" chat about meetings, sharing notes, offline recording, recording-consent notice, 21 meeting languages, import from Otter and Granola. Limited on Free, higher limits on Pro, unlimited on Growth with Notetaker. Meeting audio deleted 7 days after upload. https://docs.wisprflow.ai/collections/8559995472-wispr_notetaker
- MCP server: "Connect Claude, ChatGPT or another MCP client to Wispr Flow"; one-click Gemini setup (2026-09-15). (free per pricing page: "Use your meeting notes in Claude and ChatGPT") https://docs.wisprflow.ai/articles/9551372685-connect-an-mcp-client-to-wispr-flow-remote-mcp-server
- "Insights": "Your Usage", "Your Voice", "Leaderboard" (v1.5.55, 2026-04-24). https://docs.wisprflow.ai/articles/8760230576-your-usage-tab-track-your-dictation-stats-in-wispr-flow
- File transcription: **no**. "can't upload, attach, or import an existing audio or video file for transcription on any platform or plan." https://docs.wisprflow.ai/articles/7689167034-can-i-upload-audio-files-to-wispr-flow-for-transcription
- Translation: iOS notes that "Translate to English" is unavailable in iOS Transforms, implying a desktop Polish instruction for it; no standalone translation feature found.

### Platforms & sync
- macOS 12 Monterey or later, Apple Silicon and Intel, 8 GB RAM recommended, about 500 MB disk. https://docs.wisprflow.ai/articles/1036674442-supported-devices-and-system-requirements
- Windows 10/11 x64 only (no ARM / Snapdragon). Notetaker on Windows needs 16 GB RAM.
- iOS 18.3+, iPhone only, no iPad. App Store also lists visionOS 2.3+.
- Android 13+ (launched 2026-02-23). https://wisprflow.featurebase.app/changelog
- Linux: not supported (Linux, WSL and terminal article covers using it from Windows/Mac).
- Sync: dictionary, snippets, styles, Scratchpad sync across devices. Transcripts and audio do not sync between devices. https://docs.wisprflow.ai/articles/5284722493-sync-flow-across-your-devices
- Desktop app is Electron according to reviewers (see reception). Hub localised into four more languages (2026-06-10). Dark Mode for desktop (2026-10-19).

### Privacy & data
- No on-device mode; all transcription in the cloud. https://wisprflow.ai/data-controls
- "Improve the model for everyone" (formerly "Privacy Mode"): on by default for Free and Pro, can be turned off; off and locked for Enterprise; off for Growth and Enterprise since 2026-10-02. Reported transcripts can still be used for training. https://docs.wisprflow.ai/articles/9609615338-private-cloud-sync-and-data-sharing-preferences-in-wispr-flow
- "Dictation Cloud Storage": stores transcripts, audio and history on Wispr servers; on by default; storage options include "Delete after 24 hours" and "Never store" (from Voice Profile article). "Control how your transcripts are stored" shipped 2026-04-24.
- Usage statistics (word counts, app, duration) always collected.
- "zero data retention agreements with all third-party AI providers used in Flow Dictation." https://wisprflow.ai/data-controls
- Encryption in transit and at rest; not end-to-end; Wispr holds keys. SOC 2 Type II and ISO/IEC 27001:2022 (dictation only, not Notetaker). HIPAA with signed BAA (all tiers per pricing table; org-wide enforcement on Growth); a BAA disables Notetaker and Scratchpad. https://docs.wisprflow.ai/articles/3467817258-security-and-compliance-faq ; https://docs.wisprflow.ai/articles/4218718535-hipaa-compliance-healthcare-use
- Trust Center: https://trust.wispr.ai/
- iOS App Store privacy label: "Data used to track you: Identifiers; Usage Data"; linked data includes email, name, user ID, device ID, product interaction, advertising data, crash and performance data.

### Onboarding & permissions
- Mac order: sign in via browser (required) → Microphone → Accessibility → setup questions and privacy notice → mic test → set shortcut → languages → practice demos (skippable) → data preference → Flow Hub. Windows needs only Microphone. https://docs.wisprflow.ai/articles/3152211871-setup-guide
- iOS: enable keyboard and "Allow Full Access" in Settings, then microphone on practice cards; "Try Flow in your apps" post-onboarding. https://docs.wisprflow.ai/articles/7523910584-try-flow-in-your-apps-ios-post-onboarding-experience
- Android: display over other apps, consent, Accessibility (required to insert text), mic when needed.
- "Re-verify Wispr Flow permissions after updating" troubleshooting article: https://docs.wisprflow.ai/articles/5510622673-re-verify-wispr-flow-permissions-after-updating
- "Product-aware onboarding: choosing dictation, Notetaker, or both (macOS)"; "Guided product tours" for team features.
- Sign-in required on every platform.

### Accessibility
- "Keyboard navigation and screen reader accessibility" article: tested with VoiceOver (Mac, iOS), NVDA and JAWS (Windows), TalkBack (Android). Tab navigation, Option+↑/↓ between pages, j/k in history. Follows Reduce Motion. Lists known gaps: some unlabeled icon buttons, Flow Bar menu not keyboard-reachable, hover-only tooltips, dictionary sort needs a mouse. https://docs.wisprflow.ai/articles/3941699399-keyboard-and-screen-reader-accessibility-in-wispr-flow
- macOS Voice Control: not mentioned.

### Distribution
- Direct download (DMG from dl.wisprflow.com). https://wisprflow.ai
- Homebrew cask `wispr-flow` (v1.6.1209, needs macOS 12+). https://formulae.brew.sh/cask/wispr-flow
- iOS App Store: "Wispr Flow: AI Voice Keyboard", v1.78 (2026-10-19), 4.8 stars from 17,863 ratings, 191 MB. https://apps.apple.com/us/app/wispr-flow-ai-voice-keyboard/id6497229487
- Google Play (Android); Microsoft Store mentioned by a reviewer.
- Mac App Store: not listed (App Store search for Mac returned other apps). Setapp: none found.
- Closed source. MDM deployment and auto-update policy ("UpdateFrequency") for Enterprise. https://docs.wisprflow.ai/articles/9967754953-configure-auto-update-policy-via-mdm-updatefrequency

## Help centre article inventory (titles as listed, 2026-10-23)

Getting Started (17 of 40 listed; the macOS, Windows, iOS, Android subsections did not expand): Set up Wispr Flow for your first dictation; Supported devices and system requirements; Starting your first dictation; Use Flow hands-free; Set up SCIM user provisioning in Wispr Flow; Configure SSO; Connect and choose a microphone for Flow; Sign up for Flow Enterprise; Team plans, trials and seat billing; What is Wispr Flow?; Team Consolidation and Team-Aware Onboarding in Wispr Flow; Sign up for Flow Growth; Assign members to teams and departments; Teammates Added daily digest email for Enterprise admins; Partnership and creator collaboration inquiries; Add organization domains and finish SSO setup; Configure auto-update policy via MDM (UpdateFrequency).

Using Wispr Flow (31): Use Flow with multiple languages; Sync Flow across your devices; Dictate emails in Microsoft Outlook; Use Flow with Cursor, VS Code, and other IDEs; Use Flow with remote desktops; Create and use snippets; Teach Flow your words with the dictionary; How to setup Flow Styles; How do I use Smart Formatting & Backtrack; How to Set Up Flow Shortcuts for iPhone; Using Flow with Linux, WSL, and Terminal Applications; Snooze the Dictation Bubble; Use and organize notes in Scratchpad; How to use Command Mode; Navigating the Wispr Flow App: Desktop, iOS, and Android; Keyboard navigation and screen reader accessibility; Customize notification preferences; Rewrite text with Transforms and custom prompts; Move and Dock the Flow Bar on Desktop; Add Wispr Flow to your LinkedIn profile; Open a shared Wispr Flow note; Your Usage tab: Track your dictation stats in Wispr Flow; Email preferences and marketing opt-out; Can I upload audio files to Wispr Flow for transcription?; View dictionary words and snippets in the Flow desktop app; Why Flow capitalizes words mid-sentence, and how to control it; Connect Claude, ChatGPT or another MCP client to Wispr Flow; Auto Cleanup: control how much Flow edits your dictation; Dictating in Notification Reply Boxes and Browser Address Bars; Longer dictation sessions — now up to 20 minutes; Guided product tours in Wispr Flow (Team Features Intro).

Transcription Accuracy & Voice Quality (6): Transcription suddenly got worse or feels less accurate; How Do I Bulk Import Dictionary Items and Snippets?; Using Wispr Flow Discreetly: Microphone Guide; Flow is transcribing in the wrong language; What to expect from Flow: accuracy and known limitations; Voice Profile updates: when the 'Update your Voice Profile' notification appears.

Billing & Plans (14): Flow plans and what's included; Request a Flow discount or fix student pricing; Manage your Flow account; Manage users and billing in the Admin Portal; Review team insights and export usage; VAT, GST & tax on Wispr Flow invoices; What happens if my Wispr Flow payment fails; Trial End Value Summary in Wispr Flow; How to leave a team or enterprise, and what happens to your Flow Pro; Free tier weekly dictation limit; Manage billing, invoices and cancellation; CRED Promotion: 10 months of Flow Pro free; Manage Cost Centers in Flow Enterprise; Zepto Promotion: 3 months of Flow Pro free.

Troubleshooting (31): Fix slow or failed transcription; Fix text not pasting after dictation; What to do if the app doesn't start up after signing in and clicking "Open Wispr Flow"; Re-verify Wispr Flow permissions after updating; Uninstall Flow and remove local data; Login Issues with Wispr Flow; Quit and relaunch Wispr Flow; Reset and restart the Wispr Flow app; Delete transcripts and history in Wispr Flow; Fix a microphone that is silent or unavailable; Troubleshooting audio playback & AirPod issues (iOS, macOS); Contact support, share feedback or report a transcript; Troubleshooting Guide for Snippets Pasting Only Part of the Text or Code; Reset your password or replace an expired setup link; Troubleshooting the Flow Bar (Desktop) and Flow Bubble (Android); Customize keyboard and mouse shortcuts; Fix Flow startup and No Model Available errors; How to Fix Accidentally Using Your Password as Your Name; Find Your Hide My Email Addresses on iPhone; Refer friends and earn Flow Pro credit; Using Wispr Flow on Android Work Profiles; Fix Logitech MX Master (Logi Options+) mouse buttons not working as a Flow shortcut; Fix Flow shortcuts blocked by macOS Secure Keyboard Entry / Secure Event Input; Fix silent dictation with a Focusrite audio interface; Why Wispr Flow doesn't pause background audio on iPhone (iOS); Play back your recordings from History on iOS; Switch between the 123 and ABC layouts in the Wispr iOS keyboard; Turn off or remove the Flow keyboard on iPhone; Auto-mute music while dictating on macOS: how audio detection works; Email & Sign-In Method Change Requests; Retry and recover a failed transcription.

Privacy, Security & Data (11): Context Awareness; HIPAA Compliance & Healthcare Use; Security and privacy overview; Manage data sharing, cloud storage and local history; Requesting a Data Processing Addendum (DPA); How to Revoke a HIPAA/BAA Agreement; Restrict org-wide snippet and dictionary sharing (snippet sharing policy); Audit Logs for Enterprise admins: Track team membership and join request activity; Configure your network for Wispr Flow; Vendor security assessments, questionnaires, and security calls; Data requests: get a copy of your data or ask us to delete it.

Known Issues (12): Captcha issues blocking login, downloads, or subscriptions; Fix connection and network errors; Missing first words in transcriptions; Weekly Word Limit Not Resetting Troubleshooting Guide; Switching accounts on Android; Fake Android Apps Impersonating Wispr Flow; Redirect loops when attempting to download the app from the Wispr Flow website; Why Does Google Play Keep Asking About Wispr Flow Permissions?; iOS: Missing audio chunks during unstable internet; Flow fails to detect text fields or inserts incorrectly on non-QWERTY keyboard layouts; Service status alerts: incident banners and slow-dictation notifications; Wispr Flow website loads but sign-in and downloads fail in one browser.

Wispr Notetaker (25): Getting started with Notetaker; Recording a meeting with Notetaker; Connect a calendar and use Notetaker reminders; The live transcript in Notetaker; Dictating during a meeting with Notetaker; Meeting notes and the editor in Notetaker; Flow Summaries in Notetaker; The Notetaker hub: your meetings in one place; Troubleshooting Notetaker transcripts, summaries, and the hub; Troubleshooting Notetaker recording and audio; Control how long Notetaker keeps your meeting data; Ask Wispr about your meetings and shared notes; Sharing meeting notes from Notetaker; Notetaker settings, explained; Switching to Wispr Flow: Keep All Your Notetakers in One Place (MCP); Notetaker for Enterprise: FAQ; Product-aware onboarding: choosing dictation, Notetaker, or both (macOS); Enabling Notetaker for your organization (Enterprise admins); Connectors in Wispr Flow: connect, disconnect, and organization-blocked connectors; Offline meeting recording in Notetaker; The meeting recording-consent notice: how it's posted and how admins control it; Use Notetaker with multiple languages; Notetaker: privacy and security overview; Import past meetings from Granola or Otter; Restricting Notetaker by domain: the Blocked domains setting.

## Recent changes (last 12 months)

Sources: https://wisprflow.ai/whats-new (2026-03-31 onward), https://wisprflow.featurebase.app/changelog (older), https://releases.sh/wispr-flow/releases

- 2025-10-29: "Personalized Styles" per app category (desktop).
- 2025-11-07: Flow Pro for teams, 14-day trial per teammate, no seat minimum.
- 2026-02-23: Android launch (floating bubble; dictionary, snippets, styles came later).
- 2026-03-31: Desktop v1.4.661: "Language Picker in the Flow Bar", "20-Minute Dictations", "Mouse Flow", dictionary upgrades, HIPAA BAA access. Android v1.4.1: custom dictionary, context-aware dictation, banking-app privacy protection.
- 2026-04-24: Desktop v1.5.55: "Insights" (Your Usage, Your Voice, Leaderboard), "Auto Cleanup levels", transcript storage controls. Android copy button, bubble opacity. iOS "Quick Dictation to Notes shortcut".
- 2026-05-01: Desktop v1.5.113: "Scratchpad (Beta)", "Transforms (Beta)", dictating into AI coding terminals, recover dictations after quitting, status page link. iOS Scratchpad sync.
- 2026-06-04 to 06-17: reliability statements ("Flow has been less reliable than it should be"), provider redundancy, Desktop v1.5.891 reliability release, updated data controls. iOS v1.62: "Never Lose a Dictation Again", "One-Tap Retry", "Always-On Live Dictation Timer".
- 2026-06-24: Desktop v1.5.751: automatic mic choice, clamshell mode; "More consistent and accurate formatting".
- 2026-07-09: movable Flow Bar, Canadian English.
- 2026-07-29: v1.6.288: rich-text Snippets, Pro team leaderboard.
- 2026-08-05: Notetaker on Mac; v1.6.399 audio playback in dictation history.
- 2026-08-21: v1.6.580 virtual mics, simpler hands-free.
- 2026-08-28: self-serve Growth plans, org-wide Notetaker controls.
- 2026-09-04: v1.6.721 Otter import, org/department dictionary, updates wait until idle.
- 2026-09-15: Notetaker on Windows, 21 meeting languages, Outlook calendar, Gemini MCP.
- 2026-09-17: "Canto" in-house speech model for everyone.
- 2026-10-02: model training off for Growth and Enterprise; audit log additions.
- 2026-10-19: desktop Dark Mode, no-sound mic warning, speaker detection in Teams/Meet, @-mentions in notes.
- Funding: reported $280M raise (secondary). https://letsdatascience.com/news/wispr-raises-280m-for-ai-dictation-platform-93e5f800

## User reception

- App Store: 4.8 stars from 17,863 ratings (iTunes lookup, 2026-10-23). Praise: "Greatest dictation app so far invented." Complaint from the same page: "I absolutely will not pay a yearly fee of $150 or $15 per month". https://apps.apple.com/us/app/wispr-flow-ai-voice-keyboard/id6497229487
- App Store review: "iPad Users Should Skip" (no iPad app). same link.
- Product Hunt 4.7/5 (81 reviews). Praise: "Flow just… appears wherever I'm typing." Complaint: "it's electron based and uses 800 megabytes of RAM". https://www.producthunt.com/products/wisprflow/reviews
- Product Hunt: "A more explicit offline or privacy-first mode would make it easier to recommend" and "Would love to see streaming output". same link.
- Hacker News: "Wisprflow is magical ime" https://news.ycombinator.com/item?id=50044186 ; "accurate, the dx was top notch" https://news.ycombinator.com/item?id=50052237
- Hacker News: "wisprflow has been degraded recently" https://news.ycombinator.com/item?id=50046242 ; one user found "WisprFlow the least accurate of the 4" (vs Superwhisper, Spokenly, Fieldwork) https://news.ycombinator.com/item?id=49747122
- Hacker News: "a bit pricey for my taste" https://news.ycombinator.com/item?id=50051742 ; a flood of free local "Wispr Flow clones" posted in Oct 2026 (e.g. https://news.ycombinator.com/item?id=50047390).
- Hacker News: complaint that dictation apps "opt you into Context awareness, which means your entire page contents get s[ent]" https://news.ycombinator.com/item?id=48531184
- Vendor admitted reliability problems in June–July 2026 status posts. https://wisprflow.ai/whats-new
- Reddit r/macapps: could not be fetched (blocked to this tool).

## Gaps (not verified)

- Whether dictation shows live words while speaking. Evidence points to no (Flow Bar shows state only; a reviewer asks for "streaming output"), but no vendor page says so outright.
- Flow Bar language picker: changelog (2026-03-31) says it shipped; the languages help article says the Flow Bar has no language picker.
- Which third-party speech or AI providers are used alongside Canto; Canto's latency.
- Which plans include Transforms, Auto Cleanup and Styles (articles silent; only Command Mode and "Pause music" are stated as paid).
- History search on desktop.
- A reported May 2026 incident where Context Awareness sent screenshots and a user was banned comes only from competitor-written blogs (https://vocai.net/blog/wispr-flow-review-privacy-2026/ , https://www.getvoibe.com/resources/wispr-flow-review/). Not confirmed from a primary source; current docs say "does not take screenshots".
- The 17 Getting Started articles in the platform subsections (macOS, Windows, iOS, Android) were not listed.
- Electron and 800 MB RAM come from reviewers, not the vendor.
- Whether Pro pricing differs outside the US beyond "24 currencies".
- Reddit threads (blocked).
