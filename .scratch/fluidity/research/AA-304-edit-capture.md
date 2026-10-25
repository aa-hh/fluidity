# AA-304: capturing the user's corrections after a paste

Researched 25 Oct 2026. Sources: VoiceInk at commit [`b6f5baf`][vi], the local FluidWispr copy (`/Users/alechenderson/Projects/FluidWispr`, commit `0f1381a`, a fork of [altic-dev/Fluid-oss][fo]), Electron source at [`96a2dc1`][el], Apple and Swift docs, Wispr Flow's local database (schema and counts only, no dictated text), and two papers. VoiceInk and FluidWispr are GPL-3.0: ideas below, no code copied.

Terms used:
- **R** raw transcript (speech-to-text output), **C** cleaned text (cleanup output, or R if cleanup fell back), **P** pasted text, **F** the pasted part of the field when watching ends.
- **Span**: a run of neighbouring words that changed between two versions, found by word alignment (lining up two word lists and marking each word as kept, removed, added or swapped).
- **Accessibility (AX)**: the macOS interface screen readers use to read other apps' text fields.

## Answer

### What counts as an edit

Check the categories in this order; the first match wins. Every check runs on words, never on keystrokes.

| # | Category | Detection rule (on P → F, traced back through C and R) | Trains |
|---|---|---|---|
| 1 | Edit made by the app itself | Change appears before the baseline settles, or is a known app rewrite (smart quotes, dashes, Markdown conversion). Normalise these away before comparing. | ignore |
| 2 | Text added before or after | All of P survives, in order and in one piece, inside F; the new words sit only before or after it. Cut them off and compare the rest. | ignore |
| 3 | Whole dictation deleted or replaced | Fewer than half of P's words survive in F, or F is empty while the field still has focus. | ignore (count it as a rejected dictation) |
| 4 | Punctuation or capitalisation only | Words match once lower-cased with punctuation stripped; only the punctuation or case layer differs. | cleanup |
| 5 | Filler or stutter the cleanup left in | Only words were removed (1–3 words); they are in R and C; they are a filler word (um, uh, like, you know, I mean), repeat the word next to them, or are a false start right before a repeated phrase. | cleanup |
| 6 | Word the cleanup wrongly removed or changed, restored by the user | The added words are present in R at that aligned position, absent from C, and back in F. | cleanup |
| 7 | Word the cleanup introduced and the user fixed | The removed words are absent from R (cleanup added them) and the new words are not a sound-alike of them. | cleanup |
| 8 | Misheard word fixed | A swap of 1–3 words for 1–3 words; the old words are in R (speech-to-text produced them); the new words appear in neither R nor C; the old and new words sound or look alike (character similarity ≥ 0.5, or matching phonetic code). | speech-to-text (and dictionary) |
| 9 | Rephrasing or rewrite | Anything else: spans longer than 3 words, swaps that do not sound alike, or more than 30% of P's words changed overall. | ignore |

Fix versus rewrite, as starting thresholds (mine, to tune on real data): a span of at most 3 words on each side; at most 30% of the dictation's words changed; at most 4 spans. If any span in a dictation is a rewrite (category 9), keep the dictation out of speech-to-text training altogether. Google found that training on every user edit "quickly and dramatically degraded" its speech model, and only edits filtered to likely misrecognitions were safe ([Zhou et al. 2023, §4.2][gof]).

### When to watch

