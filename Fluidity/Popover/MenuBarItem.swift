import AppKit
import FluidityCore
import SwiftUI

/// The menu bar item: `MenuBarIcon` for the current state, and `PopoverView` in a clear borderless
/// panel under it. `NSPopover` would draw its own background behind the Glass shell.
@MainActor
final class MenuBarItem: NSObject {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let panel = PopoverPanel(
        contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
    private let willOpen: () async -> Void
    private var outsideClickMonitor: Any?

    /// `willOpen` runs before every opening, to refresh what the popover shows.
    init(model: PopoverModel, settings: SettingsModel, willOpen: @escaping () async -> Void) {
        self.willOpen = willOpen
        super.init()
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .popUpMenu
        panel.isReleasedWhenClosed = false
        panel.contentView = NSHostingView(rootView: PopoverView(model: model, settings: settings))
        panel.onDismiss = { [weak self] in self?.close() }
        item.button?.target = self
        item.button?.action = #selector(toggle)
    }

    func show(_ state: MenuBarState) {
        item.button?.image = MenuBarIcon.image(for: state)
    }

    var isOpen: Bool { panel.isVisible }

    func close() {
        guard panel.isVisible else { return }
        panel.orderOut(nil)
        item.button?.highlight(false)
        if let outsideClickMonitor { NSEvent.removeMonitor(outsideClickMonitor) }
        outsideClickMonitor = nil
    }

    /// Fits the panel to the popover's content, under the menu bar item. Call when the list changes.
    func place() {
        guard let button = item.button, let buttonWindow = button.window, let content = panel.contentView else { return }
        let anchor = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        let size = content.fittingSize
        var origin = NSPoint(x: anchor.midX - size.width / 2, y: anchor.minY - 4 - size.height)
        if let screen = buttonWindow.screen?.visibleFrame {
            origin.x = min(max(origin.x, screen.minX + 8), screen.maxX - 8 - size.width)
        }
        panel.setFrame(NSRect(origin: origin, size: size), display: true)
    }

    @objc private func toggle() {
        if panel.isVisible { return close() }
        Task {
            await willOpen()
            place()
            item.button?.highlight(true)
            // A non-activating panel takes keys without pulling focus from the app being dictated into.
            panel.makeKeyAndOrderFront(nil)
            outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { _ in
                MainActor.assumeIsolated { self.close() }
            }
        }
    }
}

private final class PopoverPanel: NSPanel {
    var onDismiss: () -> Void = {}

    override var canBecomeKey: Bool { true }

    override func cancelOperation(_ sender: Any?) { onDismiss() }

    override func resignKey() {
        super.resignKey()
        onDismiss()
    }
}
