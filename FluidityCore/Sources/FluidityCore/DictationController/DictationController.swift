import Foundation
import Observation

/// Drives one dictation at a time from key down to pasted text, and publishes
/// what the pill and the menu bar icon show.
///
/// Main actor, because key presses arrive there and the pill and menu bar are
/// drawn there, so no input or output needs a hop.
@MainActor
@Observable
public final class DictationController {
    public private(set) var phase: Phase = .ready
    public private(set) var pill: PillState = .hidden
    public private(set) var menuBar: MenuBarState = .ready

    private static let tapThreshold: Duration = .milliseconds(300)
    private static let tail: Duration = .milliseconds(200)
    private static let cleanupBudget: Duration = .seconds(1)
    private static let silenceLimit: Duration = .seconds(5)
    private static let recordingWarning: Duration = .seconds(19 * 60)
    private static let recordingLimit: Duration = .seconds(20 * 60)
    private static let micWarmLength: Duration = .seconds(3 * 60)
    private static let cancelledShownFor: Duration = .milliseconds(120)
    private static let pastedShownFor: Duration = .milliseconds(600)

    private let audio: any AudioCapturing
    private let transcriber: any Transcribing
    private let cleanup: any CleaningUp
    private let field: any FieldContextReading
    private let finisher: any Finishing
    private let paster: any Pasting
    private let watcher: any EditWatching
    private let store: any DictationStoring
    private let permissions: any PermissionChecking
    private let modelVersion: String
    private let wordListVersion: @Sendable () -> String
    private let timeline: Timeline

    @ObservationIgnored private var session: Session?
    @ObservationIgnored private var micWarm = false
    @ObservationIgnored private var micWarmTask: Task<Void, Never>?
    @ObservationIgnored private var hideTask: Task<Void, Never>?

    public init(
        audio: any AudioCapturing,
        transcriber: any Transcribing,
        cleanup: any CleaningUp,
        field: any FieldContextReading,
        finisher: any Finishing,
        paster: any Pasting,
        watcher: any EditWatching,
        store: any DictationStoring,
        permissions: any PermissionChecking,
        modelVersion: String,
        wordListVersion: @escaping @Sendable () -> String,
        clock: any Clock<Duration> = ContinuousClock()
    ) {
        self.audio = audio
        self.transcriber = transcriber
        self.cleanup = cleanup
        self.field = field
        self.finisher = finisher
        self.paster = paster
        self.watcher = watcher
        self.store = store
        self.permissions = permissions
        self.modelVersion = modelVersion
        self.wordListVersion = wordListVersion
        self.timeline = Timeline(clock)
        refreshMenuBar()
    }

    // MARK: Inputs

    /// Starts a dictation, or stops a hands-free one.
    public func keyDown() {
        switch phase {
        case .ready, .watching:
            begin()
        case .recording(.handsFree):
            if let session { stopRecording(session, atLimit: false) }
        case .recording(.held), .finishing, .cleaning, .pasting:
            break
        }
    }

    /// A release under 300 ms after key down makes the dictation hands-free; a later one stops it.
    public func keyUp() {
        guard case .recording(.held) = phase, let session else { return }
        if timeline.now() - session.keyDownAt < Self.tapThreshold {
            phase = .recording(.handsFree)
            showRecordingPill(session)
        } else {
            stopRecording(session, atLimit: false)
        }
    }

    public func escapePressed() {
        guard let session else { return }
        switch phase {
        case .recording, .finishing, .cleaning: break
        case .ready, .pasting, .watching: return
        }
        // Cancel saves no record; the audio goes to `DictationStoring.dictationCancelled`, which keeps nothing by default.
        session.task?.cancel()
        session.stopTimers()
        end(showing: .cancelled, for: Self.cancelledShownFor)
    }

    /// Re-reads the permissions and the cleanup setting; call when either may have changed.
    public func refreshMenuBar() {
        menuBar = if !permissions.microphoneGranted {
            .permissionMissing(.microphone)
        } else if !permissions.accessibilityGranted {
            .permissionMissing(.accessibility)
        } else if phase.isDictating {
            .recording
        } else if !cleanup.isOn {
            .cleanupOff
        } else if micWarm {
            .micWarm
        } else {
            .ready
        }
    }

    // MARK: One dictation

    private func begin() {
        guard permissions.microphoneGranted else {
            show(.permissionMissing(.microphone))
            refreshMenuBar()
            return
        }
        let previous = session
        if phase == .watching { previous?.task?.cancel() }
        let current = Session(keyDownAt: timeline.now(), canPaste: permissions.accessibilityGranted)
        session = current
        phase = .recording(.held)
        showRecordingPill(current)
        refreshMenuBar()
        current.task = Task { await run(current, after: previous?.task) }
    }

