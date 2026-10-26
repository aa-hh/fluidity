/// What the recording pill shows.
public enum PillState: Equatable, Sendable {
    case hidden
    case listening(preview: String, mode: DictationController.RecordingMode)
    /// The 200 ms of audio after release, then the final pass.
    case finishing
    case cleaning
    case pasted
    /// The raw transcript was pasted after a fallback; shown quietly.
    case pastedRawTranscript
    case nowhereToPaste
    /// Escape: nothing was pasted.
    case cancelled
    case permissionMissing(DictationController.Permission)
    /// No new words for 5 seconds; recording continues.
    case micSilent
    /// Recording passed 19 minutes; it stops at 20.
    case recordingLimitNear
    /// Recording reached 20 minutes and stopped; shown while it finishes.
    case recordingStoppedAtLimit
}

/// What the menu bar icon shows.
public enum MenuBarState: Equatable, Sendable {
    case ready
    /// From key down until the paste or cancel.
    case recording
    /// The 3 minutes after a dictation, while macOS still shows the microphone in use.
    case micWarm
    /// Cleanup is switched off or has no key, so the raw transcript is pasted.
    case cleanupOff
    case permissionMissing(DictationController.Permission)
}
