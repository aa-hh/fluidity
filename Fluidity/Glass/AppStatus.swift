import FluidityCore

/// Where the cleanup API key stands, as the settings and the popover show it.
enum CleanupKeyState: Equatable {
    case noKey
    case checking
    case accepted
    /// Cerebras refused the key.
    case refused
    /// No network, so the key could not be checked and cleanup is paused.
    case offline
}

/// A macOS permission as the windows show it.
enum PermissionStatus: Equatable {
    case granted
    /// The microphone prompt has not been shown yet; Accessibility never uses this.
    case notAsked
    case denied
}

/// What the status line at the sidebar's foot and the popover's status row say.
struct AppStatus: Equatable {
    enum Fix: Equatable {
        case permission(DictationController.Permission)
        case cleanup
    }

    /// The short form for the sidebar status line ("Accessibility off").
    let shortTitle: String
    /// The popover's status title ("Accessibility access is off").
    let title: String
    /// The popover's second line, if any.
    let detail: String?
    let tone: StatusDot.Tone
    /// Where the problem is fixed; the status line and popover offer a way there.
    let fix: Fix?
    /// The popover shows the fix as a button; offline has nothing to press.
    let offersFixButton: Bool
    /// Ready states show the dictation key next to the status.
    let showsKey: Bool

    static func current(menuBar: MenuBarState, cleanupKey: CleanupKeyState) -> AppStatus {
        switch (menuBar, cleanupKey) {
        case (.permissionMissing(.microphone), _):
            AppStatus(shortTitle: "Microphone off", title: "Microphone access is off",
                      detail: "Fluidity can't hear you until you allow it.",
                      tone: .attention, fix: .permission(.microphone), offersFixButton: true, showsKey: false)
        case (.permissionMissing(.accessibility), _):
            AppStatus(shortTitle: "Accessibility off", title: "Accessibility access is off",
                      detail: "Dictations wait in the list below instead of pasting.",
                      tone: .attention, fix: .permission(.accessibility), offersFixButton: true, showsKey: false)
        case (.recording, _):
            AppStatus(shortTitle: "Listening", title: "Listening", detail: nil,
                      tone: .live, fix: nil, offersFixButton: false, showsKey: true)
        case (_, .refused):
            AppStatus(shortTitle: "Key not accepted", title: "Key not accepted",
                      detail: "Raw transcript pasted. Cerebras didn't accept your key.",
                      tone: .attention, fix: .cleanup, offersFixButton: true, showsKey: false)
        case (_, .offline):
            AppStatus(shortTitle: "Offline", title: "Offline",
                      detail: "The raw transcript is pasted until you're back online.",
                      tone: .attention, fix: .cleanup, offersFixButton: false, showsKey: false)
        case (_, .noKey):
            AppStatus(shortTitle: "No Cerebras key", title: "No Cerebras key",
                      detail: "Raw transcript pasted. Add a key to turn cleanup on.",
                      tone: .attention, fix: .cleanup, offersFixButton: true, showsKey: false)
        case (.cleanupOff, _):
            AppStatus(shortTitle: "Cleanup off", title: "Ready", detail: "Cleanup off · raw transcript pasted",
                      tone: .neutral, fix: nil, offersFixButton: false, showsKey: true)
        case (.ready, _):
            AppStatus(shortTitle: "Ready", title: "Ready", detail: nil,
                      tone: .neutral, fix: nil, offersFixButton: false, showsKey: true)
        }
    }

    /// The fix button's text, in macOS title case.
    var fixButtonTitle: String? {
        switch fix {
        case .permission(.microphone): "Open Microphone Settings"
        case .permission(.accessibility): "Open Accessibility Settings"
        case .cleanup: "Open Cleanup Settings"
        case nil: nil
        }
    }
}
