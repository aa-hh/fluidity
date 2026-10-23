# Developer-specific features in Wispr Flow and Superwhisper

- Date checked: 2026-10-23
- Scope: only the developer angle (code terms, IDE and terminal handling, coding agents). The rest of both apps is covered by another researcher.
- Placement on the gamut (developer angle only):
  - Wispr Flow: full-suite for IDE prompt entry. It reads the editor through accessibility to spell code names, turns spoken filenames into @-tags in Cursor/Windsurf, and special-cases Claude Code and Codex in terminals.
  - Superwhisper: mid for in-editor dictation (no code-name or file-tag features; relies on "Super" mode and custom modes), but full-suite for coding-agent loops (plugins that pop up when Claude Code, Codex etc. need input, plus a CLI and MCP server over your dictation history).

---

## Wispr Flow (Wispr, Inc.) — https://wisprflow.ai/

### Pricing / gating
- "Vibe coding features are available on all plans." https://docs.wisprflow.ai/articles/8554805225-variable-recognition
- Developer landing page shows Flow Pro at $12/user/month with "unlimited dictation", shared dictionary and snippets, 14 days of Pro per teammate before billing. https://wisprflow.ai/developers

### Trigger & capture (developer specifics)
- Default push-to-talk Fn (Mac), Ctrl+Win (Windows); Ctrl+Option on Macs without Apple's Fn key. https://docs.wisprflow.ai/articles/6478598909-using-flow-with-linux-wsl-and-terminal-applications
- "Customizable cancel shortcut": Escape for cancelling dictation is rebindable "If you use Vim, Terminal, or certain IDEs where Escape already does something" (Settings > Shortcuts; changelog entry dated 2026-03-31). https://wisprflow.ai/whats-new

### Code terms and formatting
- "Variable recognition": "Flow uses visible variable, function, and class names to improve recognition"; "user ID" can match `userId`; recognised names "can appear as inline code". Works in "Cursor, Windsurf, and standard VS Code on Mac and Windows". https://docs.wisprflow.ai/articles/8554805225-variable-recognition , https://docs.wisprflow.ai/articles/6434410694-use-flow-with-cursor-vs-code-and-other-ides
  - No toggle in Flow: "it relies on Screen Reader Optimized mode, which you enable in the IDE yourself" (Command Palette "Toggle Screen Reader Accessibility Mode"); Flow Settings → "Vibe coding" → "Set up". Mac needs Accessibility permission "to read IDE context". Same source.
  - Limits: "Recognition quality may be lower on Windows"; "A heavily customized IDE interface can prevent mode detection"; off-screen and very large file content can be skipped; "VS Code Insiders supports neither feature." Same source.
  - Launch post says it also runs automatically in GitHub, terminals and Notion, and covers "camelCase, snake_case, acronyms, CLI commands" (2025-08-28). https://www.producthunt.com/p/wisprflow/flow-gets-syntax-aware-variable-recognition-is-live , https://wisprflow.ai/post/vibe-coding-supercharged
- Marketing claims: "syntax-smart dictation built for developers"; "Gets developer terms, like Supabase or MongoDB"; "Handles camelCase, snake_case, and acronyms"; "Ship 4x faster". https://wisprflow.ai/developers

### IDE handling
- "File Tagging": "Matching filenames become @-tags" in "Cursor and Windsurf AI chat panels only"; on by default (Settings → Vibe coding → "File Tagging in Chat (Cursor & Windsurf)"); no Screen Reader mode needed. Mac and Windows. https://docs.wisprflow.ai/articles/9805771321-file-tagging
  - Say a full filename ("index dot ts"), or "tag", "tagged", "at", "@" before a short name; camelCase match (e.g. cursorFormatting.ts); "my python script" with a trigger tags my_python_script.py; .env via "dot" (Spanish "punto" works); longest match wins; several files per dictation. Same source.
  - Limits: names must contain a dot; "Any dictionary or snippet substitution disables tagging for the entire dictation"; slow autocomplete can pick the wrong file; "Standard VS Code, including with GitHub Copilot, does not support file tagging"; no @-mentions of people in other apps. Same source.
- Windows coding editors: Flow pastes with Shift+Insert instead of Ctrl+V, not configurable. https://docs.wisprflow.ai/articles/6434410694-use-flow-with-cursor-vs-code-and-other-ides
- JetBrains, Xcode, Zed: not mentioned in the IDE article (none found).

