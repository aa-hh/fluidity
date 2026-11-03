import AVFoundation
import Observation
import RilloCore
import SwiftUI

/// Plays one dictation's saved recording and follows which raw transcript word is being heard.
@MainActor
@Observable
final class HistoryPlayer {
    private(set) var isLoaded = false
    private(set) var failed = false
    private(set) var isPlaying = false
    private(set) var time: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    /// Peak levels, 0 to 1, in time order, for the waveform.
    private(set) var levels: [Float] = []
    /// The raw transcript word being heard, by its index.
    private(set) var heardWord: Int?

    @ObservationIgnored private var player: AVAudioPlayer?
    @ObservationIgnored private var timeline = TranscriptTimeline(timings: [], transcript: "")
    @ObservationIgnored private var ticker: Task<Void, Never>?

    /// Loads the recording at `url`, or clears the player when `url` is nil.
    func load(_ url: URL?, record: DictationRecord) async {
        stop()
        player = nil
        isLoaded = false
        failed = false
        levels = []
        guard let url else { return }
        guard let player = try? AVAudioPlayer(contentsOf: url) else {
            failed = true
            return
        }
        player.prepareToPlay()
        self.player = player
        duration = player.duration
        time = 0
        isLoaded = true
        timeline = TranscriptTimeline(timings: record.wordTimings, transcript: record.rawTranscript)
        let levels = await Task.detached { Self.levels(of: url, count: 200) }.value
        // Another dictation may have been chosen while the levels were read.
        guard self.player === player else { return }
        self.levels = levels
    }

    func toggle() {
        guard let player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
            ticker?.cancel()
        } else {
            player.play()
            isPlaying = true
            ticker = Task { [weak self] in
                while !Task.isCancelled {
                    self?.tick()
                    try? await Task.sleep(for: .milliseconds(30))
                }
            }
        }
    }

    func seek(to time: TimeInterval) {
        guard let player else { return }
        player.currentTime = min(max(0, time), duration)
        tick()
    }

    /// Jumps to the start of a raw transcript word and plays from there.
    func play(fromWord index: Int) {
        guard let start = timeline.start(ofWord: index) else { return }
        seek(to: start)
        if !isPlaying { toggle() }
    }

    func stop() {
        player?.stop()
        player?.currentTime = 0
        ticker?.cancel()
        isPlaying = false
        time = 0
        heardWord = nil
    }

    private func tick() {
        guard let player else { return }
        if isPlaying && !player.isPlaying {
            // Reached the end.
            stop()
            return
        }
        time = player.currentTime
        let heard = timeline.word(at: time)
        // Paused at the start, nothing is being heard.
        if heard != heardWord { heardWord = isPlaying || time > 0 ? heard : nil }
    }

    nonisolated private static func levels(of url: URL, count: Int) -> [Float] {
        guard let file = try? AVAudioFile(forReading: url),
              let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)),
              (try? file.read(into: buffer)) != nil,
              let samples = buffer.floatChannelData?[0], buffer.frameLength > 0
        else { return [] }
        let frames = Int(buffer.frameLength)
        let peaks = (0..<count).map { bucket in
            let range = (bucket * frames / count)..<max(bucket * frames / count + 1, (bucket + 1) * frames / count)
            return range.reduce(Float(0)) { max($0, abs(samples[min($1, frames - 1)])) }
        }
        let loudest = max(peaks.max() ?? 0, 0.0001)
        return peaks.map { $0 / loudest }
    }
}

/// The player under the detail header: play or pause, the time, and the waveform, which fills as it plays and
/// jumps where it is clicked.
struct HistoryPlayerBar: View {
    let player: HistoryPlayer

    var body: some View {
        HStack(spacing: 10) {
            Button { player.toggle() } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(GlassTheme.textPrimary)
                    .frame(width: 22, height: 22)
                    .background(GlassTheme.selected, in: Circle())
                    .contentShape(Circle())
                    .glassFocusRing(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(player.isPlaying ? "Pause recording" : "Play recording")
            Text("\(Self.clock(player.time)) / \(Self.clock(player.duration))")
                .font(GlassTheme.small.monospacedDigit())
                .foregroundStyle(GlassTheme.textSecondary)
                .accessibilityHidden(true)
            Waveform(levels: player.levels, progress: player.duration > 0 ? player.time / player.duration : 0)
                .frame(height: 20)
                .overlay {
                    GeometryReader { geometry in
                        Color.clear.contentShape(Rectangle()).onTapGesture { location in
                            player.seek(to: player.duration * location.x / max(1, geometry.size.width))
                        }
                    }
                }
                .accessibilityHidden(true)
        }
        .frame(height: 28)
    }

    private static func clock(_ seconds: TimeInterval) -> String {
        let whole = Int(seconds.rounded(.down))
        return "\(whole / 60):\(String(format: "%02d", whole % 60))"
    }
}

/// Bars 2 pt wide, 1.5 pt apart; played bars in primary text, the rest in secondary.
private struct Waveform: View {
    let levels: [Float]
    let progress: Double

    var body: some View {
        Canvas { context, size in
            let count = max(1, Int(size.width / 3.5))
            for bar in 0..<count {
                let level = levels.isEmpty ? 0.15 : CGFloat(levels[bar * levels.count / count])
                let height = max(2, size.height * level)
                let rect = CGRect(x: CGFloat(bar) * 3.5, y: (size.height - height) / 2, width: 2, height: height)
                let played = Double(bar) / Double(count) < progress
                context.fill(Path(roundedRect: rect, cornerRadius: 1),
                             with: .color(played ? GlassTheme.textPrimary : GlassTheme.textSecondary.opacity(0.5)))
            }
        }
    }
}
