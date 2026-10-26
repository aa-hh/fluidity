import FluidityCore
import Foundation
import Testing

@MainActor
struct DictationControllerTests {
    typealias Phase = DictationController.Phase
    typealias Harness = ControllerHarness

    // Turns red if the 300 ms tap threshold moves or its comparison flips.
    @Test(arguments: [
        (Duration.milliseconds(299), Phase.recording(.handsFree)),
        (.milliseconds(300), .finishing),
    ])
    func pressLengthDecidesTapOrHold(press: Duration, phase: Phase) async {
        let h = Harness()
        await h.pressAndHold()
        await h.advance(press)
        h.controller.keyUp()
        #expect(h.controller.phase == phase)
    }

    // Turns red if a hands-free dictation stops on its own, or the next press does not stop and paste it.
    @Test func handsFreeRecordsUntilTheNextPress() async {
        let h = Harness()
        await h.pressAndHold()
        await h.advance(.milliseconds(100))
        h.controller.keyUp()
        #expect(h.controller.pill == .listening(preview: "", mode: .handsFree))
        await h.advance(.seconds(30))
        await h.settle()
        #expect(h.controller.phase == .recording(.handsFree))

        h.controller.keyDown()
        #expect(h.controller.phase == .finishing)
        h.controller.keyUp()
        await h.advance(.milliseconds(200))
        await h.untilDone()
        #expect(h.parts.snapshot.pasted == ["HELLO, WORLD."])
    }

    // Turns red if the audio stops less than 200 ms after release.
    @Test func audioRunsFor200msAfterRelease() async {
        let h = Harness()
        await h.pressAndHold()
        await h.advance(.seconds(1))
        h.controller.keyUp()
        await h.advance(.milliseconds(199))
        await h.settle()
        #expect(h.parts.snapshot.audioStops == 0)
        await h.advance(.milliseconds(1))
        await h.until { h.parts.snapshot.audioStops == 1 }
    }

    struct CleanupCase: Sendable, CustomTestStringConvertible {
        var name: String
        var cleanupOn = true
        /// Nil: cleanup never answers.
        var result: DictationController.CleanupResult?
        var pill: PillState
        var pasted: String
        var cleanedText: String?
        var fallbackReason: FallbackReason?
        var cleanupSeconds: TimeInterval?
        var testDescription: String { name }
    }

    nonisolated static let cleanupCases: [CleanupCase] = [
        .init(name: "cleaned", result: .cleaned("Hello, world."), pill: .pasted, pasted: "HELLO, WORLD.",
              cleanedText: "Hello, world.", cleanupSeconds: 0),
        .init(name: "offline", result: .fallback(.offline), pill: .pastedRawTranscript, pasted: "HELLO WORLD",
              fallbackReason: .offline, cleanupSeconds: 0),
        .init(name: "failed output check", result: .fallback(.wordsNotInTranscript), pill: .pastedRawTranscript,
              pasted: "HELLO WORLD", fallbackReason: .wordsNotInTranscript, cleanupSeconds: 0),
        .init(name: "slow", result: nil, pill: .pastedRawTranscript, pasted: "HELLO WORLD",
              fallbackReason: .slow, cleanupSeconds: 1),
        .init(name: "off", cleanupOn: false, pill: .pasted, pasted: "HELLO WORLD"),
    ]

    // Turns red if a cleanup answer, fallback or the off setting reaches the paste, the pill or the record wrongly,
    // or the 1 s budget moves.
    @Test(arguments: cleanupCases)
    func cleanupOutcome(_ c: CleanupCase) async {
        let h = Harness {
            $0.cleanupOn = c.cleanupOn
            $0.cleanupResult = c.result
        }
        await h.dictate()
        if c.cleanupOn, c.result == nil {
            await h.until { h.controller.pill == .cleaning }
            await h.advance(.milliseconds(999))
            await h.settle()
            #expect(h.controller.pill == .cleaning)
            await h.advance(.milliseconds(1))
        }
        await h.untilDone()
        let s = h.parts.snapshot
        #expect(h.controller.pill == c.pill)
        #expect(s.pasted == [c.pasted])
        #expect(s.cleanCalls == (c.cleanupOn ? 1 : 0))
        #expect(s.saved.first?.cleanedText == c.cleanedText)
        #expect(s.saved.first?.fallbackReason == c.fallbackReason)
        #expect(s.saved.first?.timings.cleanup == c.cleanupSeconds)
    }

