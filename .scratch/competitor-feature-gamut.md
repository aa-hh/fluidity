# Mac dictation apps: the feature gamut from minimal to full-suite

Linear: AA-300. Checked 2026-10-23. One source file per product sits in
`.scratch/competitors/`; every claim below has a URL there.

Scope: tools where you press a key, speak, and the text lands in whatever
app has focus. 26 products inventoried against 13 fixed feature headings,
plus a demand-side study of ~150 user posts and reviews from 2025-2026.

## 1. The gamut in one table

Placement is by what the product does out of the box. Prices are US dollars
unless marked.

| Product | Tier | Price model | Speech runs | Live words while speaking | AI cleanup | Dictionary | Per-app rules |
|---|---|---|---|---|---|---|---|
| Apple Dictation | Minimal (baseline) | Free with macOS | On device (48 languages) | Yes, inline at cursor | No (punctuation only) | No (Voice Control only) | No |
| Yap | Minimal | Free, MIT | Apple's engine, no download | Yes | Apple Intelligence, optional | Yes (bias + first-letter fix) | No |
| BetterDictation | Minimal | $39 to $149 once + $2/mo cleanup | Local Whisper | No | OpenAI (Pro) | No | No |
| Voice Type (Careless Whisper) | Minimal | $19.99 once | Local Whisper | No | Rewrite selected text only | Yes + find/replace | No |
| Whispering (v7.11) | Minimal to low-mid | Free, AGPL, your own key | Local or cloud (your key) | No | Prompt chains (your key) | Prompt field only | No |
| Handy | Minimal, drifting to mid | Free, MIT | Local only, 76 models | Yes (streaming models) | Your key or Apple Intelligence, off by default | Yes ("Custom Words") | No |
| Hex 2.x | Mid (defaults minimal) | Free, MIT | Local only, 8 models | No (by design) | Via OpenCode, off by default | Yes ("Corrections", hints) | Yes ("Modes") |
| Dictato | Mid | €19.99 once | Local only, 4 engines | Preview window | On device (Apple Intelligence or own model) | Yes | Yes, per app and website |
| Voicetypr | Upper mid | $39 to $99 once | Local or cloud (your key) | Yes | "Polish" via your key or Claude Code/Codex login | Yes + snippets | Yes |
| VoiceInk | Upper mid | $25 to $49 once | Local or 16 cloud providers (your key) | Yes (realtime models) | 16 providers incl. on-device "VoiceInk Refine" | Yes + auto-learn | Yes ("Modes", app and URL) |
| Ghost Pepper | Mid, free | Free, MIT | Local only | Not verified | Local Qwen model | Yes + learns from edits | No |
| Voibe Dictation | Mid | $9.90/mo, $99/yr, $199 once | On device or zero-retention cloud | Yes, editable draft (Mac) | Cloud only, does not paraphrase | Yes + "Memory" | No |
| Dictation Daddy | Mid (Dragon replacement) | $8/mo, $99/yr | Cloud only | No | Yes, medical modes | Yes + templates | No |
| MacWhisper | Mid for dictation, full-suite for files | €64 once | Local or ~20 cloud providers (your key) | No | "Dictate with AI Prompts" (Pro) | Yes + global replace | Yes ("App-specific Prompts") |
| Spokenly | Full-suite, power user | Free local; $29 once; $9.99/mo Pro | Local, cloud, or 15 providers (your key) | Yes | Your key, Apple Intelligence, or 768 MB local model | Yes + regex replacements | Yes, app and website, trigger words |
| Superwhisper | Full-suite, power user | $8.49/mo, $84.99/yr, $249.99 once; free local | Local (Whisper, Parakeet, Cohere) or cloud | Yes (Pro, streaming models) | Cloud models included, local "S1-mini" | Yes + replacements | Yes ("Modes", app and site) |
| Monologue | Full-suite, Apple only | $15/mo, $144/yr | Cloud default, local Parakeet option | iOS yes, Mac not documented | Cloud (own model "mono-1") | Yes, imports rivals' lists | Yes ("Modes", app and URL) |
| Willow Voice | Full-suite, lighter | $15/mo, $12/mo yearly | Cloud; "Offline mode" on Pro | No | Cloud, "Frontier Pro/Mini" | Yes + auto-learn + "Shortcuts" | Style presets per category |
| Typeless | Full-suite, cloud only | $12/mo yearly, $30 monthly | Cloud only | No | Cloud, learns your style | Yes, auto-added from edits | Tone per app, automatic |
| Aqua Voice | Full-suite, dictation-focused | $8 to $10/mo Pro, $24 to $30/mo Max | Cloud only ("Avalon") | Yes ("Realtime Mode", Max tier) | Cloud + "Custom Instructions" | Yes + replacements | "Casual Messaging" only |
| Wispr Flow | Full-suite, the benchmark | $15/mo, $12/mo yearly; 2,000 words/week free | Cloud only ("Canto") | No, on purpose | Cloud, 3 levels, "Backtrack" | Yes + auto-learn + snippets | Style per 4 app categories |