- **Before the paste:** turn on Electron's accessibility tree when dictation starts by setting `AXManualAccessibility` on the app (FluidWispr does this, see §2).
- **Baseline:** read the focused field every 50 ms for up to 1 s after Cmd-V. Accept the first read where the element is the one focused at dictation start, the value contains P, and the caret sits at the end of P. Pasted range = caret − length of P. If no read matches, record `paste_not_found` and stop.
- **While watching:** subscribe to `kAXValueChangedNotification` and `kAXSelectedTextChangedNotification` on the field and `kAXFocusedUIElementChangedNotification` on the app. Add a 500 ms safety poll. On every change, re-read the value and keep the last value in which the pasted range can still be found.
- **Stop when:** (a) the field no longer contains the pasted range (the user pressed Enter and the composer cleared, or deleted it): use the last good value; (b) focus has left the field for 250 ms; (c) a new dictation starts: finish the old one first; (d) 60 s pass; (e) the text on either side of the range is no longer found exactly once: discard.
- **Enter in Claude's composer:** no key monitoring is needed. Each edit fires a value change, so the value just before the field empties is already in hand. A key monitor could not read the field "just before" anyway: Apple delivers global key events asynchronously and read-only ([Apple][ns]). Input Monitoring is not required by this design.

### How to compare

Normalise text (Unicode NFC, non-breaking spaces to spaces, drop zero-width characters, unify line endings, straight quotes). Split into word tokens and punctuation tokens. Align R↔C, C↔P and P↔F on lower-cased words with Swift's `difference(from:)`, which runs Myers' diff ([Swift source][sw]). Group changes into spans, trace each span in F back to its words in C and R, and apply the table. Save one record per dictation, with one entry per span (§3).

## 1. Categories in detail

**Why the order matters.** App edits, additions and whole replacements are removed first, so the later checks only see real edits inside P. Punctuation-only changes are checked before word changes, so "its" → "it's" is not called a misheard word.

**Telling whose mistake it was** comes from where the old word came from:
- old word in R and C, new word in neither, sounds alike → the speech model misheard it (8);
- old word in C but not in R → the cleanup put it there (7);
- new word in R but not in C → the cleanup removed something the user wanted (6);
- removed word in R and C, and it is a filler or repeat → the cleanup should have removed it (5).

**Sound-alike check for category 8.** Use character similarity: 1 − (Levenshtein distance ÷ length of the longer word), where Levenshtein distance is the number of single-letter inserts, deletes and swaps between two words. Add a phonetic code such as Double Metaphone, which gives words that sound alike the same short code, to catch respellings. Because Parakeet TDT v2 gives word timestamps by default ([model card][pk]), each fix can also store the audio time of the misheard word, which lets a later check compare the sounds directly.

**What the prior art filters out:**
- FluidWispr accepts only single-word fixes, at least 2 letters, at most 40 characters, and rejects English inflections such as adding `s`, `ed` or `ing` (`Sources/Fluid/Services/DictionaryCorrectionEditPolicy.swift:6-42`, `AutomaticDictionaryCorrectionDetector.swift:210-236`).
- VoiceInk accepts exactly one changed span per dictation, at most 24 tokens, at most 5 words a side, no commas in the old text ([`CorrectionDiffEngine.swift:4-20`][vi-cde], [`AutoLearnLocalReviewer.swift:4-23`][vi-rev]).
- Wispr Flow picks at most 4 changed words, groups phrases of up to 4 words, drops stopwords, and asks a server model which are real vocabulary (`wispr-flow-teardown/evidence/js-pipeline.md:232-238`).

All three only feed a dictionary. None trains a speech model from the edits, so their filters are stricter than Fluidity needs for the cleanup step and about right for the speech model.

**Base rates from Wispr's database on this Mac** (286 dictations; read-only, counts only): 170 had a recorded end of watching, and 17 of those (10%) had any edit. Of the 17 edit distances, 13 were at most 0.22 and 3 were 0.99 or 1.0 (whole replacement), with nothing between 0.37 and 0.99. That gap supports a clear cut-off for category 3. Claude desktop: 141 dictations, 117 watched, 15 edited.

## 2. Watching window

**Turning on Chromium's tree.** Electron's app object answers two attributes: `AXManualAccessibility`, which "Electron specifically allows third-party apps to use", and `AXEnhancedUserInterface`, described in the source as "an undocumented attribute that screen reader related functionality sets". Both switch the renderer to full accessibility mode after a delay ([`electron_application.mm:249-268`][el-app]); Electron's docs name only the first ([Electron docs][el-doc]). Reading the app's role alone already switches on a basic tree ([same file, 270-281][el-app]). Prefer `AXManualAccessibility`, set it at dictation start, and keep the per-app result as FluidWispr does (`Sources/Fluid/Services/ElectronAccessibility.swift:15-37`). VoiceInk sets it only for the watching period and turns it off again afterwards ([`AccessibilityTextReader.swift:95-100, 243-253`][vi-axr]).

