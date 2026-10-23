# Voice input built into AI coding tools

- Date checked: 2026-10-23
- Question: what dictation a developer gets natively, without a separate app.
- Placement of the whole group: minimal. Each tool's dictation only fills its own prompt box (one exception: the ChatGPT desktop app's global dictation, see below), with little or no custom vocabulary and no history.

## Summary table

| Tool | Where dictated text can go | Trigger | Engine / where audio goes | Words shown while speaking | Cleanup | Custom words | Cost gate |
|---|---|---|---|---|---|---|---|
| Cursor (3.x) | Agent prompt only (Agents Window gets the new flow; main-window chat older flow) | Mic button; hold `Ctrl+M` in Agents Window | "batch STT"; provider and location not documented | No in Agents Window (records full clip, then transcribes) | none found | none found | Paid plans per a Cursor team member, later retracted as a bug |
| Claude Code CLI + VS Code extension | Claude Code prompt only | `/voice`; hold `Space` (default) or tap mode; rebindable | Streamed to Anthropic servers; not local | Yes, dimmed until final | none (raw transcript) | Auto hints: project name and git branch; tuned for dev terms | Needs claude.ai sign-in; not counted toward usage |
| Claude desktop app (chat, Cowork, Code tab) | Its own prompt boxes; Quick Entry popup | Mic icon; Caps Lock for Quick Entry (off by default); no hotkey for main-window mic | Not documented; needs macOS "Speech recognition" permission | Yes in Quick Entry ("real-time transcription") | none found | none found | All plans incl. free |
| ChatGPT desktop app (now includes Codex, Work, Chat) | Prompt box, and any Mac/Windows app via "global dictation" | Mic button; configurable "Press" (hold) and "Toggle" dictation shortcuts (off by default) | OpenAI servers (third-party reports name Whisper / `gpt-4o-transcribe`) | not documented | "dictation cleanup" (26.429) | "configurable dictation dictionary for names, file paths, and code symbols" (26.429) | Has a usage cap ("Codex dictation usage limit reached") |
| Windsurf, now Devin Desktop | Cascade chat only ("Speak to Cascade") | Mic control in chat | not documented | not documented | none found | none found | not documented |
| GitHub Copilot in VS Code | Chat, Agents window, any editor, integrated terminal | `Cmd+I` (chat), `Opt+Cmd+V` (editor); hold for push-to-talk; "Hey Code" | On-device `nemotron-3.5-asr-streaming-0.6b` by default; cloud on web | Yes (`dictation.showTranscript`, default on) | Optional LLM cleanup (experimental), custom instructions, shell-aware terminal cleanup | Via cleanup instructions only | Dictation: AI features on; hosted Voice Mode: individual Copilot plans only |

---

## 1. Cursor

- Vendor: Anysphere. Platforms: macOS, Windows, Linux. URL: https://cursor.com/
- Placement: minimal. Voice fills the agent prompt only; nothing in editor, terminal or other apps.

### Pricing / gating
- A Cursor forum responder who said "I reported this to the team" first wrote "Voice input and transcription in Cursor are only available on paid plans Pro and above", then retracted it the same day as "a regression in 3.2.21" that applies "on any tier" (2026-05-05). Gating is therefore unclear. https://forum.cursor.com/t/voice-input-button-starts-audio-context-but-receives-silent-stream-level-meter-dead-no-transcription-macos-fresh-install/159747

### Trigger & capture
- "Voice Mode": "Control Agent with your voice using built-in speech-to-text conversion." (2.0, 2025-10-29) https://cursor.com/changelog/2-0
- Agents Window: "press and hold `Ctrl+M` to speak"; recording UI with "a waveform, timer, and buttons for cancelling and confirming." (3.1, 2026-04-13) https://cursor.com/changelog/3-1
- Forum users: in the Agents Window `Ctrl+M` must be held, elsewhere it toggles; they ask for it to be configurable. https://forum.cursor.com/t/cursor-3-1-tiled-layout-and-upgraded-voice-input/157293
- "Live microphone meter while dictating." (3.20) https://cursor.com/docs/release-notes/ide
- In the Cursor browser's Design Mode the mic stays available while an agent runs. https://cursor.com/changelog/design-mode-improvements (per search summary; not fetched)
- Mic selection: none found.

