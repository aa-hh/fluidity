import AppKit

/// Reports each time a volume mounts, so held dictations can move to the drive.
public protocol MountObserving: Sendable {
    /// One element per mount. Subscribe before checking the drive, so a mount in between is not missed.
    func mounts() -> AsyncStream<Void>
}

/// Mount events from `NSWorkspace.didMountNotification`.
public struct WorkspaceMountObserver: MountObserving {
    public init() {}

    public func mounts() -> AsyncStream<Void> {
        AsyncStream { continuation in
            let center = NSWorkspace.shared.notificationCenter
            nonisolated(unsafe) let token = center.addObserver(
                forName: NSWorkspace.didMountNotification, object: nil, queue: nil
            ) { _ in continuation.yield() }
            continuation.onTermination = { _ in center.removeObserver(token) }
        }
    }
}
