import AppKit
import MetalKit

/// The pill's panel: borderless and transparent, with no shadow, never key,
/// on every Space and click-through. The rim draws in `rimView`; the words
/// sit over it in `wordsView`, drawn as text rather than by the shader. The
/// waiting bubble takes clicks through its own small panel.
@MainActor
final class PillWindow: NSPanel {
    let rimView: MTKView
    let wordsView: PillWordsView

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    init(device: MTLDevice, size: CGSize) {
        let view = MTKView(frame: .zero, device: device)
        view.colorPixelFormat = .bgra8Unorm
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        view.layer?.isOpaque = false
        view.framebufferOnly = true
        view.enableSetNeedsDisplay = false
        view.isPaused = true
        view.preferredFramesPerSecond = PillPresenter.activeFps
        self.rimView = view
        self.wordsView = PillWordsView(frame: NSRect(origin: .zero, size: size))
        super.init(contentRect: NSRect(origin: .zero, size: size), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        self.isFloatingPanel = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.ignoresMouseEvents = true
        self.hidesOnDeactivate = false
        self.animationBehavior = .none
        self.setAccessibilityElement(false)
        let container = NSView(frame: NSRect(origin: .zero, size: size))
        view.frame = container.bounds
        view.autoresizingMask = [.width, .height]
        container.addSubview(view)
        self.wordsView.autoresizingMask = [.width, .height]
        container.addSubview(self.wordsView)
        self.contentView = container
        // An MTKView made at zero size outside a window can keep a contentsScale of 0 (seen on macOS 27),
        // and the window server then shows every frame it draws at zero size.
        view.layer?.contentsScale = self.backingScaleFactor
    }

    /// The screen under the pointer, else the one with the key window.
    static func screenForPointer() -> NSScreen? {
        let pointer = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(pointer, $0.frame, false) } ?? NSScreen.main
    }
}
