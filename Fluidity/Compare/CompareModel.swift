import AVFoundation
import FluidityCore
import Observation

/// The compare window's state: the session runs the comparison; the app shell writes the model states,
/// the model in use and which engines have loaded, and fills the `on…` closures.
@MainActor
@Observable
final class CompareModel {
    let session: CompareSession
    var modelStates: [SpeechModelID: ModelState] = [:]
    /// The model dictation uses while the window is open.
    var inUse: SpeechModelID = .parakeetTDTv2
    /// A dictation is running, so the keys are its own and Speak Now waits.
    var dictationRunning = false
    /// Models whose engines have finished loading for this window.
    var loaded: Set<SpeechModelID> = []
    /// The dictation key's name, for the status line.
    var dictationKey = ""

    var onDownload: (SpeechModelID) -> Void = { _ in }
    var onCancelDownload: (SpeechModelID) -> Void = { _ in }
    /// Keep Current, Escape and the close button: close and change nothing.
    var onKeep: () -> Void = {}
    /// Switch Model: dictate with the right-hand model.
    var onSwitch: () -> Void = {}

    private let player = RecordingPlayer()

    init(session: CompareSession) {
        self.session = session
    }

    func isOnMac(_ id: SpeechModelID) -> Bool {
        [.installed, .partOfMacOS].contains(modelStates[id])
    }

    var bothOnMac: Bool { isOnMac(session.left) && isOnMac(session.right) }
    var bothReady: Bool { bothOnMac && loaded.contains(session.left) && loaded.contains(session.right) }

    func playRecording() { player.play(session.recording) }
    func stopPlaying() { player.stop() }
}

/// Plays a 16 kHz mono recording through the default output.
@MainActor
private final class RecordingPlayer {
    private let engine = AVAudioEngine()
    private let node = AVAudioPlayerNode()
    private let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16_000, channels: 1, interleaved: false)!

    init() {
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
    }

    func play(_ samples: [Float]) {
        guard !samples.isEmpty,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count))
        else { return }
        buffer.frameLength = buffer.frameCapacity
        samples.withUnsafeBufferPointer { buffer.floatChannelData![0].update(from: $0.baseAddress!, count: samples.count) }
        node.stop()
        do {
            if !engine.isRunning { try engine.start() }
        } catch {
            return
        }
        node.scheduleBuffer(buffer)
        node.play()
    }

    func stop() {
        node.stop()
        engine.stop()
    }
}
