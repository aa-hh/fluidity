import Foundation
import Observation

/// What `ModelDownloads` needs from the model files on disk and the network.
public protocol ModelFetching: Sendable {
    func isInstalled(_ id: SpeechModelID) -> Bool
    /// Free bytes on the volume the models are saved to.
    func availableBytes() -> Int64
    /// Downloads the model's files; `progress` runs from 0 to 1.
    func download(_ id: SpeechModelID, progress: @escaping @Sendable (Double) -> Void) async throws
    func removeFiles(for id: SpeechModelID) throws
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
public final class ModelDownloads {
    public private(set) var states: [SpeechModelID: ModelState] = [:]
    /// The last download that failed, and why; cleared when a new download starts.
    public private(set) var failure: (model: SpeechModelID, reason: DownloadFailure)?
    /// The model whose download finished most recently, until `clearLastFinished`.
    public private(set) var lastFinished: SpeechModelID?
    /// Models that cannot be deleted because dictation needs them: the chosen one, the one still dictating
    /// while a switch loads, and any a switch is loading. `ModelCoordinator` keeps it current.
    @ObservationIgnored public var inUse: Set<SpeechModelID> = []

    @ObservationIgnored private let fetcher: any ModelFetching
    @ObservationIgnored private let network: any NetworkMonitoring
    @ObservationIgnored private var tasks: [SpeechModelID: Task<Void, Never>] = [:]
    @ObservationIgnored private var openInCompare: Set<SpeechModelID> = []

    public init(fetcher: any ModelFetching, network: any NetworkMonitoring) {
        self.fetcher = fetcher
        self.network = network
        for model in SpeechModel.all {
            if case .partOfMacOS = model.install { states[model.id] = .partOfMacOS }
        }
        refreshInstalled()
    }

    /// Reads again which models are on disk, for one downloaded outside `download`, such as by an engine's first load.
    /// A download in progress keeps its state.
    public func refreshInstalled() {
        for model in SpeechModel.all {
            guard case .download = model.install else { continue }
            if case .downloading = states[model.id] { continue }
            states[model.id] = fetcher.isInstalled(model.id) ? .installed : .notInstalled
        }
    }

    /// Ignored for a model in use: one not on disk is being downloaded by its engine's load already.
    public func download(_ id: SpeechModelID) {
        guard !inUse.contains(id), states[id] == .notInstalled, case .download(let bytes, _, _) = SpeechModel.model(id).install else { return }
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

    public func cancelDownload(_ id: SpeechModelID) {
        tasks[id]?.cancel()
    }

    public func delete(_ id: SpeechModelID) throws(DeleteRefusal) {
        if case .partOfMacOS = SpeechModel.model(id).install { throw .partOfMacOS }
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
    public func setOpenInCompare(_ ids: Set<SpeechModelID>) {
        openInCompare = ids
    }

    public func clearLastFinished() {
        lastFinished = nil
    }

    private func showProgress(_ fraction: Double, of id: SpeechModelID, totalBytes: Int64) {
        // A progress report that lands after the download ended is dropped.
        guard case .downloading = states[id] else { return }
        states[id] = .downloading(downloadedBytes: Int64(fraction * Double(totalBytes)), totalBytes: totalBytes)
    }

    private func classify(_ error: any Error, bytes: Int64) -> DownloadFailure {
        let offlineCodes: Set<URLError.Code> = [
            .notConnectedToInternet, .networkConnectionLost, .cannotFindHost,
            .cannotConnectToHost, .dnsLookupFailed, .timedOut,
        ]
        if !network.isOnline { return .offline }
        if let urlError = error as? URLError, offlineCodes.contains(urlError.code) { return .offline }
        let outOfSpace = DownloadFailure.notEnoughSpace(neededBytes: bytes, availableBytes: fetcher.availableBytes())
        if let cocoa = error as? CocoaError, cocoa.code == .fileWriteOutOfSpace { return outOfSpace }
        let nsError = error as NSError
        if nsError.domain == NSPOSIXErrorDomain, nsError.code == Int(ENOSPC) { return outOfSpace }
        return .other(String(describing: error))
    }
}