**Claude desktop exposes the field.** A read-only probe on this Mac (lengths and attribute names only) found Claude's composers as role `AXGroup` with a settable `AXValue`, `AXSelectedTextRange`, `AXNumberOfCharacters`, and `AXStringForRange`. The fields were empty at the time, so reading a filled composer is still unverified (see Not established). VoiceInk also falls back to Chromium's text-marker attributes (`AXStringForTextMarkerRange`) when `AXValue` is missing ([`AccessibilityTextReader.swift:42-49`][vi-axr]).

**Confirming the paste landed.**
- FluidWispr tries 20 times, 50 ms apart. It accepts the field only if the caret is a plain cursor and the text just before it equals P ([`AutomaticDictionaryCorrectionTracker.swift`, `captureAnchoredInsertion`][fw]).
- Its separate paste check reads the field at 0.15, 0.5 and 1.5 s and accepts a rise in the count of P, a character count up by P's length, or a caret moved by P's length (`PasteVerifier.swift:69-170`).
- VoiceInk waits 120 ms, then reads once ([`AutoLearnTypes.swift:100-111`][vi-types]).

Use FluidWispr's caret rule, with its count and caret checks as fallbacks.

**Tracking the range when text before it changes.** There are two methods in the prior art:
- FluidWispr diffs each new value against the previous one by common start and end. It shifts the range when the change lies before it, grows or shrinks it when the change lies inside, and stops if a change straddles the edge (`AutomaticDictionaryCorrectionDetector.swift:32-84`, tracker `handleObservedValueChange`).
- VoiceInk keeps the baseline and, at the end, looks up the 16 characters before and after the range in the final text. Each must be found exactly once, or the result is discarded ([`FinalSnapshotDiffEngine.swift:4-91`][vi-fsd]).

Do both: shift the range on every change, then confirm with the 16-character text on each side at the end.

**Notifications or polling.** FluidWispr listens for value, selection and focus changes, and re-reads the value on selection change because "web-backed editors may move the caret without emitting a value-change notification" (tracker callback, end of file). VoiceInk uses no value notifications. It only listens for focus, window and app-deactivate events, and takes one final read ([`AutoLearnFocusObserver.swift:99-110`][vi-fo]). The cost is small either way: each read is one cross-process call. Both projects cap it with `AXUIElementSetMessagingTimeout` (0.1–0.25 s), and a 2-per-second poll for 60 s is 120 reads.

**Enter and the cleared field.** This is the most common way watching ends. In Wispr's data 80 of 170 watches ended with `trailing_newline_added`, most with last key `return`. Next come `next_paste_started` 24, `dictated_text_not_found` 16, `observation_window_elapsed` 16, `anchor_mismatch_transcript_intact` 14, `textbox_emptied` 11 and `anchor_mismatch` 9. The edit came from the last value read before the send, not from a read after it.
- VoiceInk takes its final read only on focus loss, at 60 s or at the next paste. After Enter clears the field, the anchors fail and the edit is lost; for its own auto-send it discards the watch on purpose ([`AutoLearnService.swift:223-388`][vi-svc]).
- Keeping the last good value on every change avoids this.

**Without Input Monitoring.** Input Monitoring is the macOS permission for listening to all key presses. Apple's docs say a global key monitor (`NSEvent.addGlobalMonitorForEvents`) needs only Accessibility trust ([Apple][ns]). The design above uses no key events at all. FluidWispr checks whether the user typed since the paste with `CGEventSource.secondsSinceLastEventType`, which gives a time without the key itself (`PasteVerifier.swift:79-92`). That is useful to tell app edits (category 1) from user edits.

