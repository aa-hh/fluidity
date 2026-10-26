import AppKit
import SwiftUI

/// The 720 × 520 settings window. The app shell keeps one and calls `show(pane:)`.
@MainActor
final class SettingsWindow {
    let model: SettingsModel
    private var window: NSWindow?

    init(model: SettingsModel) {
        self.model = model
    }

    func show(pane: SettingsPane? = nil) {
        if let pane { model.pane = pane }
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
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 520),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.title = "Fluidity Settings"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: SettingsView(model: model))
        window.center()
        return window
    }
}

struct SettingsView: View {
    let model: SettingsModel

    var body: some View {
        HStack(spacing: 0) {
            SettingsSidebar(model: model)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(model.pane.title)
                        .font(GlassTheme.title)
                        .foregroundStyle(GlassTheme.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    switch model.pane {
                    case .general: GeneralPane(model: model)
                    case .cleanup: CleanupPane(model: model)
                    case .words: WordsPane(model: model)
                    case .permissions: PermissionsPane(model: model)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
            .id(model.pane)
            .transition(.opacity)
        }
        .animation(GlassTheme.snap, value: model.pane)
        .frame(width: 720, height: 520)
        .glassShell(isLive: model.isMicLive)
        .focusEffectDisabled()
        .ignoresSafeArea()
        .onChange(of: model.pane) { model.endRecording() }
    }
}

/// The sidebar: four panes 2 pt apart under the window controls, the status line at its foot.
private struct SettingsSidebar: View {
    let model: SettingsModel

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(SettingsPane.allCases.enumerated()), id: \.element) { index, pane in
                SidebarItem(pane: pane, isSelected: model.pane == pane) { model.pane = pane }
                    .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
            }
            Spacer(minLength: 0)
            SidebarStatusLine(model: model)
        }
        .padding(.horizontal, 12)
        .padding(.top, 52)
        .padding(.bottom, 12)
        .frame(width: GlassTheme.sidebarWidth)
        .frame(maxHeight: .infinity)
        .background(GlassTheme.sidebar)
        .overlay(alignment: .trailing) {
            Rectangle().fill(GlassTheme.lineRule).frame(width: 1).accessibilityHidden(true)
        }
        .onKeyPress(.downArrow) { move(by: 1) }
        .onKeyPress(.upArrow) { move(by: -1) }
    }

    private func move(by step: Int) -> KeyPress.Result {
        let panes = SettingsPane.allCases
        guard let index = panes.firstIndex(of: model.pane) else { return .ignored }
        model.pane = panes[(index + step + panes.count) % panes.count]
        return .handled
    }
}

private struct SidebarItem: View {
    let pane: SettingsPane
    let isSelected: Bool
    let select: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: select) {
            HStack(spacing: 8) {
                Image(systemName: pane.symbol).frame(width: 16)
                Text(pane.title).font(GlassTheme.label)
                Spacer(minLength: 0)
            }
            .foregroundStyle(GlassTheme.textPrimary)
            .padding(.horizontal, 8)
            .frame(height: GlassTheme.controlHeight)
            .background {
                if isSelected { Capsule().fill(GlassTheme.selected) } else if isHovering { Capsule().fill(GlassTheme.hover) }
            }
            .contentShape(Capsule())
            .glassFocusRing(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// "Ready · ⌥ Right Option" style line. A problem line is a button to the pane that fixes it.
private struct SidebarStatusLine: View {
    let model: SettingsModel
    @State private var isHovering = false

    var body: some View {
        let status = model.status
        let line = HStack(spacing: 8) {
            StatusDot(tone: status.tone)
            Text(status.shortTitle).font(GlassTheme.label).foregroundStyle(GlassTheme.textPrimary)
                .lineLimit(1)
            Spacer(minLength: 4)
            if status.showsKey {
                Text(model.dictationKey.description).font(GlassTheme.small)
                    .foregroundStyle(GlassTheme.textSecondary).lineLimit(1)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: GlassTheme.controlHeight)

        if let fix = status.fix {
            Button {
                switch fix {
                case .permission: model.pane = .permissions
                case .cleanup: model.pane = .cleanup
                }
            } label: {
                line.background { if isHovering { Capsule().fill(GlassTheme.hover) } }
                    .contentShape(Capsule())
                    .glassFocusRing(Capsule())
            }
            .buttonStyle(.plain)
            .onHover { isHovering = $0 }
            .accessibilityLabel("Status: \(status.title)")
        } else {
            line.accessibilityElement(children: .combine)
                .accessibilityLabel("Status: \(status.shortTitle)")
        }
    }
}