    // Escape writes the outputs itself and cancels this task, so every output
    // write below comes straight after a cancellation check, with no await between.
    private func run(_ current: Session, after previous: Task<Void, Never>?) async {
        // The previous dictation saves its final text before this one records.
        await previous?.value
        guard !Task.isCancelled else { return }
        let live: AsyncStream<[Float]>
        do {
            live = try await audio.start()
        } catch {
            guard !Task.isCancelled else { return }
            phase = .ready
            show(.hidden)
            refreshMenuBar()
            return
        }
        guard !Task.isCancelled else {
            await store.dictationCancelled(await audio.stop())
            return
        }
        startTimers(current, live)
        for await _ in current.stopRequests { break }
        try? await timeline.sleep(until: (current.stopAt ?? timeline.now()) + Self.tail)
        let recording = await audio.stop()
        guard !Task.isCancelled else {
            await store.dictationCancelled(recording)
            return
        }

        let transcriptionStart = timeline.now()
        let transcript = try? await transcriber.transcribe(recording)
        guard !Task.isCancelled else {
            await store.dictationCancelled(recording)
            return
        }
        guard let transcript, !transcript.text.isEmpty else {
            end(showing: .hidden)
            return
        }
        var record = DictationRecord(
            id: current.id,
            startedAt: current.startedAt,
            rawTranscript: transcript.text,
            wordTimings: transcript.wordTimings,
            timings: StageTimings(
                transcription: seconds(since: transcriptionStart), wordListRecheck: transcript.wordListRecheck),
            modelVersion: modelVersion,
            wordListVersion: wordListVersion()
        )

        guard current.canPaste else {
            end(showing: .permissionMissing(.accessibility))
            await store.save(record, recording: recording)
            return
        }

        var text = transcript.text
        if cleanup.isOn {
            phase = .cleaning
            show(.cleaning)
            let cleanupStart = timeline.now()
            let result = await clean(text, deadline: cleanupStart + Self.cleanupBudget)
            guard let result, !Task.isCancelled else {
                await store.dictationCancelled(recording)
                return
            }
            record.timings.cleanup = seconds(since: cleanupStart)
            switch result {
            case .cleaned(let cleaned):
                record.cleanedText = cleaned
                text = cleaned
            case .fallback(let reason):
                record.fallbackReason = reason
            }
        }

        phase = .pasting
        let context = await field.read()
        let finishingStart = timeline.now()
        let finished = finisher.finish(text, in: context)
        record.timings.finishing = seconds(since: finishingStart)
        let pasteStart = timeline.now()
        let outcome = await paster.paste(finished)
        record.timings.paste = seconds(since: pasteStart)
        record.app = context?.app
        record.textBeforeCursor = context?.textBeforeCursor
        record.selectedText = context?.selectedText
        record.textAfterCursor = context?.textAfterCursor
        record.pasteLanded = outcome == .landed
        record.pastedText = record.pasteLanded ? finished : nil

        let secure = context?.isSecure ?? false
        let watches = record.pasteLanded && !secure
        switch outcome {
        case .landed:
            // Stays in pasting until the record is saved, so a new dictation cannot stop a watch that has not begun.
            end(showing: record.fallbackReason == nil ? .pasted(text: finished) : .pastedRawTranscript(text: finished),
                for: Self.pastedShownFor, phase: watches ? .pasting : .ready)
        case .nowhereToPaste:
            end(showing: .nowhereToPaste(text: finished))
        }
        guard !secure else { return }
        await store.save(record, recording: recording)
        guard watches else { return }

        phase = .watching
        refreshMenuBar()
        let stop = await watcher.watch(pastedText: finished)
        let reason: WatchStopReason = Task.isCancelled ? .newDictation : stop.reason
        await store.updateFinalText(stop.finalText, reason: reason, for: current.id)
        if session === current, phase == .watching {
            phase = .ready
            refreshMenuBar()
        }
    }

    private func stopRecording(_ current: Session, atLimit: Bool) {
        guard session === current, case .recording = phase else { return }
        current.stopAt = timeline.now()
        current.stopTimers()
        phase = .finishing
        show(atLimit ? .recordingStoppedAtLimit : .finishing)
        current.stopRequester.yield()
    }

    /// Cleanup's answer, or a `.slow` fallback at the deadline; nil when cancelled.
    private func clean(_ rawTranscript: String, deadline: Duration) async -> CleanupResult? {
        let (results, sink) = AsyncStream.makeStream(of: CleanupResult.self)
        let cleanup = self.cleanup
        let timeline = self.timeline
        let answer = Task { sink.yield(await cleanup.clean(rawTranscript)) }
        let timer = Task {
            if (try? await timeline.sleep(until: deadline)) != nil { sink.yield(.fallback(.slow)) }
        }
        // The loser is cancelled, not awaited, so a cleanup call that ignores cancellation cannot hold up the paste.
        defer {
            answer.cancel()
            timer.cancel()
            sink.finish()
        }
        for await first in results { return first }
        return nil
    }