### Transcription engine
- "records your full voice clip and transcribes it with batch STT" (3.1). Provider not named. https://cursor.com/changelog/3-1
- "Voice dictation detects your spoken language automatically", Auto-Detect default, manual language choice available. (3.19) https://cursor.com/docs/release-notes/ide

### Live preview
- Agents Window: none (batch after recording ends).
- Bug report (3.11.19, macOS 26.5.2, 2026-07-15): "no live transcript", text appears only after toggling Voice Mode off. No staff reply. https://forum.cursor.com/t/voice-mode-no-live-transcript-submit-keywords-never-send-finalize-on-stop-only/165822

### Cleanup & formatting
- none found (looked at 2.0, 3.1 changelogs and IDE release notes).

### Voice commands
- "custom submit keywords in settings to trigger the agent to begin running." (2.0) https://cursor.com/changelog/2-0
- "Voice submit keywords ... now save in Settings and trigger submit", including non-Latin scripts. (3.22) https://cursor.com/docs/release-notes/ide
- Reports that submit keywords never send (2025, again in 3.11.19). https://forum.cursor.com/t/voice-mode-no-live-transcript-submit-keywords-never-send-finalize-on-stop-only/165822

### Personalization, output, beyond dictation
- Custom vocabulary, history, other-app output: none found.

### Privacy
- Where audio is processed: not documented (none found in changelogs; a third-party guide says the docs do not say). https://voicedash.ai/?p=15007

### Reception
- "I find the tile layout and upgraded voice input especially useful." https://forum.cursor.com/t/cursor-3-1-tiled-layout-and-upgraded-voice-input/157293
- Hold-then-transcribe suits long prompts ("finish your thought, then transcribe"). Same thread.
- Wants the upgrade "present everywhere", not only the Agents Window. Same thread.
- Mic icon hidden until you type. https://forum.cursor.com/t/voice-input-missing-in-agents-window-until-you-type/156849
- Silent stream / no transcription on fresh macOS install (3.2.21 regression). https://forum.cursor.com/t/voice-input-button-starts-audio-context-but-receives-silent-stream-level-meter-dead-no-transcription-macos-fresh-install/159747

### Gaps
- Speech-to-text provider; whether `Ctrl+M` is the macOS key too; plan gating.

---

## 2. Claude Code (command line and VS Code extension) and Claude desktop app

- Vendor: Anthropic. URLs: https://code.claude.com/docs/en/voice-dictation , https://support.claude.com/en/articles/12626668-use-quick-entry-with-claude-desktop-on-mac
- Placement: minimal but the most polished prompt-box dictation in this set (hold or tap, live text, cancel, coding-tuned).

### 2a. Claude Code command line

Pricing / gating
- Needs "A Claude.ai account"; not available with an Anthropic API key, Amazon Bedrock, Google Cloud's Agent Platform or Microsoft Foundry. "Transcription does not consume Claude messages or tokens and does not count toward the limits shown in `/usage`." Admins can disable it ("Voice mode is disabled by your organization's policy"). https://code.claude.com/docs/en/voice-dictation
- Versions: needs v2.1.69+; tap mode v2.1.116+ (per search summary of the same docs).

Trigger & capture
- `/voice`, `/voice hold`, `/voice tap`, `/voice off`; persists via `"voice": {"enabled": true, "mode": "tap"}` in settings. Same source.
- Hold mode (default): hold `Space`; brief warmup ("keep holding…", then "listening…") because it detects key-repeat; first repeated spaces are removed automatically. Same source.
- Tap mode: tap `Space` with empty prompt to start ("● REC · tap to send"), tap again to stop and send. Auto-stops after 15 s of silence or 2 min total. Same source.
- Rebind `voice:pushToTalk` in `~/.claude/keybindings.json` (e.g. `meta+k`, no warmup). Caps Lock cannot be bound. Same source.
- Also works in "agent view" dispatch input and peek-panel replies. Same source.
- Mic selection: uses system default input (troubleshooting says set it in System Settings → Sound → Input). Same source.
- Does not work in cloud sessions, SSH, or VS Code Remote. Same source.

