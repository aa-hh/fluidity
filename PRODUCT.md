# Product

<!-- impeccable:product-schema 1 -->

## Platform

macos

## Stack

SwiftUI, native macOS. Chosen by the owner.

## Users

Members of the public using their own Mac. Four confirmed groups:

- People who type a lot (emails, messages, notes) and want speaking to be faster than the keyboard.
- Developers dictating prompts to AI tools, code comments and commit messages.
- People who can't type easily because of injury, disability or strain.
- Privacy-minded people who want their speech kept on their own Mac.

The job in every case: say something and have the text appear where they were about to type it.

## Product Purpose

Fluidity is a native Mac dictation app. You talk to your Mac and the text is pasted straight into whatever app you are working in. Speech-to-text runs on the Mac by default. Success means the user stops reaching for the keyboard for anything longer than a few words.

## Positioning

Local-first: the main speech models run on the user's Mac, so speech does not leave it unless the user chooses. Cloud models are optional and used only for cleaning up the text after it has been transcribed, through the user's own API key. Users can add their own word lists so Fluidity gets their names, terms and jargon right.

How Fluidity differs from other Mac dictation apps beyond these three facts is not yet established. Do not claim it is unique or first.

## Operating Context

- The user is in another app (mail, chat, a code editor, an AI chat window) when they start dictating. Fluidity works across apps rather than inside a document of its own.
- The finished text lands in the app that has focus, at the cursor.
- Cloud cleanup is a step after transcription, switched on by the user, never a requirement for dictation to work.

## Capabilities and Constraints

Confirmed:

- Dictation that pastes text into any app.
- Local speech models as the default and main option.
- Optional cloud models for text cleanup after transcription. The user supplies and pays for their own API key; Fluidity never bills for cloud use.
- User-made word lists that adapt recognition to the user.
- macOS requires the user to grant Microphone access, and pasting into other apps requires Accessibility access. Both are permission prompts the user must approve.
- Impeccable has no `macos` platform guidance. Its iOS guidance is written for iPhone and does not apply. Design work follows Apple's Human Interface Guidelines for macOS.

Decided for version 1 (Alec only; version 2 goes to a few friends). Linear holds the detail: AA-296 features, AA-297 saved data, AA-298 cleanup, AA-302 architecture.

- Where it lives: a menu bar app with no Dock icon, a popover, a settings window and the recording pill. macOS 26 or later.
- How dictation starts and stops: one customisable key, which can be left or right Command or Option on its own. Tap for hands-free until the next tap, hold to talk until release. Escape cancels.
- Speech model: Parakeet TDT v2 (English) on the Mac. A model library comes in version 2.
- Cleanup: Cerebras `gpt-oss-120b` with the user's key, on as soon as a key is entered. When it is slow (about 1 s), offline or fails its output check, the raw transcript is pasted instead.
- Every dictation's audio and texts are saved as training data, except from password fields.

Open, not yet decided:

- How people get it: direct download, Mac App Store, or both.
- Pricing and licensing.

## Evidence on Hand

None yet. No testimonials, users, benchmarks, accuracy or speed figures, press, screenshots or logo exist in the repo. Future work must not invent any of them.

## Product Principles

1. Dictation works fully offline on the Mac. Anything that needs the internet is an optional extra on top.
2. The user's speech and text stay on their Mac unless they turn on a cloud feature with their own key.
3. Fluidity serves the app the user is already in. It gets text there and gets out of the way.
4. Recognition should fit the person: their words, their names, their jargon.

## Accessibility & Inclusion

Some users can't type easily, so Fluidity is an accessibility tool for them as well as a convenience. Core tasks (starting and stopping dictation, choosing a model, editing word lists) must not depend on long typing or precise pointing, and must work with VoiceOver, Voice Control and Full Keyboard Access.
