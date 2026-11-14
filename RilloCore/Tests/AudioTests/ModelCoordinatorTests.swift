import RilloCore
import RilloTestSupport
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
    let pro = FakeSpeechEngine()

    private func make(
        chosen: SpeechModelID = .parakeetTDTv2,
        installed: Set<SpeechModelID> = [.parakeetTDTv2, .fluidSpeechPro],
        registered: Set<SpeechModelID> = Set(SpeechModelID.allCases),
        loadVoiceDetector: @escaping @Sendable () async throws -> Void = {}
    ) -> (ModelCoordinator, ModelDownloads<SpeechModelID>, ChosenModel) {
        let saved = ChosenModel(chosen)
        let downloads = ModelDownloads(fetcher: InstalledModels(installed: installed), network: Online())
        let all: [SpeechModelID: any SpeechEngine] = [.parakeetTDTv2: tdt, .appleBuiltIn: apple, .fluidSpeechPro: pro]
        let clock = clock, microphone = microphone
        let coordinator = ModelCoordinator(
            chosenModel: { saved.value },
            setChosenModel: { saved.value = $0 },
            engines: all.filter { registered.contains($0.key) },
            downloads: downloads,
            loadVoiceDetector: loadVoiceDetector,
            makeTranscriber: { engine, model in
                Transcriber(
                    engine: engine, model: model, voiceDetector: FakeVoiceDetector(speech: true), clock: clock)
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
        case .notInstalled: make(chosen: .fluidSpeechPro, installed: [.parakeetTDTv2])
        case .noEngine: make(chosen: .fluidSpeechPro, registered: [.parakeetTDTv2, .appleBuiltIn])
        case .kept: make(chosen: .fluidSpeechPro)
        }
        let expected: SpeechModelID = launch == .kept ? .fluidSpeechPro : .parakeetTDTv2
        #expect(coordinator.dictationModel == expected)
        #expect(saved.value == expected)
        #expect(try await coordinator.transcriber.finish(recording: [0]).model == expected)
    }

    @Test func aDictationReleasedDuringTheSupportLoadWaitsForTheLaunchLoad() async throws {
        // Loading Silero before the transcriber's load starts, so a final pass made meanwhile skips the wait and
        // runs on the unloaded engine, losing the dictation, turns this red.
        let (support, supportDone) = AsyncStream.makeStream(of: Void.self)
        let (coordinator, _, _) = make(chosen: .fluidSpeechPro, loadVoiceDetector: { for await _ in support {} })
        pro.hold()
        let preparing = Task { try await coordinator.prepare(progress: { _ in }) }
        await settle()
        let finishing = Task { try await coordinator.transcriber.finish(recording: [0]) }
        await settle()
        #expect(pro.audioLengths.isEmpty)

        supportDone.finish()
        await settle()
        #expect(pro.audioLengths.isEmpty)
        pro.release()
        try await preparing.value
        #expect(try await finishing.value.text == "heard 1")
    }

    // Reporting a load the launch does not run, or skipping one it does, turns this red.
    @Test(arguments: [SpeechModelID.parakeetTDTv2, .fluidSpeechPro])
    func prepareReportsEachLaunchLoadInOrder(_ model: SpeechModelID) async throws {
        let reports = Mutex<[ModelLoadProgress]>([])
        let calls = Mutex<[String]>([])
        let (coordinator, _, _) = make(chosen: model, loadVoiceDetector: { calls.withLock { $0.append("voice detector") } })
        try await coordinator.prepare { progress in reports.withLock { $0.append(progress) } }
        let reported = reports.withLock { $0 }
        #expect(reported.map { $0.step } == [0, 1, 2])
        #expect(reported.allSatisfy { $0.stepCount == 2 && !$0.needsDownload })
        #expect(reported.last?.isDone == true)
        #expect(calls.withLock { $0 } == ["voice detector"])
    }

    @Test func aFirstLaunchReportsThatItDownloads() async throws {
        // Reading whether the speech model needs a download after its load, or not at all, turns this red.
        let reports = Mutex<[ModelLoadProgress]>([])
        let (coordinator, _, _) = make(installed: [])
        try await coordinator.prepare { progress in reports.withLock { $0.append(progress) } }
        let reported = reports.withLock { $0 }
        #expect(!reported.isEmpty)
        #expect(reported.allSatisfy { $0.needsDownload })
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
        coordinator.choose(.fluidSpeechPro)
        await until { coordinator.dictationModel == .fluidSpeechPro }
        apple.release()
        await until { apple.unloaded }
        #expect(apple.unloaded)
        #expect(!pro.unloaded)
    }

    @Test func theInUseSetHoldsBothModelsWhileASwitchWaits() async throws {
        // Dropping the model still dictating from the in-use set while a switch waits, so it can be deleted
        // under the recording, turns this red.
        let (coordinator, downloads, _) = make()
        _ = await coordinator.transcriber.startRecording()
        coordinator.choose(.fluidSpeechPro)
        await settle()
        #expect(coordinator.modelsInUse == [.parakeetTDTv2, .fluidSpeechPro])
        #expect(throws: DeleteRefusal.inUse) { try downloads.delete(.parakeetTDTv2) }

        _ = try await coordinator.transcriber.finish(recording: [0])
        await until { coordinator.dictationModel == .fluidSpeechPro }
        #expect(coordinator.modelsInUse == [.fluidSpeechPro])
        #expect(throws: Never.self) { try downloads.delete(.parakeetTDTv2) }
    }

    // MARK: Compare window

    @Test func openingCompareLoadsBothColumnsAndHoldsThem() async {
        // Not loading a column, or letting a model the window holds be deleted, turns this red.
        let (coordinator, downloads, _) = make()
        coordinator.openCompare(left: .parakeetTDTv2, right: .fluidSpeechPro)
        await until { coordinator.compareLoads.count == 2 }
        #expect(coordinator.compareLoads == [.parakeetTDTv2: .loaded, .fluidSpeechPro: .loaded])
        #expect(coordinator.modelsInCompare == [.parakeetTDTv2, .fluidSpeechPro])
        #expect(throws: DeleteRefusal.openInCompare) { try downloads.delete(.fluidSpeechPro) }
        #expect(coordinator.compare?.canStart() == true)
    }

    @Test func aColumnThatFailsToLoadKeepsTheComparisonFromStarting() async {
        // Marking a column loaded when its engine's load threw, so the key starts the microphone, turns this red.
        let (coordinator, _, _) = make()
        pro.loadFails = true
        coordinator.openCompare(left: .parakeetTDTv2, right: .fluidSpeechPro)
        await until { coordinator.compareLoads.count == 2 }
        #expect(coordinator.compareLoads[.parakeetTDTv2] == .loaded)
        guard case .failed = coordinator.compareLoads[.fluidSpeechPro] else {
            Issue.record("the failed load reads \(String(describing: coordinator.compareLoads[.fluidSpeechPro]))")
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
        coordinator.openCompare(left: .parakeetTDTv2, right: .fluidSpeechPro)
        await until { coordinator.compareLoads.count == 2 }
        guard let session = coordinator.compare else { return }
        session.start()
        await until { microphone.isStarted }
        microphone.send([1, 2])
        pro.hold()
        let stopping = Task { await session.stop() }
        await until { pro.audioLengths.count == 1 }

        coordinator.closeCompare()
        let waited = Mutex(false)
        let waiting = Task {
            await coordinator.waitForClosedCompare()
            waited.withLock { $0 = true }
        }
        await settle()
        #expect(!pro.unloaded)
        #expect(!waited.withLock { $0 })

        pro.release()
        await stopping.value
        await waiting.value
        await until { pro.unloaded }
        #expect(pro.unloaded)
        #expect(!tdt.unloaded)
    }
}
