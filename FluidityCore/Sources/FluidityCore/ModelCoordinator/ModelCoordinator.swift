import Foundation
import Observation

/// Which speech model dictation uses, which models the compare window holds, and when each engine is loaded
/// or unloaded. The app shell builds it once and mirrors its state into the windows.
@MainActor
@Observable
public final class ModelCoordinator {
    /// A compare column's engine load: finished, or failed with the error's description.
    public enum LoadResult: Equatable, Sendable {
        case loaded
        case failed(String)
    }

    /// A switch whose load failed; dictation stays on the model it used before.
    public struct SwitchFailure: Equatable, Sendable {
        public var model: SpeechModelID
        public var message: String
    }

    /// The dictation transcriber, built on the model the launch choice settled on.
    public let transcriber: Transcriber
    /// The model the transcriber dictates with now; the chosen model runs ahead of it while a switch loads.
    public private(set) var dictationModel: SpeechModelID {
        didSet { refreshInUse() }
    }
    /// Models dictation needs: the chosen one, the one still dictating while a switch loads, and any a switch is loading.
    public private(set) var modelsInUse: Set<SpeechModelID> = [] {
        didSet { downloads.inUse = modelsInUse }
    }
    /// Models the open compare window holds, which a switch must not unload and nobody may delete.
    public private(set) var modelsInCompare: Set<SpeechModelID> = [] {
        didSet { downloads.setOpenInCompare(modelsInCompare) }
    }
    /// The last switch that failed; cleared by the next choice.
    public private(set) var switchFailure: SwitchFailure?
    /// Each compare column's engine load, by model; a model still loading has no entry.
    public private(set) var compareLoads: [SpeechModelID: LoadResult] = [:]
    /// The open compare window's session, which takes the dictation key while it exists.
    public private(set) var compare: CompareSession?
    /// True while `prepare` loads the launch model, which the first launch downloads outside `ModelDownloads`.
    public private(set) var isPreparing = false

    @ObservationIgnored private let chosenModel: () -> SpeechModelID
    @ObservationIgnored private let setChosenModel: (SpeechModelID) -> Void
    @ObservationIgnored private let engines: [SpeechModelID: any SpeechEngine]
    @ObservationIgnored private let downloads: ModelDownloads
    @ObservationIgnored private let loadSupport: @Sendable () async throws -> Void
    @ObservationIgnored private let makeTranscriber: (any SpeechEngine, SpeechModelID) -> Transcriber
    @ObservationIgnored private let makeCompareSession: (@escaping (SpeechModelID) -> Transcriber) -> CompareSession
    /// Models a switch is loading.
    @ObservationIgnored private var switching: Set<SpeechModelID> = []
    /// Models the compare window asked to load that are still loading.
    @ObservationIgnored private var compareLoading: Set<SpeechModelID> = []
    @ObservationIgnored private var compareWatch: Task<Void, Never>?
    /// The last closed compare session, whose discard the next dictation waits for.
    @ObservationIgnored private var closedCompare: CompareSession?

    /// - Parameters:
    ///   - loadSupport: loads Silero and the CTC recheck, which every model other than Parakeet TDT v2 needs on its own.
    ///   - makeTranscriber: builds a transcriber on an engine, for dictation and for each compare column.
    ///   - makeCompareSession: builds a compare session over the shared microphone with the given transcriber factory.
    public init(
        chosenModel: @escaping () -> SpeechModelID,
        setChosenModel: @escaping (SpeechModelID) -> Void,
        engines: [SpeechModelID: any SpeechEngine],
        downloads: ModelDownloads,
        loadSupport: @escaping @Sendable () async throws -> Void,
        makeTranscriber: @escaping (any SpeechEngine, SpeechModelID) -> Transcriber,
        makeCompareSession: @escaping (@escaping (SpeechModelID) -> Transcriber) -> CompareSession
    ) {
        // A chosen model that is no longer on this Mac, or has no engine, falls back to the default.
        var chosen = chosenModel()
        if engines[chosen] == nil || ![.installed, .partOfMacOS].contains(downloads.states[chosen]) {
            chosen = .parakeetTDTv2
            setChosenModel(chosen)
        }
        self.chosenModel = chosenModel
        self.setChosenModel = setChosenModel
        self.engines = engines
        self.downloads = downloads
        self.loadSupport = loadSupport
        self.makeTranscriber = makeTranscriber
        self.makeCompareSession = makeCompareSession
        transcriber = makeTranscriber(engines[chosen]!, chosen)
        dictationModel = chosen
        modelsInUse = [chosen]
        downloads.inUse = modelsInUse
    }