Transcription engine
- "streams your recorded audio to Anthropic's servers for transcription. Audio is not processed locally." Same source.
- "Transcription is tuned for coding vocabulary"; `regex`, `OAuth`, `JSON`, `localhost` recognised; "your current project name and git branch name are added as recognition hints automatically." Same source.
- 20 languages (cs, da, nl, en, fr, de, el, hi, id, it, ja, ko, no, pl, pt, ru, es, sv, tr, uk) via the `language` setting; default English; no auto-detect. Same source.

Live preview
- "Your speech appears in the prompt as you speak, dimmed until the transcript is finalized." Mic-level bar replaces the cursor while recording. Same source.

Cleanup & formatting
- none found beyond the speech service's own output.

Output & editing
- Inserted at the cursor; mix typing and voice; hold again to append. Same source.
- `"autoSubmit": true` sends on key release if the transcript is at least 3 words; tap mode always auto-submits at 3+ words. Same source.
- Cancel: `Esc` or `Ctrl+C` discards and restores the previous prompt. Same source.

Onboarding & permissions
- First `/voice` runs a mic check and triggers the macOS microphone prompt for the terminal; docs give a `tccutil reset Microphone <bundle-id>` fix when the terminal is missing from the list. Footer hint "hold space to speak" for the first three sessions. Same source.

Accessibility
- Mic-level animation respects `prefersReducedMotion`. Same source.

VS Code extension
- Same claude.ai requirement; mic button; 15 s no-speech and 2-minute limits; falls back to VS Code's `accessibility.voice.speechLanguage` for language. Same source.

### 2b. Claude desktop app (macOS / Windows)

