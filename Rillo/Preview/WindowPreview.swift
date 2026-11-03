import AppKit
import RilloCore
import SwiftUI

/// Opens one window with sample data so its look can be checked by eye:
/// `RILLO_PREVIEW=settings|popover|firstrun`, optionally `RILLO_PREVIEW_APPEARANCE=light|dark`.
/// Prints the window number so `screencapture -l <number>` can capture it.
/// With `RILLO_PREVIEW_OUT=<path.png>`, `settings` (with `RILLO_PREVIEW_PANE` and
/// `RILLO_PREVIEW_STATE=default|downloading|failed|ready`), `firstrun` (`RILLO_PREVIEW_STATE=permissions|speechModel|cleanup`)
/// and `compare`
/// (`RILLO_PREVIEW_STATE=idle|notOnThisMac|result`) draw into a window never shown,
/// write it as a PNG and quit.
@MainActor
enum WindowPreview {
    private static var retained: [AnyObject] = []

    /// Call once at launch; does nothing unless `RILLO_PREVIEW` is set.
    static func openIfRequested() {
        let environment = ProcessInfo.processInfo.environment
        guard let which = environment["RILLO_PREVIEW"] else { return }
        switch environment["RILLO_PREVIEW_APPEARANCE"] {
        case "dark": NSApp.appearance = NSAppearance(named: .darkAqua)
        case "light": NSApp.appearance = NSAppearance(named: .aqua)
        default: break
        }
        let settings = sampleSettings()
        let history = HistoryModel()
        history.items = sampleHistory()
        retained.append(contentsOf: [settings, history] as [AnyObject])
        if let out = environment["RILLO_PREVIEW_OUT"] {
            let state = environment["RILLO_PREVIEW_STATE"] ?? ""
            switch which {
            case "settings":
                if let pane = environment["RILLO_PREVIEW_PANE"].flatMap(SettingsPane.init(rawValue:)) { settings.pane = pane }
                renderSettings(settings, history: history, state: state, to: out)
            case "firstrun":
                renderFirstRun(settings, step: FirstRunView.Step(rawValue: state) ?? .permissions, to: out)
            case "compare":
                Task { await renderCompare(state: state, to: out) }
            default:
                break
            }
            return
        }
        let number: Int?
        switch which {
        case "settings":
            let window = SettingsWindow(model: settings, history: history)
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
        if let number { print("RILLO_PREVIEW window \(number)") }
    }

    // MARK: Offscreen render

    /// The Speech model pane's sample states. A failure is set after the first layout,
    /// because the pane shows only failures that happen while it is open.
    private static func renderSettings(_ settings: SettingsModel, history: HistoryModel, state: String, to path: String) {
        settings.speechModel = .parakeetTDTv2
        settings.modelStates = [.parakeetTDTv2: .installed, .appleBuiltIn: .partOfMacOS, .parakeetUnified: .notInstalled]
        switch state {
        case "downloading": settings.modelStates[.parakeetUnified] = .downloading(downloadedBytes: 212_000_000, totalBytes: 565_000_000)
        case "ready":
            settings.modelStates[.parakeetUnified] = .installed
            settings.readyModel = .parakeetUnified
        default: break
        }
        let view = NSHostingView(rootView: SettingsView(model: settings, history: history))
        render(view, size: NSSize(width: 1200, height: 680), to: path) {
            if state == "failed" { settings.downloadFailure = (.parakeetUnified, .offline) }
        }
    }

    /// The first-run window on one step, with the launch download half done.
    private static func renderFirstRun(_ settings: SettingsModel, step: FirstRunView.Step, to path: String) {
        settings.accessibility = .granted
        settings.speechModel = .parakeetTDTv2
        settings.modelStates = [.parakeetTDTv2: .notInstalled, .appleBuiltIn: .partOfMacOS, .parakeetUnified: .notInstalled]
        settings.modelsInUse = [.parakeetTDTv2]
        settings.isPreparingModel = true
        let model = FirstRunModel()
        model.modelProgress = 0.52
        retained.append(model)
        let view = NSHostingView(rootView: FirstRunView(model: model, settings: settings, step: step))
        render(view, size: view.fittingSize, to: path) {}
    }

    private static func renderCompare(state: String, to path: String) async {
        let left = SampleSpeech(text: "Move the standup to 10:30 and tell Priya the build is green again.")
        let right = SampleSpeech(text: "Move the stand-up to 10:30 and tell Pria the build is green again.")
        let session = CompareSession(
            audio: SampleMicrophone(),
            makeTranscriber: { id in
                let engine = id == .parakeetTDTv2 ? left : right
                return Transcriber(engine: engine, model: id, voiceDetector: engine, rechecker: engine)
            })
        session.choose(left: .parakeetTDTv2, right: state == "notOnThisMac" ? .parakeetUnified : .appleBuiltIn)
        let model = CompareModel(session: session)
        model.dictationKey = "Right Option"
        model.modelStates = [.parakeetTDTv2: .installed, .appleBuiltIn: .partOfMacOS, .parakeetUnified: .notInstalled]
        model.loads = [.parakeetTDTv2: .loaded, .appleBuiltIn: .loaded]
        retained.append(model)
        if state == "result" {
            session.start()
            await session.stop()
        }
        let view = NSHostingView(rootView: CompareView(model: model))
        view.frame.size = NSSize(width: 760, height: 600)
        view.layoutSubtreeIfNeeded()
        render(view, size: NSSize(width: 760, height: view.fittingSize.height), to: path) {}
    }

    /// Lays `view` out in a window that is never ordered front, lets SwiftUI settle,
    /// writes its drawing to `path` as a PNG and quits.
    private static func render(_ view: NSView, size: NSSize, to path: String, afterLayout: @escaping () -> Void) {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .fullSizeContentView], backing: .buffered, defer: false)
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.isReleasedWhenClosed = false
        window.contentView = view
        view.layoutSubtreeIfNeeded()
        retained.append(window)
        afterLayout()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            view.layoutSubtreeIfNeeded()
            var code: Int32 = 1
            if let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
                view.cacheDisplay(in: view.bounds, to: bitmap)
                if let png = bitmap.representation(using: .png, properties: [:]),
                   (try? png.write(to: URL(fileURLWithPath: path))) != nil {
                    print("RILLO_PREVIEW wrote \(path)")
                    code = 0
                }
            }
            exit(code)
        }
    }

    /// A model that hears `text` in any recording, for the compare preview.
    private struct SampleSpeech: StreamingSpeechEngine, VoiceDetecting, WordListRechecking {
        let text: String
        func load(progress: @escaping @Sendable (Double) -> Void) async throws {}
        func transcribe(_ audio: [Float]) async throws -> Transcript { Transcript(text: text, wordTimings: []) }
        func unload() async {}
        func startStream(partial: @escaping @Sendable (String) -> Void) async throws {}
        func feed(_ chunk: [Float]) async throws {}
        func finishStream() async throws -> Transcript { Transcript(text: text, wordTimings: []) }
        func cancelStream() async {}
        func hasSpeech(in audio: [Float]) async throws -> Bool { true }
        func hasCandidates(in transcript: Transcript, wordList: [String]) async -> Bool { false }
        func recheck(_ transcript: Transcript, audio: [Float], wordList: [String]) async -> Transcript { transcript }
    }

    /// Two seconds of silence, for the compare preview's recording.
    private struct SampleMicrophone: AudioCapturing {
        func start() async throws -> AsyncStream<[Float]> { AsyncStream { $0.finish() } }
        func stop() async -> DictationController.Recording {
            DictationController.Recording(samples: Array(repeating: 0, count: 32_000), sampleRate: 16_000)
        }
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

    /// The History page's sample: the dictation from the design, cleaned, then the popover's samples.
    private static func sampleHistory() -> [HistoryItem] {
        let raw = "um so I think we should uh move the meeting to Thursday no wait Friday at three pm and send the the notes to Priya"
        let words = TranscriptDiff.words(raw)
        let cleaned = DictationRecord(
            id: UUID(), startedAt: Date(timeIntervalSinceNow: -120), app: "com.apple.mail", rawTranscript: raw,
            cleanedText: "I think we should move the meeting to Friday at 3 PM and send the notes to Priya.",
            pastedText: "I think we should move the meeting to Friday at 3 PM and send the notes to Priya.",
            wordTimings: words.enumerated().map { WordTiming(word: $1, start: Double($0) * 0.3, end: Double($0) * 0.3 + 0.25) },
            pasteLanded: true, modelVersion: "parakeet-tdt-0.6b-v2", wordListVersion: "0000")
        return [HistoryItem(record: cleaned)] + sampleRecords().map { HistoryItem(record: $0) }
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
