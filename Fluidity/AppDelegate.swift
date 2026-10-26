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
    private var dictationModel: SpeechModelID
    /// Models the compare window holds loaded, which a switch must not unload.
    private var compareModels: Set<SpeechModelID> = []
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
        let downloads = ModelDownloads(fetcher: FluidAudioModelFetcher(), network: NetworkMonitor(), inUse: { settings.speechModel })
        // A chosen model that is no longer on this Mac falls back to the default.
        var chosen = settings.speechModel
        if engines[chosen] == nil || ![.installed, .partOfMacOS].contains(downloads.states[chosen]) {
            chosen = .parakeetTDTv2
            settings.speechModel = chosen
        }
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
                self.controller.handle(decision) { self.pasteLastDictation() }
            }
        }
        Task {
            for await phase in Observations({ self.controller.phase }) {
                self.hotkey.isRecording = phase.takesEscape
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
            hotkey.isRecording = controller.phase.takesEscape
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
    /// A failed load puts the previous choice back.
    private func chooseModel(_ id: SpeechModelID) {
        guard let engine = engines[id] else { return }
        let previous = settings.speechModel
        settings.speechModel = id
        settingsModel.speechModel = id
        Task {
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
                settings.speechModel = previous
                settingsModel.speechModel = previous
            }
        }
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
