import FluidityCore
import Synchronization

/// An `AudioInput` the test feeds by hand. Deliveries reach `AudioCapture` synchronously.
final class FakeAudioInput: AudioInput {
    private struct State {
        var handler: (@Sendable (AudioInputEvent) -> Void)?
        var starts = 0
        var stops = 0
    }

    private let state = Mutex(State())
    private let stopSink: AsyncStream<Void>.Continuation
    /// One element per `stop()` call.
    let stopped: AsyncStream<Void>

    init() { (stopped, stopSink) = AsyncStream.makeStream() }

    var starts: Int { state.withLock { $0.starts } }
    var stops: Int { state.withLock { $0.stops } }

    func start(_ handler: @escaping @Sendable (AudioInputEvent) -> Void) throws {
        state.withLock { s in
            s.starts += 1
            s.handler = handler
        }
    }

    func stop() {
        state.withLock { s in
            s.stops += 1
            s.handler = nil
        }
        stopSink.yield()
    }

    func deliver(_ samples: [Float]) { send(.samples(samples)) }

    /// Sends `.lost` and stops, as the real input does on a device change.
    func lose() {
        let handler = state.withLock { s in
            defer { s.handler = nil }
            return s.handler
        }
        handler?(.lost)
    }

    private func send(_ event: AudioInputEvent) {
        state.withLock { $0.handler }?(event)
    }
}
