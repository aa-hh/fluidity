/// The microphone as `AudioCapture` sees it: 16 kHz mono Float32 audio from a running engine.
public protocol AudioInput: Sendable {
    /// Starts the engine. `handler` receives events in order, on any thread, until `stop()` or `.lost`.
    func start(_ handler: @escaping @Sendable (AudioInputEvent) -> Void) throws
    /// Stops the engine. Waits for a handler call in progress, so never call it while holding a lock the handler takes.
    func stop()
}

public enum AudioInputEvent: Sendable {
    /// 16 kHz mono Float32 samples.
    case samples([Float])
    /// The device changed or the engine stopped on its own. The input has already stopped itself.
    case lost
}
