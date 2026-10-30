import AppKit
import AVFoundation
import CoreAudio
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
    private let devices: CoreAudioDevices
    private let input: CoreAudioInput
    /// The device the saved choice resolves to, read by `input` on every start.
    private let microphone: OSAllocatedUnfairLock<AudioDeviceID?>
    private let keychain: Keychain
    private let store: DictationStore
    private let storeChanges: AsyncStream<Void>
    private let permissions: SystemPermissions
    private let downloads: ModelDownloads
    private let models: ModelCoordinator
    /// The open compare window's model.
    private var compareModel: CompareModel?
    private var compareWindow: CompareWindow?
    /// Loops that follow the open compare window, cancelled when it closes.
    private var compareTasks: [Task<Void, Never>] = []
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
        let settingsModel = SettingsModel(shortcuts: settings)
        let devices = CoreAudioDevices()
        let microphone = OSAllocatedUnfairLock<AudioDeviceID?>(initialState: nil)
        let input = CoreAudioInput { microphone.withLock { $0 } }
        // The one microphone capture, shared by dictation and the compare window.
        let audioCapture = AudioCapture(input: input)
        let models = ModelCoordinator(
            chosenModel: { settings.speechModel },
            setChosenModel: {
                settings.speechModel = $0
                settingsModel.speechModel = $0
            },
            engines: engines,
            downloads: downloads,
            loadVoiceDetector: { try await fluid.loadVoiceDetector() },
            loadWordCheck: { try await fluid.loadWordCheck() },
            makeTranscriber: { Transcriber(engine: $0, model: $1, voiceDetector: fluid, rechecker: fluid) },
            makeCompareSession: { CompareSession(audio: AudioCaptureAdapter(capture: audioCapture), makeTranscriber: $0) })
        let field = FieldContextAdapter(field: FocusedField())
        let paste = PasteAdapter(
            paster: Paster(pasteboard: NSPasteboardPasteboard(), keySender: CGEventKeySender(), focusChecking: AXFocusChecking()),
            focusChecking: AXFocusChecking())
        let store = DictationStore()
        let (storeChanges, storeChanged) = AsyncStream.makeStream(of: Void.self, bufferingPolicy: .bufferingNewest(1))
        let pill = PillPresenter.shared
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
            transcriber: TranscriberAdapter(transcriber: models.transcriber, wordList: { settings.wordList }),
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
        self.devices = devices
        self.input = input
        self.microphone = microphone
        self.keychain = keychain
        self.permissions = permissions
        self.store = store
        self.storeChanges = storeChanges
        self.downloads = downloads
        self.models = models
        self.paste = paste
        hotkey = Hotkey(key: settings.dictationKey, pasteAgainKey: settings.pasteAgainKey)
        self.settingsModel = settingsModel
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Builds the pill's panel and compiles its shader now, so the first key press does not wait for it.
        PillPresenter.shared.prepare()
        wirePill()
        wireSettings()
        wirePopover()
        refreshSettingsModel()
        devices.watch { [unowned self] in refreshMicrophones() }
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
                if let session = self.models.compare, self.controller.phase.passesToCompare(decision) {
                    session.handle(decision)
                } else {
                    await self.models.waitForClosedCompare()
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
            for await (inUse, inCompare, failure, preparing) in Observations({
                (self.models.modelsInUse, self.models.modelsInCompare, self.models.switchFailure, self.models.isPreparing)
            }) {
                self.settingsModel.modelsInUse = inUse
                self.settingsModel.modelsInCompare = inCompare
                self.settingsModel.switchFailure = failure
                self.settingsModel.isPreparingModel = preparing
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
        model.onMicrophoneChange = { [unowned self] in
            settings.microphone = $0
            refreshMicrophones()
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
        let models = models
        model.onSpeechModelChange = { models.choose($0) }
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

    /// Copies `Settings`, the keychain, launch at login, the microphones and the permissions into the windows' model.
    private func refreshSettingsModel() {
        let model = settingsModel
        model.launchAtLogin = SMAppService.mainApp.status == .enabled
        model.liveWords = settings.liveWords
        model.isCleanupEnabled = settings.isCleanupEnabled
        model.cleanupRules = settings.cleanupRules
        model.wordList = settings.wordList
        model.speechModel = settings.speechModel
        let key = try? keychain.get()
        model.apiKey = key ?? ""
        model.cleanupKey = key == nil ? .noKey : .accepted
        refreshMicrophones()
        refreshPermissions()
    }

    /// Resolves the device to record from and prepares the input on it, resets a saved choice whose microphone is
    /// gone to Automatic, and lists the microphones for the windows.
    private func refreshMicrophones() {
        let list = devices.microphones()
        let choice = Microphones.resolve(saved: settings.microphone, devices: list, defaultInput: devices.defaultInputUID())
        if choice.clearsSaved { settings.microphone = nil }
        let device = choice.uid.flatMap(devices.device(uid:))
        microphone.withLock { $0 = device }
        input.prepare()
        settingsModel.microphones = list
        settingsModel.chosenMicrophone = settings.microphone
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

    /// The one rule for whether the hotkey takes Escape: the dictation's, or the open comparison's between dictations.
    private func syncHotkeyRecording() {
        hotkey.isRecording = controller.phase.takesEscape(comparing: models.compare?.phase)
    }

    // MARK: Compare window

    /// Opens the compare window on `left` and `right`, or points the open one at them.
    private func openCompare(left: SpeechModelID, right: SpeechModelID) {
        let isNew = models.compare == nil
        models.openCompare(left: left, right: right)
        if isNew, let session = models.compare { makeCompareWindow(session) }
        compareWindow?.show()
    }

    private func makeCompareWindow(_ session: CompareSession) {
        let downloads = downloads, models = models
        let model = CompareModel(session: session)
        model.inUse = models.dictationModel
        model.dictationRunning = controller.phase.isDictating
        model.modelStates = downloads.states
        model.loads = models.compareLoads
        model.dictationKey = settingsModel.dictationKey.description
        model.onDownload = { downloads.download($0) }
        model.onCancelDownload = { downloads.cancelDownload($0) }
        model.onKeep = { [unowned self] in closeCompare() }
        model.onSwitch = { [unowned self] in
            models.choose(session.right)
            closeCompare()
            settingsWindow.show(pane: .speechModel)
        }
        model.onStart = { session.start() }
        model.onStop = { Task { await session.stop() } }
        model.onChoose = { column, id in
            if column == .left { session.choose(left: id) } else { session.choose(right: id) }
        }
        model.onReplay = { session.replayLiveWords() }
        compareModel = model
        syncHotkeyRecording()
        compareWindow = CompareWindow(model: model)
        compareTasks = [
            Task {
                for await (states, loads, inUse) in Observations({ (downloads.states, models.compareLoads, models.dictationModel) }) {
                    model.modelStates = states
                    model.loads = loads
                    model.inUse = inUse
                }
            },
            Task {
                for await _ in Observations({ session.phase }) { self.syncHotkeyRecording() }
            },
        ]
    }

    /// Closes the compare window; it changes nothing about dictation.
    private func closeCompare() {
        guard let model = compareModel else { return }
        compareModel = nil
        for task in compareTasks { task.cancel() }
        compareTasks = []
        models.closeCompare()
        model.stopPlaying()
        compareWindow?.close()
        compareWindow = nil
        syncHotkeyRecording()
    }

    private func loadModel() async {
        PillPresenter.shared.isModelLoading = true
        do {
            try await models.prepare { progress in
                Task { @MainActor in
                    self.firstRunModel.modelProgress = progress.downloadFraction
                    PillPresenter.shared.reportModelLoad(progress)
                }
            }
            firstRunModel.isModelReady = true
            UserDefaults.standard.set(true, forKey: Self.modelPreparedKey)
        } catch {
            Self.log.error("Loading the speech model failed: \(String(describing: error), privacy: .public)")
            PillPresenter.shared.isModelLoading = false
            firstRunModel.modelError = "The download failed. Quit and reopen Fluidity to try again."
        }
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
