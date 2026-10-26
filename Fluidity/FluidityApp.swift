import FluidityCore
import SwiftUI

@main
struct FluidityApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var app

    init() { PillPreview.startIfAsked() }

    var body: some Scene {
        MenuBarExtra {
            // Windows track: replace this menu with the popover view.
            Text(statusText)
            Toggle("Launch at Login", isOn: Binding(get: { app.launchesAtLogin }, set: { app.setLaunchesAtLogin($0) }))
            Divider()
            Button("Quit Fluidity") { NSApplication.shared.terminate(nil) }
        } label: {
            // Windows track: replace with the menu bar icon for `app.controller.menuBar`.
            Image(systemName: app.controller.menuBar == .recording ? "waveform.circle.fill" : "waveform")
        }

        SwiftUI.Settings {
            // Windows track: replace with the settings window.
            Text("Settings")
                .padding()
        }
    }

    private var statusText: String {
        switch app.controller.menuBar {
        case .ready, .micWarm: "Ready · \(app.settings.dictationKey.description)"
        case .recording: "Listening"
        case .cleanupOff: "Cleanup off: the raw transcript is pasted"
        case .permissionMissing(.microphone): "Microphone permission needed"
        case .permissionMissing(.accessibility): "Accessibility permission needed"
        }
    }
}