    /// Loads the launch model, downloading it on first launch; `progress` runs from 0 to 1.
    public func prepare(progress: @escaping @Sendable (Double) -> Void) async throws {
        isPreparing = true
        defer {
            isPreparing = false
            // The first launch downloads Parakeet TDT v2 here, outside `ModelDownloads`.
            downloads.refreshInstalled()
        }
        if dictationModel != .parakeetTDTv2 { try await loadSupport() }
        try await transcriber.prepare(progress: progress)
    }

    /// Saves the choice and switches the transcriber to it once no dictation is running.
    /// A failed load puts back the model still dictating, which cannot have been deleted.
    public func choose(_ id: SpeechModelID) {
        guard let engine = engines[id] else { return }
        setChosenModel(id)
        switchFailure = nil
        switching.insert(id)
        refreshInUse()
        Task {
            defer {
                switching.remove(id)
                refreshInUse()
                // A load may have downloaded the model's files.
                downloads.refreshInstalled()
            }
            do {
                _ = try await transcriber.switchEngine(to: engine, model: id)
                let old = dictationModel
                dictationModel = id
                unloadUnlessNeeded(old)
            } catch is CancellationError {
                // A newer choice replaced this one; drop the model this one loaded unless something still uses it.
                unloadUnlessNeeded(id)
            } catch {
                switchFailure = SwitchFailure(model: id, message: String(describing: error))
                if chosenModel() == id { setChosenModel(dictationModel) }
            }
        }
    }

    // MARK: Compare window

    /// Opens a compare session on `left` and `right`, or points the open one at them, and loads both columns.
    public func openCompare(left: SpeechModelID, right: SpeechModelID) {
        let session = compare ?? startCompare()
        session.choose(left: left, right: right)
        updateCompareColumns()
    }

    /// Ends the open session. Engines dictation does not use are unloaded once any comparison still finishing ends.
    public func closeCompare() {
        guard let session = compare else { return }
        compare = nil
        compareWatch?.cancel()
        compareWatch = nil
        session.discard()
        closedCompare = session
        let held = modelsInCompare
        modelsInCompare = []
        compareLoads = [:]
        Task {
            await session.discarded()
            for id in held { unloadUnlessNeeded(id) }
        }
    }

    /// Waits until the last closed compare session has stopped the microphone and ended its streams, which can
    /// share an engine with dictation.
    public func waitForClosedCompare() async {
        guard let closed = closedCompare else { return }
        await closed.discarded()
        if closedCompare === closed { closedCompare = nil }
    }

    private func startCompare() -> CompareSession {
        let makeTranscriber = makeTranscriber, engines = engines
        let session = makeCompareSession { id in makeTranscriber(engines[id]!, id) }
        // The dictation key starts the session too, so it needs the same check as Speak Now.
        session.canStart = { [weak self, weak session] in
            guard let self, let session else { return false }
            return compareLoads[session.left] == .loaded && compareLoads[session.right] == .loaded
        }
        compare = session
        let downloads = downloads
        compareWatch = Task { [weak self] in
            for await _ in Observations({ (session.left, session.right, downloads.states) }) {
                self?.updateCompareColumns()
            }
        }
        return session
    }

    /// Loads the engines both columns need, and unloads ones a column let go that dictation does not use.
    private func updateCompareColumns() {
        guard let session = compare else { return }
        let wanted: Set = [session.left, session.right]
        let released = modelsInCompare.subtracting(wanted)
        if modelsInCompare != wanted { modelsInCompare = wanted }
        for id in released {
            compareLoads[id] = nil
            unloadUnlessNeeded(id)
        }
        for id in wanted where isOnMac(id) && compareLoads[id] == nil && !compareLoading.contains(id) {
            guard let engine = engines[id] else { continue }
            compareLoading.insert(id)
            let loadSupport = loadSupport
            Task {
                var result = LoadResult.loaded
                do {
                    // Other models still need Silero for the voice check, as in `prepare`.
                    if id != .parakeetTDTv2 { try await loadSupport() }
                    try await engine.load { _ in }
                } catch {
                    result = .failed(String(describing: error))
                }
                downloads.refreshInstalled()
                compareLoading.remove(id)
                if modelsInCompare.contains(id) {
                    compareLoads[id] = result
                } else {
                    unloadUnlessNeeded(id)
                }
            }
        }
    }

    private func isOnMac(_ id: SpeechModelID) -> Bool {
        [.installed, .partOfMacOS].contains(downloads.states[id])
    }

    private func unloadUnlessNeeded(_ id: SpeechModelID) {
        guard id != dictationModel, id != chosenModel(), !modelsInCompare.contains(id), let engine = engines[id] else { return }
        Task { await engine.unload() }
    }

    private func refreshInUse() {
        modelsInUse = switching.union([dictationModel, chosenModel()])
    }
}
