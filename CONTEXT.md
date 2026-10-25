# Fluidity — domain glossary

The words this project uses, defined once. Agents use these terms exactly
(see `docs/agents/domain.md`); a synonym the glossary avoids is a smell.

| Term | Meaning | Not to be confused with |
|---|---|---|
| Fluidity | The dictation app: speak, and the text appears in whatever app you're typing in. Mac first. | Wispr Flow, the existing product it's measured against |
| Live preview | The words shown while you're still speaking. They can still change until you release the key. | Pasted text |
| Raw transcript | The speech model's output for a dictation, before cleanup. | Cleaned text |
| Cleaned text | Cleanup's output, which is pasted when it passes the output check. | Raw transcript |
| Pasted text | What was actually pasted: the cleaned text, or the raw transcript after a fallback. | Final text |
| Final text | The pasted part of the text field when the app stops watching it, with the user's edits. | Pasted text |
| Fallback | Pasting the raw transcript because cleanup was slow, offline or failed its output check. | Cancel (Escape: nothing is pasted) |
| Correction | A user's edit to pasted text, sorted later into the categories in Linear AA-304. Only some categories train a model. | Rewrite (an edit that trains nothing) |
| Cleanup | The step that turns the raw transcript into the text that gets pasted: drops fillers, resolves self-corrections, formats numbers and lists. | Finishing rules (fixed casing and spacing rules applied on the device) |
| Contributor | A user who has opted in to share their dictation data for training the shared model, in return for a free or discounted price. | User (anyone running Fluidity, contributing or not) |
