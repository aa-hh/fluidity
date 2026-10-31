import AppKit
import FluidityCore
import Metal
import MetalKit
import QuartzCore

/// The pill drawn inside the settings window, playing `SpeechPreview`'s script with the pill's own
/// renderer and words. It keeps its own rim state and never touches the recording pill.
@MainActor
final class PillSampleView: NSView {
    var liveWords: LiveWords = .inPill
    var cleanupOn = false
    var onPasted: (() -> Void)?

    private let rimView: MTKView?
    private let wordsView: PillWordsView
    private let renderer: PillRenderer?
    private var simulation = RimSimulation(collapsesWhenDone: true)
    private var extractor = RimFeatureExtractor(attack: RimParameters.approved.attack, release: RimParameters.approved.release)
    private var words = RimWords(measure: { PillWordsView.width(of: $0, size: $1) })
    private let analyzer = RimAudioAnalyzer()

    private var state: RimState = .idle
    private var stateStartedAt: CFTimeInterval = 0
    private var startedAt: CFTimeInterval = 0
    private var lastFrameAt: CFTimeInterval?
    private var lastPhase: SpeechPreview.Phase?
    /// Seconds of made-up voice fed so far, so the voice keeps real time whatever the frame rate.
    private var voiceFed: CFTimeInterval = 0
    private var reduceMotion = false

    private static let rawWords = SpeechPreview.rawSentence.split(separator: " ")

    override init(frame: NSRect) {
        self.wordsView = PillWordsView(frame: NSRect(origin: .zero, size: frame.size))
        if let device = MTLCreateSystemDefaultDevice(),
           let renderer = PillRenderer(device: device, pixelFormat: .bgra8Unorm) {
            let view = MTKView(frame: .zero, device: device)
            view.colorPixelFormat = .bgra8Unorm
            view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
            view.layer?.isOpaque = false
            view.framebufferOnly = true
            view.enableSetNeedsDisplay = false
            view.isPaused = true
            view.preferredFramesPerSecond = PillPresenter.activeFps
            self.rimView = view
            self.renderer = renderer
        } else {
            self.rimView = nil
            self.renderer = nil
        }
        super.init(frame: frame)
        if let rimView = self.rimView {
            rimView.frame = self.bounds
            rimView.autoresizingMask = [.width, .height]
            self.addSubview(rimView)
            rimView.delegate = self.renderer
        }
        self.wordsView.frame = self.bounds
        self.wordsView.autoresizingMask = [.width, .height]
        self.addSubview(self.wordsView)
        self.renderer?.frame = { [weak self] in self?.nextFrame() ?? [Float](repeating: 0, count: RimUniform.count) }
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let window = self.window {
            // An MTKView made at zero size outside a window can keep a contentsScale of 0 and draw nothing.
            self.rimView?.layer?.contentsScale = window.backingScaleFactor
        } else {
            self.rimView?.isPaused = true
        }
    }

    /// Plays the script from the start; under Reduce Motion, or with no Metal, it goes straight to the paste.
    func play() {
        self.reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        guard !self.reduceMotion, self.rimView != nil else {
            self.stop()
            self.onPasted?()
            return
        }
        self.words.clear()
        self.extractor.reset()
        self.analyzer.setActive(true)
        self.lastPhase = nil
        self.voiceFed = 0
        self.startedAt = CACurrentMediaTime()
        self.enter(.listen)
    }

    func stop() {
        self.rimView?.isPaused = true
        self.analyzer.setActive(false)
    }

    private func enter(_ state: RimState) {
        self.state = state
        self.stateStartedAt = CACurrentMediaTime()
        guard let view = self.rimView else { return }
        view.preferredFramesPerSecond = PillPresenter.activeFps
        if view.isPaused {
            self.lastFrameAt = nil
            view.isPaused = false
        }
    }

    /// Moves the rim and the words to where the script stands now.
    private func followScript(at now: CFTimeInterval) {
        let phase = SpeechPreview.phase(at: .seconds(now - self.startedAt), reduceMotion: false)
        defer { self.lastPhase = phase }
        switch phase {
        case let .listening(heard):
            while self.voiceFed < now - self.startedAt {
                self.analyzer.ingest(PillPreview.voice(loud: 1))
                self.voiceFed += PillPreview.tick
            }
            var before = 0
            if case let .listening(count) = self.lastPhase { before = count }
            if heard > before, self.liveWords != .off {
                self.words.hear(Self.rawWords.prefix(heard).joined(separator: " "), reduced: self.reduceMotion)
            }
        case .processing:
            guard self.lastPhase != .processing else { return }
            self.analyzer.setActive(false)
            self.words.release()
            self.enter(.think)
        case .pasted:
            guard self.lastPhase != .pasted else { return }
            self.enter(.done)
            if self.liveWords == .inPill, self.words.hasWords {
                self.words.cleanUp(SpeechPreview.pastedText(cleanupOn: self.cleanupOn), reduced: self.reduceMotion)
            }
            self.onPasted?()
        }
    }

    private func nextFrame() -> [Float] {
        let now = CACurrentMediaTime()
        // Clamp so a long pause never jumps the animation.
        let dt = Float(min(max(now - (self.lastFrameAt ?? now - 1.0 / 60), 0), 0.1))
        self.lastFrameAt = now
        self.followScript(at: now)
        var elapsed = Float(now - self.stateStartedAt)

        let p = self.simulation.params
        if self.state == .done, elapsed > p.greenHold + p.collapseTime + 0.05 {
            self.enter(.idle)
            elapsed = 0
        }

        let features = self.state == .listen
            ? self.extractor.step(dt: dt, raw: self.analyzer.latestBands())
            : RimFeatures()
        self.words.setPill(height: RimParameters.pillSize.height)
        self.words.setAbove(self.liveWords == .above)
        self.words.step(dt: dt, reduced: self.reduceMotion)
        self.simulation.liveWordsInPill = self.liveWords == .inPill
        self.simulation.wordsShown = self.liveWords == .inPill && self.words.hasWords
        let keepsAbove = self.liveWords == .above && self.words.hasWords && (self.state == .listen || self.state == .think)
        self.simulation.wordsAbove = keepsAbove ? self.words.aboveSize : nil
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
        self.showWords()

        if self.state == .idle, self.words.isEmpty, self.simulation.isGone {
            self.rimView?.isPaused = true
        }
        return uniforms
    }

    private func showWords() {
        let scale = self.window?.backingScaleFactor ?? 2
        let thinking = self.state == .think
        if self.words.isAbove {
            let bubble = self.simulation.wordsBubble
            let inner = Float(max(1, bubble.size.width - 2 * self.words.padding))
            self.wordsView.show(
                self.words.looks(reduced: self.reduceMotion),
                words: self.words,
                band: self.words.band(thinking: thinking, inner: inner, reduced: self.reduceMotion),
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
        self.wordsView.show(
            self.words.looks(reduced: self.reduceMotion),
            words: self.words,
            band: self.words.band(thinking: thinking, inner: inner, reduced: self.reduceMotion),
            box: pill,
            offset: CGPoint(x: CGFloat(look.offsetX), y: 0),
            look: (look.scale, look.opacity),
            scale: scale
        )
    }
}
