import AppKit
import FluidityCore
import SwiftUI

/// The 760 pt compare window. The app shell makes one per opening and closes it with `close()`.
@MainActor
final class CompareWindow: NSObject, NSWindowDelegate {
    let model: CompareModel
    private var window: NSWindow?

    init(model: CompareModel) {
        self.model = model
    }

    func show() {
        let window = window ?? makeWindow()
        self.window = window
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    func close() {
        window?.delegate = nil
        window?.close()
        window = nil
    }

    /// The close button does what Keep Current does.
    func windowWillClose(_ notification: Notification) {
        window?.delegate = nil
        window = nil
        model.onKeep()
    }

    private func makeWindow() -> NSWindow {
        let hosting = NSHostingController(rootView: CompareView(model: model))
        // The window follows the content's height as the columns and the differences list change.
        hosting.sizingOptions = [.preferredContentSize]
        // The view draws under the title bar itself; a safe area would add the title bar's height to the window.
        hosting.safeAreaRegions = []
        let window = NSWindow(contentViewController: hosting)
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.title = "Compare speech models"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        return window
    }
}

struct CompareView: View {
    let model: CompareModel
    @AccessibilityFocusState private var differencesFocused: Bool

    private var session: CompareSession { model.session }
    private var inUseName: String { SpeechModel.model(model.inUse).name }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Compare speech models").font(GlassTheme.title).foregroundStyle(GlassTheme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text(session.phase == .finished
                     ? "Both models heard the same recording, on this Mac. Nothing was pasted."
                     : "Both models hear the same recording, on this Mac. Nothing is pasted while this window is open.")
                    .font(GlassTheme.detail).foregroundStyle(GlassTheme.textSecondary)
            }
            source
            HStack(alignment: .top, spacing: 16) {
                CompareColumn(model: model, column: .left)
                CompareColumn(model: model, column: .right)
            }
            if let result = session.result, !session.isReplaying, !result.differences.isEmpty {
                differencesList(result)
            } else if session.phase != .finished {
                meanwhile
            }
            footer
            HStack(spacing: 12) {
                Spacer()
                Button("Keep Current", action: model.onKeep)
                    .buttonStyle(.glassSecondary)
                    .keyboardShortcut(.cancelAction)
                    .accessibilityLabel("Keep \(SpeechModel.model(session.left).name), close")
                Button("Switch Model", action: model.onSwitch)
                    .buttonStyle(.glassPrimary)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!model.bothOnMac || session.result == nil)
                    .accessibilityLabel("Switch to \(SpeechModel.model(session.right).name)")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 56)
        .padding(.bottom, 20)
        .frame(width: 760)
        .glassShell(isLive: session.phase == .listening)
        .focusEffectDisabled()
        .ignoresSafeArea()
        .onChange(of: session.phase) { _, phase in
            guard phase == .finished, let count = session.result?.differences.count else { return }
            AccessibilityNotification.Announcement("Finished, \(count) \(count == 1 ? "difference" : "differences")").post()
            differencesFocused = count > 0
        }
    }

    private var source: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Say this, or anything you like").font(GlassTheme.detail).foregroundStyle(GlassTheme.textSecondary)
                Text("“Move the standup to 10:30 and tell Priya the build is green again.”")
                    .font(GlassTheme.body).foregroundStyle(GlassTheme.textPrimary)
            }
            .accessibilityElement(children: .combine)
            .frame(maxWidth: .infinity, alignment: .leading)
            Button(session.phase == .listening ? "Stop" : "Speak Now") {
                if session.phase == .listening {
                    Task { await session.stop() }
                } else {
                    session.start()
                }
            }
            .buttonStyle(.glassSecondary)
            .disabled(session.phase == .finishing || (session.phase != .listening && (!model.bothReady || model.dictationRunning)))
        }
        .padding(12)
        .glassBox()
    }

    private var meanwhile: some View {
        let text: String
        if model.bothOnMac {
            text = "Both menus list every model in the Speech model pane, on this Mac or not. Dictation keeps working with \(inUseName) while this window is open."
        } else if [session.left, session.right].contains(where: { if case .downloading = model.modelStates[$0] { true } else { false } }) {
            text = "Dictation keeps working with \(inUseName) while this downloads. You can close this window: the download carries on, and Compare in the Speech model pane brings you back here."
        } else {
            text = "Once a download starts you can close this window: it carries on, and Compare in the Speech model pane brings you back here."
        }
        return HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle").font(.system(size: 13)).foregroundStyle(GlassTheme.textPrimary)
                .frame(width: 16, height: 16)
                .accessibilityHidden(true)
            Text(text).font(GlassTheme.detail).foregroundStyle(GlassTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func differencesList(_ result: CompareSession.CompareResult) -> some View {
        let count = result.differences.count
        return VStack(spacing: 0) {
            HStack(spacing: 40) {
                Text("Differences · \(SpeechModel.model(result.leftFinal.model).name)").frame(maxWidth: .infinity, alignment: .leading)
                Text(SpeechModel.model(result.rightFinal.model).name).frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(GlassTheme.small).foregroundStyle(GlassTheme.textSecondary)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .accessibilityHidden(true)
            ForEach(Array(result.differences.enumerated()), id: \.offset) { index, difference in
                GlassRule()
                HStack(spacing: 40) {
                    Text(difference.left.isEmpty ? "–" : difference.left).frame(maxWidth: .infinity, alignment: .leading)
                    Text(difference.right.isEmpty ? "–" : difference.right).frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(GlassTheme.body).foregroundStyle(GlassTheme.textPrimary)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Difference \(index + 1) of \(count). \(SpeechModel.model(result.leftFinal.model).name): \(difference.left.isEmpty ? "nothing" : difference.left). \(SpeechModel.model(result.rightFinal.model).name): \(difference.right.isEmpty ? "nothing" : difference.right).")
            }
        }
        .glassBox()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Differences")
        .accessibilityFocused($differencesFocused)
    }

    private var footer: some View {
        let (tone, label, hint): (StatusDot.Tone, String, String) = {
            let key = model.dictationKey
            switch session.phase {
            case .listening: return (.live, "Listening", "Press Stop or tap \(key) to stop")
            case .finishing: return (.neutral, "Finishing", "Both models are writing the final text")
            case .idle where model.dictationRunning, .finished where model.dictationRunning:
                return (.neutral, "Dictating", "Finish your dictation first.")
            case .finished: return (.neutral, "Finished", "Tap \(key) to try another sentence")
            case .idle:
                if let failure = session.failure { return (.neutral, "Couldn't finish", failure) }
                let columns = [session.left, session.right]
                if columns.contains(where: { if case .downloading = model.modelStates[$0] { true } else { false } }) {
                    return (.neutral, "Waiting for the download", "\(inUseName) stays in use")
                }
                if !model.bothOnMac { return (.neutral, "Not downloaded", "\(inUseName) stays in use") }
                if model.loadFailed { return (.neutral, "Couldn't load", "\(inUseName) stays in use") }
                if !model.bothReady { return (.hollow, "Loading", "Speak Now starts once both sides are ready") }
                return (.neutral, "Ready", "Press Speak Now or tap \(key) to start")
            }
        }()
        return HStack(spacing: 8) {
            StatusDot(tone: tone)
            Text(label).font(GlassTheme.label).foregroundStyle(GlassTheme.textPrimary)
            Text(hint).font(GlassTheme.small).foregroundStyle(GlassTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            if session.phase == .finished, !session.recording.isEmpty {
                Button("Play Recording", action: model.playRecording).buttonStyle(.glassQuiet)
                Button("Replay Live Words Slowly", action: session.replayLiveWords).buttonStyle(.glassQuiet)
            }
        }
        .frame(minHeight: GlassTheme.controlHeight)
    }
}

/// One column: the model's pop-up menu, its figures, and a box with its live words, final text or download.
private struct CompareColumn: View {
    let model: CompareModel
    let column: CompareSession.Column

    private var session: CompareSession { model.session }
    private var id: SpeechModelID { column == .left ? session.left : session.right }
    private var other: SpeechModelID { column == .left ? session.right : session.left }
    private var info: SpeechModel { SpeechModel.model(id) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            menu
            Text(figures).font(GlassTheme.small).foregroundStyle(GlassTheme.textSecondary)
                // Both boxes start at the same height when either line wraps.
                .lineLimit(2, reservesSpace: !model.bothOnMac)
                .fixedSize(horizontal: false, vertical: true)
            box
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var menu: some View {
        Menu {
            Section("On this Mac") {
                ForEach(SpeechModel.all.filter { model.isOnMac($0.id) }) { item(for: $0) }
            }
            Section("Available to download") {
                ForEach(SpeechModel.all.filter { !model.isOnMac($0.id) }) { item(for: $0) }
            }
        } label: {
            HStack(spacing: 8) {
                Text(info.name)
                Image(systemName: "chevron.up.chevron.down").font(.system(size: 10, weight: .semibold))
            }
        }
        .menuStyle(.button)
        .buttonStyle(.glassSecondary)
        .menuIndicator(.hidden)
        .fixedSize()
        .disabled(session.phase == .listening || session.phase == .finishing)
        .accessibilityLabel(column == .left ? "Left model" : "Right model")
        .accessibilityValue(info.name)
    }

    private func item(for candidate: SpeechModel) -> some View {
        Button(candidate.name) {
            if column == .left { session.choose(left: candidate.id) } else { session.choose(right: candidate.id) }
        }
        .disabled(candidate.id == other)
    }

    private var figures: String {
        var parts: [String] = []
        switch model.modelStates[id] {
        case _ where id == model.inUse: parts.append("In use")
        case .installed, .partOfMacOS: parts.append("On this Mac")
        case .downloading: parts.append("Downloading")
        default: parts += ["Not downloaded", size]
        }
        if case .partOfMacOS = info.install { parts.append("built into macOS") }
        if let figures = info.figures {
            parts += ["first correct word \(figures.firstWordMs) ms", "updates every \(figures.updateEveryMs) ms"]
        } else {
            parts.append("timings not measured")
        }
        return parts.joined(separator: " · ")
    }

    private var size: String {
        guard case .download(let bytes, let approximate, _) = info.install else { return "" }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = .useMB
        formatter.countStyle = .file
        let text = formatter.string(fromByteCount: bytes)
        return approximate ? "about \(text)" : text
    }

    @ViewBuilder private var box: some View {
        switch model.modelStates[id] {
        case .downloading(let done, let total):
            VStack(alignment: .leading, spacing: 8) {
                Text("Downloading \(info.name)").font(GlassTheme.label).foregroundStyle(GlassTheme.textPrimary)
                ProgressBar(fraction: total > 0 ? Double(done) / Double(total) : 0)
                    .accessibilityLabel("Download of \(info.name)")
                    .accessibilityValue("\(Int(total > 0 ? Double(done) / Double(total) * 100 : 0)) percent")
                Text("\(size.prefix(1).uppercased())\(size.dropFirst()). When it finishes, press Speak Now and say the sentence; both models write it side by side.")
                    .font(GlassTheme.small).foregroundStyle(GlassTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Cancel Download") { model.onCancelDownload(id) }.buttonStyle(.glassSecondary)
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassBox()
        case .notInstalled where id == model.inUse:
            // The launch load is fetching the model dictation uses; ModelDownloads refuses a second download.
            VStack(alignment: .leading, spacing: 8) {
                Text("Downloading \(info.name)").font(GlassTheme.label).foregroundStyle(GlassTheme.textPrimary)
                Text("Dictation needs it, so it downloads as the app starts. When it finishes, press Speak Now and say the sentence.")
                    .font(GlassTheme.small).foregroundStyle(GlassTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassBox()
        case .notInstalled:
            VStack(alignment: .leading, spacing: 8) {
                Text("\(info.name) is not on this Mac yet").font(GlassTheme.label).foregroundStyle(GlassTheme.textPrimary)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Comparing needs it downloaded first: \(size). Dictation keeps working with \(SpeechModel.model(model.inUse).name) while it downloads.")
                        .font(GlassTheme.small).foregroundStyle(GlassTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Download") { model.onDownload(id) }
                        .buttonStyle(.glassSecondary)
                        .accessibilityLabel("Download, \(size)")
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassBox()
        default:
            VStack(alignment: .leading, spacing: 8) {
                text.font(GlassTheme.body).foregroundStyle(GlassTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(caption).font(GlassTheme.small).foregroundStyle(GlassTheme.textSecondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassBox()
        }
    }

    private var text: Text {
        if let result = session.result, !session.isReplaying {
            let final = column == .left ? result.leftFinal.text : result.rightFinal.text
            let changed = Set(result.differences.flatMap { Array(column == .left ? $0.leftWords : $0.rightWords) })
            var attributed = AttributedString()
            for (index, word) in TranscriptDiff.words(final).enumerated() {
                if index > 0 { attributed += AttributedString(" ") }
                var piece = AttributedString(word)
                if changed.contains(index) { piece.underlineStyle = .single }
                attributed += piece
            }
            return Text(attributed)
        }
        switch session.phase {
        case .listening, .finishing, .finished:
            return Text(session.liveText[column] ?? "")
        case .idle:
            switch model.loads[id] {
            case .loaded: return Text("\(info.name) is ready. Its live words appear here when you speak.")
            case .failed(let message): return Text("Couldn't load \(info.name): \(message)")
            case nil: return Text("Loading \(info.name)…")
            }
        }
    }

    private var caption: String {
        if let result = session.result, !session.isReplaying {
            let count = result.differences.count
            return count == 0 ? "No differences" : "\(count) \(count == 1 ? "difference" : "differences"), underlined"
        }
        switch session.phase {
        case .listening: return "Live words"
        case .finishing: return "Writing the final text"
        case .finished: return "Replaying live words at half speed"
        case .idle: return "Speak Now starts once both sides are ready"
        }
    }
}

/// The 4 pt capsule download bar.
private struct ProgressBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { proxy in
            Capsule().fill(GlassTheme.selected)
                .overlay(alignment: .leading) {
                    Capsule().fill(GlassTheme.textSecondary).frame(width: proxy.size.width * min(max(fraction, 0), 1))
                }
        }
        .frame(height: 4)
    }
}

private extension View {
    /// The raised box the compare window draws its prompt, columns and differences in.
    func glassBox() -> some View {
        let shape = RoundedRectangle(cornerRadius: GlassTheme.containerRadius, style: .continuous)
        return background(GlassTheme.raised, in: shape)
            .clipShape(shape)
            .overlay { shape.strokeBorder(GlassTheme.lineRule, lineWidth: 1) }
    }
}
