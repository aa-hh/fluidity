# Fluidity — domain glossary

The words this project uses, defined once. Agents use these terms exactly
(see `docs/agents/domain.md`); a synonym the glossary avoids is a smell.

| Term | Meaning | Not to be confused with |
|---|---|---|
| Fluidity | The dictation app: speak, and the text appears in whatever app you're typing in. Mac first. | Wispr Flow, the existing product it's measured against |
| Live preview | The words shown while you're still speaking. They can still change until you release the key. | Final text |
| Cleanup | The step that turns the raw transcript into the text that gets pasted: drops fillers, resolves self-corrections, formats numbers and lists. | Finishing rules (fixed casing and spacing rules applied on the device) |
| Contributor | A user who has opted in to share their dictation data for training the shared model, in return for a free or discounted price. | User (anyone running Fluidity, contributing or not) |