### Terminal and coding-agent handling
- Direct paste into Terminal.app, iTerm2, Warp, kitty, Alacritty, Hyper, Ghostty, WezTerm, Windows Terminal, PowerShell, Command Prompt, and VS Code/Cursor/Windsurf integrated terminals; "there is no terminal allow-list". https://docs.wisprflow.ai/articles/6478598909-using-flow-with-linux-wsl-and-terminal-applications
- Coding agent recognition: in a recognised coding agent, Flow "splits long dictations into plain-text sections" and drops rich text. Claude Code: over 600 characters or 3+ line breaks; Codex CLI: over 1000 characters. Mac only per the IDE article ("In Claude Code and Codex CLIs on Mac, Flow pastes long dictations in parts"). Same sources.
- Why: changelog "Dictate into AI coding terminals without your text getting hidden" — longer dictations used to collapse into "[Pasted N lines]"; now text stays "visible and editable" before sending (2026-05-01, v1.5.113). https://wisprflow.ai/whats-new
- In terminals Flow omits special keystroke commands (e.g. Tab) and skips file tagging. https://docs.wisprflow.ai/articles/6478598909-using-flow-with-linux-wsl-and-terminal-applications
- WSL, Linux VMs, remote SSH, Mac VNC: no direct paste; use "Paste last transcript" (Ctrl+Cmd+V Mac, Alt+Shift+Z Windows); "Copy last transcript" (Ctrl+Cmd+C, Alt+Shift+X). "There is no native Linux application." Same source.
- Warnings in docs: paste into an unfocused terminal "goes nowhere with no error"; formatting "can transform shell commands unexpectedly"; clipboard restored about 0.5 s after paste; Windows elevated terminals need "Run Flow as Administrator to insert text everywhere". Same source.

### Prompt entry for AI tools
- "Transforms" (Beta, 2026-05-01): highlight text, press a shortcut; built-ins "Polish" and "Prompt Engineer" ("restructures what you dictated into a well-formatted AI prompt"); custom transforms with any prompt; can run automatically after every dictation. https://wisprflow.ai/whats-new
- "Snippet library": examples "PR Checklist", "Environment Setup", "Internal API docs", "Naming Convention". https://wisprflow.ai/developers
- Personal dictionary "automatically learns your unique words" ("Never misspell Vercel again"). https://wisprflow.ai/developers

### Reception (developer angle)
- Only engagement on the variable recognition launch post: 3 upvotes, 10 comments; a request for Linux ("who do I speak with about a linux version?"). https://www.producthunt.com/p/wisprflow/flow-gets-syntax-aware-variable-recognition-is-live
- An XDA hands-on (via Windows Forum summary) preferred Flow's filler removal and self-correction over Claude Code's built-in voice input; one person's account. https://windowsforum.com/news/wispr-flow-structures-claude-code-prompts-in-mac-hands-on.445194/ (403 to us; seen via search summary only)
- Reported general complaints: deep system access, high CPU and memory (secondary, unlinked). https://eesel.ai/blog/wispr-flow-overview
- A Codex community user recommended Wispr Flow when Codex's global dictation broke. https://community.openai.com/t/global-dictation-in-codex-macos-not-working/1383381

### Gaps
- Whether variable recognition works in JetBrains IDEs or Xcode.
- Whether the Claude Code/Codex splitting applies on Windows.
- Independent accuracy numbers for code terms.

---

## Superwhisper (Super Ultra Inc.) — https://superwhisper.com/

### Pricing / gating
- "Context awareness checkboxes need a Pro license" (the Application / Copied text / Selected text context used by custom modes and Super mode). https://superwhisper.com/docs/modes/custom
- "Free tier that doesn't expire"; Pro with 30-day refund. Gating of CLI, MCP and agent plugins not stated. https://superwhisper.com/blog/cli-mcp , https://superwhisper.com/voice-coding
- Bring-your-own-key models include "GPT 5.5" (2.14.0) and "Opus 4.6 and 4.7" (2.13.2). https://superwhisper.com/changelog

### Code terms and formatting
- No dedicated code mode. Built-in modes are "Message", "Super", "Mail", "Note", "Meeting" (Windows only) and "Voice to Text"; none is coding-specific. https://superwhisper.com/docs/modes/built-in
- "Super" mode: "adapts your dictation to what's on screen" using active app, selected text and clipboard; spelling uses "app-specific terms, names, and vocabulary". Same source. Marketing: in code contexts it "keeps the text technical and tidy"; "Nothing to install inside your editor." https://superwhisper.com/voice-coding
- Super mode context details: selected text captured when recording starts; clipboard counts if copied within about 3 seconds before or during dictation; also sends date/time, your name, computer name. https://superwhisper.com/docs/common-issues/context (per search summary)
- Custom modes: prompt can reference "User Message", "Application Context", "Selected Text", "Clipboard Context"; docs example: "If Application Context shows a code editor: Format the User Message as code comments; Use coding style from Clipboard Context as reference". https://superwhisper.com/docs/modes/custom
- "Vocabulary & Replacements" (redesigned 2.13.0); CSV import for vocabulary (2.14.0). https://superwhisper.com/changelog
- camelCase / variable-name handling, file tagging: none found (looked at built-in modes, custom mode, voice-coding page, Wispr comparison page).

