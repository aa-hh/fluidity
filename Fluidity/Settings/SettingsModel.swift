import AppKit
import FluidityCore
import Observation
import SwiftUI

enum SettingsPane: String, CaseIterable, Identifiable {
    case general, speechModel, cleanup, words, permissions

    var id: Self { self }
    var title: String {
        switch self {
        case .general: "General"
        case .speechModel: "Speech model"
        case .cleanup: "Cleanup"
        case .words: "Words"
        case .permissions: "Permissions"
        }
    }
    var symbol: String {
        switch self {
        case .general: "gearshape"
        case .speechModel: "mic"
        case .cleanup: "sparkles"
        case .words: "book"
        case .permissions: "lock"
        }
    }
}

/// A shortcut the recorder refused, and why, in words for the settings screen.
struct ShortcutProblem: Equatable {
    let slot: ShortcutSlot
    let rejection: ShortcutRejection

    var message: String {
        switch rejection {
        case .escape:
            slot == .dictation ? "Escape cancels dictation, so it can't start it." : "Escape cancels dictation, so it can't be a shortcut."
        case .returnOrTab: "Return and Tab type into the app you're in, so they can't be a shortcut."
        case .typingKeyWithoutModifier: "That key types text. Hold Command, Option or Control with it, or use a key such as Right Option on its own."
        case .sameAsOtherShortcut: "The other shortcut already uses that key."
        }
    }
}

/// What the settings window, the popover's status row and the first-run check show.
/// The app shell writes the state properties; the windows call the `on…` closures for
/// the user's changes. Views hold no logic beyond this.
@MainActor
@Observable
final class SettingsModel {
    // MARK: Status

    var menuBarState: MenuBarState = .ready
    /// How the current dictation was started, while one is recording.
    var recordingMode: DictationController.RecordingMode?
    var status: AppStatus { .current(menuBar: menuBarState, cleanupKey: cleanupKey) }
    var isMicLive: Bool { menuBarState == .recording }

    var pane: SettingsPane = .general

    // MARK: General

    private(set) var dictationKey: KeyChoice
    private(set) var pasteAgainKey: KeyChoice?
    /// The shortcut being recorded, if any; the window takes the next key press for it.
    private(set) var recordingSlot: ShortcutSlot?
    private(set) var shortcutProblem: ShortcutProblem?
    var launchAtLogin = false
    var liveWords: LiveWords = .inPill
    var microphones: [Microphone] = []
    /// The saved microphone's UID, or `nil` for Automatic.
    var chosenMicrophone: String?
    /// The saved choice in words; never what Automatic picked.
    var chosenMicrophoneName: String {
        microphones.first { $0.uid == chosenMicrophone }?.name ?? "Automatic"
    }

    // MARK: Cleanup

    var isCleanupEnabled = true
    var cleanupKey: CleanupKeyState = .noKey
    /// Cleanup runs only with its switch on and a key saved.
    var isCleanupActive: Bool { isCleanupEnabled && cleanupKey != .noKey }
    /// The saved key, shown masked in the field.
    var apiKey = ""
    var cleanupRules = Settings.defaultCleanupRules
    let defaultCleanupRules = Settings.defaultCleanupRules

    // MARK: Words

    var wordList: [String] = []

    // MARK: Speech model

    var speechModel: SpeechModelID = .parakeetTDTv2
    var modelStates: [SpeechModelID: ModelState] = [:]
    /// Models dictation needs now: the chosen one, the one still dictating while a switch loads, and any a switch is loading.
    var modelsInUse: Set<SpeechModelID> = []
    /// The last download or delete that failed, and why.
    var downloadFailure: (SpeechModelID, DownloadFailure)? = nil
    /// A model whose download just finished, offered for use until the shell clears it.
    var readyModel: SpeechModelID? = nil
    /// Models the open compare window holds, which can't be deleted until it closes.
    var modelsInCompare: Set<SpeechModelID> = []
    /// The last switch whose load failed; dictation stayed on `speechModel`.
    var switchFailure: ModelCoordinator.SwitchFailure?
    /// The launch model is loading, which the first launch downloads.
    var isPreparingModel = false

    // MARK: Permissions

    var microphone: PermissionStatus = .notAsked
    var accessibility: PermissionStatus = .denied

    // MARK: User actions, filled by the app shell

