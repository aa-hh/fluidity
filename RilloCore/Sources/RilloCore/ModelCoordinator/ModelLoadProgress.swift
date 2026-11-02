import Foundation

/// How far the launch load has got: which of its loads is running, and that load's download.
public struct ModelLoadProgress: Equatable, Sendable {
    /// Loads finished so far, which is also the index of the one running; equals `stepCount` once all are done.
    public var step: Int
    /// How many loads the launch runs, the speech model's last.
    public var stepCount: Int
    /// True when the dictation model was not on this Mac when the load began, so the launch downloads it.
    public var needsDownload: Bool
    /// The running load's download from 0 to 1 when the library measures it, else nil.
    public var downloaded: Double?

    public init(step: Int, stepCount: Int, needsDownload: Bool, downloaded: Double?) {
        self.step = step
        self.stepCount = stepCount
        self.needsDownload = needsDownload
        self.downloaded = downloaded
    }

    /// True once every load has finished.
    public var isDone: Bool { step >= stepCount }

    /// The speech model's download from 0 to 1, for the first-run window's bar: 0 before its load starts, 1 once done.
    public var downloadFraction: Double {
        if isDone { return 1 }
        return step == stepCount - 1 ? downloaded ?? 0 : 0
    }
}
