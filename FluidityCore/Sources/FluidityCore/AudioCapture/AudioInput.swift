/// The microphone as `AudioCapture` sees it: 16 kHz mono Float32 audio while started.
public protocol AudioInput: Sendable {
    /// Starts the microphone. `handler` receives events in order, on any thread, until `stop()` or `.lost`.
    func start(_ handler: @escaping @Sendable (AudioInputEvent) -> Void) throws
    /// Stops the microphone. Waits for handler calls in progress or queued, so never call it while holding a lock the handler takes.
    func stop()
}

public enum AudioInputEvent: Sendable {
    /// 16 kHz mono Float32 samples.
    case samples([Float])
    /// The device changed or the engine stopped on its own. The input has already stopped itself.
    case lost
}