Not placed: Talon (hands-free computer control, free, no AI cleanup), Serenade
(voice coding, last commit 2022), Ito (shut down January 2026). Built-in voice
in AI coding tools (Cursor, Claude Code, ChatGPT desktop, Copilot in VS Code)
is covered in section 7.

Two names in the brief did not resolve: "Carelessly" is Voice Type by Careless
Whisper Inc., and voibe.app is now getvoibe.com.

## 2. What every tier has (the floor)

These appear in nearly every product, including the free minimal ones. Missing
any of them draws complaints in reviews.

- Global shortcut that can be rebound. Both hold-to-talk and tap-to-toggle.
  Yap and Apple Dictation are toggle only; BetterDictation's docs disagree
  with themselves about the default key. RSI users ask for toggle because
  "holding a key for 30+ seconds is the exact strain you're trying to avoid."
- Escape cancels. "Paste last transcript" shortcut (Wispr ⌘⌃V, Hex ⌥⇧V, Voibe ⌃⌥V).
- Menu bar app with a hide-Dock-icon option. Launch at login.
- Microphone picker. Yap and BetterDictation lack one and get asked for it.
- Mute or pause other audio while dictating (Wispr, Superwhisper, Handy, Hex, Monologue, VoiceInk, Dictato, Voibe).
- Paste at the cursor via clipboard, then restore the previous clipboard.
  Handy adds "Paste Delay" settings; Hex waits 150 ms in Chromium; Yap tunes
  the restore delay for Electron apps. Getting this wrong is the single most
  cited complaint in the demand study (10 separate sources: "eveything i said was just eaten").
- Automatic punctuation and capitalisation.
- Filler-word removal without AI. Handy and Yap strip a fixed list on device.
- Local history with copy and delete. Hex, Yap and Handy have it; BetterDictation and Voice Type do not and are noted for it.
- First-run flow that walks through Microphone and Accessibility permissions
  (Handy: two cards with a live "Granted" state; Hex: a practice field).
- Signed, notarised direct download plus a Homebrew cask.

## 3. Minimum for a mid-range product

Every product the researchers placed as mid or upper-mid has all of section 2
plus the following. This is the bar VoiceInk ($25 once), Voicetypr ($39 once),
Dictato (€19.99 once), Spokenly (free local tier) and Hex 2.x set in 2026.

### Trigger and capture
- Three activation styles on one shortcut: hold, toggle, and double-tap for
  hands-free (VoiceInk "Toggle / Push to Talk / Hybrid / Double Tap"; Hex
  "Double-tap to lock"; Voibe "double-tap Fn").
- Side-specific modifier keys as the whole shortcut (Right ⌘ is Spokenly's and
  Superwhisper's default; Right ⌥ is Monologue's). Mouse buttons as triggers
  (VoiceInk 2.20, Spokenly 2.24, Superwhisper 2.6, Wispr "Mouse Flow").
- A second shortcut that runs with AI cleanup forced on or off (Handy
  "Post-Processing Hotkey", Voicetypr "Toggle AI formatting").
- Tail buffer so the last word is not cut (Hex keeps 200 ms after release;
  Handy "Extra Recording Buffer"). Pre-roll so the first word is not cut
  (Hex "Keep ready (fast)", Yap buffers audio before the engine is ready).
  First-word clipping is a named complaint for Handy and Wispr.
- Clamshell microphone handling (Handy "Clamshell Microphone", Wispr, VoiceInk 2.11).

### Speech engine
- A model library in the app with download, size, and speed/accuracy labels.
  Minimum set in 2026: NVIDIA Parakeet v3 (25 languages, ~500 MB, the model
  users call "the gold standard" for speed), Parakeet Unified English
  (streaming), Whisper Large v3 Turbo (100 languages, ~1.5 GB), and Apple's
  on-device engine as the zero-download option on macOS 26+.
