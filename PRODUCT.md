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

Open, not yet decided:

- How people get it: direct download, Mac App Store, or both.
- Pricing and licensing.
- Which local models ship, and which cloud providers are supported.
- How dictation starts and stops (keyboard shortcut, menu bar, or something else) and where the app lives (menu bar, Dock, or both).

## Evidence on Hand

None yet. No testimonials, users, benchmarks, accuracy or speed figures, press, screenshots or logo exist in the repo. Future work must not invent any of them.

## Product Principles

1. Dictation works fully offline on the Mac. Anything that needs the internet is an optional extra on top.
2. The user's speech and text stay on their Mac unless they turn on a cloud feature with their own key.
3. Fluidity serves the app the user is already in. It gets text there and gets out of the way.
4. Recognition should fit the person: their words, their names, their jargon.

## Accessibility & Inclusion

Some users can't type easily, so Fluidity is an accessibility tool for them as well as a convenience. Core tasks (starting and stopping dictation, choosing a model, editing word lists) must not depend on long typing or precise pointing, and must work with VoiceOver, Voice Control and Full Keyboard Access.
