import SwiftUI

@main
struct FluidityApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var app

    init() { PillPreview.startIfAsked() }

    var body: some Scene {
        // `AppDelegate` owns the menu bar item and the windows. A SwiftUI app needs one scene; this one never shows.
        MenuBarExtra("Fluidity", isInserted: .constant(false)) { EmptyView() }
    }
}
