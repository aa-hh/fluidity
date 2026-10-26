import FluidityCore
import SwiftUI

@main
struct FluidityApp: App {
    var body: some Scene {
        MenuBarExtra("Fluidity", systemImage: "waveform") {
            Button("Quit Fluidity") { NSApplication.shared.terminate(nil) }
        }
    }
}
