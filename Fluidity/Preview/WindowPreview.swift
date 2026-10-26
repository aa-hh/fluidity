import AppKit
import FluidityCore
import SwiftUI

/// Opens one window with sample data so its look can be checked by eye:
/// `FLUIDITY_PREVIEW=settings|popover|firstrun`, optionally `FLUIDITY_PREVIEW_APPEARANCE=light|dark`.
/// Prints the window number so `screencapture -l <number>` can capture it.
@MainActor
enum WindowPreview {
    private static var retained: [AnyObject] = []

    /// Call once at launch; does nothing unless `FLUIDITY_PREVIEW` is set.
    static func openIfRequested() {
        let environment = ProcessInfo.processInfo.environment
        guard let which = environment["FLUIDITY_PREVIEW"] else { return }
        switch environment["FLUIDITY_PREVIEW_APPEARANCE"] {
        case "dark": NSApp.appearance = NSAppearance(named: .darkAqua)
        case "light": NSApp.appearance = NSAppearance(named: .aqua)
        default: break
        }
        let settings = sampleSettings()
        retained.append(settings)
        let number: Int?
        switch which {
        case "settings":
            let window = SettingsWindow(model: settings)
            window.show()
            retained.append(window)
            number = window.windowNumber
        case "popover":
            let model = PopoverModel()
            model.records = sampleRecords()
            let panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = true
            panel.contentView = NSHostingView(rootView: PopoverView(model: model, settings: settings))
            panel.setContentSize(panel.contentView?.fittingSize ?? .zero)
            panel.center()
            panel.orderFrontRegardless()
            retained.append(contentsOf: [model, panel] as [AnyObject])
            number = panel.windowNumber
        case "firstrun":
            settings.microphone = .granted
            let model = FirstRunModel()
            model.modelProgress = 0.52
            let window = FirstRunWindow(model: model, settings: settings)
            window.show()
            retained.append(contentsOf: [model, window] as [AnyObject])
            number = window.windowNumber
        default:
            number = nil
        }
        if let number { print("FLUIDITY_PREVIEW window \(number)") }
    }

    private final class SampleShortcuts: ShortcutStoring {
        var dictationKey = KeyChoice(keyCode: 61)
        var pasteAgainKey: KeyChoice? = KeyChoice(keyCode: 9, modifiers: [.control, .option])
    }

    private static func sampleSettings() -> SettingsModel {
        let settings = SettingsModel(shortcuts: SampleShortcuts())
        settings.launchAtLogin = true
        settings.cleanupKey = .accepted
        settings.apiKey = "csk-sample-key-for-preview"
        settings.wordList = ["Parakeet", "Cerebras", "Kubernetes", "Priya Raman"]
        settings.microphone = .granted
        settings.accessibility = .denied
        settings.menuBarState = .permissionMissing(.accessibility)
        return settings
    }

    private static func sampleRecords() -> [DictationRecord] {
        let samples: [(String, String, TimeInterval, Bool, FallbackReason?)] = [
            ("Can you check why the pill tests fail on the mule and send me the log?", "com.apple.Notes", 20, true, nil),
            ("Move the standup to 10:30 and tell Priya the build is green again.", "com.apple.MobileSMS", 240, true, nil),
            ("Rename the rules field to Rules and keep restore default right under it.", "com.apple.TextEdit", 720, true, .slow),
            ("Thanks, that works. Ship it after lunch.", "com.apple.mail", 2280, false, nil),
        ]
        return samples.map { text, app, age, landed, reason in
            DictationRecord(
                id: UUID(), startedAt: Date(timeIntervalSinceNow: -age), app: app, rawTranscript: text,
                pastedText: landed ? text : nil, pasteLanded: landed, fallbackReason: reason,
                modelVersion: "parakeet-tdt-0.6b-v2", wordListVersion: "0000")
        }
    }
}
