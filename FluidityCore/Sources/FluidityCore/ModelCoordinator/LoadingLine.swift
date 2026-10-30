import Foundation

/// The fill fraction of the pill's loading line from the launch load's reports; it never goes backwards.
public struct LoadingLine: Sendable {
    /// True once a report says every load has finished.
    public private(set) var isFinishing = false

    private let reduceMotion: Bool
    /// Twelfths of the line each load owns, in step order; empty until the first report.
    private var owned: [Int] = []
    /// How long each load usually takes, which paces its estimate.
    private var typical: [Duration] = []
    /// Twelfths the speech model's download owns: 6 when the launch downloads it, else 0.
    private var downloadOwned = 0
    /// The load running now; equals `owned.count` once all are done.
    private var running = 0
    /// When the running load's estimate began; nil while it waits for the download to end.
    private var stepStart: Duration?
    /// The highest download fraction reported for the speech model.
    private var downloadedMax = 0.0
    /// The finished loads' share, eased in from where the line stood when the last of them finished.
    private var easeFrom = 0.0
    private var easeTo = 0.0
    private var easeAt: Duration?
    /// Under Reduce Motion, the value the line fades from and the sample it fades to.
    private var previousValue = 0.0
    private var sampleValue = 0.0
    private var sampledAt = Duration.zero

    private static let easeTime = Duration.milliseconds(300)
    private static let sampleGap = Duration.milliseconds(500)
    private static let fadeTime = Duration.milliseconds(130)

    public init(reduceMotion: Bool) {
        self.reduceMotion = reduceMotion
    }

    public mutating func report(_ progress: ModelLoadProgress, at now: Duration) {
        if owned.isEmpty {
            let two = progress.stepCount == 2
            if progress.needsDownload {
                downloadOwned = 6
                owned = two ? [1, 5] : [1, 2, 3]
            } else {
                owned = two ? [2, 10] : [2, 4, 6]
            }
            typical = two ? [.seconds(1), .seconds(30)] : [.seconds(1), .seconds(25), .seconds(30)]
            running = 0
            stepStart = estimateWaitsForDownload ? nil : now
            sampledAt = now
        }
        guard !isFinishing else { return }

        let step = min(progress.step, owned.count)
        if step > running {
            easeFrom = raw(at: now)
            easeAt = now
            // The last load's end also commits the download's share, so the line ends at exactly 1.
            easeTo = Double(owned[..<step].reduce(0, +) + (step == owned.count ? downloadOwned : 0)) / 12
            running = step
            stepStart = estimateWaitsForDownload ? nil : now
            isFinishing = progress.isDone
        }
        if !progress.isDone, progress.step == owned.count - 1, let downloaded = progress.downloaded {
            downloadedMax = max(downloadedMax, downloaded)
            if downloaded >= 1, stepStart == nil { stepStart = now }
        }
    }

    /// Under Reduce Motion, takes a new sample at most every 500 ms; otherwise does nothing.
    public mutating func update(at now: Duration) {
        guard reduceMotion, !owned.isEmpty, now >= sampledAt + Self.sampleGap else { return }
        previousValue = sampleValue
        sampleValue = min(1, raw(at: now))
        sampledAt = now
    }

    public func fraction(at now: Duration) -> Double {
        guard reduceMotion else { return min(1, raw(at: now)) }
        return previousValue + (sampleValue - previousValue) * max(0, min(1, (now - sampledAt) / Self.fadeTime))
    }

    public func isDone(at now: Duration) -> Bool {
        fraction(at: now) >= 1
    }

    /// One frame of the pill's line: returns the fill to draw and drops `line` once it is over. A load that ended
    /// without finishing (it failed) drops the line at once; a finishing one eases to full first. With no line the
    /// fill is empty while loading and full otherwise.
    public static func step(_ line: inout LoadingLine?, isModelLoading: Bool, at now: Duration) -> Double {
        if !isModelLoading, line?.isFinishing == false { line = nil }
        line?.update(at: now)
        guard let current = line else { return isModelLoading ? 0 : 1 }
        if current.isDone(at: now) { line = nil }
        return current.fraction(at: now)
    }

    /// The download layout's last load starts its estimate only once its download ends.
    private var estimateWaitsForDownload: Bool {
        downloadOwned > 0 && running == owned.count - 1
    }

    /// Finished loads, plus the download so far, plus the running load's estimate, which never passes 85% of its share.
    private func raw(at now: Duration) -> Double {
        var base = easeTo
        if let easeAt, now - easeAt < Self.easeTime {
            let t = max(0, (now - easeAt) / Self.easeTime)
            base = easeFrom + (easeTo - easeFrom) * (t * t * (3 - 2 * t))
        }
        // Once finishing, the eased base already holds the download's share.
        let download = isFinishing ? 0 : Double(downloadOwned) / 12 * downloadedMax
        var estimate = 0.0
        if running < owned.count, let stepStart {
            let t = (now - stepStart) / typical[running]
            estimate = 0.85 * Double(owned[running]) / 12 * (1 - exp(-3 * t))
        }
        return base + download + estimate
    }
}