    // Turns red if a paste that landed is not watched, or one with nowhere to paste is recorded as pasted.
    @Test(arguments: [
        (DictationController.PasteOutcome.landed, PillState.pasted, Phase.watching),
        (.nowhereToPaste, .nowhereToPaste, .ready),
    ])
    func pasteOutcome(_ outcome: DictationController.PasteOutcome, pill: PillState, phase: Phase) async {
        let landed = outcome == .landed
        let h = Harness { $0.pasteOutcome = outcome }
        await h.dictate()
        await h.until { !h.parts.snapshot.saved.isEmpty && h.parts.snapshot.watched.count == (landed ? 1 : 0) }
        let s = h.parts.snapshot
        #expect(h.controller.pill == pill)
        #expect(h.controller.phase == phase)
        #expect(s.saved.first?.pasteLanded == landed)
        #expect(s.saved.first?.pastedText == (landed ? "HELLO, WORLD." : nil))
    }

    // Turns red if a stage's text, the field around the cursor, a timing or a version stops reaching the saved record.
    @Test func savedRecordHoldsEveryStage() async throws {
        let h = Harness()
        await h.dictate()
        await h.untilDone()
        let saved = try #require(h.parts.snapshot.saved.first)
        #expect(saved == DictationRecord(
            id: saved.id, startedAt: saved.startedAt, app: "com.apple.mail",
            rawTranscript: "hello world", cleanedText: "Hello, world.", pastedText: "HELLO, WORLD.",
            wordTimings: FakeParts.wordTimings,
            textBeforeCursor: "Dear Sam, ", selectedText: "", textAfterCursor: " Thanks.",
            pasteLanded: true,
            timings: StageTimings(transcription: 0, cleanup: 0, finishing: 0, paste: 0),
            modelVersion: "parakeet-v2", wordListVersion: "words-1"))
    }

    // Turns red if the pasted pill stays up, or goes before 600 ms.
    @Test func pastedPillHidesAfter600ms() async {
        let h = Harness()
        await h.dictate()
        await h.untilDone()
        await h.advance(.milliseconds(599))
        await h.settle()
        #expect(h.controller.pill == .pasted)
        await h.advance(.milliseconds(1))
        await h.until { h.controller.pill == .hidden }
    }

    // Turns red if text from a secure field is saved or watched, or stops being pasted.
    @Test func secureFieldIsPastedButNeitherSavedNorWatched() async {
        let h = Harness { $0.field?.isSecure = true }
        await h.dictate()
        await h.untilDone()
        await h.settle()
        let s = h.parts.snapshot
        #expect(s.pasted == ["HELLO, WORLD."])
        #expect(s.saved.isEmpty)
        #expect(s.watched.isEmpty)
        #expect(h.controller.phase == .ready)
    }

    // Turns red if silence is not shown at 5 s, stops the recording, or is timed from key down instead of the last new words.
    @Test func micSilentAfter5sWithoutNewWords() async {
        let h = Harness()
        await h.pressAndHold()
        await h.advance(.seconds(5))
        await h.until { h.controller.pill == .micSilent }
        #expect(h.controller.phase == .recording(.held))

        h.parts.say("hello")
        await h.until { h.controller.pill == .listening(preview: "hello", mode: .held) }
        await h.advance(.seconds(4))
        await h.settle()
        #expect(h.controller.pill == .listening(preview: "hello", mode: .held))
        await h.advance(.seconds(1))
        await h.until { h.controller.pill == .micSilent }
    }

    // Turns red if the 19 minute warning or the 20 minute stop moves, or the stop does not finish and paste.
    @Test func recordingWarnsAt19MinutesAndStopsAt20() async {
        let h = Harness()
        await h.pressAndHold()
        await h.advance(.milliseconds(100))
        h.controller.keyUp()
        await h.advance(.seconds(19 * 60) - .milliseconds(101))
        await h.settle()
        #expect(h.controller.pill == .micSilent)
        await h.advance(.milliseconds(1))
        await h.until { h.controller.pill == .recordingLimitNear }
        #expect(h.controller.phase == .recording(.handsFree))

        await h.advance(.seconds(60) - .milliseconds(1))
        await h.settle()
        #expect(h.controller.phase == .recording(.handsFree))
        await h.advance(.milliseconds(1))
        await h.until { h.controller.pill == .recordingStoppedAtLimit }
        #expect(h.controller.phase == .finishing)
        await h.advance(.milliseconds(200))
        await h.untilDone()
        #expect(h.parts.snapshot.pasted == ["HELLO, WORLD."])
    }

    // Turns red if a key press without microphone access records, or does not show the permission state.
    @Test func microphoneMissingShowsPermissionAndDoesNotRecord() async {
        let h = Harness { $0.microphoneGranted = false }
        h.controller.keyDown()
        await h.settle()
        #expect(h.controller.pill == .permissionMissing(.microphone))
        #expect(h.controller.phase == .ready)
        #expect(h.parts.snapshot.audioStarts == 0)
    }

    // Turns red if a dictation without Accessibility is pasted, is not saved, or ends without the permission state.
    @Test func accessibilityMissingSavesTheRawTranscriptInsteadOfPasting() async {
        let h = Harness { $0.accessibilityGranted = false }
        await h.dictate()
        await h.until { !h.parts.snapshot.saved.isEmpty }
        let s = h.parts.snapshot
        #expect(h.controller.pill == .permissionMissing(.accessibility))
        #expect(s.pasted.isEmpty)
        #expect(s.saved.first?.rawTranscript == "hello world")
        #expect(s.saved.first?.pasteLanded == false)
    }

    enum WatchEnd: Sendable { case newDictation, watcherStops }

    // Turns red if a new dictation starts before the watch's final text is saved with `newDictation`,
    // or the watcher's own reason is dropped.
    @Test(arguments: [
        (WatchEnd.newDictation, WatchStopReason.newDictation, Phase.recording(.held)),
        (.watcherStops, .focusLost, .ready),
    ])
    func watchingEnds(_ end: WatchEnd, reason: WatchStopReason, phase: Phase) async throws {
        let h = Harness()
        await h.dictate()
        await h.until { h.parts.snapshot.watched.count == 1 }
        let id = try #require(h.parts.snapshot.saved.first?.id)
        switch end {
        case .newDictation:
            await h.pressAndHold()
        case .watcherStops:
            h.parts.endWatch(.focusLost)
            await h.until { h.controller.phase == .ready }
        }
        #expect(h.parts.snapshot.finalTexts == [.init(finalText: "edited", reason: reason, id: id)])
        #expect(h.controller.phase == phase)
    }

    enum CancelStep: String, Sendable, CaseIterable {
        case recordingHeld, recordingHandsFree, afterRelease, finalPass, cleaning
    }

    // Turns red if Escape at any step before pasting saves or pastes something, leaves the microphone on,
    // skips the cancelled state, or leaves it up past 120 ms.
    @Test(arguments: CancelStep.allCases)
    func escapeCancels(at step: CancelStep) async {
        let h = Harness {
            $0.transcribeHangs = step == .finalPass
            if step == .cleaning { $0.cleanupResult = nil }
        }
        await h.pressAndHold()
        switch step {
        case .recordingHeld:
            await h.advance(.seconds(1))
        case .recordingHandsFree:
            await h.advance(.milliseconds(100))
            h.controller.keyUp()
        case .afterRelease:
            await h.advance(.seconds(1))
            h.controller.keyUp()
        case .finalPass:
            await h.release()
            await h.until { h.parts.snapshot.transcribeCalls == 1 }
        case .cleaning:
            await h.release()
            await h.until { h.controller.pill == .cleaning }
        }
        h.controller.escapePressed()
        h.controller.keyUp()
        #expect(h.controller.pill == .cancelled)
        #expect(h.controller.phase == .ready)
        await h.until { h.parts.snapshot.cancelledRecordings == 1 }
        await h.advance(.milliseconds(120))
        await h.until { h.controller.pill == .hidden }
        let s = h.parts.snapshot
        #expect(s.audioStops == 1)
        #expect(s.saved.isEmpty)
        #expect(s.pasted.isEmpty)
    }

    enum QuietEnd: Sendable, CaseIterable { case audioStartFails, finalPassFails, emptyTranscript }

    // Turns red if a dictation with no audio or no words pastes or saves something, or leaves the pill up.
    @Test(arguments: QuietEnd.allCases)
    func endsQuietly(_ end: QuietEnd) async {
        let h = Harness {
            switch end {
            case .audioStartFails: $0.audioStartFails = true
            case .finalPassFails: $0.rawTranscript = nil
            case .emptyTranscript: $0.rawTranscript = ""
            }
        }
        h.controller.keyDown()
        await h.advance(.seconds(1))
        h.controller.keyUp()
        await h.advance(.milliseconds(200))
        await h.until { h.controller.pill == .hidden && h.controller.phase == .ready }
        await h.settle()
        #expect(h.parts.snapshot.pasted.isEmpty)
        #expect(h.parts.snapshot.saved.isEmpty)
    }

    // Turns red if the menu bar stops following a dictation through recording and mic warm back to ready,
    // or the 3 minutes of mic warm change.
    @Test func menuBarFollowsADictation() async {
        let h = Harness()
        #expect(h.controller.menuBar == .ready)
        await h.pressAndHold()
        #expect(h.controller.menuBar == .recording)
        await h.advance(.seconds(1))
        h.controller.keyUp()
        await h.advance(.milliseconds(200))
        await h.untilDone()
        #expect(h.controller.menuBar == .micWarm)
        await h.advance(.seconds(180) - .milliseconds(1))
        await h.settle()
        #expect(h.controller.menuBar == .micWarm)
        await h.advance(.milliseconds(1))
        await h.until { h.controller.menuBar == .ready }
    }

    struct MenuBarCase: Sendable, CustomTestStringConvertible {
        var name: String
        var microphone = true
        var accessibility = true
        var cleanupOn = true
        var recording = false
        var expected: MenuBarState
        var testDescription: String { name }
    }

    // Turns red if the menu bar's order of precedence changes: permission, then recording, then cleanup off.
    @Test(arguments: [
        MenuBarCase(name: "cleanup off", cleanupOn: false, expected: .cleanupOff),
        MenuBarCase(name: "recording with cleanup off", cleanupOn: false, recording: true, expected: .recording),
        MenuBarCase(name: "recording without Accessibility", accessibility: false, recording: true,
                    expected: .permissionMissing(.accessibility)),
        MenuBarCase(name: "no microphone", microphone: false, expected: .permissionMissing(.microphone)),
    ])
    func menuBarPrecedence(_ c: MenuBarCase) async {
        let h = Harness()
        h.parts.state.withLock {
            $0.microphoneGranted = c.microphone
            $0.accessibilityGranted = c.accessibility
            $0.cleanupOn = c.cleanupOn
        }
        h.controller.refreshMenuBar()
        if c.recording { await h.pressAndHold() }
        #expect(h.controller.menuBar == c.expected)
    }
}