- "Quick entry": "Double-tap the Option key to open Claude from any app"; "Press Caps Lock to dictate your message to Claude with real-time transcription." The voice shortcut "is disabled by default because it takes over your Caps Lock key." Voice dictation needs macOS 14+; permissions: Accessibility, Screen recording, Speech recognition. All plans (free, Pro, Max, Team, Enterprise). https://support.claude.com/en/articles/12626668-use-quick-entry-with-claude-desktop-on-mac
- Main chat window: mic icon only; the Caps Lock shortcut opens Quick Entry as a new conversation instead of dictating into the open chat (user feature request, closed 2026-04-15). https://github.com/anthropics/claude-code/issues/48305
- Claude Code tab in the desktop app: mic icon works, but `/voice` says it "isn't available in this environment" and `voice:pushToTalk` has no effect; no voice hotkey (request closed 2026-05-15). https://github.com/anthropics/claude-code/issues/59400
- "In Claude Cowork and Claude Code, dictation is available but voice mode isn't." https://support.claude.com/en/articles/11101966-use-voice-mode
- "Dictation is available on the web, mobile, and desktop app"; on mobile "hold the mic while you talk and let go to send." https://academy.claude.com/tutorials/how-to-choose-between-voice-mode-and-dictation
- Linux desktop app: voice input not available (per search summary of https://code.claude.com/docs/en/desktop-linux).
- Separate from dictation: two-way "Voice mode" (beta) on mobile, desktop and web. https://support.claude.com/en/articles/11101966-use-voice-mode

### Reception
- A desktop user: built-in speech-to-text "is significantly better than macOS system dictation", but wants a hotkey instead of clicking the mic. https://github.com/anthropics/claude-code/issues/48305
- "Users must reach for the mouse every single time they want to dictate". https://github.com/anthropics/claude-code/issues/59400

### Gaps
- Speech engine behind desktop Quick Entry (permission list suggests Apple's speech recognition, not confirmed).
- Whether desktop dictation has a language setting.

---

## 3. ChatGPT desktop app (macOS), which now contains Codex

- Vendor: OpenAI. Platforms: macOS, Windows, Linux (desktop app), plus web and mobile. URL: https://learn.chatgpt.com/docs/changelog
- Context: by September 2026 the changelog describes one "ChatGPT desktop app" with "Chat, Work, and Codex"; the Codex app for macOS launched 2026-02-02 with "Voice dictation" as a key feature. https://learn.chatgpt.com/docs/changelog
- Placement: mid. It is the only tool here that dictates into any app, with cleanup and a dictionary, i.e. a direct overlap with Fluidity.

### Pricing / gating
- At Codex app launch: "For a limited time, ChatGPT Free and Go include Codex". https://learn.chatgpt.com/docs/changelog (2026-02-02 entry)
- Dictation has a quota: users on Free (2026-09-16) and another with "96% remaining" of monthly usage (2026-09-29) hit "Codex dictation usage limit reached" in macOS app 26.908.70816; Safari and iOS still worked. No staff reply, no published number. https://community.openai.com/t/a-user-is-shown-the-codex-dictation-usage-limit-reached-error-message-while-trying-to-use-the-dictation-feature-in-the-macos-chatgpt-app-v-26-908-70816/1398011
- Third-party: global dictation "Included with ChatGPT Pro / Plus subscription". https://en.kocpc.com.tw/?p=3236
- Separate "ChatGPT Voice" (live conversation, GPT-Live): Plus, Pro, Business, Edu, Enterprise. https://learn.chatgpt.com/docs/features/voice

### Trigger & capture
- Mic button in the prompt composer (dictation turns speech into prompt text before sending). https://learn.chatgpt.com/docs/features/voice
- Global dictation hotkeys exist: 26.423 (2026-04-24) "Fixed ... broken global dictation hotkeys on older macOS versions." https://learn.chatgpt.com/docs/changelog
- Settings → General → Dictation: "Press Dictation Shortcut Key" (hold) and "Toggle Dictation Shortcut Key"; off by default; example key Ctrl+M. (third-party, not in OpenAI docs) https://en.kocpc.com.tw/?p=3236 , https://www.issoh.co.jp/tech/details/12799/
- No official shortcut for the in-app mic was found in an older feature request. https://community.openai.com/t/enable-voice-transcription-via-keyboard-shortcuts-in-the-chatgpt-macos-app/1058952
- Mic selection for dictation: none found (mic/speaker/channel selection exists for voice conversations). https://learn.chatgpt.com/docs/changelog

### Transcription engine
- Cloud (OpenAI). Help center FAQ says the recording is sent to OpenAI models for transcription (per search summary; page returned 403). https://help.openai.com/en/articles/12168547-voice-dictation-faq
- Third-party claims: "Codex uses Whisper"; or `gpt-4o-transcribe` (API key sign-in) / `/backend-api/transcribe` (ChatGPT sign-in). Unverified. https://en.kocpc.com.tw/?p=3236 , https://www.issoh.co.jp/tech/details/12799/
- "ChatGPT dictation now respects your saved Main language preference." (2026-09-11, 26.908) https://learn.chatgpt.com/docs/changelog

### Cleanup & personalization
- "Added dictation cleanup plus a configurable dictation dictionary for names, file paths, and code symbols." (Codex app 26.429, 2026-05-05) https://learn.chatgpt.com/docs/changelog
- "Improved voice and dictation error messages for microphone, connection, and quota failures." Same entry.
- "Improved ... inline dictation." (2026-07-20) Same source.

### Output & editing
- In-app: text lands in the composer, editable before sending. https://learn.chatgpt.com/docs/features/voice
- Global: text inserted at the cursor in other apps ("browsers, Notes, Slack, Obsidian"; Notepad, Slack on Windows). https://en.kocpc.com.tw/?p=3236 , https://www.issoh.co.jp/tech/details/12799/
- "fixed dictation loss" (2026-04-09). https://learn.chatgpt.com/docs/changelog
- History of dictations: none found.

### Beyond dictation
- "ChatGPT Voice" live conversation that can start and steer Codex tasks; "Settings > Voice > Voice chat hotkey"; "Screen context" takes an appshot of the frontmost window. https://learn.chatgpt.com/docs/features/voice
- "ChatGPT Record" for meetings (separate feature). https://help.openai.com/en/articles/11487532-chatgpt-record

### Reception
- Users welcomed dictation arriving on desktop because conversation mode "just didn't cut it". https://community.openai.com/t/huge-thanks-to-openai-for-finally-bringing-dictation-to-the-browser-and-desktop-chatgpt-apps/1230188
- Global dictation broke after update 26.608; fixed for one user in 26.609.30741; another user moved to "WhisperFlow" [sic]. https://community.openai.com/t/global-dictation-in-codex-macos-not-working/1383381
- Mic dictation "does not activate reliably" in the Codex desktop app. https://community.openai.com/t/codex-desktop-app-microphone-dictation-does-not-activate-reliably/1380540
- Older report: dictation sometimes deletes recorded speech without recovery. https://community.openai.com/t/bug-report-on-chatgpt-dictate-button/1238917

### Gaps
- OpenAI's own documentation of the global dictation settings, default keys, and where it is available (only changelog lines and third-party articles found).
- Whether words show live while speaking.
- Size of the dictation quota per plan.
- What "dictation cleanup" does exactly (filler removal? punctuation?).

---

## 4. Windsurf (renamed Devin Desktop)

- Vendor: Cognition (acquired Windsurf July 2025). Rebranded "Devin Desktop" on 2026-06-02 per third-party reports; windsurf.com/changelog now redirects to docs.devin.ai. https://docs.devin.ai/desktop/changelog , https://webreference.com/ai/tools/windsurf/
- Placement: minimal.

### Features
- "Speak to Cascade" / "Voice": "Users can now speak into the chat rather than having to type things out." (v1.11.0, 2025-07-17) https://docs.devin.ai/desktop/changelog , https://devin.ai/blog/windsurf-wave-11
- Current docs: "Use Voice input to use your voice to interact with Cascade. In its current form it can transcribe your speech to text." No shortcut, engine, or plan stated. https://docs.devin.ai/desktop/cascade/cascade
- Cascade is now one of two local agents; new tabs default to "Devin Local"; many legacy Cascade entry points removed; a "Cascade Migration Wizard" exists. https://docs.devin.ai/desktop/changelog , https://docs.devin.ai/desktop/cascade/cascade
- Trigger, live preview, cleanup, vocabulary, privacy, languages: none found (looked at Cascade docs page, Devin Desktop changelog, Wave 11 post).

### Reception
- Third-party dictation vendors disagree on whether Windsurf has a mic at all, which suggests low visibility. https://aquavoice.com/blog/voice-dictation-for-windsurf , https://whispertyping.com/tech/voice-typing-for-windsurf/

### Gaps
- Whether "Devin Local" (the new default agent) has voice input.
- Since Devin Desktop is built on VS Code's code base, whether VS Code's new built-in dictation is present: not verified.

---

## 5. GitHub Copilot (VS Code)

- Vendor: Microsoft / GitHub. URL: https://code.visualstudio.com/docs/configure/accessibility/voice (page footer 10/21/2026)
- Placement: mid, and the strongest built-in developer dictation found: on-device, editor + terminal + chat, optional AI cleanup with custom instructions. Limited to VS Code.
- History: "GitHub Copilot Voice" (formerly "Hey, GitHub!") technical preview ended 2024-04-03; learnings moved into the VS Code Speech extension. https://githubnext.com/projects/copilot-voice , https://visualstudiomagazine.com/articles/2024/03/04/copilot-voice.aspx

### Pricing / gating
- Built-in dictation needs AI features enabled; web dictation needs GitHub sign-in. No plan price stated. https://code.visualstudio.com/docs/configure/accessibility/voice
- Hosted "Voice Mode" (Experimental) "requires an eligible individual GitHub Copilot plan and is not available with Copilot Business or Copilot Enterprise"; or bring your own OpenAI key ("incurs OpenAI usage charges"). Same source.

### Trigger & capture
- Chat dictation `⌘I` (Ctrl+I); editor dictation `⌥⌘V` (Ctrl+Alt+V); "Press and hold a dictation keyboard shortcut to use push-to-talk." Same source.
- Commands: "Voice: Start Dictation in Editor", "Voice: Start Dictation in Terminal". Same source.
- "Hey Code" keyword activation (VS Code Speech extension; `accessibility.voice.keywordActivation`). Same source; https://code.visualstudio.com/updates/v1_87
- Voice Mode `⇧⌘Space`; `agents.voice.handsFree` "starts listening again after the agent finishes speaking." https://code.visualstudio.com/docs/configure/accessibility/voice
- Shared mic selection across chat, editors and terminal. https://code.visualstudio.com/updates/v1_131
- `accessibility.voice.speechTimeout` stops terminal dictation after silence. https://code.visualstudio.com/docs/configure/accessibility/voice

### Transcription engine
- Desktop default `nemotron-3.5-asr-streaming-0.6b`, downloaded on first use, "speech recognition works locally and offline"; web uses cloud model `"mai"` (Microsoft AI voice service). Same source.
- Multilingual on-device model; `agents.voice.language` hint, default `auto`. (1.132) https://github.blog/changelog/2026-08-31-github-copilot-in-vs-code-august-2026-releases/
- Platforms for on-device model: Windows x64/Arm64, macOS Apple silicon, Linux x64/Arm64 (glibc 2.34+), remote workspaces; Intel Macs need the VS Code Speech extension. https://code.visualstudio.com/docs/configure/accessibility/voice
- Offline import of a Foundry Local model package when downloads are blocked (1.132, per search summary). https://code.visualstudio.com/updates/v1_132

### Live preview
- `dictation.showTranscript` "Shows interim transcription while you speak", default `true`; microphone icon appears at the cursor in the editor. https://code.visualstudio.com/docs/configure/accessibility/voice

### Cleanup & formatting
- `dictation.experimental.llmCleanup`: "Uses a language model to improve punctuation, capitalization, paragraphs, lists, and number formatting"; 1.131 notes say Copilot refines the transcript "adding formatting and removing filler words"; transcript text is sent to a model for this step. https://code.visualstudio.com/docs/configure/accessibility/voice , https://code.visualstudio.com/updates/v1_131
- "Add user-level or workspace-level instructions so dictation follows your project terminology and formatting preferences." https://github.blog/changelog/2026-08-31-github-copilot-in-vs-code-august-2026-releases/
- Terminal: "Shell-aware cleanup preserves command syntax instead of inserting spoken punctuation literally"; terminal dictation "removes ordinary punctuation, converts spoken symbol names, and adjusts initial capitalization." Same sources.

### Output & editing
- Dictation "does not submit the request" (no auto-send). https://code.visualstudio.com/docs/configure/accessibility/voice
- Inserts in chat, Agents window, editors, terminal. Same source.
- Other apps outside VS Code: no.

### Privacy
- On-device by default on desktop; 1.136 (2026-09-02) lets administrators require on-device transcription and turn off language-model cleanup. https://code.visualstudio.com/updates/v1_136

### Beyond dictation
- Text-to-speech for chat responses; Voice Mode reads responses aloud (`agents.voice.speakResponses`). https://code.visualstudio.com/docs/configure/accessibility/voice

### Recent changes
- 1.131 (2026-07-29): built-in dictation, experimental, no extension needed. https://code.visualstudio.com/updates/v1_131
- 1.132–1.135 (August 2026): multilingual, custom cleanup instructions, shell-aware terminal cleanup. https://github.blog/changelog/2026-08-31-github-copilot-in-vs-code-august-2026-releases/
- 1.136 (2026-09-02): admin controls. https://code.visualstudio.com/updates/v1_136

### Gaps
- Copilot voice in JetBrains, Visual Studio, Xcode: not checked.
- Model size on disk; latency.
- User reception of the new built-in dictation: none found (too new).
