import RilloCore
import Foundation
import Synchronization
import Testing

/// Holds each download until the test completes or fails it; a cancelled download throws `CancellationError`.
/// `removeFails` makes `removeFiles` throw.
final class FakeFetcher<ID: DownloadableModelID>: ModelFetching {
    private struct State {
        var installed: Set<ID>
        var available: Int64
        var downloads: [ID] = []
        var removed: [ID] = []
        var progress: (@Sendable (Double) -> Void)?
        var held: CheckedContinuation<Void, any Error>?
        var removeFails = false
    }

    struct RemoveFailed: Error {}

    private let state: Mutex<State>

    init(installed: Set<ID> = [], available: Int64 = 10_000_000_000) {
        state = Mutex(State(installed: installed, available: available))
    }

    var downloads: [ID] { state.withLock { $0.downloads } }
    var removed: [ID] { state.withLock { $0.removed } }
    var isHolding: Bool { state.withLock { $0.held != nil } }
    var available: Int64 {
        get { state.withLock { $0.available } }
        set { state.withLock { $0.available = newValue } }
    }
    var removeFails: Bool {
        get { state.withLock { $0.removeFails } }
        set { state.withLock { $0.removeFails = newValue } }
    }

    /// Puts a model on disk outside `download`, as an engine's first load does.
    func install(_ id: ID) { state.withLock { _ = $0.installed.insert(id) } }

    func report(_ fraction: Double) { state.withLock { $0.progress }?(fraction) }
    func complete() { take()?.resume() }
    func fail(_ error: any Error) { take()?.resume(throwing: error) }

    private func take() -> CheckedContinuation<Void, any Error>? {
        state.withLock { s in
            defer { s.held = nil }
            return s.held
        }
    }

    func isInstalled(_ id: ID) -> Bool { state.withLock { $0.installed.contains(id) } }
    func availableBytes() -> Int64 { state.withLock { $0.available } }

    func download(_ id: ID, progress: @escaping @Sendable (Double) -> Void) async throws {
        state.withLock {
            $0.downloads.append(id)
            $0.progress = progress
        }
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                state.withLock { $0.held = continuation }
            }
        } onCancel: {
            fail(CancellationError())
        }
    }

    func removeFiles(for id: ID) throws {
        let fails = state.withLock { s in
            if !s.removeFails { s.removed.append(id) }
            return s.removeFails
        }
        if fails { throw RemoveFailed() }
    }
}

typealias FakeModelFetcher = FakeFetcher<SpeechModelID>

/// The two catalogues `ModelDownloads` serves, for tests that run the same steps on each.
enum Catalogue: Sendable { case speech, cleanup }

@MainActor
private func until(_ condition: () -> Bool, sourceLocation: SourceLocation = #_sourceLocation) async {
    let ceiling = ContinuousClock.now + .seconds(10)
    while !condition() {
        if ContinuousClock.now > ceiling {
            Issue.record("condition never held", sourceLocation: sourceLocation)
            return
        }
        await Task.yield()
    }
}

@MainActor
@Suite struct ModelDownloadsTests {
    let proBytes: Int64 = 652_475_761

    func make(
        _ fetcher: FakeModelFetcher, online: Bool = true, inUse: Set<SpeechModelID> = [.parakeetTDTv2]
    ) -> ModelDownloads<SpeechModelID> {
        let downloads = ModelDownloads(fetcher: fetcher, network: FakeNetwork(isOnline: online))
        downloads.inUse = inUse
        return downloads
    }

    /// Starts a download and waits until the fetcher holds it.
    func start<ID: DownloadableModelID>(_ id: ID, _ downloads: ModelDownloads<ID>, _ fetcher: FakeFetcher<ID>) async {
        downloads.download(id)
        await until { fetcher.isHolding }
    }

    func startPro(_ downloads: ModelDownloads<SpeechModelID>, _ fetcher: FakeModelFetcher) async {
        await start(.fluidSpeechPro, downloads, fetcher)
    }

    // Turns red if Apple's model reads as downloadable, or the fetcher's installed check is not used at launch.
    @Test func freshStatesComeFromTheFetcher() {
        let downloads = make(FakeModelFetcher(installed: [.parakeetTDTv2]))
        #expect(downloads.states == [.parakeetTDTv2: .installed, .appleBuiltIn: .partOfMacOS, .fluidSpeechPro: .notInstalled])
    }