- Automatic language detection and a per-model language picker.
- "Unload model" timing control (Handy, Superwhisper "Voice model active duration").
- Cloud transcription through the user's own key with at least Groq, OpenAI,
  Deepgram and ElevenLabs, plus any OpenAI-compatible endpoint. Users cite
  Groq's free Whisper tier as a reason to pick an app ("Put a groq API key
  ... they offer generous free limits").

### Live words while speaking
- Shown in a pill or overlay with streaming models (Handy "Live" overlay,
  Spokenly "Capsule", VoiceInk "Live Text Display", Voibe "Live Dictation").
  No live words is dealbreaker number 5 in the demand study (7 sources:
  "i lose my train of thought"). Wispr omits it on purpose and gets asked
  for it on every channel.

### Cleanup
- Switchable AI cleanup with an editable prompt and example pairs
  (Superwhisper "Custom Mode", VoiceInk prompt templates, Ghost Pepper
  "Input / Output" examples).
- The prompt must handle: filler words, self-corrections ("no wait, I meant",
  "scratch that"), spoken numbers to digits, enumerations to lists, paragraph
  breaks. Typeless calls this "Auto-edits when you change your mind"; Wispr
  "Backtrack"; Spokenly "applies corrections you say out loud".
- A fully on-device cleanup route: Apple Intelligence on macOS 26 (Yap,
  Handy, Spokenly, MacWhisper, Dictato) or a bundled small model (Spokenly
  "Spokenly Cleanup 1", 768 MB, ~0.2 s; VoiceInk "VoiceInk Refine";
  Superwhisper "S1-mini", 462 MB; Ghost Pepper Qwen 0.8B).
