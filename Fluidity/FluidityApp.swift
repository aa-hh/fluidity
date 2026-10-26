import FluidityCore
import SwiftUI

@main
struct FluidityApp: App {
    init() { PillPreview.startIfAsked() }

    var body: some Scene {
        MenuBarExtra("Fluidity", systemImage: "waveform") {
            Button("Quit Fluidity") { NSApplication.shared.terminate(nil) }
        }
    }
}
