import Foundation

/// When each of the pill's 12 loading squares lights, from the launch load's reports. Every call takes `now`, the
/// time since the first report; squares only ever add, and each keeps the time it was scheduled for, so a grid
/// updated after a pause catches up with past times instead of flashing.
public struct LoadingGrid: Sendable {
    public static let squareCount = 12

    /// How a square comes on: a flicker, at most one a second, or a plain fade.
    public enum Arrival: Equatable, Sendable { case flicker, fade }

    /// A lit square: when it was scheduled to light and how it comes on.
    public struct Lit: Equatable, Sendable {
        public var at: Duration
        public var arrival: Arrival
    }

    /// Squares lit so far in fill order, from the bottom; square index = array index.
    public private(set) var lit: [Lit] = []
    public var litCount: Int { lit.count }
    /// True once a report says every load has finished.
    public private(set) var isFinishing = false
    /// When the last square lights, once it is scheduled.
    public private(set) var allLitAt: Duration?

    private let reduceMotion: Bool
    /// Squares each load owns, in step order; empty until the first report.
    private var owned: [Int] = []
    /// How long each load usually takes, which paces its estimate.
    private var typical: [Duration] = []
    /// Squares the speech model's download owns: 6 when the launch downloads it, else 0.
    private var downloadOwned = 0
    /// The load running now; equals `owned.count` once all are done.
    private var running = 0
    /// When the running load's estimate began; nil while it waits for the download to end.
    private var stepStart: Duration?
    /// The running load's squares the estimate has lit.
    private var estimated = 0
    /// Times of finished loads' squares still waiting to light, in order.
    private var burst: [Duration] = []
    private var downloadTarget = 0
    private var downloadLit = 0
    /// Under Reduce Motion, when a held download batch may light.
    private var heldBatchAt: Duration?
    private var lastBatchAt: Duration?
    private var lastFlicker: Duration?

    private static let burstSpacing = Duration.milliseconds(40)
    private static let flickerGap = Duration.seconds(1)
    private static let batchGap = Duration.milliseconds(500)
    private static let downloadSquares = 6

    public init(reduceMotion: Bool) {
        self.reduceMotion = reduceMotion
    }

    public mutating func report(_ progress: ModelLoadProgress, at now: Duration) {
        if owned.isEmpty {
            let two = progress.stepCount == 2
            if progress.needsDownload {
                downloadOwned = Self.downloadSquares
                owned = two ? [1, 5] : [1, 2, 3]
            } else {
                owned = two ? [2, 10] : [2, 4, 6]
            }
            typical = two ? [.seconds(1), .seconds(30)] : [.seconds(1), .seconds(25), .seconds(30)]
            stepStart = estimateWaitsForDownload ? nil : now
        }
        update(at: now)
        guard !isFinishing else { return }

        let step = min(progress.step, owned.count)
        if step > running {
            var remaining = owned[running..<step].reduce(0, +) - estimated
            if progress.isDone {
                // The last load's end also lights any download square still dark.
                remaining = Self.squareCount - lit.count - burst.count
                heldBatchAt = nil
            }
            schedule(remaining, at: now)
            running = step
            estimated = 0
            stepStart = estimateWaitsForDownload ? nil : now
            if progress.isDone {
                isFinishing = true
                allLitAt = burst.last ?? lit.last?.at ?? now
            }
        }

        if downloadOwned > 0, !progress.isDone, progress.step == owned.count - 1, let downloaded = progress.downloaded {
            let target = min(downloadOwned, Int((Double(downloadOwned) * downloaded).rounded(.down)))
            if target > downloadTarget {
                downloadTarget = target
                if reduceMotion, let last = lastBatchAt, now - last < Self.batchGap {
                    heldBatchAt = last + Self.batchGap
                } else {
                    lightDownload(at: now)
                }
            }
            if downloaded >= 1, stepStart == nil { stepStart = now }
        }
        update(at: now)
    }

    /// Lights every square scheduled at or before `now`, stamped with its scheduled time.
    public mutating func update(at now: Duration) {
        while true {
            let estimate = nextEstimate
            let times = [burst.first, estimate, heldBatchAt].compactMap { $0 }
            guard let next = times.min(), next <= now else { return }
            if next == burst.first {
                burst.removeFirst()
                arrive(at: next)
            } else if next == estimate {
                estimated += 1
                arrive(at: next)
            } else {
                lightDownload(at: next)
            }
        }
    }

    /// When the grid stopped moving, once nothing has lit for a second; nil once finishing or full.
    public func stalledSince(at now: Duration) -> Duration? {
        guard !isFinishing, lit.count < Self.squareCount else { return nil }
        let last = lit.last?.at ?? .zero
        return now - last >= Self.flickerGap ? last + Self.flickerGap : nil
    }

    /// True 260 ms after the last square lights.
    public func isDone(at now: Duration) -> Bool {
        guard let allLitAt else { return false }
        return now >= allLitAt + .milliseconds(260)
    }

    /// The download layout's last load starts its estimate only once its download ends.
    private var estimateWaitsForDownload: Bool {
        downloadOwned > 0 && running == owned.count - 1
    }

    /// When the running load's next square lights on the estimate alone; it never lights the last 15% of them.
    private var nextEstimate: Duration? {
        guard running < owned.count, let stepStart else { return nil }
        let share = 0.85 * Double(owned[running])
        guard Double(estimated + 1) <= share.rounded(.down) else { return nil }
        return stepStart + typical[running] * (-log(1 - Double(estimated + 1) / share) / 3)
    }

    private mutating func schedule(_ count: Int, at now: Duration) {
        guard count > 0 else { return }
        if reduceMotion {
            for _ in 0..<count { arrive(at: now) }
            return
        }
        // A new burst continues after one still queued, keeping 40 ms between squares.
        var time = burst.last.map { $0 + Self.burstSpacing } ?? now
        for _ in 0..<count {
            burst.append(time)
            time += Self.burstSpacing
        }
    }

    private mutating func lightDownload(at time: Duration) {
        for _ in downloadLit..<downloadTarget { arrive(at: time) }
        downloadLit = downloadTarget
        lastBatchAt = time
        heldBatchAt = nil
    }

    private mutating func arrive(at time: Duration) {
        var arrival = Arrival.fade
        if !reduceMotion, lastFlicker.map({ time - $0 >= Self.flickerGap }) ?? true {
            arrival = .flicker
            lastFlicker = time
        }
        lit.append(Lit(at: time, arrival: arrival))
    }
}
