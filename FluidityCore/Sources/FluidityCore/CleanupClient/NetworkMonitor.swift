import Foundation
import Network
import Synchronization

/// Whether the Mac has a network path, so cleanup can fall back at once when it has none.
public protocol NetworkMonitoring: Sendable {
    var isOnline: Bool { get }
}

/// Follows `NWPathMonitor` for as long as it lives.
public final class NetworkMonitor: NetworkMonitoring {
    private let monitor = NWPathMonitor()
    // Online until the first update, so a dictation right after launch is not refused.
    private let online = Mutex(true)

    public init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.online.withLock { $0 = path.status == .satisfied }
        }
        monitor.start(queue: DispatchQueue(label: "com.fluidity.network-monitor"))
    }

    deinit { monitor.cancel() }

    public var isOnline: Bool { online.withLock { $0 } }
}
