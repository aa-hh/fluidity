import Foundation
import Synchronization

/// The focused app and text field, captured when a dictation starts and compared just before pasting.
public struct FocusIdentity: Equatable, Sendable {
    public var processID: Int32
    /// Equal for the same focused element; nil when the app exposes none.
    public var element: Int?

    public init(processID: Int32, element: Int?) {
        self.processID = processID
        self.element = element
    }
}

/// Every item on the clipboard, each with the data of every type it offered, in the order offered.
public struct PasteboardSnapshot: Equatable, Sendable {
    public struct Representation: Equatable, Sendable {
        public var type: String
        public var data: Data

        public init(type: String, data: Data) {
            self.type = type
            self.data = data
        }
    }

    public var items: [[Representation]]

    public init(items: [[Representation]]) {
        self.items = items
    }
}

/// The system clipboard.
@MainActor
public protocol Pasteboard {
    func snapshot() -> PasteboardSnapshot
    /// Clears the clipboard and offers `text` by delayed rendering, marked as ours.
    /// `onRequest` runs when another app reads the text. Returns false if the clipboard refused the item.
    func writeDelayed(_ text: String, onRequest: @escaping @Sendable () -> Void) -> Bool
    var changeCount: Int { get }
    /// Whether the clipboard still carries the marker `writeDelayed` added.
    var holdsOurItem: Bool { get }
    func restore(_ snapshot: PasteboardSnapshot)
}

@MainActor
public protocol KeySender {
    /// Command down, V down, V up, Command up, using the key that types "v" in the current layout.
    func sendPaste()
}

@MainActor
public protocol FocusChecking {
    /// The focus now, or nil when no app is frontmost.
    func currentFocus() -> FocusIdentity?
}

public enum PasteFailure: Equatable, Sendable {
    case focusMoved
    /// No app read the text within the time limit: there was nowhere to paste.
    case nothingAskedForText
    case clipboardUnavailable
}

public enum PasteResult: Equatable, Sendable {
    /// Carries the time from sending ⌘V to the other app reading the text.
    case landed(Duration)
    case failed(PasteFailure)
}

/// Pastes text at the cursor through the clipboard, confirms it landed, then puts the old clipboard back.
@MainActor
public final class Paster {
    private let pasteboard: any Pasteboard
    private let keySender: any KeySender
    private let focusChecking: any FocusChecking
    private let clock: any Clock<Duration>

    public init(
        pasteboard: any Pasteboard,
        keySender: any KeySender,
        focusChecking: any FocusChecking,
        clock: any Clock<Duration> = ContinuousClock()
    ) {
        self.pasteboard = pasteboard
        self.keySender = keySender
        self.focusChecking = focusChecking
        self.clock = clock
    }

    /// Returns after the old clipboard is back, or left alone because something else replaced our text.
    /// Sends ⌘V at most once: a paste that may already have landed is never retried, since that can insert twice.
    public func paste(
        _ text: String,
        focusAtStart: FocusIdentity,
        timeout: Duration = .milliseconds(800),
        restoreDelay: Duration = .milliseconds(300)
    ) async -> PasteResult {
        let saved = pasteboard.snapshot()
        guard focusChecking.currentFocus() == focusAtStart else { return .failed(.focusMoved) }

        let elapsed = clock.stopwatch()
        let request = TextRequest()
        guard pasteboard.writeDelayed(text, onRequest: { request.finish(elapsed()) }) else {
            // The failed write may already have cleared the clipboard.
            pasteboard.restore(saved)
            return .failed(.clipboardUnavailable)
        }
        let ours = pasteboard.changeCount

        let sentAt = elapsed()
        keySender.sendPaste()
        // Deadlines are measured from the stopwatch's start, so a wait that starts late cannot stretch them.
        let deadline = sentAt + timeout
        let timer = Task { [clock] in
            do {
                try await clock.sleep(for: deadline - elapsed())
                request.finish(nil)
            } catch {}
        }
        let requestedAt = await request.wait()
        timer.cancel()

        try? await clock.sleep(for: (requestedAt ?? deadline) + restoreDelay - elapsed())
        if pasteboard.changeCount == ours, pasteboard.holdsOurItem {
            pasteboard.restore(saved)
        }
        return requestedAt.map { .landed($0 - sentAt) } ?? .failed(.nothingAskedForText)
    }
}

private extension Clock<Duration> {
    /// A function that returns the time passed since this call.
    func stopwatch() -> @Sendable () -> Duration {
        let start = now
        return { start.duration(to: now) }
    }
}

/// Settles once: with the stopwatch reading when another app asked for the text, or nil when the time limit passed first.
/// The clipboard may call back from any thread, so the state sits behind a lock.
private final class TextRequest: Sendable {
    private enum State {
        case waiting(CheckedContinuation<Duration?, Never>?)
        case finished(Duration?)
    }

    private let state = Mutex<State>(.waiting(nil))

    func finish(_ reading: Duration?) {
        let waiter: CheckedContinuation<Duration?, Never>? = state.withLock { state in
            guard case .waiting(let waiter) = state else { return nil }
            state = .finished(reading)
            return waiter
        }
        waiter?.resume(returning: reading)
    }

    func wait() async -> Duration? {
        await withCheckedContinuation { continuation in
            let finished: Duration?? = state.withLock { state in
                if case .finished(let reading) = state { return .some(reading) }
                state = .waiting(continuation)
                return nil
            }
            if let finished { continuation.resume(returning: finished) }
        }
    }
}
