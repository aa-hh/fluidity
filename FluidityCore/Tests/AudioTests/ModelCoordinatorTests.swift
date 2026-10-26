import FluidityCore
import FluidityTestSupport
import Foundation
import Synchronization
import Testing

/// Models already on disk; nothing is downloaded or removed.
private struct InstalledModels: ModelFetching {
    let installed: Set<SpeechModelID>
    func isInstalled(_ id: SpeechModelID) -> Bool { installed.contains(id) }
    func availableBytes() -> Int64 { .max }
    func download(_ id: SpeechModelID, progress: @escaping @Sendable (Double) -> Void) async throws {}
    func removeFiles(for id: SpeechModelID) throws {}
}

private struct Online: NetworkMonitoring {
    var isOnline: Bool { true }
}

/// The saved choice, standing in for `Settings.speechModel`.
@MainActor
private final class ChosenModel {
    var value: SpeechModelID
    init(_ value: SpeechModelID) { self.value = value }
}

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct ModelCoordinatorTests {
    let clock = ManualClock()
    let microphone = FakeMicrophone()
    let tdt = FakeSpeechEngine()
    let apple = FakeSpeechEngine()
    let unified = FakeSpeechEngine()

    private func make(
        chosen: SpeechModelID = .parakeetTDTv2,
        installed: Set<SpeechModelID> = [.parakeetTDTv2, .parakeetUnified],
        registered: Set<SpeechModelID> = Set(SpeechModelID.allCases)
    ) -> (ModelCoordinator, ModelDownloads, ChosenModel) {
        let saved = ChosenModel(chosen)
        let downloads = ModelDownloads(fetcher: InstalledModels(installed: installed), network: Online())
        let all: [SpeechModelID: any SpeechEngine] = [.parakeetTDTv2: tdt, .appleBuiltIn: apple, .parakeetUnified: unified]
        let clock = clock, microphone = microphone
        let coordinator = ModelCoordinator(
            chosenModel: { saved.value },
            setChosenModel: { saved.value = $0 },
            engines: all.filter { registered.contains($0.key) },
            downloads: downloads,
            loadSupport: {},
            makeTranscriber: { engine, model in
                Transcriber(
                    engine: engine, model: model, voiceDetector: FakeVoiceDetector(speech: true),
                    rechecker: FakeRechecker(candidates: false, clock: clock), clock: clock)
            },
            makeCompareSession: { CompareSession(audio: microphone, makeTranscriber: $0, clock: clock) })
        return (coordinator, downloads, saved)
    }

    /// Lets ready tasks run until `condition` holds, with a generous ceiling.
    func until(_ condition: () -> Bool) async {
        for _ in 0..<10_000 where !condition() { await Task.yield() }
    }

    func settle() async {
        for _ in 0..<100 { await Task.yield() }
    }

    // MARK: Launch

    enum Launch: Sendable, CaseIterable { case notInstalled, noEngine, kept }

    // Turns red if a chosen model that is not on this Mac, or has no engine, is kept at launch, if the fallback
    // is not saved, or if a chosen model that is on this Mac is replaced.
    @Test(arguments: Launch.allCases)
    func aChosenModelThatIsGoneFallsBackToTheDefault(_ launch: Launch) async throws {
        let (coordinator, _, saved) = switch launch {
        case .notInstalled: make(chosen: .parakeetUnified, installed: [.parakeetTDTv2])
        case .noEngine: make(chosen: .parakeetUnified, registered: [.parakeetTDTv2, .appleBuiltIn])
        case .kept: make(chosen: .parakeetUnified)
        }
        let expected: SpeechModelID = launch == .kept ? .parakeetUnified : .parakeetTDTv2
        #expect(coordinator.dictationModel == expected)
        #expect(saved.value == expected)
        #expect(try await coordinator.transcriber.finish(recording: [0]).model == expected)
    }

    // MARK: Switching

    @Test func aSwitchLandsAndUnloadsTheOldEngine() async throws {
        // Leaving the old engine loaded after a switch, or unloading the new one, turns this red.
        let (coordinator, _, saved) = make()
        coordinator.choose(.appleBuiltIn)
        #expect(saved.value == .appleBuiltIn)
        await until { coordinator.dictationModel == .appleBuiltIn }
        await until { tdt.unloaded }
        #expect(tdt.unloaded)
        #expect(!apple.unloaded)
        #expect(coordinator.modelsInUse == [.appleBuiltIn])
        #expect(try await coordinator.transcriber.finish(recording: [0]).model == .appleBuiltIn)
    }

    @Test func aFailedSwitchKeepsTheOldModelAndReportsIt() async {
        // Only logging a failed switch, or leaving the failed model saved as the choice, turns this red.
        let (coordinator, _, saved) = make()
        apple.loadFails = true
        coordinator.choose(.appleBuiltIn)
        await until { coordinator.switchFailure != nil }
        #expect(coordinator.switchFailure?.model == .appleBuiltIn)
        #expect(coordinator.dictationModel == .parakeetTDTv2)
        #expect(saved.value == .parakeetTDTv2)
        #expect(!tdt.unloaded)
    }

    @Test func aSupersededSwitchUnloadsWhatItLoaded() async {
        // Keeping the engine an overtaken switch loaded, while dictation moved on to the newer choice, turns this red.
        let (coordinator, _, _) = make()
        apple.hold()
        coordinator.choose(.appleBuiltIn)
        await settle()
        coordinator.choose(.parakeetUnified)
        await until { coordinator.dictationModel == .parakeetUnified }
        apple.release()
        await until { apple.unloaded }
        #expect(apple.unloaded)
        #expect(!unified.unloaded)
    }

    @Test func theInUseSetHoldsBothModelsWhileASwitchWaits() async throws {
        // Dropping the model still dictating from the in-use set while a switch waits, so it can be deleted
        // under the recording, turns this red.
        let (coordinator, downloads, _) = make()
        _ = await coordinator.transcriber.startRecording()
        coordinator.choose(.parakeetUnified)
        await settle()
        #expect(coordinator.modelsInUse == [.parakeetTDTv2, .parakeetUnified])
        #expect(throws: DeleteRefusal.inUse) { try downloads.delete(.parakeetTDTv2) }

        _ = try await coordinator.transcriber.finish(recording: [0])
        await until { coordinator.dictationModel == .parakeetUnified }
        #expect(coordinator.modelsInUse == [.parakeetUnified])
        #expect(throws: Never.self) { try downloads.delete(.parakeetTDTv2) }
    }

    // MARK: Compare window

    @Test func openingCompareLoadsBothColumnsAndHoldsThem() async {
        // Not loading a column, or letting a model the window holds be deleted, turns this red.
        let (coordinator, downloads, _) = make()
        coordinator.openCompare(left: .parakeetTDTv2, right: .parakeetUnified)
        await until { coordinator.compareLoads.count == 2 }
        #expect(coordinator.compareLoads == [.parakeetTDTv2: .loaded, .parakeetUnified: .loaded])
        #expect(coordinator.modelsInCompare == [.parakeetTDTv2, .parakeetUnified])
        #expect(throws: DeleteRefusal.openInCompare) { try downloads.delete(.parakeetUnified) }
        #expect(coordinator.compare?.canStart() == true)
    }

    @Test func aColumnThatFailsToLoadKeepsTheComparisonFromStarting() async {
        // Marking a column loaded when its engine's load threw, so the key starts the microphone, turns this red.
        let (coordinator, _, _) = make()
        unified.loadFails = true
        coordinator.openCompare(left: .parakeetTDTv2, right: .parakeetUnified)
        await until { coordinator.compareLoads.count == 2 }
        #expect(coordinator.compareLoads[.parakeetTDTv2] == .loaded)
        guard case .failed = coordinator.compareLoads[.parakeetUnified] else {
            Issue.record("the failed load reads \(String(describing: coordinator.compareLoads[.parakeetUnified]))")
            return
        }
        coordinator.compare?.handle(.keyDown)
        await settle()
        #expect(coordinator.compare?.phase == .idle)
        #expect(!microphone.isStarted && !microphone.isStarting)
    }

    @Test func closingUnloadsOnlyWhatDictationDoesNotUseOnceTheComparisonFinishes() async {
        // Unloading as soon as the window closes, under a final pass still running, or unloading the dictation
        // engine, turns this red; so does letting dictation start before that final pass ends.
        let (coordinator, _, _) = make()
        coordinator.openCompare(left: .parakeetTDTv2, right: .parakeetUnified)
        await until { coordinator.compareLoads.count == 2 }
        guard let session = coordinator.compare else { return }
        session.start()
        await until { microphone.isStarted }
        microphone.send([1, 2])
        unified.hold()
        let stopping = Task { await session.stop() }
        await until { unified.audioLengths.count == 1 }

        coordinator.closeCompare()
        let waited = Mutex(false)
        let waiting = Task {
            await coordinator.waitForClosedCompare()
            waited.withLock { $0 = true }
        }
        await settle()
        #expect(!unified.unloaded)
        #expect(!waited.withLock { $0 })

        unified.release()
        await stopping.value
        await waiting.value
        await until { unified.unloaded }
        #expect(unified.unloaded)
        #expect(!tdt.unloaded)
    }
}
