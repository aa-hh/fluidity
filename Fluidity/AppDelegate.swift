import AppKit
import AVFoundation
import FluidityCore
import os
import ServiceManagement

/// Builds every part once, connects them through `DictationController`, and connects the
/// controller to the pill, the menu bar item and the windows.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let log = Logger(subsystem: "com.fluidity.app", category: "App")
    /// Set once the speech model has loaded on this Mac, so later launches skip the first-run check for it.
    private static let modelPreparedKey = "speechModelPrepared"

    private let controller: DictationController
    private let settings: Settings
    private let keychain: Keychain
    private let store: DictationStore
    private let storeChanges: AsyncStream<Void>
    private let permissions: SystemPermissions
    private let transcriber: Transcriber
    /// The one microphone capture, shared by dictation and the compare window.
    private let audioCapture: AudioCapture
    private let downloads: ModelDownloads
    /// Silero voice detection and the CTC recheck for every model, and Parakeet TDT v2.
    private let fluid: FluidAudioEngine
    private let engines: [SpeechModelID: any SpeechEngine]
    /// The model the transcriber dictates with now; `settings.speechModel` runs ahead of it while a switch loads.
    private var dictationModel: SpeechModelID {
        didSet {
            compareModel?.inUse = dictationModel
            refreshModelsInUse()
        }
    }
    /// Models a switch is loading, which must not be deleted under it.
    private var switching: Set<SpeechModelID> = []
    /// Models the compare window holds loaded, which a switch must not unload.
    private var compareModels: Set<SpeechModelID> = [] {
        didSet { settingsModel.modelsInCompare = compareModels }
    }
    /// The open compare window's model, which takes the dictation key while it exists.
    private var compareModel: CompareModel?
    private var compareWindow: CompareWindow?
    /// The last closed compare window's session. Its engines may share a model with dictation, so the next
    /// dictation waits for its discard to end their streams.
    private var closedCompare: CompareSession?
    /// Loops that follow the open compare window, cancelled when it closes.
    private var compareTasks: [Task<Void, Never>] = []
    /// Models the compare window has asked to load and that are still loading.
    private var compareLoading: Set<SpeechModelID> = []
    private let paste: PasteAdapter
    private let hotkey: Hotkey
    private var hotkeyRunning = false

    private let settingsModel: SettingsModel
    private let popoverModel = PopoverModel()
    private let firstRunModel = FirstRunModel()
    private lazy var settingsWindow = SettingsWindow(model: settingsModel)
    private var firstRunWindow: FirstRunWindow?
    private var menuBarItem: MenuBarItem?

    override init() {
        let keychain = Keychain()
        let permissions = SystemPermissions()
        let settings = Settings(keyStore: keychain)
        let cleanup = CleanupAdapter(
            client: CleanupClient(session: URLSession(configuration: .ephemeral), keyStore: keychain, networkMonitor: NetworkMonitor()),
            settings: settings)
        let fluid = FluidAudioEngine()
        let engines: [SpeechModelID: any SpeechEngine] = [
            .parakeetTDTv2: fluid, .appleBuiltIn: AppleSpeechEngine(), .parakeetUnified: UnifiedEngine(),
        ]
        let downloads = ModelDownloads(fetcher: FluidAudioModelFetcher(), network: NetworkMonitor())
        // A chosen model that is no longer on this Mac falls back to the default.
        var chosen = settings.speechModel
        if engines[chosen] == nil || ![.installed, .partOfMacOS].contains(downloads.states[chosen]) {
            chosen = .parakeetTDTv2
            settings.speechModel = chosen
        }
        downloads.inUse = [chosen]
        let transcriber = Transcriber(engine: engines[chosen]!, model: chosen, voiceDetector: fluid, rechecker: fluid)
        let field = FieldContextAdapter(field: FocusedField())
        let paste = PasteAdapter(
            paster: Paster(pasteboard: NSPasteboardPasteboard(), keySender: CGEventKeySender(), focusChecking: AXFocusChecking()),
            focusChecking: AXFocusChecking())
        let store = DictationStore()
        let (storeChanges, storeChanged) = AsyncStream.makeStream(of: Void.self, bufferingPolicy: .bufferingNewest(1))
        let pill = PillPresenter.shared
        let audioCapture = AudioCapture(input: AVAudioEngineInput())
        let audio = AudioCaptureAdapter(
            capture: audioCapture,
            willStart: {
                cleanup.warmUp()
                field.prepare()
                await paste.captureFocus()
            },
            onChunk: { pill.feed($0) }
        )
        controller = DictationController(
            audio: audio,
            transcriber: TranscriberAdapter(transcriber: transcriber, wordList: { settings.wordList }),
            cleanup: cleanup,
            field: field,
            finisher: FinisherAdapter(wordList: { settings.wordList }),
            paster: paste,
            watcher: EditWatchAdapter(watcher: EditWatcher(), context: { field.lastRead }),
            store: StoreAdapter(store: store, didChange: { storeChanged.yield() }),
            permissions: permissions,
            wordListVersion: { settings.wordListVersion }
        )
        self.settings = settings
        self.keychain = keychain
        self.permissions = permissions
        self.store = store
        self.storeChanges = storeChanges
        self.transcriber = transcriber
        self.audioCapture = audioCapture
        self.downloads = downloads
        self.fluid = fluid
        self.engines = engines
        dictationModel = chosen
        self.paste = paste
        hotkey = Hotkey(key: settings.dictationKey, pasteAgainKey: settings.pasteAgainKey)
        settingsModel = SettingsModel(shortcuts: settings)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Builds the pill's panel and compiles its shader now, so the first key press does not wait for it.
        PillPresenter.shared.prepare()
        wirePill()
        wireSettings()
        wirePopover()
        refreshSettingsModel()
        menuBarItem = MenuBarItem(model: popoverModel, settings: settingsModel) { [unowned self] in
            refreshSettingsModel()
            await reloadRecords()
        }

        Task { await self.store.watchMounts() }
        Task { await self.loadModel() }
        Task { await self.askForPermissions() }
        Task {
            for await decision in self.hotkey.decisions {
                // While the compare window is open and no dictation runs, the dictation key drives the comparison.
                if let session = self.compareModel?.session, self.controller.phase.passesToCompare(decision) {
                    session.handle(decision)
                } else {
                    if let closed = self.closedCompare {
                        await closed.discarded()
                        if self.closedCompare === closed { self.closedCompare = nil }
                    }
                    self.controller.handle(decision) { self.pasteLastDictation() }
                }
            }
        }
        Task {
            for await phase in Observations({ self.controller.phase }) {
                self.syncHotkeyRecording()
                self.compareModel?.dictationRunning = phase.isDictating
                self.settingsModel.recordingMode = switch phase {
                case .recording(let mode): mode
                default: nil
                }
            }
        }
        Task {
            for await state in Observations({ self.controller.menuBar }) {
                self.menuBarItem?.show(state)
                self.settingsModel.menuBarState = state
            }
        }
        Task {
            for await pill in Observations({ self.controller.pill }) {
                switch pill {
                case .pasted(let text), .pastedRawTranscript(let text): PillPresenter.shared.showPastedText(text)
                default: break
                }
                PillPresenter.shared.show(pill)
            }
        }
        Task {
            for await (states, failure, finished) in Observations({
                (self.downloads.states, self.downloads.failure, self.downloads.lastFinished)
            }) {
                self.settingsModel.modelStates = states
                self.settingsModel.downloadFailure = failure.map { ($0.model, $0.reason) }
                self.settingsModel.readyModel = finished
            }
        }
        Task {
            for await _ in self.storeChanges {
                await self.reloadRecords()
                if self.menuBarItem?.isOpen == true { self.menuBarItem?.place() }
            }
        }

        showFirstRunIfNeeded()
        WindowPreview.openIfRequested()
    }

    // MARK: Wiring

    private func wirePill() {
        let pill = PillPresenter.shared
        pill.retryPaste = { [paste] text in
            guard case .landed? = await paste.pasteAgain(text) else { return false }
            return true
        }
        pill.openPermissionSettings = { [settingsModel] in settingsModel.onOpenPrivacySettings($0) }
        pill.liveWords = settings.liveWords
    }

    private func wireSettings() {
        let model = settingsModel, settings = settings, controller = controller
        model.onLaunchAtLoginChange = { [unowned self] in setLaunchesAtLogin($0) }
        model.onLiveWordsChange = { choice in
            settings.liveWords = choice
            PillPresenter.shared.liveWords = choice
        }
        model.onCleanupEnabledChange = { on in
            settings.isCleanupEnabled = on
            controller.refreshMenuBar()
        }
        model.onAPIKeySubmit = { [unowned self] key in
            do {
                try settings.setAPIKey(key)
            } catch {
                Self.log.error("Saving the cleanup key failed: \(String(describing: error), privacy: .public)")
                return
            }
            // The key is not checked with Cerebras here; a refused key shows up as a fallback when cleanup runs.
            refreshSettingsModel()
            controller.refreshMenuBar()
        }
        model.onCleanupRulesChange = { settings.cleanupRules = $0 }
        model.onWordListChange = { settings.wordList = $0 }
        model.onSpeechModelChange = { [unowned self] in chooseModel($0) }
        let downloads = downloads
        model.onDownloadModel = { downloads.download($0) }
        model.onCancelDownload = { downloads.cancelDownload($0) }
        model.onDeleteModel = { id in
            do {
                try downloads.delete(id)
            } catch {
                Self.log.error("Deleting \(id.rawValue, privacy: .public) was refused: \(String(describing: error), privacy: .public)")
            }
        }
        model.onClearReadyModel = { downloads.clearLastFinished() }
        model.onCompare = { [unowned self] in openCompare(left: $0, right: $1) }
        model.onRequestMicrophone = { [unowned self] in
            Task {
                await permissions.requestMicrophone()
                refreshPermissions()
            }
        }
        model.onShortcutRecordingChange = { [unowned self] recording in
            // The global hotkey would act on the key being recorded.
            if recording {
                hotkey.stop()
                hotkeyRunning = false
            } else {
                startHotkey()
            }
        }
        model.onShortcutsChange = { [unowned self] in
            hotkey.setKeys(settings.dictationKey, pasteAgainKey: settings.pasteAgainKey)
            // A new decoder starts with Escape not taken, which would break a hands-free dictation in progress.
            syncHotkeyRecording()
        }
    }

    private func wirePopover() {
        popoverModel.onPasteAgain = { [unowned self] record in
            menuBarItem?.close()
            Task { await paste.pasteAgain(record.textToPasteAgain) }
        }
        popoverModel.onCopy = { record in
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(record.textToPasteAgain, forType: .string)
        }
        popoverModel.onOpenSettings = { [unowned self] pane in
            menuBarItem?.close()
            refreshSettingsModel()
            settingsWindow.show(pane: pane)
        }
    }

    /// Copies `Settings`, the keychain, launch at login and the permissions into the windows' model.
    private func refreshSettingsModel() {
        let model = settingsModel
        model.launchAtLogin = SMAppService.mainApp.status == .enabled
        model.liveWords = settings.liveWords
        model.isCleanupEnabled = settings.isCleanupEnabled
        model.cleanupRules = settings.cleanupRules
        model.wordList = settings.wordList
        model.speechModel = settings.speechModel
        refreshModelsInUse()
        let key = try? keychain.get()
        model.apiKey = key ?? ""
        model.cleanupKey = key == nil ? .noKey : .accepted
        refreshPermissions()
    }

    private func refreshPermissions() {
        settingsModel.microphone = switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: .granted
        case .notDetermined: .notAsked
        default: .denied
        }
        settingsModel.accessibility = permissions.accessibilityGranted ? .granted : .denied
        controller.refreshMenuBar()
    }

    private func reloadRecords() async {
        popoverModel.records = await store.recent()
    }

    // MARK: Launch

    private func showFirstRunIfNeeded() {
        let modelPrepared = UserDefaults.standard.bool(forKey: Self.modelPreparedKey)
        guard !permissions.microphoneGranted || !permissions.accessibilityGranted || !modelPrepared else { return }
        firstRunModel.onDone = { [unowned self] in
            firstRunWindow?.close()
            firstRunWindow = nil
        }
        let window = FirstRunWindow(model: firstRunModel, settings: settingsModel)
        window.show()
        firstRunWindow = window
    }

    private func setLaunchesAtLogin(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            Self.log.error("Changing launch at login failed: \(String(describing: error), privacy: .public)")
        }
        settingsModel.launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    /// Saves the choice and switches the transcriber to it once no dictation is running.
    /// A failed load puts back the model still dictating, which cannot have been deleted.
    private func chooseModel(_ id: SpeechModelID) {
        guard let engine = engines[id] else { return }
        settings.speechModel = id
        settingsModel.speechModel = id
        switching.insert(id)
        refreshModelsInUse()
        Task {
            defer {
                switching.remove(id)
                refreshModelsInUse()
            }
            do {
                let old = try await transcriber.switchEngine(to: engine, model: id)
                let oldModel = dictationModel
                dictationModel = id
                if oldModel != id, !compareModels.contains(oldModel) { await old.unload() }
            } catch is CancellationError {
                // A newer choice replaced this one; drop the model this one loaded unless something still uses it.
                if id != dictationModel, id != settings.speechModel, !compareModels.contains(id) { await engine.unload() }
            } catch {
                Self.log.error("Switching to \(id.rawValue, privacy: .public) failed: \(String(describing: error), privacy: .public)")
                if settings.speechModel == id {
                    settings.speechModel = dictationModel
                    settingsModel.speechModel = dictationModel
                }
            }
            // A load may have downloaded the model's files.
            downloads.refreshInstalled()
        }
    }

    /// Tells the downloads and the Speech model pane which models dictation needs, so neither offers to delete them.
    private func refreshModelsInUse() {
        let inUse = switching.union([dictationModel, settings.speechModel])
        downloads.inUse = inUse
        settingsModel.modelsInUse = inUse
    }

    /// The one rule for whether the hotkey takes Escape: the dictation's, or the open comparison's between dictations.
    private func syncHotkeyRecording() {
        hotkey.isRecording = controller.phase.takesEscape(comparing: compareModel?.session.phase)
    }

    // MARK: Compare window

    /// Opens the compare window on `left` and `right`, or points the open one at them.
    private func openCompare(left: SpeechModelID, right: SpeechModelID) {
        let model = compareModel ?? makeCompareModel()
        model.session.choose(left: left, right: right)
        compareWindow?.show()
    }

    private func makeCompareModel() -> CompareModel {
        let engines = engines, fluid = fluid, downloads = downloads
        let session = CompareSession(
            audio: AudioCaptureAdapter(capture: audioCapture),
            makeTranscriber: { Transcriber(engine: engines[$0]!, model: $0, voiceDetector: fluid, rechecker: fluid) })
        let model = CompareModel(session: session)
        // The dictation key starts the session too, so it needs the same check as Speak Now.
        session.canStart = { [unowned model] in model.bothReady }
        model.inUse = dictationModel
        model.dictationRunning = controller.phase.isDictating
        model.modelStates = downloads.states
        model.dictationKey = settingsModel.dictationKey.description
        model.onDownload = { downloads.download($0) }
        model.onCancelDownload = { downloads.cancelDownload($0) }
        model.onKeep = { [unowned self] in closeCompare() }
        model.onSwitch = { [unowned self] in
            chooseModel(session.right)
            closeCompare()
            settingsWindow.show(pane: .speechModel)
        }
        compareModel = model
        syncHotkeyRecording()
        compareWindow = CompareWindow(model: model)
        compareTasks = [
            Task {
                for await (_, _, states) in Observations({ (session.left, session.right, downloads.states) }) {
                    model.modelStates = states
                    self.loadCompareEngines(for: model)
                }
            },
            Task {
                for await _ in Observations({ session.phase }) { self.syncHotkeyRecording() }
            },
        ]
        return model
    }

    /// Loads the engines both columns need, and unloads ones a column let go that dictation does not use.
    private func loadCompareEngines(for model: CompareModel) {
        let wanted: Set = [model.session.left, model.session.right]
        let released = compareModels.subtracting(wanted)
        compareModels = wanted
        downloads.setOpenInCompare(wanted)
        model.loaded.subtract(released)
        for id in released { unloadUnlessDictating(id) }
        for id in wanted where model.isOnMac(id) && !model.loaded.contains(id) && !compareLoading.contains(id) {
            compareLoading.insert(id)
            Task {
                do {
                    // Other models still need Silero for the voice check, as in `loadModel`.
                    if id != .parakeetTDTv2 { try await fluid.loadSupport { _ in } }
                    try await engines[id]!.load { _ in }
                } catch {
                    Self.log.error("Loading \(id.rawValue, privacy: .public) to compare failed: \(String(describing: error), privacy: .public)")
                }
                downloads.refreshInstalled()
                compareLoading.remove(id)
                if compareModel === model, compareModels.contains(id) {
                    model.loaded.insert(id)
                } else {
                    unloadUnlessDictating(id)
                }
            }
        }
    }

    /// Closes the compare window; it changes nothing about dictation.
    private func closeCompare() {
        guard let model = compareModel else { return }
        compareModel = nil
        for task in compareTasks { task.cancel() }
        compareTasks = []
        model.session.discard()
        closedCompare = model.session
        model.stopPlaying()
        compareWindow?.close()
        compareWindow = nil
        let held = compareModels
        compareModels = []
        downloads.setOpenInCompare([])
        syncHotkeyRecording()
        for id in held { unloadUnlessDictating(id) }
    }

    private func unloadUnlessDictating(_ id: SpeechModelID) {
        guard id != dictationModel, id != settings.speechModel, !compareModels.contains(id) else { return }
        Task { await engines[id]?.unload() }
    }

    private func loadModel() async {
        PillPresenter.shared.isModelLoading = true
        defer { PillPresenter.shared.isModelLoading = false }
        do {
            // Other models still need Silero and CTC for the voice check and the recheck.
            if dictationModel != .parakeetTDTv2 { try await fluid.loadSupport { _ in } }
            try await transcriber.prepare { progress in
                Task { @MainActor in self.firstRunModel.modelProgress = progress }
            }
            firstRunModel.isModelReady = true
            UserDefaults.standard.set(true, forKey: Self.modelPreparedKey)
        } catch {
            Self.log.error("Loading the speech model failed: \(String(describing: error), privacy: .public)")
            firstRunModel.modelError = "The download failed. Quit and reopen Fluidity to try again."
        }
        // The first launch downloads Parakeet TDT v2 here, outside `ModelDownloads`.
        downloads.refreshInstalled()
    }

    private func askForPermissions() async {
        await permissions.requestMicrophone()
        permissions.requestAccessibility()
        // macOS sends no event when a grant changes, so check once a second until both are granted.
        while true {
            refreshPermissions()
            startHotkey()
            if permissions.microphoneGranted, permissions.accessibilityGranted, hotkeyRunning { return }
            try? await Task.sleep(for: .seconds(1))
        }
    }

    /// The keyboard event tap needs Accessibility, so this fails until it is granted.
    private func startHotkey() {
        guard !hotkeyRunning, settingsModel.recordingSlot == nil, permissions.accessibilityGranted else { return }
        do {
            try hotkey.start()
            hotkeyRunning = true
        } catch {
            Self.log.error("Starting the dictation key failed: \(String(describing: error), privacy: .public)")
        }
    }

    private func pasteLastDictation() {
        Task {
            guard let last = await self.store.recent(limit: 1).first else { return }
            await self.paste.pasteAgain(last.textToPasteAgain)
        }
    }
}
