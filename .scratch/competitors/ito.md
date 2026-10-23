# Ito ("Hey Ito", Ito AI)

- Vendor: Ito Inc. (formerly Demox Labs team; HN launch post by co-founder and CTO "Evan")
- Platforms when active: macOS 10.15+ and Windows 10+ (Electron app with Rust helpers)
- URL: https://ito.ai (now a different product), source was https://github.com/heyito/ito
- Status: discontinued. The repository README was retitled "[DEPRECATED] - This project is no longer maintained" between 2026-01-09 and 2026-02-20 (Wayback snapshots), and the repo now returns 404 on GitHub. By 2026-01-17 ito.ai advertised "Automated QA for High-Velocity Teams"; today it sells "Runtime Code Review That Runs Your App on Every PR". AlternativeTo: "The project is no longer developed since January 2026."
- GitHub (last seen): 558–559 stars, GPL-3.0, last release v0.15.35, 478 commits, last commit date shown 2025-11-24. (Wayback 2026-02-20 and 2026-03-12 snapshots of https://github.com/heyito/ito)
- Date checked: 2026-10-23
- Placement: was low-mid, now dead. It was "hold Fn, talk, paste" plus cloud AI cleanup, an AI "Intelligent Mode", notes and a dictionary, but it was cloud-first with a sign-in, not a local minimal tool.

Sources used: archived repo README (http://web.archive.org/web/20260312162857/https://github.com/heyito/ito), archived pricing (http://web.archive.org/web/20250815024703/https://www.ito.ai/pricing), archived blog post (http://web.archive.org/web/20251112012417/https://ito.ai/post/ito-ai-vs-wispr-flow-open-source-dictation), and a third-party copy of the source from 2025-10-14 at https://github.com/JoinBXYZ/dictate (renamed "Dictate" by its copier, Souradip Mookerjee, who added a Groq key field and local-hosting changes; marked "copy" below). The copy is three months older than the final release, so later features may be missing.

## Pricing

- Aug 2025 pricing page: "All features unlocked during early access — no strings attached." (archived pricing)
  - "standard": shown as FREE, crossed-out "$8 per month": "Unlimited Voice Dictation", "Unlimited AI writing", "Custom Vocabulary", "API Integrations".
  - "pro": shown as FREE, crossed-out "$10 per month": "Everything in Standard", "Access to the best LLM model", "Team Management".
  - "enterprise": "Coming soon": "Soc2 Compliance", "Team Memory", "Team Management".
  - The same page also shows "BASIC $22 / STANDARD $46 / Pro $144 per member, per month … 3 active projects, Up to 10 blocks", which reads as leftover website-template text, not real Ito plans.
- The paid prices were never confirmed as charged; the product went free-in-early-access to discontinued. (Gap)
- Self-hosting the server was possible (README: run the gRPC server locally with your own API keys). (archived README)
- Product Hunt (launched 2025-08-21, 103 upvotes) describes it as free and open source. (https://www.hunted.space/product/ito-3)

## Feature inventory

All features were free during early access.

### Trigger & capture

- Default trigger on Mac: Fn for dictation; Control-left + Fn for "Intelligent Mode". Windows: Option-left + Control-left, and Option-left + Shift-left. (copy: lib/constants/keyboard-defaults.ts) The README says "default: Fn + Space". (archived README) The two sources disagree; gap.
- Hold-to-talk: "Simply hold down your trigger key, speak naturally". Toggle or hands-free mode: none found. (archived README)
- "Keyboard Shortcut" and "Intelligent Mode Shortcut" settings; multiple shortcuts per mode allowed (MultiShortcutEditor). Single key, key combos, and "Complex shortcuts: Fn + Cmd + Space". (copy: KeyboardSettingsContent.tsx, archived README)
- "Hey Ito" wake word while holding the regular dictation key switches to Intelligent Mode. (archived blog post, https://alternativeto.net/software/ito-ai/about)
- "Select default microphone". "Interaction Sounds" toggle. README also lists "Sensitivity adjustment" and "Noise reduction". (copy: AudioSettingsContent.tsx, archived README)
- "Show app in dock", "Launch at Login". (copy: GeneralSettingsContent.tsx)
- System audio, other-device push-to-talk: none found.

### Transcription engine

- Cloud by default. Default speech model `whisper-large-v3` on Groq; default AI model `openai/gpt-oss-120b` on Groq, temperature 0.1. LLM provider options in the UI: `groq`, `cerebras`. (copy: lib/constants/generated-defaults.ts, AdvancedSettingsContent.tsx)
- Advanced settings expose "ASR Provider", "ASR Model", "ASR Prompt", "LLM Provider", "LLM Model", "LLM Temperature", "Transcription Prompt", "No Speech Threshold" (0.6), "Low Quality Threshold" (−0.55). (copy)
- Local transcription: not shipped. Ito's own Sept 2025 blog: "Today, both Ito and Wispr Flow operate via cloud processing. There is no offline mode". HN launch (Nov 2025): "we're still working on an entirely local first experience". A self-hosted server could run on your own machine but still called cloud APIs for the model. (archived blog post, https://news.ycombinator.com/item?id=45838634)
- Languages: README claims "Multi-language support"; AlternativeTo lists "English only". No language picker found in the copy. (Gap)
- Speed claims: none found.

### Live preview

- None found. README says "Real-time transcription" but text is inserted after release; no overlay text found in the copy.

### Cleanup & formatting

- Default "Transcription Prompt" ("Transcript Polisher"): removes "uh," "um," "you know," repeats and false starts; "Resolve corrections smoothly: when the speaker self-corrects ('let's do next week... no, next month'), choose the final phrasing"; full sentences, punctuation, paragraph breaks "only where needed". User-editable. (copy: generated-defaults.ts)
- "Intelligent Mode": speak an instruction and the AI writes the result ("Draft a follow-up email confirming tomorrow at 10am"), mapping to templates like a GitHub issue or professional email, then pastes it. Uses the "Command-Interpreter" editing prompt. (archived blog post, copy)
- "Intelligent punctuation". (archived README)
- "Context awareness: Learns from your usage patterns to improve accuracy" (README claim). The source has a native "active-application" helper ("Get the active application for context"). What context reached the AI is not verified. (archived README)
- Per-app tone: none found.

### Personalization

- "Dictionary": "Add to vocabulary", plus "Make it a replacement" with "Misspelling" → "Correct spelling" fields. Vocabulary is passed to the speech model. (copy: DictionaryContent.tsx, server asrConfig.ts)
- Snippets, auto-learning from edits, per-app rules: none found.

### Output & editing

- "Instant text insertion: Automatically types transcribed text into the focused text field" via a Rust "text-writer" helper. (archived README)
- History ("Interaction history") stored locally in SQLite, including raw audio. Home screen shows "Total Words", "Average Speed", "Weekly Streak". (archived README, copy: HomeContent.tsx, sqlite/models.ts)
- "Export capabilities: Export your notes and interaction data". (archived README)
- Undo, retry, edit before paste: none found.

### Voice commands

- "Hey Ito" wake word into Intelligent Mode (see above). Editing-by-voice commands like "new line": none found. The Aug 2025 pricing page tagline "Dictate, edit, and command without lifting a finger" is marketing; no command list found.

### Beyond dictation

- "Notes": "Take a quick note with your voice", with search and edit. (copy: NotesContent.tsx, archived README)
- Meeting recording, file transcription, translation: none found.

### Platforms & sync

- macOS 10.15+ and Windows 10+. The Aug 2025 FAQ said "Right now, Ito is Mac-only"; Windows arrived by the Nov 2025 HN launch. (archived pricing, archived README, HN)
- "Cloud sync: Keep your settings and data synchronized across devices." Sign-in through Auth0 (Google, Apple, GitHub) "or create a local account". (archived README)
- Mobile: none.

### Privacy & data

- Audio goes to Ito's server (or a self-hosted one) and on to Groq/Cerebras. (copy, archived blog post)
- "Share analytics" toggle. (copy: GeneralSettingsContent.tsx)
- README: "Local-enabled: Voice processing can be done entirely on your device or using our cloud", contradicted by Ito's own blog saying there was no offline mode. (archived README, archived blog post)
- "Encrypted transmission: All network communication uses TLS encryption." (archived README)
- SOC 2: listed as "Coming soon" for Enterprise only.

### Onboarding & permissions

- "Grant permissions when prompted": Microphone and Accessibility; "Set up authentication"; "Complete the guided onboarding process"; "Test your microphone". (archived README)

### Accessibility

- None found.

### Distribution

- Direct download (DMG, Windows .exe) from the website and GitHub releases. (archived README)
- Open source, GPL-3.0 ("GNU General Public License"). Electron + React 19 + TypeScript, Rust native helpers (audio recorder, key listener, text writer), Swift for macOS text and accessibility, gRPC server on AWS. (archived README)
- Mac App Store, Setapp, Homebrew: none found.

## Recent changes (last 12 months)

- 2025-08-21: Product Hunt launch, "Speak Simpler, Work Smarter". (https://www.hunted.space/product/ito-3)
- 2025-09 (blog): "Intelligent Mode" and "Hey Ito" wake word announced. (archived blog post)
- 2025-11-06: Show HN, "open source smart dictation", Windows and Mac. Comment thread flooded with flagged accounts; one user: "Maybe don't have fake user accounts astro-turf your comments next time?" (https://news.ycombinator.com/item?id=45838634, https://news.ycombinator.com/item?id=45852326)
- 2025-11-24: last commit date shown in archived repo. Last release v0.15.35.
- By 2026-01-17: ito.ai homepage replaced with an automated QA testing product.
- Between 2026-01-09 and 2026-02-20: README marked "[DEPRECATED]". Later the repository was removed from GitHub (404 on 2026-10-23).

## User reception

- HN: "It's an electron app? Wouldn't that be a little slow for this use-case?" Reply: "latency sensitive bits are written in rust". (https://news.ycombinator.com/item?id=45838871)
- HN: the launch thread drew many flagged spam replies, called out as astroturfing. (https://news.ycombinator.com/item?id=45852326)
- Product Hunt commenter: "Is there any huge differentiator?" compared with Wispr Flow. (https://www.hunted.space/product/ito-3)
- AlternativeTo: 6 likes, no reviews; marked "Discontinued". (https://alternativeto.net/software/ito-ai/about)
- Little other reception found; it never gained a review base before being dropped.

## Gaps I could not verify

- Whether any paid plan was ever charged.
- The real default shortcut in the final release (Fn alone vs Fn + Space).
- Language count and whether auto-detect existed.
- What "Context awareness" sent to the AI (app name only, or screen/selection).
- Features added between the 2025-10-14 source copy and the final v0.15.35 release.
