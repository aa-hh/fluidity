import AppKit
import FluidityCore
import Observation
import os
import ServiceManagement

/// Builds every part once, connects them through `DictationController`, and keeps them alive
/// for the app's life.
@MainActor
@Observable
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let log = Logger(subsystem: "com.fluidity.app", category: "App")

    let controller: DictationController
    /// From 0 to 1 while the speech model downloads and loads, for the first-run check.
    private(set) var modelProgress = 0.0
    private(set) var launchesAtLogin = SMAppService.mainApp.status == .enabled

    @ObservationIgnored let settings: Settings
    @ObservationIgnored let store: DictationStore
    @ObservationIgnored private let permissions: SystemPermissions
    @ObservationIgnored private let transcriber: Transcriber
    @ObservationIgnored private let paste: PasteAdapter
    @ObservationIgnored private let hotkey: Hotkey
    @ObservationIgnored private var hotkeyRunning = false

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
        let audio = AudioCaptureAdapter(
            capture: AudioCapture(input: AVAudioEngineInput()),
            willStart: {
                cleanup.warmUp()
                field.prepare()
                await paste.captureFocus()
            }
            // Pill track: pass the pill's audio feed as `onChunk` here.
        )
        controller = DictationController(
            audio: audio,
            transcriber: TranscriberAdapter(transcriber: transcriber, wordList: { settings.wordList }),
            cleanup: cleanup,
            field: field,
            finisher: FinisherAdapter(wordList: { settings.wordList }),
            paster: paste,
            watcher: EditWatchAdapter(watcher: EditWatcher(), context: { field.lastRead }),
            store: StoreAdapter(store: store),
            permissions: permissions,
            modelVersion: "parakeet-tdt-0.6b-v2",
            wordListVersion: settings.wordListVersion
        )
        self.settings = settings
        self.permissions = permissions
        self.store = store
        self.transcriber = transcriber
        self.paste = paste
        hotkey = Hotkey(key: settings.dictationKey, pasteAgainKey: settings.pasteAgainKey)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
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
            }
        }
        // Pill track: mount the pill window here, fed by `controller.pill`.
    }

    func setLaunchesAtLogin(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            Self.log.error("Changing launch at login failed: \(String(describing: error), privacy: .public)")
        }
        launchesAtLogin = SMAppService.mainApp.status == .enabled
    }

    private func loadModel() async {
        do {
            try await transcriber.prepare { progress in
                Task { @MainActor in self.modelProgress = progress }
            }
        } catch {
            Self.log.error("Loading the speech model failed: \(String(describing: error), privacy: .public)")
        }
    }

    private func askForPermissions() async {
        await permissions.requestMicrophone()
        permissions.requestAccessibility()
        // macOS sends no event when a grant changes, so check once a second until both are granted.
        while true {
            controller.refreshMenuBar()
            startHotkey()
            if permissions.microphoneGranted, permissions.accessibilityGranted, hotkeyRunning { return }
            try? await Task.sleep(for: .seconds(1))
        }
    }

    /// The keyboard event tap needs Accessibility, so this fails until it is granted.
    private func startHotkey() {
        guard !hotkeyRunning, permissions.accessibilityGranted else { return }
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
