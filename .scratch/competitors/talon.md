# Talon Voice

- Vendor: Talon Voice (Ryan Hileman, solo developer; funded by Patreon)
- Platforms: macOS, Windows, Linux (X11 only)
- URL: https://talonvoice.com/
- Date checked: 2026-10-23
- Placement: full-suite for hands-free computer control, but minimal as a "press key, talk, text lands" dictation app. Reason: it can type into any app and has a deep scripting system, but it has no AI cleanup, no hold-to-talk default, and needs configuration files before it does anything useful.

Scope note: per the assignment, this file covers dictation and prompt entry only. The voice-coding grammar (Cursorless, code navigation, eye-tracking mouse) is mentioned only where it touches dictation.

## Pricing

- Talon itself: free download. Source: https://talon.wiki/ ("free to use").
- Patreon tiers, as reported by a competitor comparison page checked 2026-10-20 (Patreon page returned 403 to us, so not verified first-hand): https://lumevoice.com/vs/talon-voice/
  - "VIP Slack Channel": $5/month
  - "Talon+": $25/month (the tier formerly called "beta"; gives the Talon+ feature list below)
  - "Professional": $100/month
  - Annual billing: 15% off
- What Talon+ gates (vendor's own list, "Current Talon+ features (previously called "beta", ...)"): https://talonvoice.com/dl/latest/changelog.html
  - "Ongoing Linux/X11 support."
  - "Parrot noise recognition."
  - "Conformer + Whisper Hybrid engine, now GPU-accelerated and powered by Whisper Large."
  - "macOS keyboard dictation engine."
  - "Conformer D (de_DE) German speech model."
  - "Wisp Small model."
  - "Faster speech recognition."
  - "Vosk multilingual engine."
  - "WebSpeech multilingual engine."
  - "`deck()` support for Elgato Stream Deck in .talon files."
- Licence: royalty-free, for "You, as a human person, and not a corporate or other entity"; companies must "negotiate an alternate license agreement". Source: https://talonvoice.com/EULA.txt
- No free-tier word or minute limits found. No team or education plan found. No bring-your-own-key option in Talon itself (the third-party talon-ai-tools add-on uses your own OpenAI-compatible key, see below).

## Feature inventory

### Trigger & capture
- Always-listening by default: speech is treated as commands unless the user switches mode. No hold-to-talk key is described in the basic docs. (free) https://talon.wiki/Basic%20Usage/basic_usage/
- "Sleep mode" and wake phrases: "go to sleep" / "wake up". (free) https://talon.wiki/Basic%20Usage/basic_usage/
- "Sleep" item in the "Speech Recognition" menu (menu bar app). (free) https://talonvoice.com/dl/latest/changelog.html
- Noise triggers: "Pop to click, hiss to scroll"; `noise(pop)` and `noise(dental_click)` bindings in .talon files. (free) https://talonvoice.com/ , https://talonvoice.com/dl/latest/changelog.html
- "Parrot noise recognition" (custom trained sounds as triggers). (Talon+) https://talonvoice.com/dl/latest/changelog.html
- Stream Deck buttons via `deck()`. (Talon+) same source
- Any key or hotkey can be scripted to start/stop listening in .talon files (general scripting). Specific default push-to-talk binding: none found.
- "Tone (speaker verification)" model, shipped 2026-09-20, which suggests ignoring other voices; exact behaviour not documented. https://talonvoice.com/dl/latest/changelog.html
- Mic selection: none found in the pages read (looked at changelog, wiki basic usage).
- System-audio handling: none found.

### Transcription engine
- Built-in on-device engine (originally based on Facebook's wav2letter). (free) https://spectrum.ieee.org/programming-by-voice-may-be-the-next-frontier-in-software-development
- "Conformer D2 (2026-05-27) model which improves accuracy and has an algorithm for rejecting incorrect commands." (listed under 1.0) https://talonvoice.com/dl/latest/changelog.html
- Talon 1.0 (2026-09-20): "three new GPU-accelerated speech models": "Hum (streaming dictation)", "Song (command recognition + rejection)", "Tone (speaker verification)". Gating not stated. Same source.
- "Conformer + Whisper Hybrid engine, now GPU-accelerated and powered by Whisper Large." (Talon+) Same source.
- "Wisp Small model." (Talon+) Same source.
- "macOS keyboard dictation engine" (use Apple's dictation as the engine). (Talon+) Same source.
- Dragon: "Works with the integrated wav2letter speech engine as well as Dragon." (0.1.0; Dragon only exists on Windows today). Same source.
- Languages: commands are "implicitly scoped to `en_US`" since 0.3.0; German via "Conformer D (de_DE)" (Talon+); "Vosk multilingual engine" and "WebSpeech multilingual engine" (Talon+). Total language count: none found.
- Engine switching UI: "extended Speech Recognition menu"; engines can be installed "directly from Talon's Speech Recognition menu". Same source.
- Speed claims: "Faster speech recognition" (Talon+), no numbers. Cloud models: none (all engines listed are local, except WebSpeech, which is browser speech recognition; where it runs is not documented).

### Live preview
- "Add on-screen subtitles for spoken phrases." (0.2.0) https://talonvoice.com/dl/latest/changelog.html
- "Heads Up Display w/ adjacent floating subtitles"; subtitles hidden in screenshots. Same source.
- "Hum (streaming dictation)" model added 2026-09-20; whether words appear in the target app while speaking, or change afterwards, is not documented.

### Cleanup & formatting
- No AI cleanup, filler removal or self-correction handling found (searched changelog for "filler", none).
- Formatters, spoken before the text (free, community set): "say" (no formatting), "sentence" (first word capitalised), "title", "all down", "smash" (no spaces), "kebab", plus code formatters like "snake" ("snake hello world" gives hello_world). https://talon.wiki/Basic%20Usage/basic_usage/ , https://github.com/talonhub/community
- In dictation mode: "cap", "no cap", "no space", "cap that", "no cap that"; "formatted <formatter> <text>". https://talon.wiki/Basic%20Usage/basic_usage/
- Spoken punctuation ("comma" etc.; "help punctuation" lists them). Same source.
- "numb <number>" for digits; "spell" for letters using the spoken alphabet. Same source.
- Setting `user.context_sensitive_dictation` (optional; adjusts spacing/capitals based on surrounding text). Same source.
- Formatters can be applied to already-selected text. https://github.com/talonhub/community
- Per-app behaviour: .talon files can have context headers (app name, window title) so commands differ per app. (free, scripting) https://github.com/talonhub/community
- Custom prompts / modes in the AI sense: none in Talon itself. Third-party "talon-ai-tools" adds spoken `model` commands that send text to an LLM with a chosen prompt (e.g. "four o mini explain this"), settings `user.model_default` ("gpt-4o-mini"), `user.model_endpoint`, `user.model_system_prompt`, any OpenAI-compatible endpoint or the `llm` command-line tool; user brings own API key; also GitHub Copilot integration. https://github.com/C-Loftus/talon-ai-tools/blob/main/GPT/readme.md , https://github.com/mpqmpqm/talon-ai-tools
- Context awareness (screen reading): none found in Talon itself.

### Personalization
- Vocabulary additions and replacements ("words_to_replace") via commands in `edit_vocabulary.talon`. (free, community set) https://github.com/talonhub/community
- "customize" + "additional words" / "words to replace" / "abbreviations" / "homophones" / "alphabet" opens the matching list file. Same source.
- Homophones list (pick between "their/there" by voice). Same source.
- Override lists with your own `.talon-list` file with a more specific context. Same source.
- Fully custom commands: `select all: key(cmd-a)` style lines in .talon files; Python actions. (free) https://talonvoice.com/
- Auto-learning from edits: none found.
- Snippets: community set has snippet support for code; prose text-expansion feature by name: none found.

### Output & editing
- Types into any app (keystroke-based; exact paste vs typing method not documented on pages read). (free)
- Dictation-mode editing: "scratch that", "select that" (last phrase, if cursor hasn't moved); "go line end"; "clear left <n> words". https://talon.wiki/Basic%20Usage/basic_usage/
- Command-mode editing: "select", "copy", "paste", "clear", "go before", "go after" combined with "line", "line end", etc.; "copy that", "paste that", "cut that", "undo that", "redo that". Same source.
- "press <key>" sends keys while in dictation mode; "escape" types the next words literally. Same source.
- "command history" shows recent recognised phrases. Same source.
- Transcript history/search beyond that, edit-before-paste, retry: none found.

### Voice commands
- Three modes: "command mode", "dictation mode", "mixed mode" ("simultaneous dictation + command mode", added in 1.0 list). https://talon.wiki/Basic%20Usage/basic_usage/ , https://talonvoice.com/dl/latest/changelog.html
- "help context", "help active", "help alphabet", "help formatters", "help symbols", "help search <phrase>", "help close". https://talon.wiki/Basic%20Usage/basic_usage/ , https://github.com/talonhub/community
- App control, window switching, mouse by eye tracking ("Mouse by just looking", "3rd-generation eye tracking algorithm" in 1.0). https://talonvoice.com/ , https://talonvoice.com/dl/latest/changelog.html
- "customize settings" opens settings.talon. https://talon.wiki/Basic%20Usage/basic_usage/

### Beyond dictation
- Eye-tracking mouse, noise clicks, game control ("Write. Code. Browse. Game."). https://talonvoice.com/
- LLM querying and rewriting via third-party talon-ai-tools (see Cleanup). 
- File transcription, meeting recording, notes, summaries, translation: none found.

### Platforms & sync
- macOS, Windows, Linux (X11). https://talonvoice.com/
- "Talon 1.0 (plus any minor fixes) is planned to be the last public release of Talon for Linux/X11"; ongoing Linux moves to Talon+. Wayland detected and warned about. https://talonvoice.com/dl/latest/changelog.html
- macOS: "Use Metal rendering for all UI", fixes for macOS Tahoe and "older versions of macOS"; no stated minimum version. Same source.
- Apple Silicon: native since 2020-21 (Universal 2) per older changelog entries; "Fix numpy warnings on M4 CPUs" in 1.0. Same source.
- Sync across devices: none found (settings are plain files; users commonly keep them in git, not a vendor feature). iOS/Android: none.

### Privacy & data
- EULA: usage "metrics do NOT record actual input, speech, text, or screen contents"; crash reports upload automatically on next start; update checks send IP and version; plugin usage may be logged; TLS for all web traffic. https://talonvoice.com/EULA.txt
- Speech engines are installed locally (wav2letter/Conformer); EULA itself does not state where recognition runs.
- SOC 2 / HIPAA: none found.

### Onboarding & permissions
- Out of the box does little; users install the community command set ("talonhub/community") into the Talon user folder. https://talon.wiki/ , https://blakewatson.com/journal/speaking-in-code-hands-free-input-with-talon/
- Microphone / Accessibility prompt handling and first-run tutorial: none found (looked at talonvoice.com, talon.wiki home and basic usage, changelog).

### Accessibility
- Built for people who cannot use their hands ("hands-free input replacement for the keyboard and mouse"). https://talon.wiki/
- VoiceOver compatibility claims: none found.

### Distribution
- Direct download from talonvoice.com. Not on Mac App Store, Setapp or Homebrew (none found). Talon is closed source; the community command set is MIT-licensed open source. https://github.com/talonhub/community

## Recent changes (last 12 months)

- 2025-12 (per third-party reports): Talon+ build with a faster on-device engine. https://www.yaps.ai/ (competitor blog; unverified)
- 2026-05-27: "Conformer D2" model with incorrect-command rejection. https://talonvoice.com/dl/latest/changelog.html
- 2026-09-20: Talon 1.0. New "Hum" (streaming dictation), "Song", "Tone" GPU-accelerated models; "mixed mode"; Conformer + Whisper Large hybrid now GPU-accelerated (Talon+); legacy Dragon-style `<dgndictation>` captures removed; 3rd-generation eye tracking; Metal UI; last public Linux/X11 release. Same source.

## User reception

- "Talon is a wonderful piece of technology" (Josh Comeau, 2020, updated 2025). https://www.joshwcomeau.com/blog/hands-free-coding/
- Steep start: "The first few weeks were rough." Same source.
- Slower than typing: "about 50% of my normal speed". Same source.
- "The biggest issue I've found so far is voice strain". Same source.
- Best when you write your own commands, per the same author: "Talon work best when you write your own commands." Same source.
- For prose: "If you are simply writing natural language, you might not find Talon as useful." (Blake Watson, 2018/2021) https://blakewatson.com/journal/writing-and-coding-by-voice-with-talon/
- Called the state of the art for voice coding by a Julia forum user. https://discourse.julialang.org/t/voice-coding/80513
- Competitor blogs frame it as hard to learn and overkill for plain dictation (hours to weeks to feel natural). https://www.yaps.ai/

## Gaps you could not verify

- Exact Patreon tier prices: Patreon returned 403; prices come from a competitor page only.
- Whether "Hum" streaming dictation and "mixed mode" are free or Talon+.
- Whether text is typed as keystrokes or pasted via clipboard.
- Microphone selection, push-to-talk default key, first-run permission flow.
- Total language count for the multilingual engines.
- Whether the Whisper hybrid applies punctuation/capitals itself.
- No recent Reddit or Hacker News threads found specifically on prose dictation quality.
