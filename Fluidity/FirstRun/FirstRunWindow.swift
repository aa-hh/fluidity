import AppKit
import SwiftUI

/// The first-run check: one 540 pt window with Microphone, Accessibility and the speech model,
/// then the dictation key, which unlocks once both permissions are allowed. No tour.
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
        window.title = "Set up Fluidity"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.contentView = hosting
        window.center()
        return window
    }
}

struct FirstRunView: View {
    let model: FirstRunModel
    let settings: SettingsModel

    private var bothAllowed: Bool { settings.microphone == .granted && settings.accessibility == .granted }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Set up Fluidity").font(GlassTheme.title).foregroundStyle(GlassTheme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text("Allow two things, then choose your dictation key.")
                    .font(GlassTheme.body).foregroundStyle(GlassTheme.textSecondary)
            }
            GlassPanel {
                PermissionRow(model: settings, permission: .microphone)
                GlassRule()
                PermissionRow(model: settings, permission: .accessibility)
                GlassRule()
                speechModelRow
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
            HStack {
                Spacer()
                Button("Done", action: model.onDone)
                    .buttonStyle(.glassPrimary)
                    .disabled(!bothAllowed)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 44)
        .padding(.bottom, 20)
        .frame(width: 540)
        .glassShell(isLive: settings.isMicLive)
        .ignoresSafeArea()
        .onChange(of: bothAllowed) { _, allowed in
            if allowed { AccessibilityNotification.Announcement("Both allowed. Choose your dictation key.").post() }
        }
    }

    private var speechModelRow: some View {
        VStack(spacing: 0) {
            GlassRow(title: "Speech model", detail: speechModelDetail) {
                StatusIcon(kind: model.modelError != nil ? .attention : model.isModelReady ? .done : .info)
            } trailing: {
                EmptyView()
            }
            if !model.isModelReady && model.modelError == nil && model.modelProgress < 1 {
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

    private var speechModelDetail: String {
        if let error = model.modelError { return error }
        if model.isModelReady { return "Ready" }
        if model.modelProgress >= 1 { return "Getting Parakeet ready…" }
        return "Downloading Parakeet · \(Int(model.modelProgress * 100))%"
    }
}
