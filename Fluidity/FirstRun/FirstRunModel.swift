import Observation

/// The first-run check's speech model row and its Done action. Permission state and the
/// dictation key come from `SettingsModel`.
@MainActor
@Observable
final class FirstRunModel {
    /// The download's progress from 0 to 1, as `Transcriber.prepare(progress:)` reports it.
    var modelProgress: Double = 0
    /// The model is downloaded and loaded.
    var isModelReady = false
    /// Set when the download or load failed, in words for the row.
    var modelError: String?

    var onDone: () -> Void = {}
}
