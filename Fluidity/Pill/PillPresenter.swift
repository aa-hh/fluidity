import AppKit
import FluidityCore
import Metal
import MetalKit
import QuartzCore

/// The recording pill: shows `DictationController`'s `PillState` on the rim.
///
/// The panel is created once and stays ordered in; a hidden pill draws a
/// transparent frame and pauses its display link, so hiding costs no window
/// server round trip on the stop path and nothing while idle.
@MainActor
final class PillPresenter {
    static let shared = PillPresenter()

    /// Room around the pill for the halo, in points.
    static let margin: CGFloat = 6
    static let activeFps = 60
    /// The pill rests this far above the bottom of the screen's visible area, in points.
    static let dockMargin: CGFloat = 12

    /// The panel only resizes when the live words move above the pill or back,
    /// so a size change can glide and the bubble has room on either side: the
    /// pill as wide as live words make it and swollen by the split, plus the
    /// bubble, its gap and its shake. With the words above, it is tall enough
    /// for their bubble on either side, so the pill stays at its centre.
    static func panelSize(wordsAbove: Bool) -> CGSize {
        let p = RimParameters.approved
        let pill = RimParameters.pillSize
        let k = pill.height / CGFloat(RimSpring.islandHeight)
        let bubble = CGFloat(p.fluxGap + p.shake + 2.33) * k + 1.16 * CGFloat(p.fluxSize) * pill.height
        let widest = max(pill.width, RimWords.widest(pillHeight: pill.height))
        let textScale = RimWords.widest(pillHeight: pill.height) / RimWords.maxWidth
        let above = wordsAbove ? RimWords.tallestAbove(pillHeight: pill.height) + CGFloat(RimWordsBubble.gap) * textScale + 4 : 0
        return CGSize(
            width: (1.11 * widest + 2 * (bubble + margin)).rounded(.up),
            height: (1.11 * pill.height + 2 * (margin + above)).rounded(.up)
        )
    }

    /// Pastes the text waiting in the bubble again; returns true when it landed.
    var retryPaste: (@MainActor (String) async -> Bool)?
    /// Opens the System Settings pane for a missing permission; a click on the lock bubble calls it.
    var openPermissionSettings: (@MainActor (DictationController.Permission) -> Void)?
    /// Where the live preview shows: in the pill, in a bubble above it, or not at all (the waveform shows instead).
    var liveWords: LiveWords = .inPill {
        didSet { self.fitPanel() }
    }
    /// The speech model is still loading: while the pill shows, a bubble with a turning arc waits
    /// beside it and the centre line is dim and grey until the model is ready.
    var isModelLoading = false {
        didSet {
            self.simulation.modelLoading = self.isModelLoading
            self.wake()
        }
    }

    /// Splits the microphone's audio into the rim's voice bands.
    nonisolated let audio = RimAudioAnalyzer()

    private var window: PillWindow?
    private var renderer: PillRenderer?
    private var bubbleTarget: PillBubbleTarget?
    private var didFailToPrepare = false
    /// A click on the bubble asked for a retry that has not answered yet.
    private var isRetrying = false
    /// When a click on the bubble fires its action, once the press bump has started, and the state it was for.
    private var pressFiresAt: CFTimeInterval?
    private var pressedState: RimState = .idle
    /// The permission the lock bubble stands for.
    private var lockedPermission: DictationController.Permission?
    /// A failed paste's transcript waits in the bubble beside the pill.
    private var isHoldingFailedPaste = false
    /// The text that failed to paste, which a click on the bubble retries.
    private var heldText = ""

    private var state: RimState = .idle
    private var stateStartedAt: CFTimeInterval = 0
    private var lastFrameAt: CFTimeInterval?
    private var simulation = RimSimulation(collapsesWhenDone: true)
    private var extractor = RimFeatureExtractor(attack: RimParameters.approved.attack, release: RimParameters.approved.release)
    private var words = RimWords(measure: { PillWordsView.width(of: $0, size: $1) })
    private var reduceMotion = false