### IDE and terminal handling
- "Superwhisper works system-wide, so it works in any IDE or terminal"; "Cursor, Claude Code, VS Code, Xcode, terminals, all of it." https://superwhisper.com/vs/wispr-flow
- Per-app mode switching: "Activate for apps" in the mode editor ("Add apps and sites") switches modes automatically by app or website; switches back to the last manually chosen mode afterwards. Lets a user bind a code-formatting mode to Cursor or iTerm. https://superwhisper.com/docs/modes/switching-modes , https://superwhisper.com/changelog
- Old fix: "Fix app activation exceptions (WhatsApp, iTerm)" (1.45.3). https://superwhisper.com/changelog
- "Spaces are now added before pasted text if cursor is at end of a sentence". Same source.
- Terminal-specific paste rules (chunking, keystroke stripping): none found.

### Coding-agent integration
- "Superwhisper for Claude Code": control Claude Code "from a single floating window"; "Whenever your agents call, Superwhisper surfaces with the context you need to respond"; agents run in the background across projects. Install: `curl -fsSL https://superwhisper.com/install-claude-code.sh | bash`. "Requires Superwhisper for macOS." Also for OpenCode, Pi, Codex, Grok, DeepSeek. https://superwhisper.com/claude-code
- Plugins "notify you when an agent finishes and let you speak your next instruction back". https://superwhisper.com/blog/cli-mcp
- Settings → Configuration → Advanced settings → "Agent Plugins" (shown only when a supported agent is installed). https://superwhisper.com/docs/get-started/settings-advanced (per search summary)
- Changelog trail: "Integrated Claude Code and Open Code agents" (2.13.0, 2026-04-24); "Added support for Pi coding agent", "Claude hook AskUserQuestion fix" (2.13.2, 2026-04-29); "Added direct coding agent plugin installation capability", "Added Codex hook support" (2.14.0, 2026-05-15); "Polish and refinement of Coding agent panel", "Added a copy button to code snippets in agent responses", "Fixed issues with the Claude Code integration" (2.16.x, June–July 2026); "Grok build is now supported as a coding agent" (2.17.0, 2026-07-29); "Agent plugin support for DeepSeek Harness" (2.18.x); "OpenCode plugin detection now supports OpenCode 1.3 and 2.0" (3.0.2, 2026-10-20). https://superwhisper.com/changelog
- Windows: users report the Claude Code plugin calls Mac-only hooks, so it cannot work on Windows. https://superwhisper.userjot.com/board/p/claude-code-plugin-for-windows
- "Superwhisper CLI & MCP" (2026-07-16): commands `search`, `export` (JSON or Markdown), `stats` (incl. average wpm), `vocab` (vocabulary and replacements), `snippets`, `mcp` (local MCP server). Agents can search and export your dictation history, e.g. to improve your vocabulary. https://superwhisper.com/blog/cli-mcp

### Reception (developer angle)
- Vendor claim: "Andrej Karpathy coined "vibe coding" while using Superwhisper with Cursor." https://superwhisper.com/vs/wispr-flow
- Testimonial: Pieter Levels, "Lets me talk to Cursor and then it codes for me". Same source.
- Windows users asking for the Claude Code plugin. https://superwhisper.userjot.com/board/p/claude-code-plugin-for-windows
- Independent developer reviews of the agent plugins: none found.

### Gaps
- What the "Coding agent panel" shows and whether you can approve tool permissions by voice.
- Whether the CLI/MCP/plugins need Pro.
- Any code-name spelling feature comparable to Wispr's variable recognition.

---

## Side-by-side (developer angle)

| Feature | Wispr Flow | Superwhisper |
|---|---|---|
| Spells code names from the open file | "Variable recognition" (Cursor, Windsurf, VS Code; needs IDE screen-reader mode) | none found; general "Super" mode screen context (Pro) |
| Spoken filename → @-tag | "File Tagging" (Cursor, Windsurf chat only) | none found |
| Per-app mode/format rules | Not covered here | "Activate for apps" per mode |
| Claude Code / Codex terminal paste handling | Splits long text into plain sections (600 chars / 1000 chars), avoids "[Pasted N lines]" | none found |
| Agent notifications + voice reply loop | none found | Plugins for Claude Code, Codex, OpenCode, Pi, Grok, DeepSeek (macOS) |
| Rewrite dictation into an AI prompt | "Prompt Engineer" transform (Beta) | Custom modes with your own prompt |
| Agent access to dictation history | none found | CLI + local MCP server |
| Linux / WSL / SSH | No Linux app; "Paste last transcript" fallback | none found |
