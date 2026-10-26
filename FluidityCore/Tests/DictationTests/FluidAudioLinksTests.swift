import FluidAudio
import FluidityCore
import Testing

// Turns red if the package stops resolving or linking FluidAudio's speech-to-text.
@Test func fluidAudioSpeechToTextLinks() {
    #expect(AsrModelVersion.v2 != AsrModelVersion.v3)
}
