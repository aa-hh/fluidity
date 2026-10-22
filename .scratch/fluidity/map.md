# Fluidity: can a community-trained on-device dictation model compete with Wispr Flow?

Label: wayfinder:map

## Destination

A go / no-go on two bets, and if go, a spec for Fluidity's first Mac version (English, core dictation plus a personal word list):

1. The most accurate speech model we can still retrain, running on an M1 Mac through FluidAudio, matches Wispr Flow's speed (median 339 ms from release to text, across 228 of Alec's Wispr Flow dictations).
2. Contributor data makes that model measurably more accurate than it started.

## Notes

- Mac first, Apple Silicon only (M1 and later). The M1 base model is the test machine. English only.
- Speech-to-text always runs on the device. Cleanup (raw transcript to final text) may run in the cloud, because server GPUs make it much faster; where it runs is ticket 09.
- One shared model, improved from all contributors' data. Contributors get Fluidity free or discounted.
- Starting point: FluidAudio (https://docs.fluidinference.com/introduction), Parakeet TDT models on the Neural Engine. Over 40 apps already use it, many free, so the community-trained model is the only thing setting Fluidity apart.
- Interaction design: live preview while speaking, final text on release, then cleanup (https://claude.ai/artifact/T99ohW8MS4hmonR6swB4C2).
- Existing material: `/Users/alechenderson/wispr-flow-teardown/` (Wispr Flow pipeline teardown, 715 Wispr Flow and 5,483 FluidVoice raw-to-final pairs, FluidVoice recordings), `~/Projects/pico-style-model/PLAN.md` (local cleanup model plan).
- Skills: grilling and domain-modeling for grilling tickets; research for research tickets. Glossary: `CONTEXT.md`.

## Decisions so far

<!-- one line per closed ticket: [title](issues/NN-slug.md): gist -->

## Not yet specified

- First-version details: hotkey, pasting, reading screen context through macOS Accessibility (the API screen readers use), finishing rules (casing, spacing, word-list swaps).
- Price levels, and how much contributing earns a free plan.
- How improved shared models reach users (download size, how often, rollback).
- A personal layer on top of the shared model, retrained per user.
- Mac App Store versus direct download, given the Accessibility permission dictation needs.

## Out of scope

- iPhone.
- Languages other than English.
- Intel Macs.
- Feature parity with Wispr Flow beyond core dictation and a personal word list.
- Building the cleanup model itself (`~/Projects/pico-style-model` is its own project).
- Naming and trademark checks; "Fluidity" is the working name.