    // Turns red if a model an engine downloaded after launch keeps reading as not downloaded,
    // or a refresh drops a download in progress.
    @Test func refreshPicksUpModelsDownloadedElsewhere() async {
        let fetcher = FakeModelFetcher(installed: [])
        let downloads = make(fetcher)
        #expect(downloads.states[.parakeetTDTv2] == .notInstalled)
        await startPro(downloads, fetcher)
        fetcher.install(.parakeetTDTv2)
        downloads.refreshInstalled()
        #expect(downloads.states[.parakeetTDTv2] == .installed)
        #expect(downloads.states[.fluidSpeechPro] == .downloading(downloadedBytes: 0, totalBytes: proBytes))
    }

    // Turns red if progress stops mapping the fraction onto the catalogue size.
    @Test func progressShowsTheFractionOfTheCatalogueBytes() async {
        let fetcher = FakeModelFetcher()
        let downloads = make(fetcher)
        await startPro(downloads, fetcher)
        fetcher.report(0.5)
        await until { downloads.states[.fluidSpeechPro] == .downloading(downloadedBytes: proBytes / 2, totalBytes: proBytes) }
    }

    // Turns red if a finished download, of a speech or a cleanup model, is not marked installed or not reported as just finished.
    @Test(arguments: [Catalogue.speech, .cleanup])
    func finishingInstallsAndReportsTheModel(_ catalogue: Catalogue) async {
        switch catalogue {
        case .speech: await finishes(SpeechModelID.fluidSpeechPro)
        case .cleanup: await finishes(CleanupModelID.s1Mini)
        }
    }

    func finishes<ID: DownloadableModelID>(_ id: ID) async {
        let fetcher = FakeFetcher<ID>()
        let downloads = ModelDownloads(fetcher: fetcher, network: FakeNetwork(isOnline: true))
        await start(id, downloads, fetcher)
        fetcher.complete()
        await until { downloads.states[id] == .installed }
        #expect(downloads.lastFinished == id)
        #expect(downloads.failure == nil)
    }

    // Turns red if cancelling leaves the partial files behind or reports the cancel as a failure.
    @Test func cancelRemovesFilesWithoutAFailure() async {
        let fetcher = FakeModelFetcher()
        let downloads = make(fetcher)
        await startPro(downloads, fetcher)
        downloads.cancelDownload(.fluidSpeechPro)
        await until { downloads.states[.fluidSpeechPro] == .notInstalled }
        #expect(fetcher.removed == [.fluidSpeechPro])
        #expect(downloads.failure == nil)
    }

    // Turns red if a lost connection is reported as anything but offline, a file that fails its checksum as anything
    // but damaged, or either leaves files or a downloading state behind.
    @Test(arguments: [(Catalogue.speech, DownloadFailure.offline), (.cleanup, .damaged)])
    func aFailedDownloadIsReportedAndCleanedUp(_ catalogue: Catalogue, _ reason: DownloadFailure) async {
        let error: any Error = reason == .offline ? URLError(.notConnectedToInternet) : DamagedDownload(file: "model.safetensors")
        switch catalogue {
        case .speech: await fails(SpeechModelID.fluidSpeechPro, with: error, as: reason)
        case .cleanup: await fails(CleanupModelID.rilloCleanup2B, with: error, as: reason)
        }
    }

    func fails<ID: DownloadableModelID>(_ id: ID, with error: any Error, as reason: DownloadFailure) async {
        let fetcher = FakeFetcher<ID>()
        let downloads = ModelDownloads(fetcher: fetcher, network: FakeNetwork(isOnline: true))
        await start(id, downloads, fetcher)
        fetcher.fail(error)
        await until { downloads.states[id] == .notInstalled }
        #expect(downloads.failure?.model == id)
        #expect(downloads.failure?.reason == reason)
        #expect(fetcher.removed == [id])
    }

    // Turns red if a download starts without room for it, or the shortfall is reported wrong.
    @Test func tooLittleSpaceRefusesBeforeDownloading() {
        let fetcher = FakeModelFetcher(available: 500_000_000)
        let downloads = make(fetcher)
        downloads.download(.fluidSpeechPro)
        #expect(downloads.failure?.reason == .notEnoughSpace(neededBytes: proBytes - 500_000_000, availableBytes: 500_000_000))
        #expect(downloads.states[.fluidSpeechPro] == .notInstalled)
        #expect(fetcher.downloads.isEmpty)
    }

