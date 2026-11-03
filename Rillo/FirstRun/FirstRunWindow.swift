import AppKit
import SwiftUI

/// The first-run check, one step at a time in a 688 pt window: Microphone, Accessibility and the dictation key,
/// then the Speech model pane, then the Cleanup pane. It floats above every other window; closing it early is
/// fine, since Settings holds the same panes. No tour.
@MainActor
final class FirstRunWindow {
    let model: FirstRunModel
    let settings: SettingsModel
    private var window: NSWindow?

    init(model: FirstRunModel, settings: SettingsModel) {
        self.model = model
        self.settings = settings
    }

    func show() {
        let window = window ?? makeWindow()
        self.window = window
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    func close() {
        window?.close()
    }

    /// The window number, for `screencapture -l` in the preview.
    var windowNumber: Int? { window?.windowNumber }

    private func makeWindow() -> NSWindow {
        let hosting = NSHostingView(rootView: FirstRunView(model: model, settings: settings))
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: hosting.fittingSize),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.title = "Set up Rillo"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        // Above other apps' windows too, so System Settings or the app the user was in never hides it.
        window.level = .floating
        window.contentView = hosting
        window.center()
        return window
    }
}

struct FirstRunView: View {
    let model: FirstRunModel
    let settings: SettingsModel
    /// Starts on the first step; the preview passes another.
    @State var step = Step.permissions

    enum Step: String, CaseIterable {
        case permissions, speechModel, cleanup
    }

    private var bothAllowed: Bool { settings.microphone == .granted && settings.accessibility == .granted }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Group {
                switch step {
                case .permissions: permissionsStep
                case .speechModel: speechModelStep
                case .cleanup: cleanupStep
                }
            }
            .transition(.opacity)
            footer
        }
        .padding(.horizontal, 20)
        .padding(.top, 44)
        .padding(.bottom, 20)
        .frame(width: 688)
        .glassShell(isLive: settings.isMicLive)
        .focusEffectDisabled()
        .ignoresSafeArea()
        .onChange(of: bothAllowed) { _, allowed in
            if allowed { AccessibilityNotification.Announcement("Both allowed. Choose your dictation key.").post() }
        }
    }

    // MARK: Steps

    private var permissionsStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            heading("Set up Rillo", "Allow two things, then choose your dictation key.")
            GlassPanel {
                PermissionRow(model: settings, permission: .microphone)
                GlassRule()
                PermissionRow(model: settings, permission: .accessibility)
            }
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Your dictation key",
                              description: "Any one key works, even Right Option on its own.")
                GlassPanel {
                    GlassRow(title: "Dictation key",
                             error: settings.shortcutProblem?.slot == .dictation ? settings.shortcutProblem?.message : nil,
                             detail: GeneralPane.tapAndHold) {
                        ShortcutRecorderField(model: settings, slot: .dictation, name: "Dictation key")
                    }
                }
            }
            .disabled(!bothAllowed)
            .opacity(bothAllowed ? 1 : 0.4)
            .accessibilityHint(bothAllowed ? "" : "Available once Microphone and Accessibility are allowed")
        }
    }

    private var speechModelStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            heading("Choose a speech model", "It turns your voice into text, on this Mac. You can switch later in Settings.")
            if !model.isModelReady {
                GlassPanel { launchDownloadRow }
            }
            SpeechModelPane(model: settings)
        }
    }

    private var cleanupStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            heading("Clean up what you say", "Optional. Leave it off and Rillo pastes exactly what it heard.")
            CleanupPane(model: settings)
        }
    }

    private func heading(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(GlassTheme.title).foregroundStyle(GlassTheme.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(body).font(GlassTheme.body).foregroundStyle(GlassTheme.textSecondary)
        }
    }

    // MARK: Footer

    private var footer: some View {
        let steps = Step.allCases, index = steps.firstIndex(of: step) ?? 0
        return HStack(spacing: 8) {
            Text("Step \(index + 1) of \(steps.count)")
                .font(GlassTheme.small).foregroundStyle(GlassTheme.textSecondary)
            Spacer()
            if index > 0 {
                Button("Back") { go(to: steps[index - 1]) }.buttonStyle(.glassSecondary)
            }
            if index + 1 < steps.count {
                Button("Continue") { go(to: steps[index + 1]) }
                    .buttonStyle(.glassPrimary)
                    .disabled(!bothAllowed)
                    .keyboardShortcut(.defaultAction)
            } else {
                Button("Done", action: model.onDone)
                    .buttonStyle(.glassPrimary)
                    .keyboardShortcut(.defaultAction)
            }
        }
    }

    private func go(to next: Step) {
        withAnimation(GlassTheme.snap) { step = next }
    }

    // MARK: Launch download

    /// The first launch downloads and loads the chosen model before anything is picked; this row follows it.
    private var launchDownloadRow: some View {
        VStack(spacing: 0) {
            GlassRow(title: "Speech model", detail: launchDownloadDetail) {
                StatusIcon(kind: model.modelError != nil ? .attention : .info)
            } trailing: {
                EmptyView()
            }
            if model.modelError == nil && model.modelProgress < 1 {
                ProgressView(value: model.modelProgress)
                    .progressViewStyle(.linear)
                    .tint(GlassTheme.textSecondary)
                    .padding(.leading, 44)
                    .padding(.trailing, 12)
                    .padding(.bottom, 10)
                    .accessibilityLabel("Speech model download")
            }
        }
    }

    private var launchDownloadDetail: String {
        if let error = model.modelError { return error }
        if model.modelProgress >= 1 { return "Getting Parakeet ready…" }
        return "Downloading Parakeet · \(Int(model.modelProgress * 100))%"
    }
}
