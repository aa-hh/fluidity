# Serenade

- Vendor: Serenade (open-sourced the whole product in June 2022; a 2023 user comment says the founder joined OpenAI in July 2022, unverified)
- Platforms: macOS (x64 build), Windows (x64; local engine needs WSL + Ubuntu), Linux (x64)
- URL: https://serenade.ai/
- Date checked: 2026-10-23
- Placement: minimal, and effectively abandoned. Reason: it is a voice-coding command tool with a basic "dictate mode", no AI cleanup, and no merged code since July 2022.

## Maintenance status (asked for explicitly)

Not maintained.
- Latest release on the download page: "v2.0.2 (Stable)", macOS x64 / Windows x64 / Linux x64; no notice of shutdown on the site. https://serenade.ai/download/
- Last commit on `master` of the main repo: 2022-07-23 ("Merge pull request #10 from serenadeai/2.0.2"). Repo is not archived; Apache-2.0; 414 stars; 26 open issues. Checked via GitHub API: https://github.com/serenadeai/serenade
- Most recent pushes anywhere in the org: `serenade` repo 2024-06-11 (not on master), `chrome` extension 2025-05-08, `custom-commands` 2024-03-02. https://github.com/serenadeai
- A community "client: finish revamp" pull request (Node 22+, vite, "no more python") was closed without merging on 2025-11-20. https://github.com/serenadeai/serenade/pull/36
- Issue "Promising project, now death?" (opened 2023-09-13) has no maintainer answer; a 2024-01 comment says "no PRs have been merged to this repo since July 2022"; a 2025-09-22 comment says the master branch is 3 years old and the 750 MB Windows download is extremely slow. https://github.com/serenadeai/serenade/issues/30
- Breakages reported and unanswered: "Focus command no longer works in macOS sonoma" (2024-01, #31); "Jetbrains plugin compatibility ended with PyCharm/IntellJ/etc v. 2024.3.6" (2025-07, #35); setup stuck on Apple M1 Pro / Sonoma 14.7 (2024-10, #34). https://github.com/serenadeai/serenade/issues
- No native Apple Silicon build listed (download page offers macOS x64 only).

## Pricing

- Free: "Download Serenade for free." https://serenade.ai/
- Open source, Apache License 2.0 (client, online services, speech and code models, model training). https://github.com/serenadeai/serenade
- No paid tiers, team or education plans, or word limits found on the current site.

## Feature inventory

### Trigger & capture
- "Listening" switch in the app, or Alt+Space hotkey, toggles listening. (free) https://serenade.ai/docs/
- Voice: "pause" / "stop listening". Same source.
- Hold-to-talk: none found. Mic selection: none found. System audio: none found. Other-device push-to-talk: none found.

### Transcription engine
- Own speech engine, described as a "speech-to-code engine" built for developers, tuned for code or prose depending on the editor. https://serenade.ai/
- Settings > Server: choose cloud or local. Local means "all of your voice commands and source code stay on-device." On Windows, local needs WSL with Ubuntu. https://serenade.ai/ , https://serenade.ai/docs/
- Spoken languages: English only as far as found; no language list on the site.
- Programming-language detection: auto-detect, with "python mode" / "javascript mode" / "auto mode" overrides. https://serenade.ai/docs/
- Speed claims: none found.

### Live preview
- After each utterance Serenade shows a list of alternatives; the first is applied automatically, say "two" (etc.) to pick another, or "undo". https://serenade.ai/docs/
- Words while speaking (streaming): none found.

### Cleanup & formatting
- Code formatting is automatic: "no need to think about syntax, formatting, or symbols" (it inserts brackets, spacing, etc. for the target language). https://serenade.ai/
- "system <text>" inserts raw text with no formatting. https://serenade.ai/docs/
- Filler removal, self-correction, AI rewrite, per-app tone, custom prompts: none found.
- Context awareness: reads the code around the cursor through editor plugins (needed for commands like "change height to speed"). https://serenade.ai/docs/

### Personalization
- Custom commands in JavaScript: `serenade.global().command(trigger, callback)`, scoped with `serenade.app("name")`, `language()`, `extension()`, `scope()`, `url()`. (free) https://serenade.ai/docs/api/
- `pronounce(before, after)` remaps how a word is recognised; `hint(word)` biases the engine toward a word. Same source.
- Code snippets: `serenade.language("python").snippet(...)` with slots `<%cursor%>`, `<%indent%>`, `<%newline%>`, `<%terminator%>`. Same source.
- `text()` maps a phrase to typed text (simple text expansion). Same source.
- Auto-learning from edits: none found.

### Output & editing
- Native plugins for VS Code, JetBrains IDEs (PyCharm, IntelliJ, WebStorm, Android Studio), Chrome, Hyper, iTerm2, Atom; also listed: Jupyter, Colab, Repl.it, LeetCode, GitHub, GitLab, JIRA, Linear, Slack, Discord, Gmail. https://serenade.ai/
- Other apps go through OS accessibility APIs; where those fail, the "Revision Box" ("revision box" or "edit") lets you compose text and finish with "copy", "close" or "enter". https://serenade.ai/docs/
- "undo", "repeat". Same source.
- Transcript history: none found.

### Voice commands
- "dictate mode" types everything said (except "undo", "repeat", "stop listening"); back with "command mode". https://serenade.ai/docs/
- Code editing: "change <selector> to <code>", "copy next two words", "cut to end of line", "paste", "delete line four", "delete lines three to four", "comment function", "indent line", "duplicate block", "join five lines", "move argument left". Same source.
- "press control tab", "run make" (types and presses enter), "focus chrome". Same source.
- Automation API: `pressKey`, `typeText`, `click`, `focusApplication`, `launchApplication`, `runShell`, Chrome `domClick`/`domFocus`. https://serenade.ai/docs/api/

### Beyond dictation
- Supported code/markup languages: Python, JavaScript, TypeScript, Java, C/C++, Dart, Bash, HTML, CSS, Sass, Markdown. https://serenade.ai/
- File transcription, meetings, notes, summaries, translation, AI chat: none found.

### Platforms & sync
- macOS x64, Windows x64, Linux x64 (v2.0.2). https://serenade.ai/download/
- Sync, mobile apps: none found. Minimum OS: none stated.

### Privacy & data
- Local mode keeps "voice commands and source code ... on-device"; cloud mode sends audio and code context to Serenade's servers. https://serenade.ai/
- Site links "Terms of Service", "Privacy Policy" and "Code Privacy" pages (not read). https://serenade.ai/download/
- Whether the cloud server still runs reliably: a 2023 comment mentions "the server issue" posted by the founder on Discord. https://github.com/serenadeai/serenade/issues/30

### Onboarding & permissions
- App shows "Did you know?" prompts to install editor plugins (bug report says it repeats even when installed). https://github.com/serenadeai/serenade/issues/32
- A user on M1 Pro / Sonoma could not get past a setup screen. https://github.com/serenadeai/serenade/issues/34
- Specific microphone/Accessibility prompt flow: none found.

### Accessibility
- Pitched at reducing typing ("code with voice"), including for people with repetitive strain. VoiceOver claims: none found.

### Distribution
- Direct download, 750 MB on Windows per a user. Open source on GitHub (Apache-2.0). Mac App Store / Setapp / Homebrew: none found.

## Recent changes (last 12 months)

- None from the vendor. Only community activity: unmerged revamp pull request closed 2025-11-20; Chrome extension repo push 2025-05-08. https://github.com/serenadeai

## User reception

- "this is the best solution out there that i'm aware of. i've tried talon" (2023-10). https://github.com/serenadeai/serenade/issues/30
- "I also like Serenade better than Talon, it's more intuitive for me." (2024-01) Same thread.
- Same user: the engine "consistently misunderstood my Australian accent." Same thread.
- "I would pay for this to see it continue development." (2023-09) Same thread.
- Abandonment complaints: master branch 3 years old, slow download (2025-09). Same thread.
- IEEE Spectrum contrasted Serenade's natural "describe what you want" style with Talon's line-by-line control. https://spectrum.ieee.org/programming-by-voice-may-be-the-next-frontier-in-software-development
- Breakage on current macOS and JetBrains versions (issues #31, #35). https://github.com/serenadeai/serenade/issues

## Gaps you could not verify

- Whether the cloud speech server still responds today (did not install).
- Whether the x64 macOS build runs under Rosetta on current macOS (one M1 user stuck at setup; no general answer).
- Historical paid "Pro" tier before open-sourcing: not checked, not relevant now.
- Privacy policy contents.