    // Turns red if a disk filling up mid-download reports anything but the free space the fetcher reads at that moment.
    @Test func runningOutOfSpaceMidDownloadReportsTheFreeSpaceLeft() async {
        let fetcher = FakeModelFetcher()
        let downloads = make(fetcher)
        await startPro(downloads, fetcher)
        fetcher.available = 20_000_000
        fetcher.fail(CocoaError(.fileWriteOutOfSpace))
        await until { downloads.failure != nil }
        #expect(downloads.failure?.reason == .notEnoughSpace(neededBytes: proBytes, availableBytes: 20_000_000))
    }

    // Turns red if Download can fetch a model in use, which the launch load may be downloading into the same folder.
    @Test func aModelInUseIsNeverDownloaded() {
        let fetcher = FakeModelFetcher(installed: [])
        let downloads = make(fetcher, inUse: [.parakeetTDTv2])
        downloads.download(.parakeetTDTv2)
        #expect(fetcher.downloads.isEmpty)
        #expect(downloads.states[.parakeetTDTv2] == .notInstalled)
    }

    // Turns red if a second press of Download starts a second fetch of the same model.
    @Test func aSecondDownloadWhileDownloadingIsIgnored() async {
        let fetcher = FakeModelFetcher()
        let downloads = make(fetcher)
        await startPro(downloads, fetcher)
        downloads.download(.fluidSpeechPro)
        #expect(fetcher.downloads == [.fluidSpeechPro])
    }

    // Turns red if a model in use (chosen, or still dictating while a switch loads), part of macOS, still downloading
    // or open in the compare window can be deleted, or an installed model that is none of these cannot, including the
    // chosen cleanup model, which the user may delete.
    @Test func deleteRefusesWhatMustStay() async throws {
        let fetcher = FakeModelFetcher(installed: [.parakeetTDTv2])
        let downloads = make(fetcher, inUse: [.parakeetTDTv2, .appleBuiltIn])
        #expect(throws: DeleteRefusal.inUse) { try downloads.delete(.parakeetTDTv2) }
        downloads.inUse = [.fluidSpeechPro, .parakeetTDTv2]
        #expect(throws: DeleteRefusal.inUse) { try downloads.delete(.parakeetTDTv2) }
        downloads.inUse = [.appleBuiltIn]
        #expect(throws: DeleteRefusal.partOfMacOS) { try downloads.delete(.appleBuiltIn) }
        await startPro(downloads, fetcher)
        #expect(throws: DeleteRefusal.downloading) { try downloads.delete(.fluidSpeechPro) }
        fetcher.complete()
        await until { downloads.states[.fluidSpeechPro] == .installed }

        downloads.setOpenInCompare([.fluidSpeechPro])
        #expect(throws: DeleteRefusal.openInCompare) { try downloads.delete(.fluidSpeechPro) }
        downloads.setOpenInCompare([])
        try downloads.delete(.fluidSpeechPro)
        #expect(downloads.states[.fluidSpeechPro] == .notInstalled)
        #expect(fetcher.removed == [.fluidSpeechPro])

        let cleanup = ModelDownloads(fetcher: FakeFetcher<CleanupModelID>(installed: [.s1Mini]), network: FakeNetwork(isOnline: true))
        try cleanup.delete(.s1Mini)
        #expect(cleanup.states[.s1Mini] == .notInstalled)
    }

    // Turns red if a delete whose files could not be removed marks the model not installed, or says nothing.
    @Test func aFailedDeleteKeepsTheModelAndReportsIt() throws {
        let fetcher = FakeModelFetcher(installed: [.parakeetTDTv2, .fluidSpeechPro])
        fetcher.removeFails = true
        let downloads = make(fetcher)
        try downloads.delete(.fluidSpeechPro)
        #expect(downloads.states[.fluidSpeechPro] == .installed)
        #expect(downloads.failure?.model == .fluidSpeechPro)
        #expect(downloads.failure?.reason == .other(String(describing: FakeModelFetcher.RemoveFailed())))
    }

    // Turns red if the TDT v2 id stops matching the model version string older dictation records hold.
    @Test func theDefaultModelIdMatchesOldRecords() {
        #expect(SpeechModelID.parakeetTDTv2.rawValue == "parakeet-tdt-0.6b-v2")
    }
}
