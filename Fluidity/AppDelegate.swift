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
        let engine = FluidAudioEngine()
        let transcriber = Transcriber(engine: engine, voiceDetector: engine, rechecker: engine)
        let field = FieldContextAdapter(field: FocusedField())
        let paste = PasteAdapter(
            paster: Paster(pasteboard: NSPasteboardPasteboard(), keySender: CGEventKeySender(), focusChecking: AXFocusChecking()),
            focusChecking: AXFocusChecking())
        let store = DictationStore()
        let (storeChanges, storeChanged) = AsyncStream.makeStream(of: Void.self, bufferingPolicy: .bufferingNewest(1))
        let pill = PillPresenter.shared
        let audio = AudioCaptureAdapter(
            capture: AudioCapture(input: AVAudioEngineInput()),
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
            modelVersion: "parakeet-tdt-0.6b-v2",
            wordListVersion: { settings.wordListVersion }
        )
        self.settings = settings
        self.keychain = keychain
        self.permissions = permissions
        self.store = store
        self.storeChanges = storeChanges
        self.transcriber = transcriber
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
    }

    private func wireSettings() {
        let model = settingsModel, settings = settings, controller = controller
        model.onLaunchAtLoginChange = { [unowned self] in setLaunchesAtLogin($0) }
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
        model.isCleanupEnabled = settings.isCleanupEnabled
        model.cleanupRules = settings.cleanupRules
        model.wordList = settings.wordList
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

    private func loadModel() async {
        do {
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
