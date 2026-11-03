import AppKit
import SwiftUI

/// The app window: History and the settings panes. It opens at 1200 × 680 and resizes down to 1040 × 640.
/// The app shell keeps one and calls `show(pane:)`.
@MainActor
final class SettingsWindow {
    static let minimumSize = NSSize(width: 1040, height: 640)

    let model: SettingsModel
    let history: HistoryModel
    private var window: NSWindow?

    init(model: SettingsModel, history: HistoryModel) {
        self.model = model
        self.history = history
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
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 680),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.title = "Rillo"
        window.contentMinSize = Self.minimumSize
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: SettingsView(model: model, history: history))
        window.center()
        return window
    }
}

struct SettingsView: View {
    let model: SettingsModel
    let history: HistoryModel

    var body: some View {
        HStack(spacing: 0) {
            SettingsSidebar(model: model)
            Group {
                if model.pane == .history {
                    HistoryPane(model: history, settings: model)
                } else {
                    settingsPane
                }
            }
            .id(model.pane)
            .transition(.opacity)
        }
        .animation(GlassTheme.snap, value: model.pane)
        .frame(
            minWidth: SettingsWindow.minimumSize.width, maxWidth: .infinity,
            minHeight: SettingsWindow.minimumSize.height, maxHeight: .infinity)
        .glassShell(isLive: model.isMicLive)
        .focusEffectDisabled()
        .ignoresSafeArea()
        .onChange(of: model.pane) { old, _ in
            model.endRecording()
            if old == .speechModel { model.onClearReadyModel() }
        }
    }

    private var settingsPane: some View {
        GeometryReader { geometry in
            ScrollViewReader { scroller in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(model.pane.title)
                            .font(GlassTheme.title)
                            .foregroundStyle(GlassTheme.textPrimary)
                            .accessibilityAddTraits(.isHeader)
                        switch model.pane {
                        case .history: EmptyView()
                        case .general: GeneralPane(model: model)
                        case .speechModel: SpeechModelPane(model: model)
                        case .cleanup: CleanupPane(model: model)
                        case .words: WordsPane(model: model)
                        case .permissions: PermissionsPane(model: model)
                        }
                    }
                    .padding(.leading, 20)
                    .padding(.trailing, 4)
                    .padding(.vertical, 20)
                    // A fixed width, 16 pt short of the scroll view and pinned left, so a scroll bar appearing or
                    // disappearing (Cloud's rows overflow, Local's don't) never shifts the pane sideways.
                    .frame(width: max(0, geometry.size.width - 16), alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollBounceBehavior(.basedOnSize)
                .task(id: model.revealsHistorySettings) {
                    guard model.revealsHistorySettings else { return }
                    // One layout pass first, so the group has a place to scroll to.
                    await Task.yield()
                    withAnimation(GlassTheme.snap) { scroller.scrollTo(GeneralPane.historyGroupID, anchor: .top) }
                    model.revealsHistorySettings = false
                }
            }
        }
    }
}

/// The sidebar: History and five panes 2 pt apart under the window controls, the status line at its foot.
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
