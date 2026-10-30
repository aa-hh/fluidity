import AppKit
import FluidityCore

/// Shows one pill state without dictating, so each look can be checked by eye.
///
/// Launch with `FLUIDITY_PILL_PREVIEW` set to listening, finishing, cleaning,
/// pasted, pastedRawTranscript, nowhereToPaste, cancelled, microphoneMissing,
/// accessibilityMissing, micSilent, recordingLimitNear,
/// recordingStoppedAtLimit, modelLoadingLine or modelLoadingLineDownload, and optionally `FLUIDITY_PILL_WORDS` to inPill,
/// above or off. Most states follow two seconds of made-up speech; pasted and
/// cancelled repeat every five seconds. A click on the retry bubble fails.
@MainActor
enum PillPreview {
    private struct Script {
        var listensFor: Double? = 2
        var then: [(at: Double, state: PillState)] = []
        var repeatsEvery: Double?
        /// The made-up voice: silent after the listening part, or still speaking.
        var speaksAfter: Bool?
        /// The launch load's reports, at seconds from the start; the speech model loads from 0 until the done report.
        var loads: [(at: Double, progress: ModelLoadProgress)] = []
    }

    private static let sentence = "so this is how the words look while you are still talking to the pill".split(separator: " ")
    private static let tick = 0.02
    private static var script = Script()
    private static var startedAt = Date()
    private static var nextStep = 0
    private static var nextLoad = 0
    private static var sample = 0

    static func startIfAsked() {
        let environment = ProcessInfo.processInfo.environment
        guard let name = environment["FLUIDITY_PILL_PREVIEW"], let script = Self.script(named: name) else { return }
        // After launch finishes, so the panel is made in a running app.
        DispatchQueue.main.async {
            let pill = PillPresenter.shared
            if let words = environment["FLUIDITY_PILL_WORDS"].flatMap(LiveWords.init(rawValue:)) { pill.liveWords = words }
            pill.retryPaste = { _ in false }
            Self.script = script
            Self.restart()
            Timer.scheduledTimer(withTimeInterval: Self.tick, repeats: true) { _ in
                MainActor.assumeIsolated { Self.step() }
            }
        }
    }

    private static func script(named name: String) -> Script? {
        let processing: [(at: Double, state: PillState)] = [(0, .finishing), (0.25, .cleaning)]
        let pasted = "So this is how the words look while you are still talking to the pill."
        switch name {
        case "listening": return Script(listensFor: .infinity)
        case "finishing": return Script(then: [(0, .finishing)])
        case "cleaning": return Script(then: processing)
        case "pasted": return Script(then: processing + [(1, .pasted(text: pasted)), (1.6, .hidden)], repeatsEvery: 5)
        case "pastedRawTranscript":
            return Script(then: processing + [(1, .pastedRawTranscript(text: pasted)), (1.6, .hidden)], repeatsEvery: 5)
        case "nowhereToPaste": return Script(then: processing + [(1, .nowhereToPaste(text: pasted))])
        case "cancelled": return Script(then: [(0, .cancelled), (0.12, .hidden)], repeatsEvery: 4)
        case "microphoneMissing": return Script(listensFor: nil, then: [(0, .permissionMissing(.microphone))])
        case "accessibilityMissing": return Script(then: [(0, .finishing), (0.5, .permissionMissing(.accessibility))])
        case "micSilent": return Script(then: [(0, .micSilent)], speaksAfter: false)
        case "recordingLimitNear": return Script(then: [(0, .recordingLimitNear)], speaksAfter: true)
        case "recordingStoppedAtLimit": return Script(then: [(0, .recordingStoppedAtLimit)])
        case "modelLoadingLine":
            let load = { (step: Int) in ModelLoadProgress(step: step, stepCount: 2, needsDownload: false, downloaded: nil) }
            return Script(
                listensFor: 4, then: [(0, .finishing), (17.75, .pasted(text: pasted)), (18.35, .hidden)], repeatsEvery: 23,
                loads: [(0, load(0)), (1, load(1)), (21, load(2))]
            )
        case "modelLoadingLineDownload":
            let load = { (step: Int, downloaded: Double?) in
                ModelLoadProgress(step: step, stepCount: 2, needsDownload: true, downloaded: downloaded)
            }
            // The download reports every tick from 1 s to 9 s.
            let ramp = stride(from: 1.0, through: 9.0, by: Self.tick).map { (at: $0, progress: load(1, ($0 - 1) / 8)) }
            return Script(
                listensFor: 4, then: [(0, .finishing), (18.75, .pasted(text: pasted)), (19.35, .hidden)], repeatsEvery: 24,
                loads: [(0, load(0, nil))] + ramp + [(22, load(2, nil))]
            )
        default: return nil
        }
    }

    private static func restart() {
        Self.startedAt = Date()
        Self.nextStep = 0
        Self.nextLoad = 0
    }

    private static func step() {
        let pill = PillPresenter.shared
        var t = Date().timeIntervalSince(Self.startedAt)
        if let period = Self.script.repeatsEvery, t >= period {
            Self.restart()
            t = 0
        }
        let listening = Self.script.listensFor ?? 0
        while Self.nextLoad < Self.script.loads.count, t >= Self.script.loads[Self.nextLoad].at {
            pill.reportModelLoad(Self.script.loads[Self.nextLoad].progress)
            Self.nextLoad += 1
        }
        let doneAt = Self.script.loads.first { $0.progress.isDone }?.at
        let loading = doneAt.map { t < $0 } ?? false
        if pill.isModelLoading != loading { pill.isModelLoading = loading }
        if t < listening {
            // No live words come while the speech model loads.
            let count = loading ? 0 : min(Self.sentence.count, Int(t / 0.22) + 1)
            pill.show(.listening(preview: Self.sentence.prefix(count).joined(separator: " "), mode: .held))
            pill.feed(Self.voice(loud: 1))
            return
        }
        if let speaks = Self.script.speaksAfter { pill.feed(Self.voice(loud: speaks ? 1 : 0)) }
        let after = t - listening
        while Self.nextStep < Self.script.then.count, after >= Self.script.then[Self.nextStep].at {
            let state = Self.script.then[Self.nextStep].state
            switch state {
            case .pasted(let text), .pastedRawTranscript(let text): pill.showPastedText(text)
            default: break
            }
            pill.show(state)
            Self.nextStep += 1
        }
    }

    /// One tick of a made-up voice at 16 kHz: a gliding pitch with falling harmonics,
    /// in syllables about six times a second, with a hiss now and then.
    private static func voice(loud: Float) -> [Float] {
        let rate: Float = 16_000
        let count = Int(Double(rate) * Self.tick)
        var chunk = [Float](repeating: 0, count: count)
        for index in 0..<count {
            let time = Float(Self.sample + index) / rate
            let syllable = max(0, sin(2 * .pi * 3 * time))
            let pitch = 140 + 25 * sin(2 * .pi * 0.7 * time)
            var tone: Float = 0
            for harmonic in 1...12 { tone += sin(2 * .pi * pitch * Float(harmonic) * time) / Float(harmonic) }
            let hiss: Float = time.truncatingRemainder(dividingBy: 0.9) < 0.08 ? Float.random(in: -0.05...0.05) : 0
            chunk[index] = loud * (0.12 * syllable * syllable * tone + hiss)
        }
        Self.sample += count
        return chunk
    }
}
