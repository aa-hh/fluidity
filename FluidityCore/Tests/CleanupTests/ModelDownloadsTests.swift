import FluidityCore
import Foundation
import Synchronization
import Testing

/// Holds each download until the test completes or fails it; a cancelled download throws `CancellationError`.
final class FakeModelFetcher: ModelFetching {
    private struct State {
        var installed: Set<SpeechModelID>
        var available: Int64
        var downloads: [SpeechModelID] = []
        var removed: [SpeechModelID] = []
        var progress: (@Sendable (Double) -> Void)?
        var held: CheckedContinuation<Void, any Error>?
    }

    private let state: Mutex<State>

    init(installed: Set<SpeechModelID> = [.parakeetTDTv2], available: Int64 = 10_000_000_000) {
        state = Mutex(State(installed: installed, available: available))
    }

    var downloads: [SpeechModelID] { state.withLock { $0.downloads } }
    var removed: [SpeechModelID] { state.withLock { $0.removed } }
    var isHolding: Bool { state.withLock { $0.held != nil } }

    func report(_ fraction: Double) { state.withLock { $0.progress }?(fraction) }
    func complete() { take()?.resume() }
    func fail(_ error: any Error) { take()?.resume(throwing: error) }

    private func take() -> CheckedContinuation<Void, any Error>? {
        state.withLock { s in
            defer { s.held = nil }
            return s.held
        }
    }

    func isInstalled(_ id: SpeechModelID) -> Bool { state.withLock { $0.installed.contains(id) } }
    func availableBytes() -> Int64 { state.withLock { $0.available } }

    func download(_ id: SpeechModelID, progress: @escaping @Sendable (Double) -> Void) async throws {
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

    func removeFiles(for id: SpeechModelID) throws { state.withLock { $0.removed.append(id) } }
}

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
    let unifiedBytes: Int64 = 565_000_000

    func make(
        _ fetcher: FakeModelFetcher, online: Bool = true, inUse: SpeechModelID = .parakeetTDTv2
    ) -> ModelDownloads {
        ModelDownloads(fetcher: fetcher, network: FakeNetwork(isOnline: online), inUse: { inUse })
    }

    /// Starts a Unified download and waits until the fetcher holds it.
    func startUnified(_ downloads: ModelDownloads, _ fetcher: FakeModelFetcher) async {
        downloads.download(.parakeetUnified)
        await until { fetcher.isHolding }
    }

    // Turns red if Apple's model reads as downloadable, or the fetcher's installed check is not used at launch.
    @Test func freshStatesComeFromTheFetcher() {
        let downloads = make(FakeModelFetcher())
        #expect(downloads.states == [.parakeetTDTv2: .installed, .appleBuiltIn: .partOfMacOS, .parakeetUnified: .notInstalled])
    }

    // Turns red if progress stops mapping the fraction onto the catalogue size.
    @Test func progressShowsTheFractionOfTheCatalogueBytes() async {
        let fetcher = FakeModelFetcher()
        let downloads = make(fetcher)
        await startUnified(downloads, fetcher)
        fetcher.report(0.5)
        await until { downloads.states[.parakeetUnified] == .downloading(downloadedBytes: unifiedBytes / 2, totalBytes: unifiedBytes) }
    }

    // Turns red if a finished download is not marked installed or not reported as just finished.
    @Test func finishingInstallsAndReportsTheModel() async {
        let fetcher = FakeModelFetcher()
        let downloads = make(fetcher)
        await startUnified(downloads, fetcher)
        fetcher.complete()
        await until { downloads.states[.parakeetUnified] == .installed }
        #expect(downloads.lastFinished == .parakeetUnified)
        #expect(downloads.failure == nil)
    }

    // Turns red if cancelling leaves the partial files behind or reports the cancel as a failure.
    @Test func cancelRemovesFilesWithoutAFailure() async {
        let fetcher = FakeModelFetcher()
        let downloads = make(fetcher)
        await startUnified(downloads, fetcher)
        downloads.cancelDownload(.parakeetUnified)
        await until { downloads.states[.parakeetUnified] == .notInstalled }
        #expect(fetcher.removed == [.parakeetUnified])
        #expect(downloads.failure == nil)
    }

    // Turns red if a lost connection is reported as anything but offline, or leaves files or a downloading state behind.
    @Test func aConnectionErrorFailsAsOffline() async {
        let fetcher = FakeModelFetcher()
        let downloads = make(fetcher)
        await startUnified(downloads, fetcher)
        fetcher.fail(URLError(.notConnectedToInternet))
        await until { downloads.states[.parakeetUnified] == .notInstalled }
        #expect(downloads.failure?.model == .parakeetUnified)
        #expect(downloads.failure?.reason == .offline)
        #expect(fetcher.removed == [.parakeetUnified])
    }

    // Turns red if a download starts without room for it, or the shortfall is reported wrong.
    @Test func tooLittleSpaceRefusesBeforeDownloading() {
        let fetcher = FakeModelFetcher(available: 500_000_000)
        let downloads = make(fetcher)
        downloads.download(.parakeetUnified)
        #expect(downloads.failure?.reason == .notEnoughSpace(neededBytes: unifiedBytes - 500_000_000))
        #expect(downloads.states[.parakeetUnified] == .notInstalled)
        #expect(fetcher.downloads.isEmpty)
    }

    // Turns red if a second press of Download starts a second fetch of the same model.
    @Test func aSecondDownloadWhileDownloadingIsIgnored() async {
        let fetcher = FakeModelFetcher()
        let downloads = make(fetcher)
        await startUnified(downloads, fetcher)
        downloads.download(.parakeetUnified)
        #expect(fetcher.downloads == [.parakeetUnified])
    }

    // Turns red if a model in use, part of macOS, still downloading or open in the compare window can be deleted,
    // or an installed model that is none of these cannot.
    @Test func deleteRefusesWhatMustStay() async throws {
        let fetcher = FakeModelFetcher(installed: [.parakeetTDTv2])
        let downloads = make(fetcher, inUse: .parakeetTDTv2)
        #expect(throws: DeleteRefusal.inUse) { try downloads.delete(.parakeetTDTv2) }
        #expect(throws: DeleteRefusal.partOfMacOS) { try downloads.delete(.appleBuiltIn) }
        await startUnified(downloads, fetcher)
        #expect(throws: DeleteRefusal.downloading) { try downloads.delete(.parakeetUnified) }
        fetcher.complete()
        await until { downloads.states[.parakeetUnified] == .installed }

        downloads.setOpenInCompare([.parakeetUnified])
        #expect(throws: DeleteRefusal.openInCompare) { try downloads.delete(.parakeetUnified) }
        downloads.setOpenInCompare([])
        try downloads.delete(.parakeetUnified)
        #expect(downloads.states[.parakeetUnified] == .notInstalled)
        #expect(fetcher.removed == [.parakeetUnified])
    }

    // Turns red if the TDT v2 id stops matching the model version string older dictation records hold.
    @Test func theDefaultModelIdMatchesOldRecords() {
        #expect(SpeechModelID.parakeetTDTv2.rawValue == "parakeet-tdt-0.6b-v2")
    }
}