## 3. Comparison method

**Tokenising.** Words: runs of letters and digits, keeping inner apostrophes and hyphens (`don't`, `on-device`). Every punctuation mark is its own token. Compare twice:
- the **word layer**: lower-cased words only, for categories 2, 3 and 5–9;
- the **surface layer**: original case plus punctuation, for category 4.

Wispr stores the same split: one letter per word for word edits and one for punctuation edits (M kept, S swapped, I added, D deleted; seen in `userEditMetaData`, letters only).

**Aligning.** Swift's `difference(from:)` on `[String]` gives removals and insertions by position, using a linear-space Myers diff ([Diffing.swift][sw]). VoiceInk groups the result into spans the same way ([`CorrectionDiffEngine.swift:210-280`][vi-cde]). Run three alignments: R↔C, C↔P (normally identical; differences come from Fluidity's own finishing rules) and P↔F. Map each P↔F span back to C and R through the alignments.

**Record per dictation** (one row, with corrections as a list):
- ids and context: dictation id, app bundle id, paste time, watch end time, end reason (`sent`, `focus_left`, `next_dictation`, `timeout`, `anchor_lost`, `paste_not_found`);
- texts: R, C, P, F (pasted range only, never the rest of the field), and whether cleanup fell back to R;
- totals: share of P's words changed, number of spans, character edit distance P→F, whether the user typed after the paste;
- per span: category, word positions in R, C, P and F, old words, new words, character similarity, phonetic match, audio start and end of the old words from Parakeet's timestamps.

**Training targets from the record.**
- Speech-to-text: the audio, with R plus category-8 fixes as the target. Use only dictations with no category-9 span. Mix in ordinary data so the model does not forget: Google got an 11% gain on rare words and "little or no regression" only by also training on the original data ([Zhou et al. 2023, §4.1–4.3][gof]).
- Cleanup: input R, target C plus fixes from categories 4–7. Category-8 fixes stay out of the target by default, so the cleanup model is not taught to guess at misheard words.

## 4. Prior art

- **Wispr Flow 1.6.1209.** It watches for up to 60 s with a value observer and a key tap, and returns `pastedText`, `editedText`, `contentObservationEndReason`, `editDistanceToDictated` and a keystroke trace (`wispr-flow-teardown/evidence/swift-helper.md:87`, `js-pipeline.md:232-238`). Database columns for edits: `editedText`, `editedTextUnbounded`, `pastedText`, `userEditMetaData` (`word_edits`, `punctuation_edits`), `editDistanceToDictated`, `contentObservationEndReason`, `contentObservationEndLastKeystroke`, `numWordsCorrected`, `hasRevertedAI`, `formattingDivergenceScore`. Last-key values seen: `return`, `backspace`, `delete_word`, `delete_line`, `select_all_delete`, `cmd_x`.
- **VoiceInk AutoLearn.** It takes one baseline and one final snapshot and works out the edit from the 16 characters on either side of the paste. It accepts one span only and proposes dictionary replacements the user must approve ([folder][vi-dir]).
- **FluidWispr / Fluid-oss.** It follows each change live, keeps track of the pasted range, accepts single words only, and suggests a word only after it has seen the same fix twice within 7 days (`AutomaticDictionaryCorrectionTracker.swift:5-12`). It watches for 30 s and waits 1 s after the edit settles (3 s if the caret is still on the word).
- **Literature.**
  - Yu et al., Interspeech 2004: dictation software that first decides "whether the user is correcting an error or editing the text", then learns new words and pronunciations, for over 10% relative fewer word errors ([ISCA][yu]).
  - Zhou et al. (Google), ASRU 2023: training examples are the audio, the model's transcript and "the final text committed by the user after any edits". Unfiltered edits hurt the model; a word-list filter and replay of the original data fixed it ([arXiv 2310.00141][gof]).
  - Wispr says its Canto model folds likely fixes into its reference transcripts (`wispr-flow-teardown/README.md`, section 1).

