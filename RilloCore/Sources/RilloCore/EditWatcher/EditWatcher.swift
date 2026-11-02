import Foundation

/// The final text of one dictation and why watching the field stopped.
public struct WatchOutcome: Equatable, Sendable {
    public var finalText: String
    public var stopReason: WatchStopReason

    public init(finalText: String, stopReason: WatchStopReason) {
        self.finalText = finalText
        self.stopReason = stopReason
    }
}

/// Reads the field back after a paste until the user sends, leaves or starts another dictation,
/// so the final text carries the user's corrections. It never watches key presses.
public actor EditWatcher {
    private let clock: any Clock<Duration>
    private var endCurrent: (@Sendable () -> Void)?

    public init(clock: any Clock<Duration> = ContinuousClock()) {
        self.clock = clock
    }

    /// Ends the watch in progress, if any, with `.newDictation`.
    public func endForNewDictation() {
        endCurrent?()
    }

    /// Watches `field` from the moment the paste lands until a stop reason applies.
    ///
    /// `textBefore` and `textAfter` are the field's text on either side of the cursor at paste time.
    /// Returns nil when the field is secure, so nothing from it is ever recorded,
    /// and when the calling task is cancelled.
    public func watch(
        pastedText: String,
        in field: any WatchedField,
        textBefore: String,
        textAfter: String
    ) async -> WatchOutcome? {
        endForNewDictation()
        let (events, input) = AsyncStream.makeStream(of: Event.self)
        endCurrent = { input.yield(.stop(.newDictation)) }
        let clock = self.clock

        return await withTaskGroup(of: Void.self) { group in
            group.addTask {
                for await _ in field.notifications { input.yield(.read) }
            }
            group.addTask {
                input.yield(.read)
                for _ in 0..<20 {
                    guard (try? await clock.sleep(for: .milliseconds(50))) != nil else { return }
                    input.yield(.read)
                }
                input.yield(.baselineDeadline)
                while (try? await clock.sleep(for: .milliseconds(500))) != nil {
                    input.yield(.read)
                }
            }
            group.addTask {
                guard (try? await clock.sleep(for: .seconds(60))) != nil else { return }
                input.yield(.stop(.timeLimit))
            }

            var part = PastedPart(pastedText: pastedText, textBefore: textBefore, textAfter: textAfter)
            var focusLosses = 0
            var outcome: WatchOutcome?
            watching: for await event in events {
                var step: PastedPart.Step
                switch event {
                case .read:
                    step = part.take(field.read())
                case .baselineDeadline:
                    // A paste that never shows up leaves nothing to locate later, so the watch
                    // ends as surroundingTextLost and the pasted text stands as the final text.
                    step = part.landed ? .watching : .stop(.surroundingTextLost)
                case .focusDeadline(let loss):
                    guard loss == focusLosses, part.focusGone else { continue }
                    step = part.take(field.read())
                    if case .watching = step, part.focusGone { step = .stop(.focusLost) }
                case .stop(let reason):
                    step = .stop(reason)
                }
                switch step {
                case .watching:
                    continue
                case .focusJustLost:
                    focusLosses += 1
                    let loss = focusLosses
                    group.addTask {
                        guard (try? await clock.sleep(for: .milliseconds(250))) != nil else { return }
                        input.yield(.focusDeadline(loss))
                    }
                case .stop(let reason):
                    outcome = WatchOutcome(finalText: part.finalText, stopReason: reason)
                    break watching
                case .secure:
                    break watching
                }
            }
            input.finish()
            group.cancelAll()
            return outcome
        }
    }

    private enum Event: Sendable {
        case read, baselineDeadline, focusDeadline(Int), stop(WatchStopReason)
    }
}

/// The pasted part of the field, located by the text on either side of it.
struct PastedPart {
    enum Step { case watching, focusJustLost, stop(WatchStopReason), secure }

    /// Long enough to be unique in practice, short enough to survive typing elsewhere in the field.
    static let anchorLength = 20

    let pastedText: String
    let before: String
    let after: String
    private(set) var landed = false
    private(set) var focusGone = false
    /// The pasted part from the last reading that still had the text on both sides.
    private(set) var finalText: String

    init(pastedText: String, textBefore: String, textAfter: String) {
        self.pastedText = pastedText
        before = String(textBefore.suffix(Self.anchorLength))
        after = String(textAfter.prefix(Self.anchorLength))
        finalText = pastedText
    }

    mutating func take(_ reading: (value: String, cursor: Int, hasFocus: Bool, isSecure: Bool)?) -> Step {
        guard let reading else {
            // An unreadable field after the paste has usually lost its element, so it counts as focus gone.
            return landed ? noteFocus(false) : .watching
        }
        if reading.isSecure { return .secure }
        if !landed {
            guard Self.cursorFollowsPaste(reading.value, reading.cursor, pastedText) else { return .watching }
            landed = true
        }
        // A composer may hold a lone newline between Enter and clearing.
        if reading.value.allSatisfy(\.isWhitespace) { return .stop(.fieldCleared) }
        guard let located = locate(in: reading.value) else { return .stop(.surroundingTextLost) }
        finalText = located
        return noteFocus(reading.hasFocus)
    }

    private mutating func noteFocus(_ hasFocus: Bool) -> Step {
        defer { focusGone = !hasFocus }
        return !hasFocus && !focusGone ? .focusJustLost : .watching
    }

    /// The first match of the text before and the last match of the text after,
    /// so the pasted part may itself contain either.
    private func locate(in value: String) -> String? {
        var start = value.startIndex
        if !before.isEmpty {
            guard let found = value.range(of: before) else { return nil }
            start = found.upperBound
        }
        var end = value.endIndex
        if !after.isEmpty {
            guard let found = value.range(of: after, options: .backwards, range: start..<value.endIndex) else { return nil }
            end = found.lowerBound
        }
        return String(value[start..<end])
    }

    private static func cursorFollowsPaste(_ value: String, _ cursor: Int, _ pastedText: String) -> Bool {
        let units = value.utf16
        guard cursor >= 0, cursor <= units.count else { return false }
        return String(decoding: units.prefix(cursor), as: UTF16.self).hasSuffix(pastedText)
    }
}
