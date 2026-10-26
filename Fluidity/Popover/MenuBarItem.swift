import AppKit
import FluidityCore
import SwiftUI

/// The menu bar item: `MenuBarIcon` for the current state, and `PopoverView` in a clear borderless
/// panel under it. `NSPopover` would draw its own background behind the Glass shell.
/// A right-click or Control-click shows a short system menu instead: Open, Settings and Quit.
@MainActor
final class MenuBarItem: NSObject {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let panel = PopoverPanel(
        contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
    private let model: PopoverModel
    private let willOpen: () async -> Void
    private var outsideClickMonitor: Any?

    /// `willOpen` runs before every opening, to refresh what the popover shows.
    init(model: PopoverModel, settings: SettingsModel, willOpen: @escaping () async -> Void) {
        self.model = model
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
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
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
        if let event = NSApp.currentEvent,
           event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            return showMenu()
        }
        if panel.isVisible { return close() }
        open()
    }

    @objc private func open() {
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

extension MenuBarItem {
    private func showMenu() {
        close()
        guard let button = item.button else { return }
        let menu = NSMenu()
        menu.addItem(withTitle: "Open Fluidity", action: #selector(open), keyEquivalent: "")
        menu.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Fluidity", action: #selector(quit), keyEquivalent: "q")
        menu.items.forEach { $0.target = self }
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.maxY + 5), in: button)
    }

    @objc private func openSettings() { model.onOpenSettings(nil) }

    @objc private func quit() { model.onQuit() }
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