    var onLaunchAtLoginChange: (Bool) -> Void = { _ in }
    var onLiveWordsChange: (LiveWords) -> Void = { _ in }
    var onMicrophoneChange: (String?) -> Void = { _ in }
    var onCleanupEnabledChange: (Bool) -> Void = { _ in }
    /// The user entered a key; the shell saves it and marks any saved key `.accepted` without checking it.
    var onAPIKeySubmit: (String) -> Void = { _ in }
    var onCleanupRulesChange: (String) -> Void = { _ in }
    var onWordListChange: ([String]) -> Void = { _ in }
    var onSpeechModelChange: (SpeechModelID) -> Void = { _ in }
    var onDownloadModel: (SpeechModelID) -> Void = { _ in }
    var onCancelDownload: (SpeechModelID) -> Void = { _ in }
    var onDeleteModel: (SpeechModelID) -> Void = { _ in }
    var onClearReadyModel: () -> Void = {}
    /// Opens the compare window with the left and right models.
    var onCompare: (SpeechModelID, SpeechModelID) -> Void = { _, _ in }
    var onRequestMicrophone: () -> Void = {}
    var onOpenPrivacySettings: (DictationController.Permission) -> Void = { permission in
        let anchor = permission == .microphone ? "Privacy_Microphone" : "Privacy_Accessibility"
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(anchor)") {
            NSWorkspace.shared.open(url)
        }
    }
    /// True while a shortcut is being recorded, so the shell can pause the global hotkey.
    var onShortcutRecordingChange: (Bool) -> Void = { _ in }
    /// A shortcut was saved through `ShortcutStoring`; the shell updates the hotkey.
    var onShortcutsChange: () -> Void = {}

    private var recorder: ShortcutRecorder
    private var keyMonitor: Any?
    private var resignObserver: (any NSObjectProtocol)?

    init(shortcuts: any ShortcutStoring) {
        recorder = ShortcutRecorder(store: shortcuts)
        dictationKey = shortcuts.dictationKey
        pasteAgainKey = shortcuts.pasteAgainKey
    }

    // MARK: Changes the user makes

    func changeLaunchAtLogin(_ on: Bool) {
        launchAtLogin = on
        onLaunchAtLoginChange(on)
    }

    func changeLiveWords(_ choice: LiveWords) {
        liveWords = choice
        onLiveWordsChange(choice)
    }

    func changeMicrophone(_ uid: String?) {
        chosenMicrophone = uid
        onMicrophoneChange(uid)
    }

    func changeSpeechModel(_ id: SpeechModelID) {
        speechModel = id
        onSpeechModelChange(id)
    }

    func changeCleanupEnabled(_ on: Bool) {
        isCleanupEnabled = on
        onCleanupEnabledChange(on)
    }

    func changeCleanupRules(_ rules: String) {
        cleanupRules = rules
        onCleanupRulesChange(rules)
    }

    func changeWordList(_ words: [String]) {
        wordList = words
        onWordListChange(words)
    }

    func submitAPIKey(_ key: String) {
        apiKey = key
        onAPIKeySubmit(key)
    }

    // MARK: Shortcut recording

    func beginRecording(_ slot: ShortcutSlot) {
        endRecording()
        recorder.arm(for: slot)
        recordingSlot = slot
        if shortcutProblem?.slot == slot { shortcutProblem = nil }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged]) { [weak self] event in
            MainActor.assumeIsolated { self?.handle(event) }
            return nil
        }
        resignObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.endRecording() }
        }
        onShortcutRecordingChange(true)
        AccessibilityNotification.Announcement("Press the key to use").post()
    }

    func endRecording() {
        guard recordingSlot != nil else { return }
        recorder.disarm()
        recordingSlot = nil
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        if let resignObserver { NotificationCenter.default.removeObserver(resignObserver) }
        keyMonitor = nil
        resignObserver = nil
        onShortcutRecordingChange(false)
    }

    func clearPasteAgainKey() {
        recorder.store.pasteAgainKey = nil
        pasteAgainKey = nil
        onShortcutsChange()
    }

    private func handle(_ event: NSEvent) {
        guard let slot = recordingSlot else { return }
        let kind: RawKeyEvent.Kind = switch event.type {
        case .keyDown: .keyDown
        case .keyUp: .keyUp
        default: .flagsChanged
        }
        let raw = RawKeyEvent(
            kind: kind,
            keyCode: event.keyCode,
            flags: KeyModifiers(rawValue: UInt64(event.modifierFlags.rawValue)),
            isRepeat: kind == .keyDown && event.isARepeat)
        switch recorder.record(raw) {
        case nil:
            break
        case .accepted(let choice):
            shortcutProblem = nil
            dictationKey = recorder.store.dictationKey
            pasteAgainKey = recorder.store.pasteAgainKey
            endRecording()
            onShortcutsChange()
            AccessibilityNotification.Announcement(choice.description).post()
        case .rejected(let rejection):
            shortcutProblem = ShortcutProblem(slot: slot, rejection: rejection)
            AccessibilityNotification.Announcement(shortcutProblem?.message ?? "").post()
            // Escape is also how a keyboard user leaves recording, so it ends it after saying why.
            if rejection == .escape { endRecording() }
        }
    }
}
