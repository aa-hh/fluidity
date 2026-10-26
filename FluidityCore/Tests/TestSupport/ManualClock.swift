import Foundation

/// A clock that moves only when a test calls `advance(by:)`, so timing tests never wait on real time.
public final class ManualClock: Clock, @unchecked Sendable {
    public struct Instant: InstantProtocol {
        public var offset: Duration

        public init(offset: Duration) { self.offset = offset }

        public func advanced(by duration: Duration) -> Instant { Instant(offset: offset + duration) }
        public func duration(to other: Instant) -> Duration { other.offset - offset }
        public static func < (lhs: Instant, rhs: Instant) -> Bool { lhs.offset < rhs.offset }
    }

    private struct Sleeper {
        let id: UInt64
        let deadline: Instant
        let continuation: CheckedContinuation<Void, any Error>
    }

    private let lock = NSLock()
    private var current = Instant(offset: .zero)
    private var sleepers: [Sleeper] = []
    private var nextID: UInt64 = 0

    public init() {}

    public var now: Instant { lock.withLock { current } }
    public var minimumResolution: Duration { .zero }

    public func sleep(until deadline: Instant, tolerance: Duration? = nil) async throws {
        let id = lock.withLock { nextID += 1; return nextID }
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                enum Outcome { case parked, due, cancelled }
                let outcome: Outcome = lock.withLock {
                    // Checked under the lock so a cancel that lands before parking is not lost.
                    if Task.isCancelled { return .cancelled }
                    if deadline <= current { return .due }
                    sleepers.append(Sleeper(id: id, deadline: deadline, continuation: continuation))
                    return .parked
                }
                switch outcome {
                case .parked: break
                case .due: continuation.resume()
                case .cancelled: continuation.resume(throwing: CancellationError())
                }
            }
        } onCancel: {
            let sleeper: Sleeper? = lock.withLock {
                guard let index = sleepers.firstIndex(where: { $0.id == id }) else { return nil }
                return sleepers.remove(at: index)
            }
            sleeper?.continuation.resume(throwing: CancellationError())
        }
    }

    /// Moves the clock forward and wakes every sleeper whose deadline has passed, earliest first.
    public func advance(by duration: Duration) async {
        // Gives tasks that are about to sleep a chance to park before the clock moves.
        for _ in 0..<10 { await Task.yield() }
        let due: [Sleeper] = lock.withLock {
            current = current.advanced(by: duration)
            let due = sleepers.filter { $0.deadline <= current }.sorted { $0.deadline < $1.deadline }
            sleepers.removeAll { $0.deadline <= current }
            return due
        }
        for sleeper in due { sleeper.continuation.resume() }
    }
}