- "Does not paraphrase" as a guarantee or a mode (Voibe; Voicetypr "Keep my
  words"; Wispr "Light" level). Over-editing is dealbreaker number 2
  ("changing the meaning of what I say, sometimes to the opposite").
- Skip cleanup for very short dictations (VoiceInk skips for "yes").
- Smart spacing and capitalisation from the characters around the cursor
  (Spokenly "Smart Spacing", Aqua "Inline Text Normalization", Monologue).

### Personalisation
- Dictionary of words and names fed to the model as hints, plus a separate
  spoken-to-written replacement list (Superwhisper "Vocabulary" and
  "Replacements"; VoiceInk "Word Replacements"; Hex "Corrections"). CSV
  import and export.
- Spoken trigger phrases that insert saved text (Voicetypr "Snippets", Voibe
  "Memory", Dictation Daddy "Templates", Wispr "Snippets", Willow
  "Shortcuts"). A replacement list covers this at minimum.
- Per-app and per-website profiles that switch model, prompt, language and
  output behaviour (VoiceInk "Modes", Dictato "Profiles", Hex "Modes",
  Spokenly, MacWhisper "App-specific Prompts"). Website rules need the
  browser's Automation permission; Dictato covers seven browsers, Hex only Brave.
- Mode switching during a dictation by number key (VoiceInk ⌥1-9, Monologue
  right Shift picker, Superwhisper ⌥⇧K) or by a spoken trigger word
  (VoiceInk, Spokenly).

### Output
- Paste method choice for apps that reject ⌘V: simulated typing, AppleScript,
  or ⌃⇧V for terminals (VoiceInk "Paste Method", Handy, Hex "Terminal paste",
  Superwhisper "Simulate keypresses"). Terminals, VS Code and remote desktops
  are dealbreaker number 11.
- "Auto Send": press Return, ⌘Return or ⇧Return after paste, and Return while
  recording to stop and deliver (VoiceInk, Handy "Auto Submit", Spokenly
  "Quick Send", Monologue "Auto enter").
- Clipboard: keep the user's clipboard, mark the paste transient so clipboard
  managers skip it (Hex), option to also leave text on the clipboard.
- History: full-text search, audio playback, re-transcribe with another
  model, paste destination recorded, retention settings down to "never
  save audio" (Superwhisper, VoiceInk, Spokenly, Voicetypr).
- Fallback when no text field has focus: floating panel with the text and
  a copy button (Spokenly 2.26, Superwhisper "Close after transcription",
  Monologue "Copied / App changed").

### Privacy
- A documented fully-offline path, and a plain list of every network call
  the app makes (Handy's privacy page, Yap's README, Dictato's site, Voibe's
  cloud page name their providers). Users check for this; the April 2026
  investigation of Wispr Flow's background logging is cited in switching
  posts.
- Telemetry off or opt-in. Hex and Voice Type collect none; Spokenly's
  "Local Only Mode" blocks all traffic except model downloads.

### Pricing
- One-time purchase in the $25 to $65 band, by device count (VoiceInk
  $25/$39/$49; Voicetypr $39/$69/$99; MacWhisper €64; Spokenly Local+ $29),
  or free local use with cloud and extras paid. 7-day trial, 14-day refund.
  Users call this band fair; a subscription for models that run on their
  own Mac is dealbreaker number 3 ("Subscribe even for local models? Wth").

### Platform
- Apple Silicon, macOS 14 or 15 minimum. Intel is dropped or cloud-only
  across the mid tier. 8 GB RAM recommended.

## 4. Expected at the high range

Everything in section 3, plus the following. Wispr Flow, Superwhisper, Aqua,
Willow, Monologue, Typeless and Spokenly Pro have most of this list; no single
product has all of it.

### Engine and speed
- An in-house or tuned speech model with a published benchmark: Wispr "Canto",
  Superwhisper "S1-Voice" (6.6% word error rate claimed), Aqua "Avalon",
  Monologue "mono-1" (7.22% WER, 109 ms median), Willow "Frontier Pro".
- Latency under a second from key release to pasted text (Aqua: "final text
  in about 450ms"; Hex 2.3: 0.1 s after release by streaming internally;
  Baseten reports under 700 ms p99 for Wispr). Over about 1 s is dealbreaker
  number 6 ("if dictation doesnt feel instant I stop using it").
- Provider redundancy or local fallback when the cloud fails (Wispr
  2026-06-04, Voibe "Automatic Fallback to Local", Spokenly "Keep dictating
  when a transcription provider goes down").
- 20-minute dictation sessions (Wispr; Typeless 9 min; Voibe 5 min; Willow
  8 min on Pro).

### Live words and editing before paste
- Streaming words that resolve into clean text while you speak, and spoken
  mid-dictation corrections that change the live text (Aqua "Realtime Mode":
  "change Thursday to Friday").
- An editable live draft you can click into before it lands (Voibe "Live
  Dictation": "a real text box, not a preview"; Dictato preview window).

### Voice editing and rewriting
- Select text in any app and speak the change, with no extra hotkey (Aqua
  "Edit Mode", Willow "Edit with Scribe", Typeless "Speak to edit", Wispr
  "Command Mode" on Pro, Superwhisper "Super" mode commands).
- Rewrite shortcuts with built-in and custom prompts, each on its own key
  (Wispr "Transforms": "Polish" ⌥1, "Prompt Engineer" ⌥2, "View Diff" ⌥O,
  up to 8 custom; Typeless "Ask anything"; Dictato "Tones", nine styles).
- Compose from intent: speak what the message should do and get the message
  (Willow "Willow Scribe", Typeless "Help me write", Ito "Intelligent Mode").
- Translate on the fly to a target language (Typeless "Translate" with preset
  targets; Superwhisper to English; Voicetypr "Final text language").

### Style and context
- Tone per app category with presets (Wispr "Flow Styles": Formal / Casual /
  very casual / Excited across Personal, Work, Email, Other; Willow has 15
  presets; Superwhisper "Tone" slider).
- Learning the user's style from their writing (Willow "Smart memory of your
  writing style", Typeless "Personalization progress").
- Context from the text around the cursor, selected text, clipboard, app name
  and site (Wispr "Context Awareness", Superwhisper, Spokenly, VoiceInk).
  Screen reading by OCR or screenshot (Aqua "Deep Context", Monologue
  "Deep context", VoiceInk "Screen", Ghost Pepper). Both are privacy
  flashpoints: Wispr's docs now say it "does not take screenshots", and Aqua
  ships Deep Context off by default.
- Dictionary that learns from edits made after paste (Wispr "auto-learn
  words", Willow "Auto-learning dictionary", Typeless "Auto-added",
  VoiceInk "Auto-Learn Dictionary" with a review queue, Ghost Pepper
  re-reads the field 15 s later). Dictionary import from rivals (Monologue
  imports Wispr, Superwhisper, Aqua, Willow lists).
- Rich-text snippets (Wispr, 4,000 characters, bold and links).

### Send and command
- End a dictation with a spoken "send it" that presses the right key for the
  app: Enter in Slack, ⌘Enter in Gmail (Aqua, Max tier, six languages).
- Spoken structure commands: "new line", "new paragraph", "bullet point",
  "start numbered list" (Voibe "Structure By Voice", Willow, Wispr,
  Dictation Daddy, Apple). Superwhisper, Typeless and Aqua do not document
  these, and users notice ("I need to use command for punctuation").
- Spoken actions beyond text (Spokenly "Agentic Actions": search, open site,
  launch app, Apple Shortcut, shell command; Hex "Voice commands" with a
  separate always-on command model; Wispr Command Mode web search).

### Developer features
- Spell code names from the open file (Wispr "Variable recognition", needs
  the IDE's screen-reader mode; Voibe "Developer Mode" IDE extension sends
  file and symbol names).
- Spoken filenames become @-tags in Cursor and Windsurf chat (Wispr and Aqua
  "File Tagging").
- Long dictations split so Claude Code and Codex do not collapse them into
  "[Pasted N lines]" (Wispr: over 600 and 1,000 characters).
- Coding-agent plugins that pop up when the agent needs input and take a
  spoken answer (Superwhisper for Claude Code, Codex, OpenCode, Pi, Grok,
  DeepSeek).
- A command-line tool and an MCP server so agents can search dictation
  history, edit the dictionary, or ask the user a question by voice
  (Superwhisper CLI and MCP; Aqua MCP and CLI; Spokenly "Voice for Agents"
  with `ask_user_dictation`; Hex `hex mcp`; Voicetypr CLI).

### Beyond dictation
- Meeting recording without a bot: mic plus system audio, speaker labels,
  summaries, calendar detection, local option (Superwhisper "Meetings" 3.0,
  Wispr "Notetaker", Monologue "Bot-free meeting notes", Voibe Work, Hex
  Meetings beta, Spokenly, MacWhisper, Ghost Pepper).
- File transcription with subtitle export (Superwhisper, MacWhisper,
  Spokenly, VoiceInk, Voicetypr, Dictation Daddy, Aqua CLI). Wispr cannot.
- Notes and quick capture (Wispr "Scratchpad", Monologue "Voice Notes",
  VoiceInk journal, Willow iOS notes).
- Usage stats and a "words per minute / time saved" card (Wispr "Insights",
  Superwhisper, Aqua "Wrapped", Ito streaks).

### Platforms and sync
- Windows and an iPhone keyboard on one licence (Wispr, Superwhisper, Aqua,
  Willow, Typeless, Spokenly). Mac-only is dealbreaker number 8.
- Sync of dictionary, snippets, modes and settings, never of transcripts or
  audio (Wispr, Aqua "Setting Sync", Monologue, Spokenly "Sync Settings",
  Superwhisper "Filesync"). iPhone action-button and Shortcuts triggers
  (Aqua, Monologue, Spokenly).

### Trust, teams, compliance
- Published providers and zero-data-retention terms with each; training
  opt-out that is off by default on business tiers (Wispr since 2026-10-02).
- SOC 2 Type II, ISO 27001, HIPAA with a BAA, enforced "privacy mode" for the
  whole organisation (Wispr, Superwhisper, Aqua, Willow, Typeless).
- Team tier with shared dictionary and snippets, SSO/SAML, SCIM, MDM
  deployment, admin lock of context awareness and cloud models (Wispr Growth
  $18 to $26, Aqua Business $19 to $24 per seat, Spokenly MDM-enforced
  "Local Only Mode").
- A written accessibility statement. Only Wispr publishes one (VoiceOver,
  NVDA, JAWS, TalkBack tested, with known gaps listed). Blind users report
  that third-party dictation apps rarely work with VoiceOver; none of the 13
  comparison articles tests it.

### Pricing at the high range
- $12 per month billed yearly, $15 monthly (Wispr, Willow, Monologue,
  Typeless). Cheaper subscriptions at $8 to $10 (Aqua Pro, Superwhisper,
  Spokenly Pro, Dictation Daddy). Free tiers cap words: 2,000 per week
  (Wispr desktop, Typeless), 1,000 once (Aqua, Monologue).
- No lifetime licence and no bring-your-own-key at the cloud-only vendors.
  Superwhisper's $249.99 lifetime is the one exception and users call it
  "absolutely crazy".
- Student discounts of 40% to 70% everywhere.

## 5. What users punish and reward

From the demand study (`.scratch/competitors/demand-side.md`), ranked by how
many separate sources raised each.

Dealbreakers:
1. Text recorded but never pasted, or needs a restart (10 sources).
2. Accuracy drops after updates, or cleanup rewrites meaning (8).
3. Subscription for models that run on the Mac (8).
4. Cloud-only processing and background logging (8).
5. No live words while speaking (7).
6. Delay over about one second (6).
7. Punctuation, capitals and spoken commands wrong (6).
8. Mac-only (6).
9. Hotkeys that cannot be changed or that steal Escape (5).
10. Dictionary entries ignored (5).
11. Breaks in terminals, VS Code, remote desktop, banking apps (5).
12. Weekly word caps that change without notice (4).

Delighters:
1. Cleanup that removes the need to think about pauses, "um" and punctuation (6).
2. Speed that feels instant, credited to Parakeet on the Mac (5).
3. Pay once in the $25 to $65 band (6).
4. Speech that never leaves the Mac (4).
5. A free route through the user's own Groq key (3).
6. Fast fixes and a reachable developer (4).
7. Context awareness and per-app styles (3).
8. Starting dictation from a Stream Deck, foot pedal or Bluetooth remote (3).
9. Easy first run (2).

Accessibility demand is specific: toggle over hold for RSI, offline as a
requirement not a preference, VoiceOver support decides the choice for
blind users, and full voice control ("I wouldn't be using my voice if my
hands worked!") is what dictation-only apps leave undone.

## 6. Where Fluidity's confirmed decisions land

PRODUCT.md fixes three things: local models by default, optional cloud
cleanup through the user's own key, and user word lists. That is the
VoiceInk / Spokenly / Handy band: upper-mid, one-time or free pricing, and
the band users are moving into from Wispr Flow subscriptions.

What that band already has that is not yet in Fluidity's confirmed list,
in the order the demand study ranks it:
- Hold, toggle and double-tap hands-free on one shortcut; side-specific
  modifiers; mouse buttons.
- A model library with Parakeet v3, Parakeet Unified (streaming), Whisper
  Large v3 Turbo and Apple's engine.
- An on-device cleanup route (Apple Intelligence on macOS 26, or a bundled
  small model) so cleanup works offline too.
- Spoken-to-written replacements alongside the word list; CSV import.
- Per-app modes.
- Searchable history with audio playback and re-transcribe.
- Paste method fallbacks for terminals and Electron apps; auto-send.
- A published list of every network call.

The live preview pill in DESIGN.md already covers dealbreaker 5, which
Wispr, Willow, Typeless and Hex all lack.

Things the high range has that no mid-range product has yet, so they are
open ground rather than table stakes: editable live draft before paste
(only Voibe), spoken "send it" (only Aqua, Max tier), an accessibility
statement (only Wispr).

## 7. What a developer already gets without a separate app

- Claude Code: `/voice`, hold or tap Space, live dimmed text, 20 languages,
  project name and git branch sent as hints, streamed to Anthropic's servers,
  not counted toward usage. Prompt box only.
- Claude desktop: mic icon; Caps Lock dictation only in Quick Entry.
- ChatGPT desktop (with Codex): the one overlap with Fluidity. "Global
  dictation" into any Mac or Windows app with hold and toggle shortcuts (off
  by default), "dictation cleanup" and a "dictation dictionary for names,
  file paths, and code symbols" since 2026-05-05. Has an undocumented usage
  cap ("Codex dictation usage limit reached").
- VS Code with Copilot: on-device `nemotron-3.5-asr-streaming-0.6b` since
  1.131 (July 2026), live words, works in editor, terminal and chat,
  optional cleanup with per-project instructions, shell-aware terminal
  cleanup. VS Code only.
- Cursor: hold Ctrl+M in the Agents Window, batch transcription, no live
  words, no cleanup. Windsurf (now Devin Desktop): a mic button.

## 8. Caveats

- Reddit blocked direct fetching; the demand study read threads through an
  archive, and most September to October 2026 r/WisprFlow complaint posts
  were removed, so only their titles are cited.
- X and Product Hunt review pages could not be fetched.
- Several vendor sites contradict themselves (Willow team pricing and
  language count, Dictation Daddy HIPAA claims, VoiceInk minimum macOS,
  BetterDictation default shortcut). Each product file lists these under
  "Gaps".
- Whispering's current main branch has dropped system-wide dictation; the
  inventory covers its last release (v7.11.0, December 2025).
- Prices and free limits change often: Typeless cut free words from 8,000 to
  2,000 per week in September 2026; Monologue went from $10 to $15 per month
  between May and October 2026; Aqua moved Realtime Mode from Pro to Max.
