import Foundation
import Observation

/// A catalogue's model ids, as `ModelDownloads` needs them.
public protocol DownloadableModelID: Hashable, CaseIterable, Sendable {
    /// The bytes a download fetches; nil for a model that is part of macOS.
    var downloadBytes: Int64? { get }
}

/// What `ModelDownloads` needs from the model files on disk and the network.
public protocol ModelFetching<ID>: Sendable {
    associatedtype ID: DownloadableModelID
    func isInstalled(_ id: ID) -> Bool
    /// Free bytes on the volume the models are saved to.
    func availableBytes() -> Int64
    /// Downloads the model's files; `progress` runs from 0 to 1.
    func download(_ id: ID, progress: @escaping @Sendable (Double) -> Void) async throws
    func removeFiles(for id: ID) throws
}

/// Thrown by a fetcher when a downloaded file's size or checksum does not match the catalogue.
public struct DamagedDownload: Error {
    public let file: String
    public init(file: String) { self.file = file }
}

/// Free bytes on the volume holding `url`, which may not exist yet: its nearest existing parent is on the same volume.
func freeBytes(onVolumeOf url: URL) -> Int64 {
    var url = url
    while !FileManager.default.fileExists(atPath: url.path), url.pathComponents.count > 1 {
        url.deleteLastPathComponent()
    }
    let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
    return values?.volumeAvailableCapacityForImportantUsage ?? 0
}

public enum ModelState: Equatable, Sendable {
    case partOfMacOS
    case notInstalled
    case downloading(downloadedBytes: Int64, totalBytes: Int64)
    case installed
}

public enum DownloadFailure: Equatable, Sendable {
    case offline
    /// `availableBytes` is the free space the fetcher reported when the failure was found.
    case notEnoughSpace(neededBytes: Int64, availableBytes: Int64)
    case damaged
    case other(String)
}

public enum DeleteRefusal: Error, Equatable {
    case inUse
    case partOfMacOS
    case downloading
    case openInCompare
}

/// Each model's install state, and downloading, cancelling and deleting the optional ones.
/// It never changes the model the user dictates with.
@MainActor
@Observable
public final class ModelDownloads<ID: DownloadableModelID> {
    public private(set) var states: [ID: ModelState] = [:]
    /// The last download that failed, and why; cleared when a new download starts.
    public private(set) var failure: (model: ID, reason: DownloadFailure)?
    /// The model whose download finished most recently, until `clearLastFinished`.
    public private(set) var lastFinished: ID?
    /// Models that cannot be deleted because dictation needs them: the chosen one, the one still dictating
    /// while a switch loads, and any a switch is loading. `ModelCoordinator` keeps it current; cleanup models leave it empty.
    @ObservationIgnored public var inUse: Set<ID> = []

    @ObservationIgnored private let fetcher: any ModelFetching<ID>
    @ObservationIgnored private let network: any NetworkMonitoring
    @ObservationIgnored private var tasks: [ID: Task<Void, Never>] = [:]
    @ObservationIgnored private var openInCompare: Set<ID> = []

    public init(fetcher: any ModelFetching<ID>, network: any NetworkMonitoring) {
        self.fetcher = fetcher
        self.network = network
        for id in ID.allCases where id.downloadBytes == nil {
            states[id] = .partOfMacOS
        }
        refreshInstalled()
    }

    /// Reads again which models are on disk, for one downloaded outside `download`, such as by an engine's first load.
    /// A download in progress keeps its state.
    public func refreshInstalled() {
        for id in ID.allCases where id.downloadBytes != nil {
            if case .downloading = states[id] { continue }
            states[id] = fetcher.isInstalled(id) ? .installed : .notInstalled
        }
    }

    /// Ignored for a model in use: one not on disk is being downloaded by its engine's load already.
    public func download(_ id: ID) {
        guard !inUse.contains(id), states[id] == .notInstalled, let bytes = id.downloadBytes else { return }
        failure = nil
        let free = fetcher.availableBytes()
        guard free >= bytes else {
            failure = (id, .notEnoughSpace(neededBytes: bytes - free, availableBytes: free))
            return
        }
        states[id] = .downloading(downloadedBytes: 0, totalBytes: bytes)
        let fetcher = fetcher
        tasks[id] = Task {
            do {
                try await fetcher.download(id) { fraction in
                    Task { @MainActor in self.showProgress(fraction, of: id, totalBytes: bytes) }
                }
                tasks[id] = nil
                states[id] = .installed
                lastFinished = id
            } catch {
                tasks[id] = nil
                try? fetcher.removeFiles(for: id)
                states[id] = .notInstalled
                if !(error is CancellationError) && !Task.isCancelled {
                    failure = (id, classify(error, bytes: bytes))
                }
            }
        }
    }

    public func cancelDownload(_ id: ID) {
        tasks[id]?.cancel()
    }

    public func delete(_ id: ID) throws(DeleteRefusal) {
        if id.downloadBytes == nil { throw .partOfMacOS }
        if inUse.contains(id) { throw .inUse }
        if case .downloading = states[id] { throw .downloading }
        if openInCompare.contains(id) { throw .openInCompare }
        do {
            try fetcher.removeFiles(for: id)
        } catch {
            // Files that could not be removed may still be whole, so the model stays installed.
            failure = (id, .other(String(describing: error)))
            return
        }
        states[id] = .notInstalled
    }

    /// The models the compare window holds, which cannot be deleted while it is open.
    public func setOpenInCompare(_ ids: Set<ID>) {
        openInCompare = ids
    }

    public func clearLastFinished() {
        lastFinished = nil
    }

    private func showProgress(_ fraction: Double, of id: ID, totalBytes: Int64) {
        // A progress report that lands after the download ended is dropped.
        guard case .downloading = states[id] else { return }
        states[id] = .downloading(downloadedBytes: Int64(fraction * Double(totalBytes)), totalBytes: totalBytes)
    }

    private func classify(_ error: any Error, bytes: Int64) -> DownloadFailure {
        let offlineCodes: Set<URLError.Code> = [
            .notConnectedToInternet, .networkConnectionLost, .cannotFindHost,
            .cannotConnectToHost, .dnsLookupFailed, .timedOut,
        ]
        if error is DamagedDownload { return .damaged }
        if !network.isOnline { return .offline }
        if let urlError = error as? URLError, offlineCodes.contains(urlError.code) { return .offline }
        let outOfSpace = DownloadFailure.notEnoughSpace(neededBytes: bytes, availableBytes: fetcher.availableBytes())
        if let cocoa = error as? CocoaError, cocoa.code == .fileWriteOutOfSpace { return outOfSpace }
        let nsError = error as NSError
        if nsError.domain == NSPOSIXErrorDomain, nsError.code == Int(ENOSPC) { return outOfSpace }
        return .other(String(describing: error))
    }
}