## Not established

- Whether Claude's composer reports the full typed text in `AXValue` once it holds text, and whether Enter-to-send fires a value change before the clear. The probe only saw empty composers. Next step: dictate into Claude with a logger that records value lengths per notification.
- Why Wispr names its most common end reason `trailing_newline_added`: perhaps the composer briefly holds a newline before clearing. Unverified.
- What Wispr's `numWordsCorrected` counts: 48 rows have it above 0 with no user edit, so it is not user edits.
- Whether `CGEventSource.secondsSinceLastEventType` needs any permission on macOS 27.
- Which phonetic code works best for names and product terms. The 0.5 similarity, 3-word, 30% and 4-span thresholds are untested starting values.
- How often Claude's composer rewrites pasted text itself (Markdown, smart quotes).

[vi]: https://github.com/Beingpax/VoiceInk/tree/b6f5baff7d95b8a7696c8f488226e9da5e468e7a
[vi-dir]: https://github.com/Beingpax/VoiceInk/tree/b6f5baff7d95b8a7696c8f488226e9da5e468e7a/VoiceInk/Features/Dictionary/AutoLearn
[vi-cde]: https://github.com/Beingpax/VoiceInk/blob/b6f5baff7d95b8a7696c8f488226e9da5e468e7a/VoiceInk/Features/Dictionary/AutoLearn/CorrectionDiffEngine.swift
[vi-rev]: https://github.com/Beingpax/VoiceInk/blob/b6f5baff7d95b8a7696c8f488226e9da5e468e7a/VoiceInk/Features/Dictionary/AutoLearn/AutoLearnLocalReviewer.swift
[vi-fsd]: https://github.com/Beingpax/VoiceInk/blob/b6f5baff7d95b8a7696c8f488226e9da5e468e7a/VoiceInk/Features/Dictionary/AutoLearn/FinalSnapshotDiffEngine.swift
[vi-types]: https://github.com/Beingpax/VoiceInk/blob/b6f5baff7d95b8a7696c8f488226e9da5e468e7a/VoiceInk/Features/Dictionary/AutoLearn/AutoLearnTypes.swift
[vi-svc]: https://github.com/Beingpax/VoiceInk/blob/b6f5baff7d95b8a7696c8f488226e9da5e468e7a/VoiceInk/Features/Dictionary/AutoLearn/AutoLearnService.swift
[vi-fo]: https://github.com/Beingpax/VoiceInk/blob/b6f5baff7d95b8a7696c8f488226e9da5e468e7a/VoiceInk/Features/Dictionary/AutoLearn/AutoLearnFocusObserver.swift
[vi-axr]: https://github.com/Beingpax/VoiceInk/blob/b6f5baff7d95b8a7696c8f488226e9da5e468e7a/VoiceInk/Infrastructure/SystemIntegration/Accessibility/AccessibilityTextReader.swift
[fo]: https://github.com/altic-dev/Fluid-oss
[fw]: file:///Users/alechenderson/Projects/FluidWispr/Sources/Fluid/Services/AutomaticDictionaryCorrectionTracker.swift
[el]: https://github.com/electron/electron/tree/96a2dc1f28a4e4a32fdc19d54ba0af36c7f2c536
[el-app]: https://github.com/electron/electron/blob/96a2dc1f28a4e4a32fdc19d54ba0af36c7f2c536/shell/browser/mac/electron_application.mm#L222-L281
[el-doc]: https://www.electronjs.org/docs/latest/tutorial/accessibility
[ns]: https://developer.apple.com/documentation/appkit/nsevent/addglobalmonitorforevents(matching:handler:)
[sw]: https://github.com/swiftlang/swift/blob/main/stdlib/public/core/Diffing.swift
[pk]: https://huggingface.co/nvidia/parakeet-tdt-0.6b-v2
[gof]: https://arxiv.org/abs/2310.00141
[yu]: https://www.isca-archive.org/interspeech_2004/yu04f_interspeech.html