    // MARK: Recording timers

    private func startTimers(_ current: Session, _ live: AsyncStream<[Float]>) {
        let previews = transcriber.preview(live)
        current.timers = [
            Task { for await text in previews { heard(text, in: current) } },
            Task {
                guard await sleep(until: current.keyDownAt + Self.recordingWarning) else { return }
                current.limitNear = true
                showRecordingPill(current)
            },
            Task {
                guard await sleep(until: current.keyDownAt + Self.recordingLimit) else { return }
                stopRecording(current, atLimit: true)
            },
        ]
        watchForSilence(current, from: current.keyDownAt)
    }

    private func heard(_ text: String, in current: Session) {
        guard session === current, case .recording = phase, text != current.preview else { return }
        current.preview = text
        current.silent = false
        watchForSilence(current, from: timeline.now())
        showRecordingPill(current)
    }

    private func watchForSilence(_ current: Session, from heardAt: Duration) {
        current.silenceTimer?.cancel()
        current.silenceTimer = Task {
            guard await sleep(until: heardAt + Self.silenceLimit) else { return }
            current.silent = true
            showRecordingPill(current)
        }
    }

    // MARK: Outputs

    private func showRecordingPill(_ current: Session) {
        guard session === current, case .recording(let mode) = phase else { return }
        if current.limitNear {
            show(.recordingLimitNear)
        } else if current.silent {
            show(.micSilent)
        } else {
            show(.listening(preview: current.preview, mode: mode))
        }
    }

    private func end(showing finalPill: PillState, for shownFor: Duration? = nil, phase newPhase: Phase = .ready) {
        phase = newPhase
        show(finalPill, hidingAfter: shownFor)
        warmMicrophone()
        refreshMenuBar()
    }

    private func show(_ newPill: PillState, hidingAfter shownFor: Duration? = nil) {
        hideTask?.cancel()
        hideTask = nil
        pill = newPill
        guard let shownFor else { return }
        let deadline = timeline.now() + shownFor
        hideTask = Task {
            guard await sleep(until: deadline) else { return }
            pill = .hidden
        }
    }

    private func warmMicrophone() {
        micWarmTask?.cancel()
        micWarm = true
        let deadline = timeline.now() + Self.micWarmLength
        micWarmTask = Task {
            guard await sleep(until: deadline) else { return }
            micWarm = false
            refreshMenuBar()
        }
    }

    // MARK: Time

    /// False when cancelled before or at the deadline.
    private func sleep(until deadline: Duration) async -> Bool {
        do { try await timeline.sleep(until: deadline) } catch { return false }
        return !Task.isCancelled
    }

    private func seconds(since start: Duration) -> TimeInterval {
        let elapsed = (timeline.now() - start).components
        return Double(elapsed.seconds) + Double(elapsed.attoseconds) * 1e-18
    }
}

extension DictationController.Phase {
    var isDictating: Bool {
        switch self {
        case .recording, .finishing, .cleaning, .pasting: true
        case .ready, .watching: false
        }
    }
}

/// The state of the dictation in progress.
@MainActor
private final class Session {
    let id = UUID()
    let startedAt = Date()
    let keyDownAt: Duration
    let canPaste: Bool
    let stopRequests: AsyncStream<Void>
    let stopRequester: AsyncStream<Void>.Continuation
    var stopAt: Duration?
    var preview = ""
    var silent = false
    var limitNear = false
    var task: Task<Void, Never>?
    var timers: [Task<Void, Never>] = []
    var silenceTimer: Task<Void, Never>?

    init(keyDownAt: Duration, canPaste: Bool) {
        self.keyDownAt = keyDownAt
        self.canPaste = canPaste
        let stop = AsyncStream<Void>.makeStream()
        stopRequests = stop.stream
        stopRequester = stop.continuation
    }

    func stopTimers() {
        timers.forEach { $0.cancel() }
        silenceTimer?.cancel()
    }
}

/// The injected clock read as time since the controller was made. Every wait
/// is until a deadline fixed when its event happened, so a test that moves a
/// `ManualClock` before a timer has started waiting still fires that timer.
private struct Timeline: Sendable {
    let now: @Sendable () -> Duration
    private let sleepUntil: @Sendable (Duration) async throws -> Void

    init<C: Clock<Duration>>(_ clock: C) {
        let origin = clock.now
        now = { origin.duration(to: clock.now) }
        sleepUntil = { try await clock.sleep(until: origin.advanced(by: $0), tolerance: nil) }
    }

    func sleep(until deadline: Duration) async throws {
        try await sleepUntil(deadline)
    }
}
