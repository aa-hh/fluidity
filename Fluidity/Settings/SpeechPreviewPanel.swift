import FluidityCore
import SwiftUI

/// The pill sample, played again each time `playCount` changes.
private struct PillSample: NSViewRepresentable {
    let liveWords: LiveWords
    let cleanupOn: Bool
    let isVisible: Bool
    let playCount: Int
    let onPasted: () -> Void

    final class Coordinator {
        var playCount = 0
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> PillSampleView { PillSampleView(frame: .zero) }

    func updateNSView(_ view: PillSampleView, context: Context) {
        view.liveWords = liveWords
        view.cleanupOn = cleanupOn
        view.onPasted = onPasted
        if playCount != context.coordinator.playCount {
            context.coordinator.playCount = playCount
            view.play()
        }
        if !isVisible { view.stop() }
    }

    static func dismantleNSView(_ view: PillSampleView, coordinator: Coordinator) {
        view.stop()
    }
}

/// Plays a scripted dictation with the current Live words, speech model and cleanup choices.
struct SpeechPreviewPanel: View {
    let model: SettingsModel
    @State private var playCount = 0
    @State private var landed = false
    @State private var isVisible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var cleanupOn: Bool { model.isCleanupEnabled && model.cleanupKey != .noKey }

    var body: some View {
        let inner = RoundedRectangle(cornerRadius: GlassTheme.innerRadius, style: .continuous)
        GlassPanel {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Preview").font(GlassTheme.label).foregroundStyle(GlassTheme.textPrimary)
                    Spacer()
                    Button("Play again") { play() }
                        .buttonStyle(.glassQuiet)
                        .padding(.trailing, -10)
                }
                VStack(spacing: 4) {
                    Text(landed ? SpeechPreview.pastedText(cleanupOn: cleanupOn) : "")
                        .font(GlassTheme.body)
                        .foregroundStyle(GlassTheme.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        // Keeps the box from collapsing while it waits for the paste.
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .background(GlassTheme.raised, in: inner)
                        .overlay { inner.strokeBorder(GlassTheme.lineRule, lineWidth: 1) }
                        .accessibilityLabel("Pasted text")
                        .accessibilityValue(landed ? SpeechPreview.pastedText(cleanupOn: cleanupOn) : "")
                    PillSample(liveWords: model.liveWords, cleanupOn: cleanupOn, isVisible: isVisible,
                               playCount: playCount, onPasted: { landed = true })
                        .frame(maxWidth: .infinity)
                        .frame(height: 140)
                }
                .padding(.horizontal, 12)
                .padding(.top, 16)
                .padding(.bottom, 4)
                .background(GlassTheme.hover, in: inner)
                .clipShape(inner)
                if cleanupOn {
                    HStack(spacing: 6) {
                        Text("You said")
                        Text(SpeechPreview.rawSentence)
                    }
                    .font(GlassTheme.detail)
                    .foregroundStyle(GlassTheme.textSecondary)
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .onScrollVisibilityChange(threshold: 0.5) { visible in
            isVisible = visible
            if visible { play() }
        }
        .onChange(of: model.liveWords) { play() }
        .onChange(of: cleanupOn) { play() }
        .onChange(of: model.speechModel) { play() }
    }

    private func play() {
        if reduceMotion {
            landed = true
            return
        }
        landed = false
        playCount += 1
    }
}