    private init() {
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { PillPresenter.shared.position(on: nil) }
        }
    }

    /// Feeds 16 kHz mono samples from the microphone, the same chunks the
    /// transcriber reads. Call it from one task at a time; it never blocks.
    nonisolated func feed(_ chunk: [Float]) {
        self.audio.ingest(chunk)
    }

    /// Shows what the dictation controller published.
    func show(_ pill: PillState) {
        switch pill {
        case .hidden:
            switch self.state {
            case .listen, .think:
                self.finish(pasted: false)
            case .flux, .problem:
                self.isHoldingFailedPaste = false
                self.isRetrying = false
                self.pressFiresAt = nil
                self.enter(.idle)
            case .idle, .done, .pasted, .fixed:
                // A paste's own collapse ends it; anything else is already leaving.
                break
            }
        case let .listening(preview, _):
            // Hands-free and held look the same.
            if self.state != .listen { self.beginListening() }
            self.hear(preview)
        case .micSilent, .recordingLimitNear:
            // Recording goes on; the rim's own pulse shows when it hears no speech.
            if self.state != .listen { self.beginListening() }
        case .finishing, .cleaning, .recordingStoppedAtLimit:
            if self.state == .listen {
                self.beginProcessing()
            } else if self.state != .think {
                self.showProcessing()
            }
        case .pasted, .pastedRawTranscript:
            // A fallback paste is quiet: it ends in mint like any other.
            self.finish(pasted: true)
        case let .nowhereToPaste(text):
            self.heldText = text
            self.holdFailedPaste()
        case .cancelled:
            self.finish(pasted: false)
        case let .permissionMissing(permission):
            self.showLock(for: permission)
        }
    }

    /// The pasted text: in the pill, the words settle into it; above the pill they stay a preview.
    func showPastedText(_ text: String) {
        guard self.liveWords == .inPill, self.words.hasWords, self.state == .think || self.state == .done else { return }
        self.words.cleanUp(text, reduced: self.reduceMotion)
        self.wake()
    }

    /// Builds the panel and compiles the shader once. Returns false when this Mac cannot draw the pill.
    @discardableResult
    func prepare() -> Bool {
        if self.window != nil { return true }
        if self.didFailToPrepare { return false }
        guard let device = MTLCreateSystemDefaultDevice(),
              let renderer = PillRenderer(device: device, pixelFormat: .bgra8Unorm)
        else {
            self.didFailToPrepare = true
            return false
        }
        let window = PillWindow(device: device, size: Self.panelSize(wordsAbove: self.liveWords == .above))
        renderer.frame = { [weak self] in self?.nextFrame() ?? [Float](repeating: 0, count: RimUniform.count) }
        window.rimView.delegate = renderer
        self.window = window
        self.renderer = renderer
        self.bubbleTarget = PillBubbleTarget(
            onHover: { PillPresenter.shared.setBubbleHover($0) },
            onClick: { PillPresenter.shared.bubbleClicked() }
        )
        window.orderFrontRegardless()
        self.position(on: PillWindow.screenForPointer())
        return true
    }

    // MARK: - Dictation states

    /// Key down: the pill grows from a point and the rim listens.
    private func beginListening() {
        guard self.prepare() else { return }
        // A new dictation supersedes anything waiting: the bubble merges back into the pill.
        self.isHoldingFailedPaste = false
        self.isRetrying = false
        self.pressFiresAt = nil
        if !self.isShowingBubble { self.position(on: PillWindow.screenForPointer()) }
        self.reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        // The words of a transcript still waiting in the bubble leave as the new dictation starts.
        if self.words.hasWords, self.state == .flux { self.words.dropAll() } else { self.words.clear() }
        self.extractor.reset()
        self.audio.setActive(true)
        self.enter(.listen)
    }

    /// A new live preview of everything heard so far, shown in the pill or in the bubble above it.
    private func hear(_ text: String) {
        guard self.state == .listen, self.liveWords != .off else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || self.words.hasWords else { return }
        self.words.hear(trimmed, reduced: self.reduceMotion)
        self.wake()
    }

    /// Key up: the rim's light travels inward to the centre line.
    private func beginProcessing() {
        guard self.state == .listen else { return }
        self.audio.setActive(false)
        self.words.release()
        self.enter(.think)
    }

    /// Processing shown after the pill already left. Grows straight into the centre line.
    private func showProcessing() {
        guard self.prepare() else { return }
        self.showFromNothing()
        self.audio.setActive(false)
        self.enter(.think)
    }

    /// The dictation finished. A paste turns the line green first; anything else goes straight away.
    private func finish(pasted: Bool) {
        guard self.state == .listen || self.state == .think else { return }
        self.audio.setActive(false)
        if !pasted { self.words.dropAll() }
        self.enter(pasted ? .done : .idle)
    }

    /// A paste found nowhere to go, and its transcript waits in a bubble beside the pill for a click.
    private func holdFailedPaste() {
        guard self.prepare(), !(self.isHoldingFailedPaste && self.state == .flux) else { return }
        self.isHoldingFailedPaste = true
        self.isRetrying = false
        self.audio.setActive(false)
        self.showFromNothing()
        self.enter(.flux)
    }

    /// A retry of the held transcript landed: the pill and the bubble turn green and the bubble dissolves.
    private func retryPasteSucceeded() {
        guard self.isHoldingFailedPaste, self.prepare() else { return }
        self.isHoldingFailedPaste = false
        self.isRetrying = false
        self.enter(.pasted)
    }

    /// A retry of the held transcript failed again: soft orange and one shake; the transcript keeps waiting.
    func retryPasteFailed() {
        guard self.isHoldingFailedPaste, self.state == .flux else { return }
        self.isRetrying = false
        self.simulation.failRetry(reduced: self.reduceMotion)
        self.wake()
    }

    /// A permission is missing: the pill shows amber with a lock in its bubble. A click opens its settings pane.
    private func showLock(for permission: DictationController.Permission) {
        guard self.prepare() else { return }
        self.lockedPermission = permission
        self.audio.setActive(false)
        self.isHoldingFailedPaste = false
        self.isRetrying = false
        self.pressFiresAt = nil
        self.showFromNothing()
        self.simulation.problem = .lock
        self.enter(.problem)
    }

    /// A pill that has fully gone comes back on the screen under the pointer.
    private func showFromNothing() {
        guard self.state == .idle, self.simulation.isGone else { return }
        self.reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        self.position(on: PillWindow.screenForPointer())
    }

    private var isShowingBubble: Bool { self.state == .flux || self.state == .problem }

    private func setBubbleHover(_ on: Bool) {
        self.simulation.setBubbleHover(on)
        self.wake()
    }

    /// The bubble bumps under the click, and its action fires once the bump has started.
    private func bubbleClicked() {
        guard self.simulation.bubble.isWaiting, !self.isRetrying, self.pressFiresAt == nil else { return }
        guard self.state == .flux || self.state == .problem else { return }
        self.simulation.pressBubble(showsFlash: false, reduced: self.reduceMotion)
        if self.state == .flux { self.isRetrying = true }
        self.pressedState = self.state
        self.pressFiresAt = CACurrentMediaTime() + Double(RimParameters.pressDelay)
        self.wake()
    }

    private func takeBubbleAction() {
        guard self.state == self.pressedState else { return }
        if self.state == .problem {
            // The lock waits until the controller shows something else; the click only opens the pane.
            if let permission = self.lockedPermission { self.openPermissionSettings?(permission) }
            return
        }
        guard let retryPaste = self.retryPaste else {
            self.isRetrying = false
            return
        }
        let text = self.heldText
        Task { @MainActor in
            if await retryPaste(text) { self.retryPasteSucceeded() } else { self.retryPasteFailed() }
        }
    }

    private func enter(_ state: RimState) {
        self.state = state
        self.stateStartedAt = CACurrentMediaTime()
        self.wake()
    }

    private func wake() {
        guard let view = self.window?.rimView else { return }
        view.preferredFramesPerSecond = Self.activeFps
        if view.isPaused {
            self.lastFrameAt = nil
            view.isPaused = false
        }
    }

    // MARK: - Frames

    /// Steps the voice features and the rim, then returns this frame's uniforms.
    private func nextFrame() -> [Float] {
        let now = CACurrentMediaTime()
        // Clamp so a long pause never jumps the animation.
        let dt = Float(min(max(now - (self.lastFrameAt ?? now - 1.0 / 60), 0), 0.1))
        self.lastFrameAt = now
        var elapsed = Float(now - self.stateStartedAt)

        let p = self.simulation.params
        if self.state == .done || self.state == .pasted, elapsed > p.greenHold + p.collapseTime + 0.05 {
            self.enter(.idle)
            elapsed = 0
        }
        if let firesAt = self.pressFiresAt, now >= firesAt {
            self.pressFiresAt = nil
            self.takeBubbleAction()
        }

        let features = self.state == .listen
            ? self.extractor.step(dt: dt, raw: self.audio.latestBands())
            : RimFeatures()
        self.words.setPill(height: RimParameters.pillSize.height)
        self.words.setAbove(self.liveWords == .above)
        self.words.step(dt: dt, reduced: self.reduceMotion)
        self.simulation.liveWordsInPill = self.liveWords == .inPill
        self.simulation.wordsShown = self.liveWords == .inPill && self.words.hasWords
        self.simulation.wordsAbove = self.wordsAboveTarget
        self.simulation.wordsGap = RimWordsBubble.gap * Float(self.words.scale)
        self.simulation.update(
            dt: dt, state: self.state, features: features, reduced: self.reduceMotion, pill: self.words.pillSize(base: RimParameters.pillSize)
        )
        if self.simulation.isGone, !self.words.isEmpty { self.words.clear() }
        let uniforms = self.simulation.uniforms(
            state: self.state,
            stateTime: elapsed,
            displayScale: Float(self.window?.backingScaleFactor ?? 2),
            reduced: self.reduceMotion,
            dimAtRest: true
        )
        self.placeBubbleTarget()
        self.showWords()

        if self.state == .idle, self.words.isEmpty, self.simulation.isGone {
            // This frame is fully transparent; nothing to draw until the next key down.
            self.window?.rimView.isPaused = true
        }
        return uniforms
    }

    /// The size the words need above the pill. The bubble is for while you talk and while the AI
    /// works; a paste, or a failed one, takes it back in.
    private var wordsAboveTarget: CGSize? {
        let keeps = self.liveWords == .above && self.words.hasWords && (self.state == .listen || self.state == .think)
        return keeps ? self.words.aboveSize : nil
    }

    private func showWords() {
        guard let wordsView = self.window?.wordsView else { return }
        let scale = self.window?.backingScaleFactor ?? 2
        let thinking = self.state == .think
        if self.words.isAbove {
            let bubble = self.simulation.wordsBubble
            let inner = Float(max(1, bubble.size.width - 2 * self.words.padding))
            wordsView.show(
                self.words.looks(thinking: thinking, inner: inner, reduced: self.reduceMotion),
                words: self.words,
                box: bubble.size,
                // The shader's y grows downward and the view's upward.
                offset: CGPoint(x: 0, y: CGFloat(-bubble.y)),
                look: (SIMD2(1, 1), bubble.textOpacity),
                scale: scale
            )
            return
        }
        let pill = self.simulation.size
        let inner = Float(max(1, pill.width - 2 * self.words.padding))
        let look = self.simulation.wordsLook()
        wordsView.show(
            self.words.looks(thinking: thinking, inner: inner, reduced: self.reduceMotion),
            words: self.words,
            box: pill,
            offset: CGPoint(x: CGFloat(look.offsetX), y: 0),
            look: (look.scale, look.opacity),
            scale: scale
        )
    }

    // MARK: - Placement

    private func fitPanel() {
        guard let window = self.window else { return }
        let size = Self.panelSize(wordsAbove: self.liveWords == .above)
        if window.frame.size != size {
            window.setContentSize(size)
            self.position(on: nil)
        }
        self.wake()
    }

    /// The bubble takes clicks through its own small panel, so the pill's panel
    /// stays click-through and a click never lands on the pill's empty corners.
    private func placeBubbleTarget() {
        guard let target = self.bubbleTarget, let window = self.window else { return }
        guard self.simulation.bubble.isWaiting else {
            target.hide()
            return
        }
        let pill = self.simulation.size
        let k = pill.height / CGFloat(RimSpring.islandHeight)
        let p = self.simulation.params
        let radius = 0.5 * CGFloat(p.fluxSize) * pill.height
        let offset = pill.width / 2 + CGFloat(p.fluxGap) * k + radius
        target.show(centre: NSPoint(x: window.frame.midX + offset, y: window.frame.midY), radius: radius, label: self.bubbleLabel)
    }

    private var bubbleLabel: String {
        guard self.state == .problem else { return "Paste transcript" }
        switch self.lockedPermission {
        case .accessibility: return "Open Accessibility settings"
        case .microphone, nil: return "Open Microphone settings"
        }
    }

    /// Puts the pill on its spot on `screen`, or on the screen it is on: centred,
    /// `dockMargin` above the bottom of the visible area.
    private func position(on screen: NSScreen?) {
        guard let window = self.window, let screen = screen ?? window.screen ?? PillWindow.screenForPointer() else { return }
        let centre = CGPoint(x: screen.frame.midX, y: screen.visibleFrame.minY + Self.dockMargin + RimParameters.pillSize.height / 2)
        let size = window.frame.size
        let scale = max(1, window.backingScaleFactor)
        let origin = NSPoint(
            x: ((centre.x - size.width / 2) * scale).rounded() / scale,
            y: ((centre.y - size.height / 2) * scale).rounded() / scale
        )
        // Moving a window waits on the window server; skip it when nothing changed.
        if window.frame.origin != origin { window.setFrameOrigin(origin) }
        // On a screen with another scale the layer has to follow, or the pill draws at the wrong size.
        if let layer = window.rimView.layer, layer.contentsScale != window.backingScaleFactor {
            layer.contentsScale = window.backingScaleFactor
        }
    }
}
